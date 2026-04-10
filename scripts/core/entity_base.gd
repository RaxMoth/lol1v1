extends Node2D
class_name EntityBase

signal died

@export_group("Team")
@export var team_id: int = -1

@export_group("Detection")
@export var detection_radius: float = 172.0
@export var show_detection_radius: bool = false

@export_group("XP System")
@export var xp_value: float = 0.0

@export_group("Combat Behavior")
@export var combat_role: Types.CombatRole = Types.CombatRole.MELEE
@export var preferred_distance: float = 50.0
@export var min_distance: float = 30.0
@export var max_distance: float = 150.0
@export var strafe_enabled: bool = true
@export var strafe_speed: float = 60.0

@export_group("Smart Targeting")
@export var enable_smart_targeting: bool = true
@export var target_reeval_interval_approach: float = 0.5
@export var target_reeval_interval_fight: float = 1.0
@export var switch_threshold_approach: float = 30.0
@export var switch_threshold_fight: float = 50.0
@export var max_chase_distance: float = 1000.0
@export var priority_champion: int = 100
@export var priority_minion: int = 50
@export var priority_camp: int = 30

@onready var sprite: Node2D = $Sprite2D
@onready var state_chart: StateChart = %StateChart
@onready var navigation_agent_2d: NavigationAgent2D = %NavigationAgent2D
@onready var health_bar: ProgressBar = %HealthBar
@onready var detection_area: Area2D = %DetectionArea
@onready var lv_label: Label = %LVLabel

var target: Node2D = null
var target_entity: Node = null
var is_on_cooldown: bool = false
var last_attacker: Node2D = null
var strafe_direction: int = 1
var strafe_timer: float = 0.0
var strafe_change_interval: float = 2.0
var _last_nav_target_pos: Vector2 = Vector2.ZERO
var _nav_update_threshold: float = 20.0
var _idle_timer: float = 0.0
var _idle_goal: Vector2 = Vector2.ZERO
var _target_reeval_timer: float = 0.0

var move_speed: float:
	get: return _get_move_speed()
var attack_range: float:
	get: return _get_attack_range()
var idle_retarget_time: float:
	get: return _get_idle_retarget_time()
var idle_wander_radius: float:
	get: return _get_idle_wander_radius()
var keep_distance: float:
	get: return _get_keep_distance()

func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_update_detection_radius()
	if health_bar:
		health_bar.max_value = get_health()
		health_bar.value = get_health()
	if lv_label:
		lv_label.text = str(_get_entity_level())
	_setup_navigation()

func _update_detection_radius() -> void:
	if not is_instance_valid(detection_area):
		return
	var collision_shape = detection_area.get_node_or_null("CollisionShape2D")
	if not collision_shape:
		return
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = detection_radius
		if show_detection_radius:
			detection_area.visible = true

func _setup_navigation() -> void:
	var tilemap_layer := get_parent().get_node_or_null("Ground")
	if not tilemap_layer or not tilemap_layer.has_method("get_navigation_map"):
		return
	var nav_map = tilemap_layer.get_navigation_map()
	if not nav_map.is_valid():
		return
	navigation_agent_2d.set_navigation_map(nav_map)
	navigation_agent_2d.path_desired_distance = 6.0
	navigation_agent_2d.simplify_path = true
	navigation_agent_2d.target_desired_distance = 4.0
	navigation_agent_2d.avoidance_enabled = false

func _is_attack_ready() -> bool:
	return not is_on_cooldown
func is_alive() -> bool:
	push_error("is_alive() not implemented in " + name)
	return false
func take_damage(_amount: float) -> void:
	push_error("take_damage() not implemented in " + name)
func get_health() -> float:
	push_error("get_health() not implemented in " + name)
	return 0.0
func _get_entity_level() -> int:
	return 1
func _get_move_speed() -> float:
	return 80.0
func _get_attack_range() -> float:
	return 50.0
func _get_idle_retarget_time() -> float:
	return 1.2
func _get_idle_wander_radius() -> float:
	return 160.0
