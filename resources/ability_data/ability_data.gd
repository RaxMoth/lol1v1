## Ability Data - configurable ability definition
## Level-indexed arrays for damage, cooldown, range
## References an ability scene for visual/gameplay implementation

extends Resource
class_name AbilityData

@export var ability_name: String = "Ability"
@export var description: String = ""
@export var icon: Texture2D

@export_group("Scaling (indexed by level 0-4)")
@export var base_cooldowns: Array[float] = [10.0, 9.0, 8.0, 7.0, 6.0]
@export var base_damages: Array[float] = [80.0, 110.0, 140.0, 170.0, 200.0]
@export var base_ranges: Array[float] = [300.0, 300.0, 325.0, 325.0, 350.0]

@export_group("Scene")
@export var ability_scene: PackedScene  # Visual/gameplay implementation
