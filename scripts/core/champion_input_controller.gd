extends Node
class_name ChampionInputController

@export var champion: ChampionBase
@export var ability_system: Node

var attack_move_pending: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if not champion or not is_instance_valid(champion): return
	if champion.is_dead: return
	if event.is_action_pressed("move_to"):
		var target_pos = champion.get_global_mouse_position()
		if attack_move_pending:
			_attack_move(target_pos)
			attack_move_pending = false
		else:
			_move_to(target_pos)
	elif event.is_action_pressed("attack_move"):
		attack_move_pending = true
	elif event.is_action_pressed("ability_q"):
		_cast(Types.AbilitySlot.Q)
	elif event.is_action_pressed("ability_w"):
		_cast(Types.AbilitySlot.W)
	elif event.is_action_pressed("ability_e"):
		_cast(Types.AbilitySlot.E)
	elif event.is_action_pressed("ability_r"):
		_cast(Types.AbilitySlot.R)

func _move_to(pos: Vector2) -> void:
	if champion.has_method("move_to"):
		champion.move_to(pos)
	else:
		champion.set("target_position", pos)

func _attack_move(pos: Vector2) -> void:
	if champion.has_method("attack_move"):
		champion.attack_move(pos)
	else:
		_move_to(pos)

func _cast(slot: int) -> void:
	if ability_system and ability_system.has_method("cast_ability"):
		ability_system.cast_ability(slot)