func _get_keep_distance() -> float:
	return 24.0
func _on_death_cleanup() -> void:
	queue_free()

func is_target_valid() -> bool:
	return is_instance_valid(target) and is_instance_valid(target_entity)
func distance_to_target() -> float:
	return target.global_position.distance_to(global_position) if is_target_valid() else INF

func _find_best_target() -> Area2D:
	if not enable_smart_targeting:
		return _find_first_valid_target()
	if not is_instance_valid(detection_area):
		return null
	var best_area: Area2D = null
	var best_score: float = -INF
	for area in detection_area.get_overlapping_areas():
		if not _can_target_area(area):
			continue
		var entity = area.get_owner()
		if not is_instance_valid(entity):
			continue
		var score = _score_target(entity)
		if score > best_score:
			best_score = score
			best_area = area
	return best_area if best_score > 0.0 else null

func _find_first_valid_target() -> Area2D:
	if not is_instance_valid(detection_area):
		return null
	for area in detection_area.get_overlapping_areas():
		if _can_target_area(area):
			return area
	return null

func _score_target(target_node: Node2D) -> float:
	if not is_instance_valid(target_node):
		return -1000.0
	var score = 0.0
	var distance = global_position.distance_to(target_node.global_position)
	score += _get_target_priority(target_node)
	score += _get_distance_score(distance)
	score += _get_threat_score(target_node)
	if target_entity != target_node:
		score -= 20.0
	if distance > max_chase_distance:
		score -= 100.0
	return score

func _get_target_priority(target_node: Node2D) -> float:
	if target_node.is_in_group("Champion"):
		return priority_champion
	elif target_node.is_in_group("Minion"):
		return priority_minion
	elif target_node.is_in_group("JungleCamp"):
		return priority_camp
	return 0.0

func _get_distance_score(distance: float) -> float:
	if distance < 50.0: return 50.0
	elif distance < 150.0: return 30.0
	elif distance < 300.0: return 10.0
	elif distance < 500.0: return -10.0
	else: return -50.0

func _get_threat_score(target_node: Node2D) -> float:
	var threat = 0.0
	if "target_entity" in target_node:
		if target_node.get("target_entity") == self:
			threat += 30.0
	if target_node.has_method("get_health") and target_node.has_method("is_alive"):
		if target_node.call("is_alive"):
			var current_hp = target_node.call("get_health")
			var max_hp = target_node.get_health() if target_node.has_method("get_health") else 100.0
			var health_percent = current_hp / max_hp if max_hp > 0 else 1.0
			if health_percent < 0.3:
				threat += 15.0
	var distance = global_position.distance_to(target_node.global_position)
	if distance > 400.0 and is_target_valid() and target_entity == target_node:
		threat -= 20.0
	return threat

func _should_switch_target(new_target_area: Area2D, threshold: float) -> bool:
	if not enable_smart_targeting:
		return not is_target_valid()
	if not is_target_valid():
		return true
	var new_target_node = new_target_area.get_owner()
	if not is_instance_valid(new_target_node):
		return false
	return _score_target(new_target_node) > _score_target(target_entity) + threshold

func _reevaluate_current_target(threshold: float) -> void:
	if not enable_smart_targeting:
		return
	var best_target_area = _find_best_target()
	if not best_target_area:
		if is_target_valid():
			target = null
			target_entity = null
			state_chart.send_event(Types.EVENT_ENEMY_LOST)
		return
	var best_target_node = best_target_area.get_owner()
	if is_target_valid() and target_entity == best_target_node:
		return
	if _should_switch_target(best_target_area, threshold):
		target = best_target_area
		target_entity = best_target_node

func _check_for_nearby_enemies() -> void:
	if not is_instance_valid(detection_area):
		return
	var best_target_area = _find_best_target()
	if best_target_area:
		target = best_target_area
		target_entity = best_target_area.get_owner()
		state_chart.send_event(Types.EVENT_ENEMY_SPOTTED)

