--!strict

export type RejectReason =
	| "rate_limited"
	| "duplicate_shot"
	| "no_hit"
	| "no_humanoid"
	| "friendly_fire"
	| "not_server"
	| "out_of_range"
	| "invalid_params"
	| nil -- nil = success/hit

export type ValidationMode = "Ray" | "Sphere" | "Capsule" | "Cone" | "Fan"

export type Options = {
	enabled: boolean?,
	snapshotHz: number?,
	windowMs: number?,
	maxRewindMs: number?,
	maxRayDistance: number?,
	allowHeadshots: boolean?,
	friendlyFire: boolean?,
	teamCheck: boolean?,
	antiSpam: { perSecond: number, burst: number }?,
	mode: "Analytic" | "GhostParts"?,
	debug: {
		enabled: boolean?,
	}?,
}

export type WeaponProfile = {
	id: string,
	-- Timing
	maxRewindMs: number?,
	-- Distance / Range
	maxDistance: number?,
	extraForgivenessStuds: number?,
	-- Melee-specific tuning
	meleeRange: number?,
	meleeAngleDeg: number?,
	meleeRays: number?,
	capsuleRadius: number?,
	capsuleSteps: number?,
	-- Flags
	requireLineOfSight: boolean?,
	isMelee: boolean?, -- if true, disables clientShotId duplicate check
	-- Scaled avatar support
	scaleMultiplier: number?, -- scale hitboxes by this factor
}

export type ValidateRayParams = {
	weaponId: string?,
	origin: Vector3,
	direction: Vector3,
	clientTime: number?,
	clientShotId: string?,
	ignore: { Instance }?,
}

export type ValidateSphereParams = {
	weaponId: string?,
	center: Vector3,
	radius: number,
	clientTime: number?,
	clientShotId: string?,
	ignore: { Instance }?,
}

export type ValidateCapsuleParams = {
	weaponId: string?,
	a: Vector3,
	b: Vector3,
	radius: number,
	steps: number?,
	clientTime: number?,
	clientShotId: string?,
	ignore: { Instance }?,
}

export type ValidateArcParams = {
	weaponId: string?,
	origin: CFrame,
	range: number,
	angleDeg: number,
	clientTime: number?,
	clientShotId: string?,
}

export type ValidateFanParams = {
	weaponId: string?,
	origin: CFrame,
	range: number,
	angleDeg: number,
	rays: number,
	clientTime: number?,
	clientShotId: string?,
}

export type ValidateMeleeArcParams = ValidateArcParams
export type ValidateMeleeFanParams = ValidateFanParams

-- Unified params for Rewind.Validate() dispatcher
export type ValidateParams = {
	mode: ValidationMode,
	weaponId: string?,
	clientTime: number?,
	clientShotId: string?,
	-- Ray
	origin: (Vector3 | CFrame)?,
	direction: Vector3?,
	-- Sphere
	center: Vector3?,
	radius: number?,
	-- Capsule
	a: Vector3?,
	b: Vector3?,
	steps: number?,
	-- Cone/Fan
	range: number?,
	angleDeg: number?,
	rays: number?,
}

export type HitResult = {
	hit: boolean,
	character: Model?,
	humanoid: Humanoid?,
	player: Player?,
	part: BasePart?,
	partName: string?,
	hitPosition: Vector3?,
	hitNormal: Vector3?,
	serverNow: number,
	rewindTo: number,
	usedRewindMs: number,
	isHeadshot: boolean?,
	reason: RejectReason,
}

-- Re-export types for convenience
export type Profile = {
	id: string,
	parts: { string },
	forgiveness: { [string]: number }?,
}

return nil
