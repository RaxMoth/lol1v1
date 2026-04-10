extends Resource
class_name AbilityBase

signal ability_triggered(ability_name: StringName)
signal ability_cooldown_started(ability_name: StringName, duration: float)
signal ability_ready(ability_name: StringName)

@export var ability_name: StringName = &"Ability"
@export var ability_description: String = "Base ability"
@export var is_passive: bool = false

@export_group("Level Scaling")
@export var level: int = 1
@export var max_level: int = 5
@export var base_cooldowns: Array[float] = [10.0, 9.0, 8.0, 7.0, 6.0]
@export var base_damages: Array[float] = [80.0, 110.0, 140.0, 170.0, 200.0]
@export var base_ranges: Array[float] = [300.0, 300.0, 325.0, 325.0, 350.0]

var caster: Node2D = null
var current_cooldown: float = 0.0
var cdr_modifier: float = 0.0

func _process(delta: float) -> void:
	if current_cooldown > 0.0:
		current_cooldown -= delta
		if current_cooldown <= 0.0:
			current_cooldown = 0.0
			ability_ready.emit(ability_name)

func get_effective_cooldown() -> float:
	var idx = clampi(level - 1, 0, base_cooldowns.size() - 1)
	return base_cooldowns[idx] * (1.0 - cdr_modifier)

func get_effective_damage() -> float:
	var idx = clampi(level - 1, 0, base_damages.size() - 1)
	return base_damages[idx]

func get_effective_range() -> float:
	var idx = clampi(level - 1, 0, base_ranges.size() - 1)
	return base_ranges[idx]

func level_up() -> bool:
	if level >= max_level: return false
	level += 1
	return true

func get_ability_name() -> StringName: return ability_name
func is_ability_ready() -> bool: return current_cooldown <= 0.0

func can_cast_ability(_caster_entity: Node2D = null) -> bool:
	return is_ability_ready()

func execute_ability(_caster_entity: Node2D, _target: Node2D = null) -> void:
	push_warning("execute_ability() not implemented in " + ability_name)

func start_cooldown() -> void:
	current_cooldown = get_effective_cooldown()
	ability_cooldown_started.emit(ability_name, current_cooldown)

func reset_cooldown() -> void:
	current_cooldown = 0.0
	ability_ready.emit(ability_name)

func get_remaining_cooldown() -> float:
	return max(0.0, current_cooldown)
