## Champion Data - defines a champion's identity, stats, and abilities
## Used as a Resource to configure champions in the editor

extends Resource
class_name ChampionData

@export var champion_name: String = "Champion"
@export var archetype: Types.ChampionArchetype = Types.ChampionArchetype.BURST
@export var description: String = ""
@export var icon: Texture2D

@export_group("Base Stats")
@export var base_health: float = 500.0
@export var base_attack_damage: float = 50.0
@export var base_movement_speed: float = 120.0
@export var base_attack_range: float = 125.0
@export var base_attack_cooldown: float = 0.8

@export_group("Per-Level Scaling")
@export var health_per_level: float = 80.0
@export var damage_per_level: float = 5.0
@export var speed_per_level: float = 2.0

@export_group("Abilities")
@export var passive_ability: AbilityBase
@export var q_ability: AbilityBase
@export var w_ability: AbilityBase
@export var e_ability: AbilityBase
@export var r_ability: AbilityBase

@export_group("Progression")
@export var unlocked: bool = true  # For meta progression system
@export var recommended_loadout: Array[Resource] = []  # Default item loadout
@export var recommended_runes: Array[Resource] = []     # Default rune setup
