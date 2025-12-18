--!strict
local Workspace = game:GetService("Workspace")

local WorldGhost = {}
WorldGhost.__index = WorldGhost

local function getRoot()
	local root = Workspace:FindFirstChild("RewindGhost")
	if not root then
		root = Instance.new("Folder")
		root.Name = "RewindGhost"
		root.Parent = Workspace
	end

	local wm = root:FindFirstChild("WorldModel")
	if not wm then
		wm = Instance.new("WorldModel")
		wm.Name = "WorldModel"
		wm.Parent = root
	end

	return root, wm :: WorldModel
end

local function mkPart(parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Parent = parent
	return p
end

function WorldGhost.new()
	local _, wm = getRoot()
	return setmetatable({
		wm = wm,
		pool = {} :: { BasePart },
		inUse = {} :: { BasePart },
	}, WorldGhost)
end

function WorldGhost:Clear()
	for _, p in ipairs(self.inUse) do
		p.Parent = nil
		table.insert(self.pool, p)
	end
	table.clear(self.inUse)
end

function WorldGhost:Acquire(): BasePart
	local p = table.remove(self.pool)
	if not p then
		p = mkPart(self.wm)
	end
	p.Parent = self.wm
	table.insert(self.inUse, p)
	return p
end

function WorldGhost:BuildPose(poseParts: { [string]: { cf: CFrame, size: Vector3 } }): Model
	self:Clear()

	local m = Instance.new("Model")
	m.Name = "Pose"
	m.Parent = self.wm

	for name, snap in pairs(poseParts) do
		local p = self:Acquire()
		p.Name = name
		p.Size = snap.size
		p.CFrame = snap.cf
		p.Parent = m
	end

	return m
end

return WorldGhost
