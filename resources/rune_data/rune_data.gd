## Rune Data - pre-game passive bonuses applied at match start
## Distinct from items: runes are baseline playstyle modifiers,
## items are in-match power progression

extends Resource
class_name RuneData

@export var rune_name: String = "Rune"
@export var description: String = ""
@export var icon: Texture2D

@export_group("Stats")
@export var stat_modifiers: Dictionary = {}  # e.g. {"cdr": 0.05, "move_speed": 10.0}

@export_group("Passive")
@export var passive_description: String = ""

@export_group("Progression")
@export var unlocked: bool = true  # For meta progression
