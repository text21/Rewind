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

export type EntityType = "Player" | "NPC"

export type EntityInfo = {
	id: string,
	entityType: EntityType,
	model: Model,
	player: Player?,
	priority: number,
	lastUpdate: number,
}

export type EntityState = {
	t: number,
	rootCf: CFrame,
	velocity: Vector3,
	parts: { [string]: CFrame }?,
}

export type CompressedState = {
	t: number,
	pos: Vector3,
	rot: { number },
	vel: Vector3?,
}

export type ReplicationConfig = {
	enabled: boolean?,
	tickRate: number?,
	interpolationDelay: number?,
	maxExtrapolation: number?,

	deltaCompression: boolean?,
	proximityBased: boolean?,
	nearDistance: number?,
	farDistance: number?,
	farTickDivisor: number?,

	clientAuthoritative: boolean?,
	reconciliationThreshold: number?,
}

export type InterpolationState = {
	entity: EntityInfo,
	buffer: { EntityState },
	bufferSize: number,
	renderTime: number,
	lastReceivedTime: number,
}

export type HitPriority = {
	partName: string,
	priority: number,
	damageMultiplier: number?,
}

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
	replication: ReplicationConfig?,
}

export type WeaponProfile = {
	id: string,
	maxRewindMs: number?,
	maxDistance: number?,
	extraForgivenessStuds: number?,

	meleeRange: number?,
	meleeAngleDeg: number?,
	meleeRays: number?,

	capsuleRadius: number?,
	capsuleSteps: number?,
	requireLineOfSight: boolean?,

	isMelee: boolean?,
	scaleMultiplier: number?,
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

export type Profile = {
	id: string,
	parts: { string },
	forgiveness: { [string]: number }?,
	hitPriority: { [string]: HitPriority }?,
}

return nil
