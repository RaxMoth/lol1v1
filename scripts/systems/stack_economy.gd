extends Node
class_name StackEconomy

signal stacks_changed(player_id: int, new_stacks: int)
signal item_unlocked(player_id: int, item_index: int)
signal minion_kill_counted(player_id: int, new_kill_count: int)
signal champion_kill_counted(player_id: int, killer_id: int)

const STACKS_PER_MINION: int = 1
const STACKS_PER_CAMP: int = 2
const STACKS_PER_CHAMPION_KILL: int = 5
const STACKS_PER_ITEM: int = 25

var player_stacks: Dictionary = {}
var player_minion_kills: Dictionary = {}
var player_champion_kills: Dictionary = {}
var player_items_unlocked: Dictionary = {}

func register_player(player_id: int) -> void:
	player_stacks[player_id] = 0
	player_minion_kills[player_id] = 0
	player_champion_kills[player_id] = 0
	player_items_unlocked[player_id] = 0

func get_stacks(player_id: int) -> int: return player_stacks.get(player_id, 0)
func get_minion_kills(player_id: int) -> int: return player_minion_kills.get(player_id, 0)
func get_champion_kills(player_id: int) -> int: return player_champion_kills.get(player_id, 0)
func get_items_unlocked(player_id: int) -> int: return player_items_unlocked.get(player_id, 0)

func award_minion_kill(player_id: int, was_denied: bool = false) -> void:
	if was_denied: return
	_add_stacks(player_id, STACKS_PER_MINION)
	player_minion_kills[player_id] = player_minion_kills.get(player_id, 0) + 1
	minion_kill_counted.emit(player_id, player_minion_kills[player_id])

func award_camp_kill(player_id: int, camp_stacks: int = STACKS_PER_CAMP) -> void:
	_add_stacks(player_id, camp_stacks)

func award_champion_kill(killer_id: int, victim_id: int) -> void:
	_add_stacks(killer_id, STACKS_PER_CHAMPION_KILL)
	player_champion_kills[killer_id] = player_champion_kills.get(killer_id, 0) + 1
	champion_kill_counted.emit(victim_id, killer_id)

func _add_stacks(player_id: int, amount: int) -> void:
	player_stacks[player_id] = player_stacks.get(player_id, 0) + amount
	stacks_changed.emit(player_id, player_stacks[player_id])

func try_unlock_next_item(player_id: int) -> bool:
	var unlocked = player_items_unlocked.get(player_id, 0)
	if player_stacks.get(player_id, 0) >= (unlocked + 1) * STACKS_PER_ITEM:
		player_items_unlocked[player_id] = unlocked + 1
		item_unlocked.emit(player_id, unlocked + 1)
		return true
	return false

func get_stacks_to_next_item(player_id: int) -> int:
	var unlocked = player_items_unlocked.get(player_id, 0)
	return max(0, (unlocked + 1) * STACKS_PER_ITEM - player_stacks.get(player_id, 0))

func on_minion_died(minion: MinionBase, killer: Node) -> void:
	if not killer or not killer.is_in_group("Champion"): return
	var killer_id: int = killer.get("player_id") if "player_id" in killer else -1
	if killer_id < 0: return
	var killer_team: int = killer.get("team_id") if "team_id" in killer else -1
	award_minion_kill(killer_id, killer_team == minion.team_id)
