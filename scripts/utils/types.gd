extends Node

# ============================================
# TEAM & FACTION
# ============================================

enum Team {
	NEUTRAL = -1,
	BLUE = 0,
	RED = 1
}

# ============================================
# COMBAT
# ============================================

enum CombatRole {
	MELEE = 0,
	RANGED = 1,
	SUPPORT = 2
}

# ============================================
# CHAMPION ARCHETYPES
# ============================================

enum ChampionArchetype {
	POKE,
	BURST,
	TANK,
	ASSASSIN,
	SUSTAIN,
	SKIRMISHER
}

# ============================================
# MINION TYPES
# ============================================

enum MinionType {
	MELEE,
	RANGED
}

# ============================================
# MATCH CONFIG
# ============================================

enum MatchMode {
	ONE_V_ONE,
	TWO_V_TWO
}

enum MatchPhase {
	LOBBY,
	CHAMPION_SELECT,
	LOADOUT,
	LOADING,
	MATCH_ACTIVE,
	MATCH_PAUSED,
	MATCH_ENDED
}

enum WinCondition {
	NEXUS_DESTROYED,
	MINION_MILESTONE
}

# ============================================
# ABILITY SLOTS
# ============================================

enum AbilitySlot {
	PASSIVE = 0,
	Q = 1,
	W = 2,
	E = 3,
	R = 4
}

# ============================================
# STATE CHART EVENT NAME CONSTANTS
# ============================================

# Entity detection & combat
const EVENT_ENEMY_SPOTTED: StringName = &"enemie_entered"
const EVENT_ENEMY_LOST: StringName = &"enemie_exited"
const EVENT_ATTACK_TRIGGERED: StringName = &"enemy_fight"
const EVENT_TARGET_LOST: StringName = &"target_lost"
const EVENT_REAPPROACH: StringName = &"re_approach"

# Death & respawn
const EVENT_DEATH: StringName = &"death"
const EVENT_RESPAWN_READY: StringName = &"respawn_ready"

# Ability casting
const EVENT_CAST_START: StringName = &"cast_start"
const EVENT_CAST_END: StringName = &"cast_end"

# Crowd control
const EVENT_STUNNED: StringName = &"stunned"
const EVENT_STUN_END: StringName = &"stun_end"

# Tower states
const EVENT_TOWER_DESTROYED: StringName = &"tower_destroyed"

# Camp states
const EVENT_CAMP_KILLED: StringName = &"camp_killed"
const EVENT_CAMP_RESPAWN: StringName = &"camp_respawn"
