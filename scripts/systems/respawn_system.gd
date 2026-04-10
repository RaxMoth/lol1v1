extends Node
class_name RespawnSystem

signal champion_died(champion: ChampionBase)
signal champion_respawning(champion: ChampionBase, respawn_time: float)
signal champion_respawned(champion: ChampionBase)

var blue_spawn_position: Vector2 = Vector2.ZERO
var red_spawn_position: Vector2 = Vector2.ZERO
var match_start_time: float = 0.0

func start_match() -> void:
	match_start_time = Time.get_ticks_msec() / 1000.0

func get_match_elapsed() -> float:
	return (Time.get_ticks_msec() / 1000.0) - match_start_time

func calculate_respawn_time(match_elapsed: float) -> float:
	return lerpf(5.0, 12.0, clampf(match_elapsed / 1200.0, 0.0, 1.0))

func on_champion_died(champion: ChampionBase) -> void:
	var elapsed = get_match_elapsed()
	var respawn_time = calculate_respawn_time(elapsed)
	if champion.team_id == Types.Team.BLUE:
		champion.global_position = blue_spawn_position
	else:
		champion.global_position = red_spawn_position
	champion.start_respawn_timer(elapsed)
	champion_died.emit(champion)
	champion_respawning.emit(champion, respawn_time)
	if not champion.champion_respawned.is_connected(_on_champion_respawned):
		champion.champion_respawned.connect(_on_champion_respawned)

func _on_champion_respawned(champion: ChampionBase) -> void:
	champion_respawned.emit(champion)
