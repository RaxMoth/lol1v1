## Item Data - defines a purchasable item in the pre-game loadout
## Items are complete effects, no components or build paths
## Each costs 25 stacks to unlock during a match

extends Resource
class_name ItemData

@export var item_name: String = "Item"
@export var description: String = ""
@export var icon: Texture2D

@export_group("Stats")
@export var stat_modifiers: Dictionary = {}  # e.g. {"attack_damage": 25.0, "cdr": 0.1}

@export_group("Passive Effect")
@export var passive_description: String = ""  # Text description of passive

@export_group("Progression")
@export var unlocked: bool = true  # For meta progression
