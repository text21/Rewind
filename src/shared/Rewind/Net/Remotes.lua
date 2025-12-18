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

function Remotes.EnsureAll()
	ensureRemoteEvent("DebugData")
	ensureRemoteEvent("DebugCmd")
end

function Remotes.DebugData(): RemoteEvent
	return ensureRemoteEvent("DebugData")
end

function Remotes.DebugCmd(): RemoteEvent
	return ensureRemoteEvent("DebugCmd")
end

return Remotes
