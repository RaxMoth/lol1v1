extends EntityBase
class_name ChampionBase

signal health_changed(current: float, max_health: float)
signal leveled_up(new_level: int, xp: float)
signal stacks_changed(new_stacks: int)
signal champion_died(champion: ChampionBase)
signal champion_respawned(champion: ChampionBase)

@export_group("Champion Identity")
@export var player_id: int = 0
@export var champion_data: Resource = null

@export_group("Champion Stats")
@export var max_health: float = 500.0
@export var base_movement_speed: float = 120.0
@export var base_attack_range: float = 125.0
@export var base_attack_damage: float = 50.0
@export var attack_cooldown: float = 0.8

@export_group("Scaling Per Level")
@export var health_per_level: float = 80.0
@export var damage_per_level: float = 5.0
@export var speed_per_level: float = 2.0

@export_group("Progression")
@export var xp_to_level_up: float = 100.0
@export var xp_multiplier_per_level: float = 1.15

const MAX_LEVEL: int = 8
const MAX_ITEMS: int = 4

var current_health: float
var current_xp: float = 0.0
var champion_level: int = 1
var attack_timer: float = 0.0
var total_damage_dealt: float = 0.0
var stacks: int = 0
var minion_kills: int = 0
var champion_kills: int = 0
var items_unlocked: int = 0
var loadout: Array = []
var runes: Array = []
var is_dead: bool = false
var respawn_timer: float = 0.0
var is_attacking: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("Champion")
	super._ready()
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _physics_process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta
	if is_dead:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			_respawn()

func take_damage(damage_amount: float) -> void:
	if is_dead: return
	current_health = max(0.0, current_health - damage_amount)
	health_changed.emit(current_health, max_health)
	if health_bar: health_bar.value = current_health
	if current_health <= 0.0:
		_on_champion_died()

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	if health_bar: health_bar.value = current_health

func apply_damage_to_target(target_node: Node2D, damage: float) -> void:
	if not is_instance_valid(target_node): return
	if target_node.has_method("take_damage"):
		target_node.take_damage(damage)
		total_damage_dealt += damage

func gain_xp(amount: float) -> void:
	if champion_level >= MAX_LEVEL: return
	current_xp += amount
	var xp_needed = xp_to_level_up * pow(xp_multiplier_per_level, champion_level - 1)
	while current_xp >= xp_needed and champion_level < MAX_LEVEL:
		current_xp -= xp_needed
		_level_up()
		xp_needed = xp_to_level_up * pow(xp_multiplier_per_level, champion_level - 1)

func _level_up() -> void:
	champion_level += 1
	max_health += health_per_level
	current_health = max_health
	base_attack_damage += damage_per_level
	base_movement_speed += speed_per_level
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	if lv_label: lv_label.text = str(champion_level)
	leveled_up.emit(champion_level, current_xp)

func add_stacks(amount: int) -> void:
	stacks += amount
	stacks_changed.emit(stacks)

func add_minion_kill() -> void:
	minion_kills += 1
	add_stacks(1)

func add_champion_kill() -> void:
	champion_kills += 1
	add_stacks(5)

func try_unlock_next_item() -> bool:
	if items_unlocked >= MAX_ITEMS or items_unlocked >= loadout.size(): return false
	if stacks >= (items_unlocked + 1) * 25:
		items_unlocked += 1
		return true
	return false

func get_respawn_time(match_elapsed: float) -> float:
	return lerpf(5.0, 12.0, clampf(match_elapsed / 1200.0, 0.0, 1.0))

func _on_champion_died() -> void:
	is_dead = true
	visible = false
	set_physics_process(false)
	if detection_area: detection_area.set_deferred("monitoring", false)
	champion_died.emit(self)

func _respawn() -> void:
	is_dead = false
	current_health = max_health
	visible = true
	set_physics_process(true)
	if detection_area: detection_area.set_deferred("monitoring", true)
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	champion_respawned.emit(self)

func start_respawn_timer(match_elapsed: float) -> void:
	respawn_timer = get_respawn_time(match_elapsed)

func _on_death_cleanup() -> void:
	_on_champion_died()

func _is_attack_ready() -> bool: return attack_timer <= 0.0
func is_alive() -> bool: return current_health > 0.0 and not is_dead
func get_health() -> float: return current_health
func _get_entity_level() -> int: return champion_level
func _get_move_speed() -> float: return base_movement_speed
func _get_attack_range() -> float: return base_attack_range
func _get_idle_retarget_time() -> float: return 3.0
func _get_idle_wander_radius() -> float: return 200.0
func _get_keep_distance() -> float: return 40.0

func _on_fight_logic(_delta: float) -> void:
	if _is_attack_ready() and is_target_valid():
		_perform_attack()

func _perform_attack() -> void:
	if not is_target_valid(): return
	attack_timer = attack_cooldown
	is_attacking = true
	var damage = base_attack_damage * randf_range(0.9, 1.1)
	apply_damage_to_target(target_entity as Node2D, damage)
	is_attacking = false
