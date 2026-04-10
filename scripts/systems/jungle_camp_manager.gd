extends Node
class_name JungleCampManager

signal camp_killed(camp: JungleCampMob, killer: Node)
signal camp_respawned(camp: JungleCampMob)

var match_config: MatchConfig
var camps: Array[JungleCampMob] = []
var respawn_timers: Dictionary = {}

func register_camp(camp: JungleCampMob) -> void:
	camps.append(camp)
	camp.camp_killed.connect(_on_camp_killed)

func _process(delta: float) -> void:
	var to_respawn: Array[JungleCampMob] = []
	for c in respawn_timers.keys():
		respawn_timers[c] -= delta
		if respawn_timers[c] <= 0.0: to_respawn.append(c)
	for c in to_respawn:
		respawn_timers.erase(c)
		c.respawn()
		camp_respawned.emit(c)

func _on_camp_killed(camp: JungleCampMob, killer: Node) -> void:
	respawn_timers[camp] = match_config.camp_respawn_time if match_config else 30.0
	camp_killed.emit(camp, killer)
