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
	| "vehicle_blocked"
	| "armor_absorbed"
	| nil -- nil = success/hit

export type ValidationMode = "Ray" | "Sphere" | "Capsule" | "Cone" | "Fan"

export type EntityType = "Player" | "NPC" | "Vehicle" | "Mount"

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

export type VehicleHitbox = {
	size: Vector3,
	offset: Vector3?,
	damageMultiplier: number?,
	isWeakSpot: boolean?,
}

export type VehicleConfig = {
	hitboxes: { [string]: VehicleHitbox }?,
	hitboxProfile: string?,
	protectsPassengers: boolean?,
	damageMultiplier: number?,
	health: number?,
}

export type MountConfig = {
	hitboxProfile: string?,
	exposeRider: boolean?,
	riderOffset: Vector3?,
}

export type VehicleInfo = {
	id: string,
	model: Model,
	config: VehicleConfig,
	passengers: { Player },
	health: number,
	maxHealth: number,
	destroyed: boolean,
}

export type MountInfo = {
	id: string,
	model: Model,
	config: MountConfig,
	rider: Player?,
}

export type ArmorLayer = {
	name: string,
	health: number,
	maxHealth: number,
	damageReduction: number,
	coversParts: { string },
	broken: boolean,
	regenerates: boolean?,
	regenRate: number?,
	regenDelay: number?,
	lastDamageTime: number?,
}

export type ArmorConfig = {
	layers: { {
		name: string,
		health: number,
		damageReduction: number,
		coversParts: { string },
		regenerates: boolean?,
		regenRate: number?,
		regenDelay: number?,
	} },
}

export type ArmorState = {
	entityId: string,
	model: Model,
	layers: { ArmorLayer },
}

export type DamageResult = {
	finalDamage: number,
	armorDamage: number,
	brokenLayers: { string },
	penetrated: boolean,
}

export type AbuseReason =
	| "rate_limited"
	| "duplicate_shot"
	| "impossible_distance"
	| "future_timestamp"
	| "past_timestamp"
	| "invalid_origin"
	| "speed_hack"
	| "teleport"
	| "fly_hack"
	| "invalid_target"

export type AbuseRecord = {
	reason: AbuseReason,
	count: number,
	firstOccurrence: number,
	lastOccurrence: number,
	metadata: { [string]: any }?,
}

export type PlayerAbuseHistory = {
	playerId: number,
	playerName: string,
	records: { [string]: AbuseRecord },
	totalViolations: number,
	sessionViolations: number,
	isBanned: boolean,
	lastSeen: number,
}

export type AbuseConfig = {
	enabled: boolean?,
	useDataStore: boolean?,
	dataStoreName: string?,
	thresholds: {
		warnAt: number?,
		kickAt: number?,
		banAt: number?,
	}?,
	autoKick: boolean?,
	autoBan: boolean?,
	saveInterval: number?,
}

export type AnomalyType =
	| "speed_hack"
	| "teleport"
	| "fly_hack"
	| "noclip"
	| "vertical_speed"

export type MovementValidationResult = {
	valid: boolean,
	anomaly: AnomalyType?,
	details: {
		speed: number?,
		distance: number?,
		airTime: number?,
		expectedMax: number?,
	}?,
}

export type MovementConfig = {
	maxSpeed: number?,
	maxVerticalSpeed: number?,
	teleportThreshold: number?,
	flyCheckInterval: number?,
	maxAirTime: number?,
	noclipCheckEnabled: boolean?,
	speedTolerance: number?,
	enableMonitoring: boolean?,
}

export type PlayerMovementState = {
	lastPosition: Vector3,
	lastTimestamp: number,
	airStartTime: number?,
	isInAir: boolean,
	violations: {
		speed: number,
		teleport: number,
		fly: number,
		noclip: number,
	},
	lastGroundPosition: Vector3?,
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
	movement: MovementConfig?,
	abuse: AbuseConfig?,
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

	armorPenetration: number?,
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

	vehicle: Model?,
	vehicleInfo: VehicleInfo?,
	armorResult: DamageResult?,
}

export type Profile = {
	id: string,
	parts: { string },
	forgiveness: { [string]: number }?,
	hitPriority: { [string]: HitPriority }?,
}

return nil
