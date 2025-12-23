--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Trove = require(game:GetService("ReplicatedStorage").Packages.trove)

local Config = require(script.Parent.Parent.Config)
local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local HitboxProfile = require(script.Parent.Parent.Rig.HitboxProfile)
local RigAdapter = require(script.Parent.Parent.Rig.RigAdapter)

local SnapshotStore = require(script.Parent.SnapshotStore)
local Rewinder = require(script.Parent.Rewinder)
local Validator = require(script.Parent.Validator)
local Stats = require(script.Parent.Stats)

local Remotes = require(script.Parent.Parent.Net.Remotes)
local WorldGhost = require(script.Parent.WorldGhost)

local Server = {}
Server.__index = Server

type TargetState = {
	store: any,
	parts: { [string]: BasePart },
	profileId: string,
}

type PlayerState = {
	limiter: any,
	seen: { [string]: number },
}

local function serverNow(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	if ok then return t end
	return os.clock()
end

function Server.new()
	return setmetatable({
		opts = table.clone(Config.Defaults),
		trove = Trove.new(),
		started = false,

		targets = {} :: { [Model]: TargetState },
		playerState = {} :: { [Player]: PlayerState },

		weapons = {} :: { [string]: any },
		stats = Stats.new(),

        debugPlayers = {} :: { [Player]: boolean },
        ghost = nil :: any,

		_accum = 0,
	}, Server)
end

function Server:Configure(opts)
	for k, v in pairs(opts) do
		if typeof(v) == "table" and typeof(self.opts[k]) == "table" then
			for kk, vv in pairs(v) do
				(self.opts[k])[kk] = vv
			end
		else
			self.opts[k] = v
		end
	end
end

function Server:GetOptions()
	return self.opts
end

function Server:DefineWeapon(profile)
	self.weapons[profile.id] = profile
end

function Server:GetWeapon(id: string)
	return self.weapons[id]
end

function Server:_getPlayerState(player: Player)
	local st = self.playerState[player]
	if st then return st end

	local anti = self.opts.antiSpam
	local limiter = RateLimiter.new(anti.perSecond, anti.burst)
	st = { limiter = limiter, seen = {} }
	self.playerState[player] = st
	return st
end

function Server:_cleanupSeen(st: PlayerState, now: number)
	for id, t in pairs(st.seen) do
		if (now - t) > 3 then
			st.seen[id] = nil
		end
	end
end

--[[
	Check for duplicate shots with weapon-mode awareness.
	- Projectiles (isMelee = false): require unique clientShotId
	- Melee (isMelee = true): skip duplicate check entirely

	@return true if duplicate detected (should reject), false if OK
]]
function Server:_checkDuplicate(pst: PlayerState, params, weapon, now: number): boolean
	-- If weapon is melee, skip duplicate check
	if weapon and weapon.isMelee then
		return false
	end

	-- For projectiles/raycasts, check duplicate
	if params.clientShotId then
		if pst.seen[params.clientShotId] then
			return true -- duplicate
		end
		pst.seen[params.clientShotId] = now
	end

	return false
end

--[[
	Distance sanity check - ensure attacker is within reasonable range.
	This prevents validation from across the map.

	@param attackerPos The attacker's position
	@param targetPos The target/hit position
	@param maxRange Maximum allowed range (from weapon or global config)
	@param margin Extra margin to add (for forgiveness)
	@return true if within range, false if out of range
]]
function Server:_checkDistanceSanity(attackerPos: Vector3, targetPos: Vector3, maxRange: number, margin: number?): boolean
	margin = margin or 0
	local dist = (targetPos - attackerPos).Magnitude
	return dist <= (maxRange + margin)
end

--[[
	Get the attacker's position for distance checks.
	Uses the player's character HumanoidRootPart.
]]
function Server:_getAttackerPosition(player: Player): Vector3?
	local char = player.Character
	if not char then return nil end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp.Position
	end

	return nil
end

function Server:RegisterCharacter(character: Model, profileId: string?)
	profileId = profileId or RigAdapter.ResolveProfileId(character)
	local profile = HitboxProfile.Get(profileId)
	if not profile then
		profileId = RigAdapter.ResolveProfileId(character)
		profile = HitboxProfile.Get(profileId)
	end
	if not profile then return end

	local parts = RigAdapter.CollectParts(character, profile.parts)
	local store = SnapshotStore.new(self.opts.windowMs, self.opts.snapshotHz)

	self.targets[character] = {
		store = store,
		parts = parts,
		profileId = profileId,
	}
end

function Server:UnregisterCharacter(character: Model)
	self.targets[character] = nil
end

function Server:ServerNow()
	return serverNow()
end

function Server:EstimateRewindTime(player: Player, clientTime: number?)
	local now = serverNow()

	if not clientTime then
		return now
	end

	local ageMs = (now - clientTime) * 1000
	local clampMs = self.opts.maxRewindMs
	if ageMs < 0 then ageMs = 0 end
	if ageMs > clampMs then ageMs = clampMs end

	return now - (ageMs / 1000)
end

function Server:_emitDebug(player: Player, payload)
	if not self.opts.debug.enabled then return end
	if not self.debugPlayers[player] then return end
	Remotes.DebugData():FireClient(player, payload)
end

function Server:_captureSnapshot(character: Model, ts: TargetState, now: number)
	local partsSnap = {}
	for name, part in pairs(ts.parts) do
		if part and part.Parent then
			partsSnap[name] = {
				cf = part.CFrame,
				size = part.Size,
			}
		end
	end

	ts.store:Push({
		t = now,
		parts = partsSnap,
	})
end

function Server:_bestOverTargets(rewindTo: number, tester, scale: number?)
	local best = nil
	local bestScore = math.huge
	local bestChar: Model? = nil

	for character, ts in pairs(self.targets) do
		local pose = Rewinder.Sample(ts.store, rewindTo)
		if pose then
			-- Apply scale for scaled avatar support
			if scale and scale ~= 1.0 then
				pose = self:_applyScaleToPose(pose, scale)
			end

			local r, score = tester(pose, character)
			if r and score < bestScore then
				bestScore = score
				best = r
				bestChar = character
			end
		end
	end

	return best, bestChar, bestScore
end

function Server:_ghostRaycast(origin: Vector3, dir: Vector3, poseParts)
	if not self.ghost then return nil end

	local model = self.ghost:BuildPose(poseParts)

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { model }
	rp.IgnoreWater = true

	local res = workspace:Raycast(origin, dir, rp)

	model:Destroy()
	self.ghost:Clear()

	return res
end

function Server:_tick(dt: number)
	if not self.opts.enabled then return end

	self._accum += dt
	local interval = 1 / self.opts.snapshotHz
	if self._accum < interval then
		return
	end

	local now = serverNow()
	self._accum = self._accum % interval

	for character, ts in pairs(self.targets) do
		if character.Parent then
			self:_captureSnapshot(character, ts, now)
		else
			self.targets[character] = nil
		end
	end
end

function Server:ValidateSphere(player: Player, params)
	local now = serverNow()
	self.stats:Inc("validations")

	local pst = self:_getPlayerState(player)
	self:_cleanupSeen(pst, now)

	if not pst.limiter:Allow(now, 1) then
		self.stats:Inc("rejects", "rate_limited")
		return { hit = false, serverNow = now, rewindTo = now, usedRewindMs = 0, reason = "rate_limited" }
	end

	local weapon, extraForgiveness, maxDist, allowHead = self:_resolveWeaponTuning(params.weaponId)

	-- Weapon-mode aware duplicate check
	if self:_checkDuplicate(pst, params, weapon, now) then
		self.stats:Inc("rejects", "duplicate_shot")
		return { hit = false, serverNow = now, rewindTo = now, usedRewindMs = 0, reason = "duplicate_shot" }
	end

	local rewindTo = self:EstimateRewindTime(player, params.clientTime)
	local usedRewindMs: number
	rewindTo, usedRewindMs = self:_applyWeaponRewindClamp(now, rewindTo, weapon)

	local center = params.center
	local radius = params.radius

	-- Get scale multiplier for scaled avatar support
	local scale = self:_getScaleMultiplier(weapon)

	local hitData, hitChar = self:_bestOverTargets(rewindTo, function(pose)
		local r = Validator.SpherePose(center, radius, pose, {
			maxRayDistance = self.opts.maxRayDistance,
			allowHeadshots = allowHead,
			extraForgiveness = extraForgiveness,
		})
		if not r then return nil end
		return r, 0
	end, scale)

	if not hitData or not hitChar then
		return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "no_hit" }
	end

	local humanoid = hitChar:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		self.stats:Inc("rejects", "no_humanoid")
		return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "no_humanoid" }
	end

	local targetPlayer = Players:GetPlayerFromCharacter(hitChar)
	if self.opts.teamCheck and targetPlayer and player.Team and targetPlayer.Team then
		if player.Team == targetPlayer.Team and not self.opts.friendlyFire then
			self.stats:Inc("rejects", "friendly_fire")
			return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "friendly_fire" }
		end
	end

	self.stats:Inc("hits")
	return {
		hit = true,
		character = hitChar,
		humanoid = humanoid,
		player = targetPlayer,
		part = hitChar:FindFirstChild(hitData.partName) :: any,
		partName = hitData.partName,
		hitPosition = hitData.closest,
		serverNow = now,
		rewindTo = rewindTo,
		usedRewindMs = usedRewindMs,
		isHeadshot = hitData.isHeadshot,
	}