func _can_target_area(area: Area2D) -> bool:
	if area.get_owner() == self or area.get_parent() == self:
		return false
	var root := area.get_owner()
	if not root:
		return false
	return Global.can_entity_target(self, root)

func _on_detection_area_area_entered(area: Area2D) -> void:
	if area.get_owner() == self or area.get_parent() == self:
		return
	if not area.get_owner():
		return
	if not _can_target_area(area):
		return
	if enable_smart_targeting:
		var best = _find_best_target()
		if best:
			var node = best.get_owner()
			if is_instance_valid(node):
				target = best
				target_entity = node
				state_chart.send_event(Types.EVENT_ENEMY_SPOTTED)
	else:
		target = area
		target_entity = area.get_parent()
		state_chart.send_event(Types.EVENT_ENEMY_SPOTTED)

func _on_detection_area_area_exited(area: Area2D) -> void:
	if target == area:
		if enable_smart_targeting:
			_reevaluate_current_target(switch_threshold_approach)
		else:
			target = null
			target_entity = null
			state_chart.send_event(Types.EVENT_ENEMY_LOST)

func _steer_along_nav(speed: float, delta: float) -> void:
	if not is_instance_valid(navigation_agent_2d) or navigation_agent_2d.is_navigation_finished():
		return
	var next_pos := navigation_agent_2d.get_next_path_position()
	var dir := (next_pos - global_position).normalized()
	if dir.length_squared() < 0.000001:
		return
	position += dir * speed * delta
	sprite.rotation = dir.angle()

func _set_nav_target_lazy(target_pos: Vector2) -> void:
	if not is_instance_valid(navigation_agent_2d):
		return
	if target_pos.distance_to(_last_nav_target_pos) > _nav_update_threshold:
		navigation_agent_2d.target_position = target_pos
		_last_nav_target_pos = target_pos

func move_toward_point(target_pos: Vector2, speed: float, delta: float) -> void:
	var dir := (target_pos - global_position).normalized()
	if dir.length_squared() < 0.000001:
		return
	position += dir * speed * delta
	sprite.rotation = dir.angle()

func _move_toward_target(speed: float, delta: float) -> void:
	if not is_target_valid(): return
	_set_nav_target_lazy(target.global_position)
	_steer_along_nav(speed, delta)

func _move_away_from_target(speed: float, delta: float) -> void:
	if not is_target_valid(): return
	var away_dir = (global_position - target.global_position).normalized()
	_set_nav_target_lazy(global_position + away_dir * 100.0)
	_steer_along_nav(speed, delta)

func _kite_away_from_target(speed: float, delta: float) -> void:
	if not is_target_valid(): return
	var away_dir = (global_position - target.global_position).normalized()
	var perpendicular = Vector2(-away_dir.y, away_dir.x) * strafe_direction
	var kite_dir = (away_dir + perpendicular * 0.3).normalized()
	_set_nav_target_lazy(global_position + kite_dir * 80.0)
	_steer_along_nav(speed, delta)

func _strafe_around_target(delta: float, dir: Vector2) -> void:
	if not is_target_valid(): return
	strafe_timer += delta
	if strafe_timer >= strafe_change_interval:
		strafe_timer = 0.0
		if randf() > 0.5: strafe_direction *= -1
	var perpendicular = Vector2(-dir.y, dir.x) * strafe_direction
	_set_nav_target_lazy(global_position + perpendicular * strafe_speed * delta)
	_steer_along_nav(strafe_speed, delta)

func _get_smart_idle_destination() -> Vector2:
	return _get_valid_random_destination()

func _get_valid_random_destination() -> Vector2:
	var best_point = global_position
	var best_score = -INF
	for i in range(5):
		var candidate = _generate_random_point()
		var score = _score_destination(candidate)
		if score > best_score:
			best_score = score
			best_point = candidate
	return best_point

func _generate_random_point() -> Vector2:
	var angle := randf() * TAU
	var dist := randf_range(idle_wander_radius * 0.3, idle_wander_radius)
	return global_position + Vector2.from_angle(angle) * dist

