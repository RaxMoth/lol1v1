extends AbilityBase
class_name BasicAttackAbility

@export var attack_damage: float = 10.0
@export var attack_range: float = 125.0

func _ready() -> void:
	ability_name = &"BasicAttack"
	ability_description = "Basic melee/ranged attack"
	is_passive = false
	base_cooldowns = [0.8, 0.75, 0.7, 0.65, 0.6]
	base_damages = [50.0, 55.0, 60.0, 65.0, 70.0]
	base_ranges = [125.0, 125.0, 125.0, 125.0, 125.0]

func can_cast_ability(caster_entity: Node2D = null) -> bool:
	if not caster_entity: return is_ability_ready()
	if caster_entity.has_method("is_target_valid"):
		if not caster_entity.is_target_valid(): return false
	return is_ability_ready()

func execute_ability(caster_entity: Node2D, target_node: Node2D = null) -> void:
	if not caster_entity: return
	if not target_node:
		if caster_entity.has_method("is_target_valid") and caster_entity.is_target_valid():
			target_node = caster_entity.target_entity
		else: return
	if not is_instance_valid(target_node): return
	if caster_entity.global_position.distance_to(target_node.global_position) > get_effective_range(): return
	var damage = get_effective_damage() * randf_range(0.9, 1.1)
	if target_node.has_method("take_damage_from"):
		target_node.take_damage_from(damage, caster_entity)
	elif target_node.has_method("take_damage"):
		target_node.take_damage(damage)
	start_cooldown()
	ability_triggered.emit(ability_name)