end

function Server:ValidateCapsule(player: Player, params)
	local now = serverNow()
	self.stats:Inc("validations")

	local pst = self:_getPlayerState(player)
	self:_cleanupSeen(pst, now)

	if not pst.limiter:Allow(now, 1) then
		self.stats:Inc("rejects", "rate_limited")
		self:_emitDebug(player, { reason="rate_limited", serverNow=now, rewindTo=now, usedRewindMs=0 })
		return { hit=false, serverNow=now, rewindTo=now, usedRewindMs=0, reason="rate_limited" }
	end

	local weapon, extraForgiveness, maxDist, allowHead = self:_resolveWeaponTuning(params.weaponId)

	if self:_checkDuplicate(pst, params, weapon, now) then
		self.stats:Inc("rejects", "duplicate_shot")
		self:_emitDebug(player, { reason="duplicate_shot", serverNow=now, rewindTo=now, usedRewindMs=0 })
		return { hit=false, serverNow=now, rewindTo=now, usedRewindMs=0, reason="duplicate_shot" }
	end

	local rewindTo = self:EstimateRewindTime(player, params.clientTime)
	local usedRewindMs: number
	rewindTo, usedRewindMs = self:_applyWeaponRewindClamp(now, rewindTo, weapon)

	local a: Vector3, b: Vector3, radius: number = params.a, params.b, params.radius
	local steps = params.steps or 10

	local attackerPos = self:_getAttackerPosition(player)
	if attackerPos then
		local capsuleOrigin = a
		if not self:_checkDistanceSanity(attackerPos, capsuleOrigin, maxDist, extraForgiveness + 10) then
			self.stats:Inc("rejects", "out_of_range")
			self:_emitDebug(player, { reason="out_of_range", serverNow=now, rewindTo=rewindTo, usedRewindMs=usedRewindMs })
			return { hit=false, serverNow=now, rewindTo=rewindTo, usedRewindMs=usedRewindMs, reason="out_of_range" }
		end
	end

	local capsulePoints = {}
	do
		local n = math.max(2, steps + 1)
		for i = 0, n - 1 do
			local t = i / (n - 1)
			capsulePoints[#capsulePoints + 1] = a:Lerp(b, t)
		end
	end

	local bestHit = nil
	local bestScore = math.huge
	local bestChar: Model? = nil
	local bestPoseParts = nil

	local scale = self:_getScaleMultiplier(weapon)

	for character, ts in pairs(self.targets) do
		local pose = Rewinder.Sample(ts.store, rewindTo)
		if pose then
			pose = self:_applyScaleToPose(pose, scale)

			local r = Validator.CapsuleSweepPose(a, b, radius, pose, {
				maxRayDistance = self.opts.maxRayDistance,
				allowHeadshots = allowHead,
				extraForgiveness = extraForgiveness,
			}, steps)

			if r and r.t < bestScore then
				bestScore = r.t
				bestHit = r
				bestChar = character
				bestPoseParts = pose.parts
			end
		end
	end

	if not bestHit or not bestChar then
		self:_emitDebug(player, {
			reason = "no_hit",
			serverNow = now,
			rewindTo = rewindTo,
			usedRewindMs = usedRewindMs,
			capsulePoints = capsulePoints,
		})
		return { hit=false, serverNow=now, rewindTo=rewindTo, usedRewindMs=usedRewindMs, reason="no_hit" }
	end

	self:_emitDebug(player, {
		reason = "hit",
		serverNow = now,
		rewindTo = rewindTo,
		usedRewindMs = usedRewindMs,
		targetName = bestChar.Name,
		partName = bestHit.partName,
		poseParts = bestPoseParts,
		capsulePoints = capsulePoints,
	})

	local humanoid = bestChar:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		self.stats:Inc("rejects", "no_humanoid")
		return { hit=false, serverNow=now, rewindTo=rewindTo, usedRewindMs=usedRewindMs, reason="no_humanoid" }
	end

	local targetPlayer = Players:GetPlayerFromCharacter(bestChar)
	if self.opts.teamCheck and targetPlayer and player.Team and targetPlayer.Team then
		if player.Team == targetPlayer.Team and not self.opts.friendlyFire then
			self.stats:Inc("rejects", "friendly_fire")
			return { hit=false, serverNow=now, rewindTo=rewindTo, usedRewindMs=usedRewindMs, reason="friendly_fire" }
		end
	end

	self.stats:Inc("hits")
	return {
		hit = true,
		character = bestChar,
		humanoid = humanoid,
		player = targetPlayer,
		part = bestChar:FindFirstChild(bestHit.partName) :: any,
		partName = bestHit.partName,
		hitPosition = bestHit.point,
		serverNow = now,
		rewindTo = rewindTo,
		usedRewindMs = usedRewindMs,
		isHeadshot = bestHit.isHeadshot,
	}
end

function Server:ValidateMeleeArc(player: Player, params)
	local now = serverNow()
	self.stats:Inc("validations")

	local pst = self:_getPlayerState(player)
	self:_cleanupSeen(pst, now)

	if not pst.limiter:Allow(now, 1) then
		self.stats:Inc("rejects", "rate_limited")
		return { hit = false, serverNow = now, rewindTo = now, usedRewindMs = 0, reason = "rate_limited" }
	end

	local weapon, extraForgiveness, maxDist, allowHead = self:_resolveWeaponTuning(params.weaponId)

	if self:_checkDuplicate(pst, params, weapon, now) then
		self.stats:Inc("rejects", "duplicate_shot")
		return { hit = false, serverNow = now, rewindTo = now, usedRewindMs = 0, reason = "duplicate_shot" }
	end

	local rewindTo = self:EstimateRewindTime(player, params.clientTime)
	local usedRewindMs: number
	rewindTo, usedRewindMs = self:_applyWeaponRewindClamp(now, rewindTo, weapon)

	local originCf = params.origin
	local range = weapon and weapon.meleeRange or params.range
	local angleDeg = weapon and weapon.meleeAngleDeg or params.angleDeg

	local attackerPos = self:_getAttackerPosition(player)
	if attackerPos then
		local originPos = originCf.Position
		if not self:_checkDistanceSanity(attackerPos, originPos, 10, 5) then
			self.stats:Inc("rejects", "out_of_range")
			return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "out_of_range" }
		end
	end

	local scale = self:_getScaleMultiplier(weapon)

	local hitData, hitChar = self:_bestOverTargets(rewindTo, function(pose)
		local r = Validator.ConePose(originCf, range, angleDeg, pose, {
			maxRayDistance = self.opts.maxRayDistance,
			allowHeadshots = allowHead,
			extraForgiveness = extraForgiveness,
		})
		if not r then return nil end
		local dist2 = (r.point - originCf.Position):Dot(r.point - originCf.Position)
		return r, dist2
	end, scale)

	if not hitData or not hitChar then
		return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "no_hit" }
	end

	local humanoid = hitChar:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		self.stats:Inc("rejects", "no_humanoid")
		return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "no_humanoid" }
	end

	local targetPlayer = Players:GetPlayerFromCharacter(hitChar)
	if self.opts.teamCheck and targetPlayer and player.Team and targetPlayer.Team then
		if player.Team == targetPlayer.Team and not self.opts.friendlyFire then
			self.stats:Inc("rejects", "friendly_fire")
			return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "friendly_fire" }
		end
	end

	self.stats:Inc("hits")
	return {
		hit = true,
		character = hitChar,
		humanoid = humanoid,
		player = targetPlayer,
		part = hitChar:FindFirstChild(hitData.partName) :: any,
		partName = hitData.partName,
		hitPosition = hitData.point,
		serverNow = now,
		rewindTo = rewindTo,
		usedRewindMs = usedRewindMs,
		isHeadshot = hitData.isHeadshot,
	}
