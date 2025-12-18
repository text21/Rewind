--!strict
local RunService = game:GetService("RunService")
if RunService:IsServer() then
	return {} :: any
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Draw = {}
Draw.__index = Draw

type BoxItem = { part: BasePart }
type PtItem = { part: BasePart }

local function camFolder()
	local cam = Workspace.CurrentCamera
	if not cam then
		return nil
	end
	local f = cam:FindFirstChild("RewindDebug")
	if not f then
		f = Instance.new("Folder")
		f.Name = "RewindDebug"
		f.Parent = cam
	end
	return f
end

local function mkPart(parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Parent = parent
	return p
end

local function mkBox(parent: Instance, part: BasePart)
	local a = Instance.new("BoxHandleAdornment")
	a.AlwaysOnTop = true
	a.ZIndex = 5
	a.Adornee = part
	a.Size = part.Size
	a.Transparency = 0.6
	a.Parent = parent
	return a
end

local function mkSphere(parent: Instance, part: BasePart)
	local a = Instance.new("SphereHandleAdornment")
	a.AlwaysOnTop = true
	a.ZIndex = 6
	a.Adornee = part
	a.Radius = 0.2
	a.Transparency = 0.2
	a.Parent = parent
	return a
end

local function mkRay(parent: Instance)
	local p0 = mkPart(parent)
	local p1 = mkPart(parent)

	local a0 = Instance.new("Attachment")
	a0.Parent = p0
	local a1 = Instance.new("Attachment")
	a1.Parent = p1

	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.FaceCamera = true
	beam.Width0 = 0.06
	beam.Width1 = 0.06
	beam.Transparency = NumberSequence.new(0.1)
	beam.Parent = parent

	return { p0 = p0, p1 = p1, beam = beam }
end

function Draw.new()
	local parent = camFolder()
	local self = setmetatable({
		parent = parent,
		boxPool = {} :: { BoxItem },
		ptPool = {} :: { PtItem },
		ray = nil :: any,
		liveBoxes = {} :: { BasePart },
		livePts = {} :: { BasePart },
	}, Draw)

	return self
end

function Draw:Clear()
	if not self.parent then return end

	for _, p in ipairs(self.liveBoxes) do
		p:Destroy()
	end
	for _, p in ipairs(self.livePts) do
		p:Destroy()
	end
	self.liveBoxes = {}
	self.livePts = {}

	if self.ray then
		self.ray.p0:Destroy()
		self.ray.p1:Destroy()
		self.ray.beam:Destroy()
		self.ray = nil
	end
end

function Draw:DrawRay(origin: Vector3, hitPos: Vector3)
	if not self.parent then return end
	if not self.ray then
		self.ray = mkRay(self.parent)
	end
	self.ray.p0.CFrame = CFrame.new(origin)
	self.ray.p1.CFrame = CFrame.new(hitPos)
end

function Draw:DrawBoxes(parts: { [string]: { cf: CFrame, size: Vector3 } })
	if not self.parent then return end

	for _, p in ipairs(self.liveBoxes) do
		p:Destroy()
	end
	self.liveBoxes = {}

	for _, snap in pairs(parts) do
		local p = mkPart(self.parent)
		p.Size = snap.size
		p.CFrame = snap.cf
		mkBox(self.parent, p).Size = snap.size
		table.insert(self.liveBoxes, p)
	end
end

function Draw:DrawPoints(points: { Vector3 })
	if not self.parent then return end

	for _, p in ipairs(self.livePts) do
		p:Destroy()
	end
	self.livePts = {}

	for _, pos in ipairs(points) do
		local p = mkPart(self.parent)
		p.CFrame = CFrame.new(pos)
		mkSphere(self.parent, p)
		table.insert(self.livePts, p)
	end
end

return Draw
