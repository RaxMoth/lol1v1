extends EntityBase
class_name MinionBase

signal health_changed(current: float, max_health: float)
signal minion_died(minion: MinionBase, killer: Node)

@export_group("Minion Stats")
@export var max_health: float = 300.0
@export var base_movement_speed: float = 80.0
@export var base_attack_range: float = 40.0
@export var base_attack_damage: float = 12.0
@export var attack_cooldown: float = 1.2

@export_group("Minion Identity")
@export var minion_type: Types.MinionType = Types.MinionType.MELEE

var current_health: float
var attack_timer: float = 0.0
var last_hit_by: Node = null
var lane_path_points: Array[Vector2] = []
var current_path_index: int = 0

func _ready() -> void:
	current_health = max_health
	add_to_group("Minion")
	if minion_type == Types.MinionType.RANGED:
		base_attack_range = 200.0
		base_attack_damage = 18.0
		max_health = 200.0
		current_health = max_health
	super._ready()
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _physics_process(delta: float) -> void:
	if attack_timer > 0.0: attack_timer -= delta

func take_damage(damage_amount: float) -> void:
	current_health = max(0.0, current_health - damage_amount)
	health_changed.emit(current_health, max_health)
	if health_bar: health_bar.value = current_health
	if current_health <= 0.0: _on_minion_died()

func take_damage_from(damage_amount: float, attacker: Node) -> void:
	last_hit_by = attacker
	take_damage(damage_amount)

func apply_damage_to_target(target_node: Node2D, damage: float) -> void:
	if not is_instance_valid(target_node): return
	if target_node.has_method("take_damage_from"):
		target_node.take_damage_from(damage, self)
	elif target_node.has_method("take_damage"):
		target_node.take_damage(damage)

func get_health_percent() -> float:
	return current_health / max_health if max_health > 0.0 else 0.0

func set_lane_path(points: Array[Vector2]) -> void:
	lane_path_points = points
	current_path_index = 0

func _on_idle_state_entered() -> void:
	_check_for_nearby_enemies()

func _on_idle_state_processing(delta: float) -> void:
	if lane_path_points.is_empty() or current_path_index >= lane_path_points.size(): return
	var target_point = lane_path_points[current_path_index]
	if global_position.distance_to(target_point) < 20.0:
		current_path_index += 1
		if current_path_index >= lane_path_points.size(): return
		target_point = lane_path_points[current_path_index]
	move_toward_point(target_point, move_speed, delta)

func _is_attack_ready() -> bool: return attack_timer <= 0.0
func is_alive() -> bool: return current_health > 0.0
func get_health() -> float: return current_health
func _get_move_speed() -> float: return base_movement_speed
func _get_attack_range() -> float: return base_attack_range
func _get_idle_retarget_time() -> float: return 0.5
func _get_idle_wander_radius() -> float: return 0.0
func _get_keep_distance() -> float: return 20.0

func _on_fight_logic(_delta: float) -> void:
	if _is_attack_ready() and is_target_valid(): _perform_attack()

func _perform_attack() -> void:
	if not is_target_valid(): return
	attack_timer = attack_cooldown
	var damage = base_attack_damage * randf_range(0.9, 1.1)
	apply_damage_to_target(target_entity as Node2D, damage)

func _on_minion_died() -> void:
	minion_died.emit(self, last_hit_by)

func _on_death_cleanup() -> void:
	_on_minion_died()
	queue_free()