end

function Server:ValidateMeleeFan(player: Player, params)
	local now = serverNow()
	self.stats:Inc("validations")

	local pst = self:_getPlayerState(player)
	self:_cleanupSeen(pst, now)

	if not pst.limiter:Allow(now, 1) then
		self.stats:Inc("rejects", "rate_limited")
		return { hit = false, serverNow = now, rewindTo = now, usedRewindMs = 0, reason = "rate_limited" }
	end

	local weapon, extraForgiveness, maxDist, allowHead = self:_resolveWeaponTuning(params.weaponId)

	if self:_checkDuplicate(pst, params, weapon, now) then
		self.stats:Inc("rejects", "duplicate_shot")
		return { hit = false, serverNow = now, rewindTo = now, usedRewindMs = 0, reason = "duplicate_shot" }
	end

	local rewindTo = self:EstimateRewindTime(player, params.clientTime)
	local usedRewindMs: number
	rewindTo, usedRewindMs = self:_applyWeaponRewindClamp(now, rewindTo, weapon)

	local originCf = params.origin
	local range = weapon and weapon.meleeRange or params.range
	local angleDeg = weapon and weapon.meleeAngleDeg or params.angleDeg
	local rays = weapon and weapon.meleeRays or params.rays

	local attackerPos = self:_getAttackerPosition(player)
	if attackerPos then
		local originPos = originCf.Position
		if not self:_checkDistanceSanity(attackerPos, originPos, 10, 5) then
			self.stats:Inc("rejects", "out_of_range")
			return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "out_of_range" }
		end
	end

	local scale = self:_getScaleMultiplier(weapon)

	local hitData, hitChar, bestT = self:_bestOverTargets(rewindTo, function(pose)
		local r = Validator.FanRaysPose(originCf, range, angleDeg, rays, pose, {
			maxRayDistance = self.opts.maxRayDistance,
			allowHeadshots = allowHead,
			extraForgiveness = extraForgiveness,
		})
		if not r then return nil end
		return r, r.t
	end, scale)

	if not hitData or not hitChar then
		return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "no_hit" }
	end

	local humanoid = hitChar:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		self.stats:Inc("rejects", "no_humanoid")
		return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "no_humanoid" }
	end

	local targetPlayer = Players:GetPlayerFromCharacter(hitChar)
	if self.opts.teamCheck and targetPlayer and player.Team and targetPlayer.Team then
		if player.Team == targetPlayer.Team and not self.opts.friendlyFire then
			self.stats:Inc("rejects", "friendly_fire")
			return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "friendly_fire" }
		end
	end

	local hitPos = originCf.Position + originCf.LookVector * bestT

	self.stats:Inc("hits")
	return {
		hit = true,
		character = hitChar,
		humanoid = humanoid,
		player = targetPlayer,
		part = hitChar:FindFirstChild(hitData.partName) :: any,
		partName = hitData.partName,
		hitPosition = hitPos,
		hitNormal = hitData.normal,
		serverNow = now,
		rewindTo = rewindTo,
		usedRewindMs = usedRewindMs,
		isHeadshot = hitData.isHeadshot,
	}