func _score_destination(point: Vector2) -> float:
	if Global.is_point_too_close_to_wall(get_world_2d(), point, 32.0, 1, 8):
		return -1000.0
	var score = 0.0
	var current_facing = sprite.rotation if sprite else 0.0
	var point_angle = (point - global_position).normalized().angle()
	score += (PI - abs(Global.angle_difference(current_facing, point_angle))) * 50.0
	score -= Global.count_walls_in_radius(get_world_2d(), point, 50.0, 1, 12) * 30.0
	return score

func _grant_xp_to_killer() -> void:
	if not is_instance_valid(target_entity): return
	if not target_entity.has_method("gain_xp"): return
	if xp_value > 0:
		target_entity.gain_xp(xp_value)

func _on_idle_state_entered() -> void:
	_idle_timer = 0.0
	_idle_goal = global_position
	_check_for_nearby_enemies()

func _on_idle_state_processing(delta: float) -> void:
	if not is_instance_valid(navigation_agent_2d): return
	_idle_timer -= delta
	if _idle_timer <= 0.0 or global_position.distance_squared_to(_idle_goal) < 64.0:
		_idle_timer = idle_retarget_time
		_idle_goal = _get_smart_idle_destination()
		navigation_agent_2d.target_position = _idle_goal
	_steer_along_nav(move_speed, delta)

func _on_approach_state_entered() -> void:
	_target_reeval_timer = target_reeval_interval_approach
	if not is_target_valid():
		_check_for_nearby_enemies()

func _on_approach_state_processing(delta: float) -> void:
	if not is_target_valid():
		state_chart.send_event(Types.EVENT_ENEMY_LOST)
		return
	if distance_to_target() <= max(attack_range, keep_distance):
		state_chart.send_event(Types.EVENT_ATTACK_TRIGGERED)
		return
	if enable_smart_targeting:
		_target_reeval_timer -= delta
		if _target_reeval_timer <= 0.0:
			_target_reeval_timer = target_reeval_interval_approach
			_reevaluate_current_target(switch_threshold_approach)
	if is_instance_valid(navigation_agent_2d):
		navigation_agent_2d.target_position = target.global_position
		_steer_along_nav(move_speed, delta)
	else:
		move_toward_point(target.global_position, move_speed, delta)

func _on_fight_state_entered() -> void:
	_target_reeval_timer = target_reeval_interval_fight
	if not is_target_valid():
		state_chart.send_event(Types.EVENT_TARGET_LOST)

func _on_fight_state_processing(delta: float) -> void:
	if not is_target_valid():
		state_chart.send_event(Types.EVENT_TARGET_LOST)
		return
	var distance = distance_to_target()
	if distance > max_distance:
		state_chart.send_event(Types.EVENT_REAPPROACH)
		return
	if enable_smart_targeting:
		_target_reeval_timer -= delta
		if _target_reeval_timer <= 0.0:
			_target_reeval_timer = target_reeval_interval_fight
			_reevaluate_current_target(switch_threshold_fight)
	var dir := (target.global_position - global_position).normalized()
	sprite.rotation = dir.angle()
	if _is_attack_ready() and distance <= attack_range and distance >= min_distance:
		_on_fight_logic(delta)
	else:
		match combat_role:
			Types.CombatRole.MELEE:
				if distance > attack_range: _move_toward_target(move_speed, delta)
				elif distance < min_distance: _move_away_from_target(move_speed * 0.5, delta)
			Types.CombatRole.RANGED, Types.CombatRole.SUPPORT:
				if distance < min_distance: _kite_away_from_target(move_speed, delta)
				elif distance > preferred_distance + 30.0: _move_toward_target(move_speed * 0.7, delta)
				elif strafe_enabled: _strafe_around_target(delta, dir)

func _on_fight_logic(_delta: float) -> void:
	pass

func _on_dead_state_entered() -> void:
	died.emit()
	_grant_xp_to_killer()
	_on_death_cleanup()
