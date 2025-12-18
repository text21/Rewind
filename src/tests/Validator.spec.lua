return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Validator = require(ReplicatedStorage.Rewind.Server.Validator)

	local ctx = {
		maxRayDistance = 1000,
		allowHeadshots = true,
		extraForgiveness = 0,
	}

	local ctxNoHead = {
		maxRayDistance = 1000,
		allowHeadshots = false,
		extraForgiveness = 0,
	}

	describe("Validator", function()
		describe("RaycastPose", function()
			it("hits a single OBB", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(0, 0, 10), size = Vector3.new(4, 6, 2) },
					},
				}

				local r = Validator.RaycastPose(Vector3.new(0, 0, 0), Vector3.new(0, 0, 100), pose, ctx)
				expect(r ~= nil).to.equal(true)
				expect(r.partName).to.equal("Torso")
			end)

			it("returns nil when ray misses all OBBs", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(100, 0, 10), size = Vector3.new(4, 6, 2) },
					},
				}

				local r = Validator.RaycastPose(Vector3.new(0, 0, 0), Vector3.new(0, 0, 100), pose, ctx)
				expect(r).to.equal(nil)
			end)

			it("returns closest hit when multiple OBBs in path", function()
				local pose = {
					parts = {
						FarTorso = { cf = CFrame.new(0, 0, 20), size = Vector3.new(4, 6, 2) },
						NearTorso = { cf = CFrame.new(0, 0, 10), size = Vector3.new(4, 6, 2) },
					},
				}

				local r = Validator.RaycastPose(Vector3.new(0, 0, 0), Vector3.new(0, 0, 100), pose, ctx)
				expect(r ~= nil).to.equal(true)
				expect(r.partName).to.equal("NearTorso")
			end)

			it("respects maxRayDistance", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(0, 0, 500), size = Vector3.new(4, 6, 2) },
					},
				}

				local r = Validator.RaycastPose(Vector3.new(0, 0, 0), Vector3.new(0, 0, 1000), pose, {
					maxRayDistance = 100,
					allowHeadshots = true,
					extraForgiveness = 0,
				})
				expect(r).to.equal(nil)
			end)

			it("handles zero-length direction", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(0, 0, 10), size = Vector3.new(4, 6, 2) },
					},
				}

				local r = Validator.RaycastPose(Vector3.new(0, 0, 0), Vector3.new(0, 0, 0), pose, ctx)
				expect(r).to.equal(nil)
			end)

			it("is deterministic (same input = same output)", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(0, 0, 10), size = Vector3.new(4, 6, 2) },
					},
				}

				local r1 = Validator.RaycastPose(Vector3.new(0, 0, 0), Vector3.new(0, 0, 100), pose, ctx)
				local r2 = Validator.RaycastPose(Vector3.new(0, 0, 0), Vector3.new(0, 0, 100), pose, ctx)

				expect(r1.partName).to.equal(r2.partName)
				expect(r1.t).to.equal(r2.t)
				expect(r1.isHeadshot).to.equal(r2.isHeadshot)
			end)
		end)

		describe("SpherePose", function()
			it("detects sphere overlapping OBB", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(0, 0, 5), size = Vector3.new(4, 6, 2) },
					},
				}

				local r = Validator.SpherePose(Vector3.new(0, 0, 0), 5, pose, ctx)
				expect(r ~= nil).to.equal(true)
				expect(r.partName).to.equal("Torso")
			end)

			it("returns nil when sphere doesn't overlap", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(0, 0, 100), size = Vector3.new(4, 6, 2) },
					},
				}

				local r = Validator.SpherePose(Vector3.new(0, 0, 0), 5, pose, ctx)
				expect(r).to.equal(nil)
			end)

			it("is deterministic", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(0, 0, 5), size = Vector3.new(4, 6, 2) },
					},
				}

				local r1 = Validator.SpherePose(Vector3.new(0, 0, 0), 5, pose, ctx)
				local r2 = Validator.SpherePose(Vector3.new(0, 0, 0), 5, pose, ctx)

				expect(r1.partName).to.equal(r2.partName)
				expect(r1.closest).to.equal(r2.closest)
			end)
		end)

		describe("CapsuleSweepPose", function()
			it("detects hit along sweep", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(0, 0, 6), size = Vector3.new(4, 6, 2) },
					},
				}

				local r = Validator.CapsuleSweepPose(
					Vector3.new(0, 0, 0),
					Vector3.new(0, 0, 10),
					1,
					pose,
					ctx,
					10
				)

				expect(r ~= nil).to.equal(true)
				expect(r.partName).to.equal("Torso")
			end)

			it("returns nil when sweep misses", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(100, 0, 6), size = Vector3.new(4, 6, 2) },
					},
				}

				local r = Validator.CapsuleSweepPose(
					Vector3.new(0, 0, 0),
					Vector3.new(0, 0, 10),
					1,
					pose,
					ctx,
					10
				)

				expect(r).to.equal(nil)
			end)

			it("returns earliest hit along sweep", function()
				local pose = {
					parts = {
						FarTorso = { cf = CFrame.new(0, 0, 15), size = Vector3.new(4, 6, 2) },
						NearTorso = { cf = CFrame.new(0, 0, 5), size = Vector3.new(4, 6, 2) },
					},
				}

				local r = Validator.CapsuleSweepPose(
					Vector3.new(0, 0, 0),
					Vector3.new(0, 0, 20),
					1,
					pose,
					ctx,
					20
				)

				expect(r ~= nil).to.equal(true)
				expect(r.partName).to.equal("NearTorso")
			end)

			it("is deterministic", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(0, 0, 6), size = Vector3.new(4, 6, 2) },
					},
				}

				local r1 = Validator.CapsuleSweepPose(Vector3.new(0, 0, 0), Vector3.new(0, 0, 10), 1, pose, ctx, 10)
				local r2 = Validator.CapsuleSweepPose(Vector3.new(0, 0, 0), Vector3.new(0, 0, 10), 1, pose, ctx, 10)

				expect(r1.partName).to.equal(r2.partName)
				expect(r1.t).to.equal(r2.t)
			end)

			it("handles zero-length sweep (point sphere)", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(0, 0, 0), size = Vector3.new(4, 6, 2) },
					},
				}

				local r = Validator.CapsuleSweepPose(
					Vector3.new(0, 0, 0),
					Vector3.new(0, 0, 0),
					2,
					pose,
					ctx,
					10
				)

				expect(r ~= nil).to.equal(true)
			end)
		end)

		describe("Headshot filtering", function()
			it("allows headshot when enabled", function()
				local pose = {
					parts = {
						Head = { cf = CFrame.new(0, 0, 10), size = Vector3.new(2, 2, 2) },
					},
				}

				local r = Validator.RaycastPose(Vector3.new(0, 0, 0), Vector3.new(0, 0, 100), pose, ctx)
				expect(r ~= nil).to.equal(true)
				expect(r.isHeadshot).to.equal(true)
			end)

			it("filters headshot when disabled", function()
				local pose = {
					parts = {
						Head = { cf = CFrame.new(0, 0, 10), size = Vector3.new(2, 2, 2) },
					},
				}

				local r = Validator.RaycastPose(Vector3.new(0, 0, 0), Vector3.new(0, 0, 100), pose, ctxNoHead)
				expect(r == nil).to.equal(true)
			end)

			it("still hits body when headshots disabled", function()
				local pose = {
					parts = {
						Head = { cf = CFrame.new(0, 0, 10), size = Vector3.new(2, 2, 2) },
						Torso = { cf = CFrame.new(0, 0, 15), size = Vector3.new(4, 6, 2) },
					},
				}

				local r = Validator.RaycastPose(Vector3.new(0, 0, 0), Vector3.new(0, 0, 100), pose, ctxNoHead)
				expect(r ~= nil).to.equal(true)
				expect(r.partName).to.equal("Torso")
			end)
		end)

		describe("FanRaysPose", function()
			it("can hit via rays", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(2, 0, 10), size = Vector3.new(4, 6, 2) },
					},
				}

				local originCf = CFrame.new(0, 0, 0)
				local r = Validator.FanRaysPose(originCf, 50, 90, 9, pose, ctx)
				expect(r ~= nil).to.equal(true)
			end)

			it("returns nil when all rays miss", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(100, 0, 10), size = Vector3.new(4, 6, 2) },
					},
				}

				local originCf = CFrame.new(0, 0, 0)
				local r = Validator.FanRaysPose(originCf, 50, 45, 5, pose, ctx)
				expect(r).to.equal(nil)
			end)
		end)

		describe("ConePose", function()
			it("hits target within cone", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(0, 0, 5), size = Vector3.new(4, 6, 2) },
					},
				}

				local originCf = CFrame.new(0, 0, 0)
				local r = Validator.ConePose(originCf, 10, 90, pose, ctx)
				expect(r ~= nil).to.equal(true)
				expect(r.partName).to.equal("Torso")
			end)

			it("misses target outside cone angle", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(10, 0, 1), size = Vector3.new(4, 6, 2) },
					},
				}

				-- Looking forward (+Z), target is mostly to the side
				local originCf = CFrame.new(0, 0, 0)
				local r = Validator.ConePose(originCf, 20, 10, pose, ctx) -- very narrow cone
				expect(r).to.equal(nil)
			end)

			it("misses target outside range", function()
				local pose = {
					parts = {
						Torso = { cf = CFrame.new(0, 0, 50), size = Vector3.new(4, 6, 2) },
					},
				}

				local originCf = CFrame.new(0, 0, 0)
				local r = Validator.ConePose(originCf, 10, 90, pose, ctx) -- range = 10, target at 50
				expect(r).to.equal(nil)
			end)
		end)
	end)
end