end

function Server:_resolveWeaponTuning(weaponId: string?)
	local weapon = nil
	local extraForgiveness = 0
	local maxDist = self.opts.maxRayDistance
	local allowHead = self.opts.allowHeadshots

	if weaponId then
		weapon = self.weapons[weaponId]
		if weapon then
			if weapon.extraForgivenessStuds then
				extraForgiveness = weapon.extraForgivenessStuds
			end
			if weapon.maxDistance then
				maxDist = math.min(maxDist, weapon.maxDistance)
			end
		end
	end

	return weapon, extraForgiveness, maxDist, allowHead
end

--[[
	Get scale multiplier from weapon profile for scaled avatar support.
	@param weapon The weapon profile (or nil)
	@return Scale multiplier (1.0 if not specified)
]]
function Server:_getScaleMultiplier(weapon): number
	if weapon and weapon.scaleMultiplier then
		return weapon.scaleMultiplier
	end
	return 1.0
end

--[[
	Apply scale to a pose's parts for scaled avatar support.
	@param pose The rewound pose
	@param scale The scale multiplier
	@return Pose with scaled part sizes
]]
function Server:_applyScaleToPose(pose, scale: number)
	if not pose or scale == 1.0 then return pose end

	local scaledParts = {}
	for name, snap in pairs(pose.parts) do
		scaledParts[name] = {
			cf = snap.cf,
			size = snap.size * scale,
		}
	end

	return {
		t = pose.t,
		parts = scaledParts,
	}
