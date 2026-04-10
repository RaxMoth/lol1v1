extends Node
class_name MatchManager

signal match_started
signal match_ended(winning_team: int, condition: Types.WinCondition)

@export var match_config: MatchConfig

var wave_spawner: MinionWaveSpawner
var stack_economy: StackEconomy
var win_condition: WinConditionSystem
var respawn_system: RespawnSystem
var jungle_camp_manager: JungleCampManager

var match_phase: Types.MatchPhase = Types.MatchPhase.LOBBY
var match_start_time: float = 0.0
var is_match_active: bool = false

func _ready() -> void:
	if not match_config:
		match_config = MatchConfig.create_1v1()

func start_match() -> void:
	if is_match_active: return
	is_match_active = true
	match_phase = Types.MatchPhase.MATCH_ACTIVE
	match_start_time = Time.get_ticks_msec() / 1000.0
	if win_condition:
		win_condition.setup(match_config)
		win_condition.reset()
		if not win_condition.match_won.is_connected(_on_match_won):
			win_condition.match_won.connect(_on_match_won)
	if stack_economy and win_condition:
		if not stack_economy.minion_kill_counted.is_connected(win_condition.on_minion_kill_counted):
			stack_economy.minion_kill_counted.connect(win_condition.on_minion_kill_counted)
	if wave_spawner:
		wave_spawner.match_config = match_config
		wave_spawner.start_spawning()
	if jungle_camp_manager:
		jungle_camp_manager.match_config = match_config
	match_started.emit()

func end_match(winning_team: int, condition: Types.WinCondition) -> void:
	if not is_match_active: return
	is_match_active = false
	match_phase = Types.MatchPhase.MATCH_ENDED
	if wave_spawner:
		wave_spawner.stop_spawning()
	match_ended.emit(winning_team, condition)

func get_match_elapsed() -> float:
	if not is_match_active: return 0.0
	return Time.get_ticks_msec() / 1000.0 - match_start_time

func _on_match_won(winning_team_id: int, condition: Types.WinCondition) -> void:
	end_match(winning_team_id, condition)
