--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "RewindRemotes"

local Remotes = {}

local function getFolder(): Folder
	local f = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if f and f:IsA("Folder") then
		return f
	end

	if RunService:IsServer() then
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end

	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local function ensureRemoteEvent(name: string): RemoteEvent
	local folder = getFolder()
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	if RunService:IsServer() then
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = folder
		return re
	end

	return folder:WaitForChild(name) :: RemoteEvent
end

local function ensureUnreliableRemoteEvent(name: string): UnreliableRemoteEvent
	local folder = getFolder()
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("UnreliableRemoteEvent") then
		return existing
	end

	if RunService:IsServer() then
		local re = Instance.new("UnreliableRemoteEvent")
		re.Name = name
		re.Parent = folder
		return re
	end

	return folder:WaitForChild(name) :: UnreliableRemoteEvent
end

function Remotes.EnsureAll()
	ensureRemoteEvent("DebugData")
	ensureRemoteEvent("DebugCmd")
	ensureUnreliableRemoteEvent("StateUpdate")
	ensureRemoteEvent("StateCorrection")
	ensureUnreliableRemoteEvent("ClientState")
	ensureRemoteEvent("EntityAdded")
	ensureRemoteEvent("EntityRemoved")
end

function Remotes.DebugData(): RemoteEvent
	return ensureRemoteEvent("DebugData")
end

function Remotes.DebugCmd(): RemoteEvent
	return ensureRemoteEvent("DebugCmd")
end

--[[
	StateUpdate - Server broadcasts entity states to clients (unreliable for performance)
	Payload: { [entityId]: CompressedState }
]]
function Remotes.StateUpdate(): UnreliableRemoteEvent
	return ensureUnreliableRemoteEvent("StateUpdate")
end

--[[
	StateCorrection - Server sends authoritative correction to client (reliable)
	Payload: CompressedState
]]
function Remotes.StateCorrection(): RemoteEvent
	return ensureRemoteEvent("StateCorrection")
end

--[[
	ClientState - Client sends own state to server (unreliable for performance)
	Payload: CompressedState
]]
function Remotes.ClientState(): UnreliableRemoteEvent
	return ensureUnreliableRemoteEvent("ClientState")
end

--[[
	EntityAdded - Server notifies clients when an entity joins replication
	Payload: { id: string, entityType: EntityType, modelPath: string }
]]
function Remotes.EntityAdded(): RemoteEvent
	return ensureRemoteEvent("EntityAdded")
end

--[[
	EntityRemoved - Server notifies clients when an entity leaves replication
	Payload: string (entityId)
]]
function Remotes.EntityRemoved(): RemoteEvent
	return ensureRemoteEvent("EntityRemoved")
end

return Remotes
