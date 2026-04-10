## Match Scene - orchestrates a single MOBA match
## Connects all systems: wave spawner, stack economy, win conditions, respawn, HUD
##
## Signals:
##   match_started() — emitted when match begins
##   match_ended(winning_team: int, condition: Types.WinCondition) — emitted on match end

extends Node2D

signal match_started
signal match_ended(winning_team: int, condition: Types.WinCondition)

@export var match_config: MatchConfig
@export var enable_debug_mode: bool = false

# System nodes (create as children or assign in editor)
var match_manager: MatchManager
var wave_spawner: MinionWaveSpawner
var stack_economy: StackEconomy
var win_condition: WinConditionSystem
var respawn_system: RespawnSystem
var jungle_camp_manager: JungleCampManager
var hud: MatchHUD

# Entity containers
@onready var game_world: Node2D = %GameWorld if has_node("%GameWorld") else null
@onready var entities: Node = %Entities if has_node("%Entities") else null

var champions: Array[ChampionBase] = []
var nexus_towers: Array[NexusTower] = []

func _ready() -> void:
	if not match_config:
		match_config = MatchConfig.create_1v1()
	_create_systems()
	_connect_signals()

func _create_systems() -> void:
	# Create system nodes
	match_manager = MatchManager.new()
	match_manager.name = "MatchManager"
	match_manager.match_config = match_config
	add_child(match_manager)

	wave_spawner = MinionWaveSpawner.new()
	wave_spawner.name = "MinionWaveSpawner"
	wave_spawner.match_config = match_config
	add_child(wave_spawner)

	stack_economy = StackEconomy.new()
	stack_economy.name = "StackEconomy"
	add_child(stack_economy)

	win_condition = WinConditionSystem.new()
	win_condition.name = "WinConditionSystem"
	add_child(win_condition)

	respawn_system = RespawnSystem.new()
	respawn_system.name = "RespawnSystem"
	add_child(respawn_system)

	jungle_camp_manager = JungleCampManager.new()
	jungle_camp_manager.name = "JungleCampManager"
	jungle_camp_manager.match_config = match_config
	add_child(jungle_camp_manager)

	# Wire systems into match manager
	match_manager.wave_spawner = wave_spawner
	match_manager.stack_economy = stack_economy
	match_manager.win_condition = win_condition
	match_manager.respawn_system = respawn_system
	match_manager.jungle_camp_manager = jungle_camp_manager

func _connect_signals() -> void:
	# Match lifecycle
	match_manager.match_started.connect(func(): match_started.emit())
	match_manager.match_ended.connect(_on_match_ended)

	# Minion deaths -> stack economy
	wave_spawner.minion_spawned.connect(_on_minion_spawned)

	# Champion deaths -> respawn system
	# (Connected per-champion when they're registered)

	# Nexus tower destruction -> win condition
	# (Connected per-tower when they're registered)

	# Jungle camp kills -> stack economy
	jungle_camp_manager.camp_killed.connect(_on_camp_killed)

func _process(_delta: float) -> void:
	# Update HUD with match timer
	if hud and match_manager:
		hud.update_match_timer(match_manager.get_match_elapsed())

# ============================================
# ENTITY REGISTRATION
# ============================================

func register_champion(champion: ChampionBase) -> void:
	champions.append(champion)
	champion.champion_died.connect(_on_champion_died)
	champion.stacks_changed.connect(func(stacks):
		if hud:
			hud.update_stacks(champion.team_id, stacks)
	)
	champion.health_changed.connect(func(current, max_hp):
		if hud:
			hud.update_champion_health(champion.team_id, current, max_hp)
	)

func register_nexus_tower(tower: NexusTower) -> void:
	nexus_towers.append(tower)
	tower.nexus_destroyed.connect(win_condition.on_nexus_destroyed)
	tower.health_changed.connect(func(current, max_hp):
		if hud:
			hud.update_tower_health(tower.team_id, current, max_hp)
	)

# ============================================
# SIGNAL HANDLERS
# ============================================

func _on_minion_spawned(minion: MinionBase, _team_id: int) -> void:
	minion.minion_died.connect(_on_minion_died)

func _on_minion_died(minion: MinionBase, killer: Node) -> void:
	stack_economy.on_minion_died(minion, killer)
	# Update HUD kill counts
	if killer and killer.is_in_group("Champion"):
		var pid: int = killer.get("player_id") if "player_id" in killer else -1
		if pid >= 0 and hud:
			hud.update_minion_kills(killer.team_id, stack_economy.get_minion_kills(pid))

func _on_champion_died(champion: ChampionBase) -> void:
	respawn_system.on_champion_died(champion)
	# Award kill stacks to the killer
	if champion.last_attacker and champion.last_attacker.is_in_group("Champion"):
		var killer_id: int = champion.last_attacker.get("player_id") if "player_id" in champion.last_attacker else -1
		if killer_id >= 0:
			stack_economy.award_champion_kill(killer_id, champion.player_id)

func _on_camp_killed(camp: JungleCampMob, killer: Node) -> void:
	if killer and killer.is_in_group("Champion"):
		var pid: int = killer.get("player_id") if "player_id" in killer else -1
		if pid >= 0:
			stack_economy.award_camp_kill(pid, camp.stack_reward)

func _on_match_ended(winning_team: int, condition: Types.WinCondition) -> void:
	if hud:
		hud.show_match_result(winning_team, condition)
	match_ended.emit(winning_team, condition)

# ============================================
# MATCH FLOW
# ============================================

func start_match() -> void:
	match_manager.start_match()