end

function Server:_applyWeaponRewindClamp(now: number, rewindTo: number, weapon): (number, number)
	local usedMs = (now - rewindTo) * 1000
	if weapon and weapon.maxRewindMs and usedMs > weapon.maxRewindMs then
		local clampMs = weapon.maxRewindMs
		rewindTo = now - (clampMs / 1000)
		usedMs = clampMs
	end
	return rewindTo, usedMs
end

function Server:ValidateRay(player: Player, params)
	local now = serverNow()
	self.stats:Inc("validations")

	local pst = self:_getPlayerState(player)
	self:_cleanupSeen(pst, now)

	if not pst.limiter:Allow(now, 1) then
		self.stats:Inc("rejects", "rate_limited")
		return { hit = false, serverNow = now, rewindTo = now, usedRewindMs = 0, reason = "rate_limited" }
	end

	local weapon, extraForgiveness, maxDist, allowHead = self:_resolveWeaponTuning(params.weaponId)

	if self:_checkDuplicate(pst, params, weapon, now) then
		self.stats:Inc("rejects", "duplicate_shot")
		return { hit = false, serverNow = now, rewindTo = now, usedRewindMs = 0, reason = "duplicate_shot" }
	end

	local rewindTo = self:EstimateRewindTime(player, params.clientTime)
	local usedRewindMs: number
	rewindTo, usedRewindMs = self:_applyWeaponRewindClamp(now, rewindTo, weapon)

	local origin: Vector3 = params.origin
	local dir: Vector3 = params.direction

	if dir.Magnitude > maxDist then
		dir = dir.Unit * maxDist
	end

	local attackerPos = self:_getAttackerPosition(player)
	if attackerPos then
		if not self:_checkDistanceSanity(attackerPos, origin, 20, 5) then
			self.stats:Inc("rejects", "out_of_range")
			self:_emitDebug(player, { reason="out_of_range", serverNow=now, rewindTo=rewindTo, usedRewindMs=usedRewindMs })
			return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "out_of_range" }
		end
	end

	local bestHit = nil
	local bestT = math.huge
	local bestChar: Model? = nil
	local bestPoseParts = nil

	local scale = self:_getScaleMultiplier(weapon)

	for character, ts in pairs(self.targets) do
		local pose = Rewinder.Sample(ts.store, rewindTo)
		if pose then
			pose = self:_applyScaleToPose(pose, scale)

			local r = Validator.RaycastPose(origin, dir, pose, {
				maxRayDistance = maxDist,
				allowHeadshots = allowHead,
				extraForgiveness = extraForgiveness,
			})
			if r and r.t < bestT then
				bestT = r.t
				bestHit = r
				bestChar = character
				bestPoseParts = pose.parts
			end
		end
	end

	if not bestHit or not bestChar then
		self:_emitDebug(player, {
			reason = "no_hit",
			serverNow = now,
			rewindTo = rewindTo,
			usedRewindMs = usedRewindMs,
			ray = { origin = origin, hitPos = origin + dir },
		})
		return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "no_hit" }
	end

	local hitPos = origin + dir.Unit * bestT
	local hitNormal = bestHit.normal

	if self.opts.mode == "GhostParts" and bestPoseParts then
		local rr = self:_ghostRaycast(origin, dir, bestPoseParts)
		if rr then
			hitPos = rr.Position
			hitNormal = rr.Normal
		end
	end

	self:_emitDebug(player, {
		reason = "hit",
		serverNow = now,
		rewindTo = rewindTo,
		usedRewindMs = usedRewindMs,
		targetName = bestChar.Name,
		partName = bestHit.partName,
		poseParts = bestPoseParts,
		ray = { origin = origin, hitPos = hitPos },
	})

	local humanoid = bestChar:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		self.stats:Inc("rejects", "no_humanoid")
		return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "no_humanoid" }
	end

	local targetPlayer = Players:GetPlayerFromCharacter(bestChar)
	if self.opts.teamCheck and targetPlayer and player.Team ~= nil and targetPlayer.Team ~= nil then
		if player.Team == targetPlayer.Team and not self.opts.friendlyFire then
			self.stats:Inc("rejects", "friendly_fire")
			return { hit = false, serverNow = now, rewindTo = rewindTo, usedRewindMs = usedRewindMs, reason = "friendly_fire" }
		end
	end

	self.stats:Inc("hits")
	return {
		hit = true,
		character = bestChar,
		humanoid = humanoid,
		player = targetPlayer,
		part = (bestChar:FindFirstChild(bestHit.partName) :: any),
		partName = bestHit.partName,
		hitPosition = hitPos,
		hitNormal = hitNormal,
		serverNow = now,
		rewindTo = rewindTo,
		usedRewindMs = usedRewindMs,
		isHeadshot = bestHit.isHeadshot,
	}
