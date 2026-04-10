extends CanvasLayer
class_name MatchHUD

@onready var match_timer_label: Label = $Root/TopBar/MatchTimer
@onready var blue_stacks_label: Label = $Root/TopBar/BlueStacks
@onready var red_stacks_label: Label = $Root/TopBar/RedStacks
@onready var blue_kills_label: Label = $Root/TopBar/BlueKills
@onready var red_kills_label: Label = $Root/TopBar/RedKills
@onready var blue_champ_hp: ProgressBar = $Root/BottomBar/BlueChampHP
@onready var red_champ_hp: ProgressBar = $Root/BottomBar/RedChampHP
@onready var blue_tower_hp: ProgressBar = $Root/BottomBar/BlueTowerHP
@onready var red_tower_hp: ProgressBar = $Root/BottomBar/RedTowerHP
@onready var result_label: Label = $Root/ResultLabel

func update_match_timer(elapsed: float) -> void:
	if not match_timer_label: return
	var minutes = int(elapsed) / 60
	var seconds = int(elapsed) % 60
	match_timer_label.text = "%02d:%02d" % [minutes, seconds]

func update_stacks(team_id: int, stacks: int) -> void:
	var label = blue_stacks_label if team_id == Types.Team.BLUE else red_stacks_label
	if label: label.text = "Stacks: %d" % stacks

func update_minion_kills(team_id: int, kills: int) -> void:
	var label = blue_kills_label if team_id == Types.Team.BLUE else red_kills_label
	if label: label.text = "CS: %d" % kills

func update_champion_health(team_id: int, current: float, max_hp: float) -> void:
	var bar = blue_champ_hp if team_id == Types.Team.BLUE else red_champ_hp
	if bar:
		bar.max_value = max_hp
		bar.value = current

func update_tower_health(team_id: int, current: float, max_hp: float) -> void:
	var bar = blue_tower_hp if team_id == Types.Team.BLUE else red_tower_hp
	if bar:
		bar.max_value = max_hp
		bar.value = current

func show_match_result(winning_team: int, condition: Types.WinCondition) -> void:
	if not result_label: return
	var team_name = "BLUE" if winning_team == Types.Team.BLUE else "RED"
	var cond_str = "Nexus Destroyed" if condition == Types.WinCondition.NEXUS_DESTROYED else "Minion Milestone"
	result_label.text = "%s WINS!\n(%s)" % [team_name, cond_str]
	result_label.visible = true
