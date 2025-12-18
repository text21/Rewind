-- filepath: c:\Users\myass\Desktop\VSC Projects\Rewind\src\tests\SnapshotStore.spec.lua
return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local SnapshotStore = require(ReplicatedStorage.Rewind.Server.SnapshotStore)

	describe("SnapshotStore", function()
		describe("Basic operations", function()
			it("starts empty", function()
				local store = SnapshotStore.new(1000, 30)
				expect(store:Len()).to.equal(0)
				expect(store:First()).to.equal(nil)
				expect(store:Last()).to.equal(nil)
			end)

			it("can push and retrieve a single snapshot", function()
				local store = SnapshotStore.new(1000, 30)
				local snap = { t = 1.0, parts = { Torso = { cf = CFrame.new(), size = Vector3.new(2, 3, 1) } } }

				store:Push(snap)

				expect(store:Len()).to.equal(1)
				expect(store:First()).to.equal(snap)
				expect(store:Last()).to.equal(snap)
				expect(store:At(1)).to.equal(snap)
			end)

			it("maintains order with multiple pushes", function()
				local store = SnapshotStore.new(1000, 30)

				local s1 = { t = 1.0, parts = {} }
				local s2 = { t = 2.0, parts = {} }
				local s3 = { t = 3.0, parts = {} }

				store:Push(s1)
				store:Push(s2)
				store:Push(s3)

				expect(store:Len()).to.equal(3)
				expect(store:First().t).to.equal(1.0)
				expect(store:Last().t).to.equal(3.0)
				expect(store:At(2).t).to.equal(2.0)
			end)
		end)

		describe("Ring buffer behavior", function()
			it("overwrites old entries when capacity exceeded", function()
				-- windowMs=100, snapshotHz=10 => cap = floor(0.1 * 10) + 4 = 5
				local store = SnapshotStore.new(100, 10)

				for i = 1, 10 do
					store:Push({ t = i, parts = {} })
				end

				-- Should only keep most recent entries up to capacity
				local len = store:Len()
				expect(len).to.be.near(5, 1) -- capacity varies based on formula

				-- First should be one of the later entries (not 1)
				expect(store:First().t).to.be.gt(1)
				-- Last should be 10
				expect(store:Last().t).to.equal(10)
			end)

			it("handles At() out of bounds gracefully", function()
				local store = SnapshotStore.new(1000, 30)
				store:Push({ t = 1.0, parts = {} })

				expect(store:At(0)).to.equal(nil)
				expect(store:At(-1)).to.equal(nil)
				expect(store:At(2)).to.equal(nil)
				expect(store:At(100)).to.equal(nil)
			end)
		end)

		describe("Boundary conditions", function()
			it("handles minimum capacity", function()
				-- Very small window
				local store = SnapshotStore.new(1, 1)

				store:Push({ t = 1.0, parts = {} })
				store:Push({ t = 2.0, parts = {} })

				expect(store:Len()).to.be.gte(1)
				expect(store:Last().t).to.equal(2.0)
			end)

			it("handles rapid pushes at same time", function()
				local store = SnapshotStore.new(1000, 30)

				for _ = 1, 5 do
					store:Push({ t = 1.0, parts = {} })
				end

				expect(store:Len()).to.equal(5)
			end)

			it("preserves part data through push/retrieve cycle", function()
				local store = SnapshotStore.new(1000, 30)

				local cf = CFrame.new(10, 20, 30) * CFrame.Angles(1, 2, 3)
				local size = Vector3.new(4, 5, 6)

				store:Push({
					t = 1.0,
					parts = {
						Head = { cf = cf, size = size },
						Torso = { cf = CFrame.new(), size = Vector3.new(2, 3, 1) },
					},
				})

				local snap = store:First()
				expect(snap.parts.Head.cf).to.equal(cf)
				expect(snap.parts.Head.size).to.equal(size)
				expect(snap.parts.Torso).to.be.ok()
			end)
		end)
	end)
end