end

function Server:GetStats()
	return self.stats:Snapshot()
end

function Server:Start(opts)
    Remotes.EnsureAll()

	if self.started then return end
	self.started = true

	if opts then
		self:Configure(opts)
	end

    Remotes.DebugCmd()
    Remotes.DebugData()

    self.trove:Add(Players.PlayerRemoving:Connect(function(plr)
        self.playerState[plr] = nil
        self.debugPlayers[plr] = nil
    end))

    self.ghost = WorldGhost.new()

    self.trove:Add(Remotes.DebugCmd().OnServerEvent:Connect(function(player, action, value)
        if action == "set_enabled" then
            self.debugPlayers[player] = (value == true)
        end
    end))

	self.trove:Add(Players.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function(char)
			self:RegisterCharacter(char)
		end)
	end))


	for _, plr in ipairs(Players:GetPlayers()) do
		plr.CharacterAdded:Connect(function(char)
			self:RegisterCharacter(char)
		end)
		local c = plr.Character
		if c then
			self:RegisterCharacter(c)
		end
	end

	self.trove:Add(RunService.Heartbeat:Connect(function(dt)
		self:_tick(dt)
	end))
end

function Server:Stop()
	if not self.started then return end
	self.started = false
	self.trove:Clean()
	table.clear(self.targets)
	table.clear(self.playerState)
end

return Server
