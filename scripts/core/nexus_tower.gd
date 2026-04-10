extends Node2D
class_name NexusTower

signal tower_clicked
signal enemy_spotted(enemy: Node)
signal enemy_lost(enemy: Node)
signal nexus_destroyed(tower_team_id: int)
signal fire_triggered(target: Node)
signal health_changed(current: float, max_health: float)

@export_group("Tower Identity")
@export var team_id: int = 0

@export_group("Tower Stats")
@export var tower_name: StringName = &"Nexus Tower"
@export var max_health: float = 3000.0
@export var attack_damage: float = 150.0
@export var attack_range: float = 500.0
@export var rate_of_fire: float = 0.8
@export var rotation_speed: float = 5.0

@export_group("Aggro")
@export var aggro_reset_time: float = 3.0

@onready var detection_area: Area2D = %DetectionArea
@onready var turret_sprite: Sprite2D = %TurretSprite
@onready var range_display: Node2D = %RangeDisplay
@onready var fire_timer: Timer = %FireTimer

var current_health: float
var attack_timer: float = 0.0
var detected_enemies: Array[Node] = []
var current_target: Node = null
var is_destroyed: bool = false
var forced_champion_target: Node = null
var forced_aggro_timer: float = 0.0

func _ready() -> void:
	current_health = max_health
	add_to_group("NexusTower")
	if detection_area:
		detection_area.area_entered.connect(_on_detection_area_entered)
		detection_area.area_exited.connect(_on_detection_area_exited)
		var cs = detection_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if cs and cs.shape is CircleShape2D:
			(cs.shape as CircleShape2D).radius = attack_range * 0.5
	var input_area = get_node_or_null("ClickArea") as Area2D
	if input_area: input_area.input_event.connect(_on_input_event)

func _physics_process(delta: float) -> void:
	if is_destroyed or detected_enemies.is_empty():
		current_target = null
		return
	if forced_aggro_timer > 0.0:
		forced_aggro_timer -= delta
		if forced_aggro_timer <= 0.0: forced_champion_target = null
	_update_target()
	if current_target:
		_rotate_toward_target(delta)
		if attack_timer <= 0.0:
			fire()
			attack_timer = rate_of_fire
		else:
			attack_timer -= delta

func _update_target() -> void:
	if forced_champion_target and is_instance_valid(forced_champion_target):
		if forced_champion_target in detected_enemies:
			current_target = forced_champion_target
			return
	var minions: Array[Node] = []
	var champs: Array[Node] = []
	for enemy in detected_enemies:
		if not is_instance_valid(enemy): continue
		var et: int = enemy.get("team_id") if "team_id" in enemy else -1
		if et == team_id: continue
		if enemy.is_in_group("Minion"): minions.append(enemy)
		elif enemy.is_in_group("Champion"): champs.append(enemy)
	if not minions.is_empty(): current_target = _get_closest(minions)
	elif not champs.is_empty(): current_target = _get_closest(champs)
	else: current_target = null

func _get_closest(targets: Array[Node]) -> Node:
	var closest: Node = null
	var closest_dist = INF
	for t in targets:
		var dist = global_position.distance_squared_to(t.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = t
	return closest

func on_champion_attacked_ally(champion: Node) -> void:
	if champion in detected_enemies:
		forced_champion_target = champion
		forced_aggro_timer = aggro_reset_time

func _rotate_toward_target(delta: float) -> void:
	if not current_target or not turret_sprite: return
	var dir = (current_target.global_position - global_position).normalized()
	var target_angle = dir.angle()
	var angle_diff = fmod(target_angle - turret_sprite.rotation + PI, TAU) - PI
	turret_sprite.rotation += sign(angle_diff) * min(abs(angle_diff), rotation_speed * delta)

func fire() -> void:
	if current_target and not is_destroyed:
		fire_triggered.emit(current_target)
		if current_target.has_method("take_damage"):
			current_target.take_damage(attack_damage)

func take_damage(damage_amount: float) -> void:
	if is_destroyed: return
	current_health = max(0.0, current_health - damage_amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0: _on_tower_destroyed()

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func _on_tower_destroyed() -> void:
	is_destroyed = true
	nexus_destroyed.emit(team_id)

func get_health_percentage() -> float:
	return current_health / max_health if max_health > 0.0 else 0.0

func _on_detection_area_entered(area: Area2D) -> void:
	var entity = area.get_owner()
	if not entity: return
	var et: int = entity.get("team_id") if "team_id" in entity else -1
	if et != team_id and et != Types.Team.NEUTRAL:
		if entity not in detected_enemies:
			detected_enemies.append(entity)
			enemy_spotted.emit(entity)

func _on_detection_area_exited(area: Area2D) -> void:
	var entity = area.get_owner()
	if entity in detected_enemies:
		detected_enemies.erase(entity)
		if entity == current_target: current_target = null
		if entity == forced_champion_target: forced_champion_target = null
		enemy_lost.emit(entity)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tower_clicked.emit()

func get_detected_enemy_count() -> int: return detected_enemies.size()
func is_targeting_enemy() -> bool: return current_target != null
