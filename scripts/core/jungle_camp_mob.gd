extends EntityBase
class_name JungleCampMob

signal health_changed(current: float, max_health: float)
signal camp_killed(camp: JungleCampMob, killer: Node)

@export_group("Camp Stats")
@export var max_health: float = 400.0
@export var base_movement_speed: float = 60.0
@export var base_attack_range: float = 40.0
@export var base_attack_damage: float = 25.0
@export var attack_cooldown: float = 1.5

@export_group("Camp Rewards")
@export var stack_reward: int = 2

@export_group("Camp Behavior")
@export var leash_radius: float = 200.0

var current_health: float
var attack_timer: float = 0.0
var spawn_position: Vector2 = Vector2.ZERO
var last_hit_by: Node = null

func _ready() -> void:
	current_health = max_health
	team_id = Types.Team.NEUTRAL
	add_to_group("JungleCamp")
	spawn_position = global_position
	super._ready()
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _physics_process(delta: float) -> void:
	if attack_timer > 0.0: attack_timer -= delta
	if global_position.distance_to(spawn_position) > leash_radius:
		_reset_to_spawn()

func take_damage(damage_amount: float) -> void:
	current_health = max(0.0, current_health - damage_amount)
	health_changed.emit(current_health, max_health)
	if health_bar: health_bar.value = current_health
	if current_health <= 0.0: _on_camp_died()

func take_damage_from(damage_amount: float, attacker: Node) -> void:
	last_hit_by = attacker
	take_damage(damage_amount)

func get_health_percent() -> float:
	return current_health / max_health if max_health > 0.0 else 0.0

func _is_attack_ready() -> bool: return attack_timer <= 0.0
func is_alive() -> bool: return current_health > 0.0
func get_health() -> float: return current_health
func _get_move_speed() -> float: return base_movement_speed
func _get_attack_range() -> float: return base_attack_range
func _get_idle_retarget_time() -> float: return 2.0
func _get_idle_wander_radius() -> float: return 80.0
func _get_keep_distance() -> float: return 30.0

func _on_fight_logic(_delta: float) -> void:
	if _is_attack_ready() and is_target_valid(): _perform_attack()

func _perform_attack() -> void:
	if not is_target_valid(): return
	attack_timer = attack_cooldown
	if target_entity.has_method("take_damage"):
		target_entity.take_damage(base_attack_damage * randf_range(0.9, 1.1))

func _on_camp_died() -> void:
	camp_killed.emit(self, last_hit_by)

func _on_death_cleanup() -> void:
	_on_camp_died()
	visible = false
	set_physics_process(false)
	if detection_area: detection_area.set_deferred("monitoring", false)

func respawn() -> void:
	current_health = max_health
	last_hit_by = null
	visible = true
	set_physics_process(true)
	global_position = spawn_position
	if detection_area: detection_area.set_deferred("monitoring", true)
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _reset_to_spawn() -> void:
	global_position = spawn_position
	current_health = max_health
	target = null
	target_entity = null
	if health_bar: health_bar.value = current_health
