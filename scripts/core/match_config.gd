extends Resource
class_name MatchConfig

@export var mode: Types.MatchMode = Types.MatchMode.ONE_V_ONE
@export var players_per_side: int = 1

@export_group("Lane")
@export var lane_width_multiplier: float = 1.0

@export_group("Minions")
@export var minions_per_wave: int = 6
@export var melee_per_wave: int = 4
@export var ranged_per_wave: int = 2
@export var wave_spawn_interval: float = 45.0

@export_group("Jungle")
@export var jungle_camps_per_side: int = 2
@export var camp_respawn_time: float = 30.0
@export var stacks_per_camp: int = 2

@export_group("Win Conditions")
@export var minion_kill_threshold: int = 100

@export_group("Nexus Tower")
@export var nexus_tower_hp_multiplier: float = 1.0
@export var nexus_tower_base_hp: float = 3000.0

@export_group("Match Timing")
@export var match_length_target_minutes: float = 17.5

func get_nexus_tower_hp() -> float:
	return nexus_tower_base_hp * nexus_tower_hp_multiplier

static func create_1v1() -> MatchConfig:
	var config = MatchConfig.new()
	config.mode = Types.MatchMode.ONE_V_ONE
	config.players_per_side = 1
	config.lane_width_multiplier = 1.0
	config.minions_per_wave = 6
	config.melee_per_wave = 4
	config.ranged_per_wave = 2
	config.jungle_camps_per_side = 2
	config.minion_kill_threshold = 100
	config.nexus_tower_hp_multiplier = 1.0
	return config

static func create_2v2() -> MatchConfig:
	var config = MatchConfig.new()
	config.mode = Types.MatchMode.TWO_V_TWO
	config.players_per_side = 2
	config.lane_width_multiplier = 1.5
	config.minions_per_wave = 9
	config.melee_per_wave = 6
	config.ranged_per_wave = 3
	config.jungle_camps_per_side = 3
	config.minion_kill_threshold = 200
	config.nexus_tower_hp_multiplier = 1.3
	return config
