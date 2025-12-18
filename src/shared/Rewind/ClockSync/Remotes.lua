--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER = "RewindRemotes"
local FN_NAME = "ClockSync"

local function getFolder(): Folder
	local f = ReplicatedStorage:FindFirstChild(FOLDER)
	if f and f:IsA("Folder") then return f end

	if RunService:IsServer() then
		f = Instance.new("Folder")
		f.Name = FOLDER
		f.Parent = ReplicatedStorage
		return f
	end

	return ReplicatedStorage:WaitForChild(FOLDER) :: Folder
end

local Remotes = {}

function Remotes.ClockSync(): RemoteFunction
	local folder = getFolder()
	local rf = folder:FindFirstChild(FN_NAME)
	if rf and rf:IsA("RemoteFunction") then
		return rf
	end

	if RunService:IsServer() then
		rf = Instance.new("RemoteFunction")
		rf.Name = FN_NAME
		rf.Parent = folder
		return rf
	end

	return folder:WaitForChild(FN_NAME) :: RemoteFunction
end

function Remotes.Ensure()
	Remotes.ClockSync()
end

return Remotes
