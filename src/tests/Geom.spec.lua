return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Geom = require(ReplicatedStorage.Rewind.Util.Geom)

	describe("Geom", function()
		describe("ClosestPointOBB", function()
			it("clamps outside point to box surface", function()
				local cf = CFrame.new(0, 0, 0)
				local size = Vector3.new(4, 4, 4)

				local p = Geom.ClosestPointOBB(Vector3.new(10, 0, 0), cf, size)
				expect(p.X).to.equal(2)
				expect(p.Y).to.equal(0)
				expect(p.Z).to.equal(0)
			end)

			it("returns same point when inside box", function()
				local cf = CFrame.new(0, 0, 0)
				local size = Vector3.new(4, 4, 4)

				local p = Geom.ClosestPointOBB(Vector3.new(1, 1, 1), cf, size)
				expect(p.X).to.equal(1)
				expect(p.Y).to.equal(1)
				expect(p.Z).to.equal(1)
			end)

			it("handles rotated box correctly", function()
				-- Box rotated 45 degrees around Y
				local cf = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(45), 0)
				local size = Vector3.new(4, 4, 4)

				-- Point directly along +X axis should clamp to rotated corner
				local p = Geom.ClosestPointOBB(Vector3.new(10, 0, 0), cf, size)
				-- The closest point should be on the box surface
				expect((p - Vector3.new(0, 0, 0)).Magnitude).to.be.near(math.sqrt(8), 0.01)
			end)

			it("handles offset box position", function()
				local cf = CFrame.new(10, 5, 3)
				local size = Vector3.new(2, 2, 2)

				local p = Geom.ClosestPointOBB(Vector3.new(20, 5, 3), cf, size)
				expect(p.X).to.equal(11) -- box edge at 10 + 1
				expect(p.Y).to.equal(5)
				expect(p.Z).to.equal(3)
			end)
		end)

		describe("SphereOBB", function()
			it("detects overlap when sphere center inside box", function()
				local cf = CFrame.new(0, 0, 0)
				local size = Vector3.new(4, 4, 4)

				local ok = (Geom.SphereOBB(Vector3.new(0, 0, 0), 0.1, cf, size))
				expect(ok).to.equal(true)
			end)

			it("detects no overlap when sphere is far away", function()
				local cf = CFrame.new(0, 0, 0)
				local size = Vector3.new(4, 4, 4)

				local ok = (Geom.SphereOBB(Vector3.new(10, 0, 0), 1, cf, size))
				expect(ok).to.equal(false)
			end)

			it("detects overlap when sphere touches box edge", function()
				local cf = CFrame.new(0, 0, 0)
				local size = Vector3.new(4, 4, 4) -- half-size = 2

				-- Sphere at X=3 with radius 1.5 should touch box edge at X=2
				local ok = (Geom.SphereOBB(Vector3.new(3, 0, 0), 1.5, cf, size))
				expect(ok).to.equal(true)
			end)

			it("returns closest point on box surface", function()
				local cf = CFrame.new(0, 0, 0)
				local size = Vector3.new(4, 4, 4)

				local ok, closest = Geom.SphereOBB(Vector3.new(5, 0, 0), 10, cf, size)
				expect(ok).to.equal(true)
				expect(closest.X).to.equal(2)
				expect(closest.Y).to.equal(0)
				expect(closest.Z).to.equal(0)
			end)
		end)

		describe("AngleBetween", function()
			it("returns 0 for same direction", function()
				local a = Vector3.new(1, 0, 0)
				local b = Vector3.new(1, 0, 0)
				local angle = Geom.AngleBetween(a, b)
				expect(angle).to.be.near(0, 0.0001)
			end)

			it("returns pi for opposite directions", function()
				local a = Vector3.new(1, 0, 0)
				local b = Vector3.new(-1, 0, 0)
				local angle = Geom.AngleBetween(a, b)
				expect(angle).to.be.near(math.pi, 0.0001)
			end)

			it("returns pi/2 for perpendicular vectors", function()
				local a = Vector3.new(1, 0, 0)
				local b = Vector3.new(0, 1, 0)
				local angle = Geom.AngleBetween(a, b)
				expect(angle).to.be.near(math.pi / 2, 0.0001)
			end)

			it("handles non-unit vectors", function()
				local a = Vector3.new(5, 0, 0)
				local b = Vector3.new(0, 10, 0)
				local angle = Geom.AngleBetween(a, b)
				expect(angle).to.be.near(math.pi / 2, 0.0001)
			end)

			it("returns 0 for zero-length vectors", function()
				local a = Vector3.new(0, 0, 0)
				local b = Vector3.new(1, 0, 0)
				local angle = Geom.AngleBetween(a, b)
				expect(angle).to.equal(0)
			end)

			it("handles 45 degree angle", function()
				local a = Vector3.new(1, 0, 0)
				local b = Vector3.new(1, 1, 0)
				local angle = Geom.AngleBetween(a, b)
				expect(angle).to.be.near(math.rad(45), 0.0001)
			end)
		end)
	end)
end
