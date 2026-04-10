extends Node
class_name MetaProgression

signal content_unlocked(content_type: String, content_id: String)

var unlocked_champions: Array[String] = []
var unlocked_items: Array[String] = []
var unlocked_runes: Array[String] = []

const SAVE_PATH: String = "user://progression.json"

func _ready() -> void:
	load_progression()

func is_champion_unlocked(id: String) -> bool: return id in unlocked_champions
func is_item_unlocked(id: String) -> bool: return id in unlocked_items
func is_rune_unlocked(id: String) -> bool: return id in unlocked_runes

func unlock_champion(id: String) -> void:
	if id not in unlocked_champions:
		unlocked_champions.append(id)
		content_unlocked.emit("champion", id)
		save_progression()

func unlock_item(id: String) -> void:
	if id not in unlocked_items:
		unlocked_items.append(id)
		content_unlocked.emit("item", id)
		save_progression()

func unlock_rune(id: String) -> void:
	if id not in unlocked_runes:
		unlocked_runes.append(id)
		content_unlocked.emit("rune", id)
		save_progression()

func save_progression() -> void:
	var data = {"champions": unlocked_champions, "items": unlocked_items, "runes": unlocked_runes}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(data))

func load_progression() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		unlocked_champions = ["champion_01"]
		unlocked_items = ["item_01", "item_02", "item_03", "item_04"]
		unlocked_runes = ["rune_01", "rune_02"]
		save_progression()
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.data
			unlocked_champions = data.get("champions", [])
			unlocked_items = data.get("items", [])
			unlocked_runes = data.get("runes", [])
