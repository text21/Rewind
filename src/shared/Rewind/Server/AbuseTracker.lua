--!strict
--[[
	AbuseTracker - Tracks abuse events and provides DataStore persistence

	Monitors and logs abuse events (rate limiting, duplicate shots, impossible hits)
	for analysis and potential banning. Optionally persists to DataStore.

	v1.2.0: Initial implementation

	Usage:
		-- Enable tracking with DataStore
		Rewind.StartAbuseTracking({
			useDataStore = true,
			dataStoreName = "RewindAbuseLog",
			thresholds = {
				warnAt = 10,      -- Warn after 10 violations
				kickAt = 50,      -- Kick after 50 violations
				banAt = 100,      -- Consider ban after 100 violations
			},
		})

		-- Listen for abuse events
		Rewind.OnAbuseDetected:Connect(function(player, record)
			print(player.Name, "abuse:", record.reason, "count:", record.count)
		end)

		-- Check a player's abuse history
		local history = Rewind.GetAbuseHistory(player)
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local AbuseTracker = {}

export type AbuseReason =
	| "rate_limited"
	| "duplicate_shot"
	| "impossible_distance"
	| "future_timestamp"
	| "past_timestamp"
	| "invalid_origin"
	| "speed_hack"
	| "teleport"
	| "fly_hack"
	| "invalid_target"

export type AbuseRecord = {
	reason: AbuseReason,
	count: number,
	firstOccurrence: number,
	lastOccurrence: number,
	metadata: { [string]: any }?,
}

export type PlayerAbuseHistory = {
	playerId: number,
	playerName: string,
	records: { [AbuseReason]: AbuseRecord },
	totalViolations: number,
	sessionViolations: number,
	isBanned: boolean,
	lastSeen: number,
}

export type AbuseConfig = {
	enabled: boolean?,
	useDataStore: boolean?,
	dataStoreName: string?,
	thresholds: {
		warnAt: number?,
		kickAt: number?,
		banAt: number?,
	}?,
	autoKick: boolean?,
	autoBan: boolean?,
	saveInterval: number?,
}

local DEFAULT_CONFIG: AbuseConfig = {
	enabled = true,
	useDataStore = false,
	dataStoreName = "RewindAbuseLog",
	thresholds = {
		warnAt = 10,
		kickAt = 50,
		banAt = 100,
	},
	autoKick = false,
	autoBan = false,
	saveInterval = 60,
}

local _config: AbuseConfig = DEFAULT_CONFIG
local _dataStore: DataStore? = nil
local _playerHistories: { [Player]: PlayerAbuseHistory } = {}
local _onAbuseDetected = Instance.new("BindableEvent")
local _onThresholdReached = Instance.new("BindableEvent")
local _saveQueue: { Player } = {}
local _lastSaveTime = 0
local _started = false

-- Public events
AbuseTracker.OnAbuseDetected = _onAbuseDetected.Event
AbuseTracker.OnThresholdReached = _onThresholdReached.Event

--[[
	Start the abuse tracking system

	@param config AbuseConfig options
]]
function AbuseTracker.Start(config: AbuseConfig?)
	if _started then return end
	_started = true

	_config = {
		enabled = if config and config.enabled ~= nil then config.enabled else DEFAULT_CONFIG.enabled,
		useDataStore = config and config.useDataStore or DEFAULT_CONFIG.useDataStore,
		dataStoreName = config and config.dataStoreName or DEFAULT_CONFIG.dataStoreName,
		thresholds = {
			warnAt = config and config.thresholds and config.thresholds.warnAt or DEFAULT_CONFIG.thresholds.warnAt,
			kickAt = config and config.thresholds and config.thresholds.kickAt or DEFAULT_CONFIG.thresholds.kickAt,
			banAt = config and config.thresholds and config.thresholds.banAt or DEFAULT_CONFIG.thresholds.banAt,
		},
		autoKick = config and config.autoKick or DEFAULT_CONFIG.autoKick,
		autoBan = config and config.autoBan or DEFAULT_CONFIG.autoBan,
		saveInterval = config and config.saveInterval or DEFAULT_CONFIG.saveInterval,
	}

	if _config.useDataStore and RunService:IsServer() then
		local success, store = pcall(function()
			return DataStoreService:GetDataStore(_config.dataStoreName :: string)
		end)
		if success then
			_dataStore = store
		else
			warn("[Rewind.AbuseTracker] Failed to get DataStore:", store)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		AbuseTracker._loadPlayerHistory(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		AbuseTracker._savePlayerHistory(player)
		_playerHistories[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		AbuseTracker._loadPlayerHistory(player)
	end

	if _config.useDataStore then
		task.spawn(function()
			while _started do
				task.wait(_config.saveInterval or 60)
				AbuseTracker._flushSaveQueue()
			end
		end)
	end
end

--[[
	Stop the abuse tracking system
]]
function AbuseTracker.Stop()
	_started = false

	for player, _ in pairs(_playerHistories) do
		AbuseTracker._savePlayerHistory(player)
	end
end

--[[
	Record an abuse event

	@param player The player who committed the abuse
	@param reason The type of abuse
	@param metadata Optional additional data
]]
function AbuseTracker.RecordAbuse(player: Player, reason: AbuseReason, metadata: { [string]: any }?)
	if not _config.enabled then return end

	local history = _playerHistories[player]
	if not history then
		history = AbuseTracker._createHistory(player)
	end

	local now = os.time()
	local record = history.records[reason]

	if record then
		record.count += 1
		record.lastOccurrence = now
		if metadata then
			record.metadata = metadata
		end
	else
		history.records[reason] = {
			reason = reason,
			count = 1,
			firstOccurrence = now,
			lastOccurrence = now,
			metadata = metadata,
		}
		record = history.records[reason]
	end

	history.totalViolations += 1
	history.sessionViolations += 1
	history.lastSeen = now

	_onAbuseDetected:Fire(player, record)

	AbuseTracker._checkThresholds(player, history)

	if _config.useDataStore and not table.find(_saveQueue, player) then
		table.insert(_saveQueue, player)
	end
end

--[[
	Get abuse history for a player

	@param player The player
	@return PlayerAbuseHistory or nil
]]
function AbuseTracker.GetHistory(player: Player): PlayerAbuseHistory?
	return _playerHistories[player]
end

--[[
	Get violation count for a specific reason

	@param player The player
	@param reason The abuse reason
	@return Count
]]
function AbuseTracker.GetViolationCount(player: Player, reason: AbuseReason): number
	local history = _playerHistories[player]
	if not history then return 0 end

	local record = history.records[reason]
	return record and record.count or 0
end

--[[
	Get total violations for a player

	@param player The player
	@return Total count
]]
function AbuseTracker.GetTotalViolations(player: Player): number
	local history = _playerHistories[player]
	return history and history.totalViolations or 0
end

--[[
	Clear abuse history for a player

	@param player The player
	@param reason Optional specific reason to clear (nil = all)
]]
function AbuseTracker.ClearHistory(player: Player, reason: AbuseReason?)
	local history = _playerHistories[player]
	if not history then return end

	if reason then
		local record = history.records[reason]
		if record then
			history.totalViolations -= record.count
			history.records[reason] = nil
		end
	else
		history.records = {}
		history.totalViolations = 0
	end

	history.sessionViolations = 0

	if _config.useDataStore then
		AbuseTracker._savePlayerHistory(player)
	end
end

--[[
	Check if a player should be banned

	@param player The player
	@return Whether they exceed ban threshold
]]
function AbuseTracker.ShouldBan(player: Player): boolean
	local history = _playerHistories[player]
	if not history then return false end

	local banThreshold = _config.thresholds and _config.thresholds.banAt or 100
	return history.totalViolations >= banThreshold
end

--[[
	Manually ban a player (sets flag in DataStore)

	@param player The player
	@param reason Optional ban reason
]]
function AbuseTracker.BanPlayer(player: Player, reason: string?)
	local history = _playerHistories[player]
	if history then
		history.isBanned = true
	end

	if _config.useDataStore then
		AbuseTracker._savePlayerHistory(player)
	end

	player:Kick(reason or "You have been banned for abuse.")
end

--[[
	Check if a player is banned

	@param player The player
	@return boolean
]]
function AbuseTracker.IsBanned(player: Player): boolean
	local history = _playerHistories[player]
	return history and history.isBanned or false
end

--[[
	Get all players with violations above a threshold

	@param minViolations Minimum violation count
	@return Array of { player, history }
]]
function AbuseTracker.GetPlayersAboveThreshold(minViolations: number): { { player: Player, history: PlayerAbuseHistory } }
	local result = {}

	for player, history in pairs(_playerHistories) do
		if history.totalViolations >= minViolations then
			table.insert(result, { player = player, history = history })
		end
	end

	return result
end

--[[
	Get abuse statistics

	@return Table with stats
]]
function AbuseTracker.GetStats(): { [string]: any }
	local totalPlayers = 0
	local totalViolations = 0
	local byReason: { [AbuseReason]: number } = {}

	for _, history in pairs(_playerHistories) do
		totalPlayers += 1
		totalViolations += history.sessionViolations

		for reason, record in pairs(history.records) do
			byReason[reason] = (byReason[reason] or 0) + record.count
		end
	end

	return {
		trackedPlayers = totalPlayers,
		sessionViolations = totalViolations,
		byReason = byReason,
	}
end

function AbuseTracker._createHistory(player: Player): PlayerAbuseHistory
	local history: PlayerAbuseHistory = {
		playerId = player.UserId,
		playerName = player.Name,
		records = {},
		totalViolations = 0,
		sessionViolations = 0,
		isBanned = false,
		lastSeen = os.time(),
	}

	_playerHistories[player] = history
	return history
end

function AbuseTracker._loadPlayerHistory(player: Player)
	if not _config.useDataStore or not _dataStore then
		AbuseTracker._createHistory(player)
		return
	end

	local key = "player_" .. player.UserId

	task.spawn(function()
		local success, data = pcall(function()
			return _dataStore:GetAsync(key)
		end)

		if success and data then
			local history: PlayerAbuseHistory = {
				playerId = player.UserId,
				playerName = player.Name,
				records = data.records or {},
				totalViolations = data.totalViolations or 0,
				sessionViolations = 0,
				isBanned = data.isBanned or false,
				lastSeen = os.time(),
			}

			_playerHistories[player] = history

			if history.isBanned then
				player:Kick("You have been banned for abuse.")
			end
		else
			AbuseTracker._createHistory(player)
		end
	end)
end

function AbuseTracker._savePlayerHistory(player: Player)
	if not _config.useDataStore or not _dataStore then return end

	local history = _playerHistories[player]
	if not history then return end

	local key = "player_" .. player.UserId
	local data = {
		records = history.records,
		totalViolations = history.totalViolations,
		isBanned = history.isBanned,
		lastSeen = history.lastSeen,
	}

	task.spawn(function()
		local success, err = pcall(function()
			_dataStore:SetAsync(key, data)
		end)

		if not success then
			warn("[Rewind.AbuseTracker] Failed to save history for", player.Name, ":", err)
		end
	end)
end

function AbuseTracker._flushSaveQueue()
	local queue = _saveQueue
	_saveQueue = {}

	for _, player in ipairs(queue) do
		if player.Parent then
			AbuseTracker._savePlayerHistory(player)
		end
	end
end

function AbuseTracker._checkThresholds(player: Player, history: PlayerAbuseHistory)
	local thresholds = _config.thresholds
	if not thresholds then return end

	local violations = history.totalViolations

	if thresholds.banAt and violations >= thresholds.banAt then
		_onThresholdReached:Fire(player, "ban", violations)
		if _config.autoBan then
			AbuseTracker.BanPlayer(player, "Automatic ban: Too many violations")
			return
		end
	end

	if thresholds.kickAt and violations >= thresholds.kickAt then
		_onThresholdReached:Fire(player, "kick", violations)
		if _config.autoKick and not _config.autoBan then
			player:Kick("You have been kicked for suspicious behavior.")
			return
		end
	end

	if thresholds.warnAt and violations >= thresholds.warnAt then
		if violations % thresholds.warnAt == 0 then
			_onThresholdReached:Fire(player, "warn", violations)
		end
	end
end

return AbuseTracker
