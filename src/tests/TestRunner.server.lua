local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.Packages.testez)

local results = TestEZ.TestBootstrap:run({
	ReplicatedStorage.Rewind.Parent.Parent:FindFirstChild("tests") or script.Parent
})

print(results.errors)
