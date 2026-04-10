extends Node
class_name RankedSystem

signal rank_changed(mode: Types.MatchMode, new_points: int)

const POINTS_PER_WIN: int = 25
const POINTS_PER_LOSS: int = -20

var ranked_points: Dictionary = {
	Types.MatchMode.ONE_V_ONE: 0,
	Types.MatchMode.TWO_V_TWO: 0
}

const SAVE_PATH: String = "user://ranked_data.json"

func record_match_result(mode: Types.MatchMode, won: bool) -> void:
	var change = POINTS_PER_WIN if won else POINTS_PER_LOSS
	ranked_points[mode] = max(0, ranked_points[mode] + change)
	rank_changed.emit(mode, ranked_points[mode])
	save_ranked_data()

func get_points(mode: Types.MatchMode) -> int:
	return ranked_points.get(mode, 0)

func save_ranked_data() -> void:
	var data = {"1v1": ranked_points[Types.MatchMode.ONE_V_ONE], "2v2": ranked_points[Types.MatchMode.TWO_V_TWO]}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(data))

func load_ranked_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.data
			ranked_points[Types.MatchMode.ONE_V_ONE] = data.get("1v1", 0)
			ranked_points[Types.MatchMode.TWO_V_TWO] = data.get("2v2", 0)
