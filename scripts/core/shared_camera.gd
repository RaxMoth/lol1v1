extends Camera2D
class_name SharedCamera

@export var tracked_champions: Array[Node2D] = []
@export var follow_speed: float = 5.0
@export var zoom_speed: float = 3.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 1.5
@export var zoom_padding: Vector2 = Vector2(400, 300)

var target_zoom: Vector2 = Vector2.ONE

func register_champion(champion: Node2D) -> void:
	if champion and not tracked_champions.has(champion):
		tracked_champions.append(champion)

func unregister_champion(champion: Node2D) -> void:
	tracked_champions.erase(champion)

func _process(delta: float) -> void:
	var valid: Array[Node2D] = []
	for c in tracked_champions:
		if is_instance_valid(c): valid.append(c)
	if valid.is_empty(): return
	var midpoint = Vector2.ZERO
	for c in valid: midpoint += c.global_position
	midpoint /= valid.size()
	global_position = global_position.lerp(midpoint, clampf(follow_speed * delta, 0.0, 1.0))
	if valid.size() >= 2:
		var min_p = valid[0].global_position
		var max_p = min_p
		for c in valid:
			min_p = min_p.min(c.global_position)
			max_p = max_p.max(c.global_position)
		var span = (max_p - min_p) + zoom_padding * 2.0
		var viewport_size = get_viewport_rect().size
		var z = min(viewport_size.x / max(span.x, 1.0), viewport_size.y / max(span.y, 1.0))
		target_zoom = Vector2(clampf(z, min_zoom, max_zoom), clampf(z, min_zoom, max_zoom))
	else:
		target_zoom = Vector2.ONE
	zoom = zoom.lerp(target_zoom, clampf(zoom_speed * delta, 0.0, 1.0))
