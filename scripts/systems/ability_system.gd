extends Node
class_name AbilitySystem

signal ability_executed(ability_name: StringName)
signal ability_failed(ability_name: StringName, reason: String)

const MAX_ABILITY_SLOTS: int = 5
const SLOT_PASSIVE: int = 0
const SLOT_Q: int = 1
const SLOT_W: int = 2
const SLOT_E: int = 3
const SLOT_R: int = 4

var owner_entity: Node2D = null
var ability_slots: Array[AbilityBase] = []

func _ready() -> void:
	owner_entity = get_parent()
	ability_slots.resize(MAX_ABILITY_SLOTS)
	await get_tree().process_frame
	_setup_initial_abilities()

func _process(delta: float) -> void:
	for ability in ability_slots:
		if ability and ability.current_cooldown > 0.0:
			ability.current_cooldown -= delta

func _setup_initial_abilities() -> void:
	var basic_attack = BasicAttackAbility.new()
	add_ability(basic_attack, SLOT_Q)

func add_ability(ability: AbilityBase, slot: int = -1) -> bool:
	if slot < 0:
		for i in range(MAX_ABILITY_SLOTS):
			if ability_slots[i] == null:
				slot = i
				break
	if slot < 0 or slot >= MAX_ABILITY_SLOTS: return false
	ability_slots[slot] = ability
	ability.caster = owner_entity
	return true

func remove_ability(slot: int) -> void:
	if slot >= 0 and slot < MAX_ABILITY_SLOTS: ability_slots[slot] = null

func get_ability(slot: int) -> AbilityBase:
	if slot >= 0 and slot < MAX_ABILITY_SLOTS: return ability_slots[slot]
	return null

func get_ability_by_name(ability_name: StringName) -> AbilityBase:
	for ability in ability_slots:
		if ability and ability.ability_name == ability_name: return ability
	return null

func try_cast_ability(slot: int, target: Node2D = null) -> bool:
	var ability = get_ability(slot)
	if not ability:
		ability_failed.emit(&"", "No ability in slot " + str(slot))
		return false
	if not ability.can_cast_ability(owner_entity):
		ability_failed.emit(ability.ability_name, "Ability not ready")
		return false
	ability.execute_ability(owner_entity, target)
	ability_executed.emit(ability.ability_name)
	return true

func try_cast_ability_by_name(ability_name: StringName, target: Node2D = null) -> bool:
	var ability = get_ability_by_name(ability_name)
	if not ability:
		ability_failed.emit(ability_name, "Ability not found")
		return false
	if not ability.can_cast_ability(owner_entity):
		ability_failed.emit(ability_name, "Ability not ready")
		return false
	ability.execute_ability(owner_entity, target)
	ability_executed.emit(ability_name)
	return true

func level_up_ability(slot: int) -> bool:
	var ability = get_ability(slot)
	if not ability: return false
	return ability.level_up()

func get_ability_cooldown(slot: int) -> float:
	var ability = get_ability(slot)
	return ability.get_remaining_cooldown() if ability else 0.0

func reset_all_cooldowns() -> void:
	for ability in ability_slots:
		if ability: ability.reset_cooldown()

func is_any_ability_ready() -> bool:
	for ability in ability_slots:
		if ability and ability.is_ability_ready(): return true
	return false
