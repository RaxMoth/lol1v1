extends Node
class_name WinConditionSystem

signal match_won(winning_team_id: int, condition: Types.WinCondition)

var match_config: MatchConfig
var match_ended: bool = false

func setup(config: MatchConfig) -> void:
	match_config = config

func on_nexus_destroyed(tower_team_id: int) -> void:
	if match_ended: return
	match_ended = true
	var winning_team: int
	if tower_team_id == Types.Team.BLUE: winning_team = Types.Team.RED
	else: winning_team = Types.Team.BLUE
	match_won.emit(winning_team, Types.WinCondition.NEXUS_DESTROYED)

func on_minion_kill_counted(player_id: int, kill_count: int) -> void:
	if match_ended: return
	var threshold = match_config.minion_kill_threshold if match_config else 100
	if kill_count >= threshold:
		match_ended = true
		var winning_team = Types.Team.BLUE if player_id % 2 == 0 else Types.Team.RED
		match_won.emit(winning_team, Types.WinCondition.MINION_MILESTONE)

func reset() -> void:
	match_ended = false
