extends Node
class_name MinionWaveSpawner

signal wave_spawned(wave_number: int, team_id: int)
signal minion_spawned(minion: MinionBase, team_id: int)

@export_group("Spawning")
@export var melee_minion_scene: PackedScene
@export var ranged_minion_scene: PackedScene
@export var enabled: bool = false

@export_group("Scaling")
@export var health_scale_per_wave: float = 1.03
@export var damage_scale_per_wave: float = 1.02

@export_group("Spawn Points")
@export var blue_spawn_point: Marker2D
@export var red_spawn_point: Marker2D

var match_config: MatchConfig
var blue_lane_path: Array[Vector2] = []
var red_lane_path: Array[Vector2] = []
var current_wave: int = 0
var wave_timer: Timer = null
var spawn_interval_timer: Timer = null
var _pending_spawns: Array[Dictionary] = []

func _ready() -> void:
	wave_timer = Timer.new()
	add_child(wave_timer)
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	spawn_interval_timer = Timer.new()
	spawn_interval_timer.wait_time = 0.3
	add_child(spawn_interval_timer)
	spawn_interval_timer.timeout.connect(_on_spawn_interval)

func start_spawning() -> void:
	if not match_config: match_config = MatchConfig.create_1v1()
	enabled = true
	wave_timer.start(match_config.wave_spawn_interval)
	_spawn_wave()

func stop_spawning() -> void:
	enabled = false
	wave_timer.stop()
	spawn_interval_timer.stop()
	_pending_spawns.clear()

func _on_wave_timer_timeout() -> void:
	if enabled: _spawn_wave()

func _spawn_wave() -> void:
	current_wave += 1
	var melee_count = match_config.melee_per_wave if match_config else 4
	var ranged_count = match_config.ranged_per_wave if match_config else 2
	for team in [Types.Team.BLUE, Types.Team.RED]:
		for i in range(melee_count):
			_pending_spawns.append({"team_id": team, "type": Types.MinionType.MELEE, "wave": current_wave})
		for i in range(ranged_count):
			_pending_spawns.append({"team_id": team, "type": Types.MinionType.RANGED, "wave": current_wave})
	wave_spawned.emit(current_wave, Types.Team.BLUE)
	wave_spawned.emit(current_wave, Types.Team.RED)
	if spawn_interval_timer.is_stopped(): spawn_interval_timer.start()

func _on_spawn_interval() -> void:
	if _pending_spawns.is_empty():
		spawn_interval_timer.stop()
		return
	_spawn_single_minion(_pending_spawns.pop_front())

func _spawn_single_minion(data: Dictionary) -> void:
	var scene = melee_minion_scene if data["type"] == Types.MinionType.MELEE else ranged_minion_scene
	if not scene: return
	var minion = scene.instantiate() as MinionBase
	if not minion: return
	minion.team_id = data["team_id"]
	minion.minion_type = data["type"]
	if data["wave"] > 1:
		minion.max_health *= pow(health_scale_per_wave, data["wave"] - 1)
		minion.base_attack_damage *= pow(damage_scale_per_wave, data["wave"] - 1)
	var spawn_point: Marker2D
	if data["team_id"] == Types.Team.BLUE:
		spawn_point = blue_spawn_point
		minion.set_lane_path(blue_lane_path)
	else:
		spawn_point = red_spawn_point
		minion.set_lane_path(red_lane_path)
	if spawn_point: minion.global_position = spawn_point.global_position
	get_parent().add_child(minion)
	minion_spawned.emit(minion, data["team_id"])

func get_wave_number() -> int: return current_wave
