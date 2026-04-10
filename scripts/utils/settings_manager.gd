extends Resource
class_name SettingsManager

signal setting_changed(key: String, value: Variant)
signal master_volume_changed(volume: float)
signal music_volume_changed(volume: float)
signal sfx_volume_changed(volume: float)
signal graphics_setting_changed(setting: String, value: Variant)
signal language_changed(language: String)

@export_group("Audio")
@export var master_volume: float = 1.0
@export var music_volume: float = 0.8
@export var sfx_volume: float = 0.8
@export var voice_volume: float = 0.8

@export_group("Graphics")
@export var fullscreen: bool = false
@export var vsync_enabled: bool = true
@export var fps_cap: int = 60
@export var particle_quality: String = "high"
@export var screen_shake_enabled: bool = true
@export var camera_smoothing: float = 0.8

@export_group("Gameplay")
@export var show_tutorials: bool = true
@export var camera_lock: bool = false

@export_group("Accessibility")
@export var language: String = "en"
@export var colorblind_mode: String = "off"
@export var text_scale: float = 1.0
@export var high_contrast_ui: bool = false
@export var show_subtitles: bool = true

var audio_buses: Dictionary = {}

func _init() -> void:
	_setup_audio_buses()
	_apply_settings()

func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	_update_audio_bus_volume("Master", master_volume)
	master_volume_changed.emit(master_volume)
	setting_changed.emit("master_volume", master_volume)

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	_update_audio_bus_volume("Music", music_volume * master_volume)
	music_volume_changed.emit(music_volume)
	setting_changed.emit("music_volume", music_volume)

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	_update_audio_bus_volume("SFX", sfx_volume * master_volume)
	sfx_volume_changed.emit(sfx_volume)
	setting_changed.emit("sfx_volume", sfx_volume)

func _setup_audio_buses() -> void:
	audio_buses = {
		"Master": AudioServer.get_bus_index("Master"),
		"Music": AudioServer.get_bus_index("Music"),
		"SFX": AudioServer.get_bus_index("SFX"),
	}

func _update_audio_bus_volume(bus_name: String, volume: float) -> void:
	if bus_name in audio_buses:
		var bus_idx = audio_buses[bus_name]
		if bus_idx >= 0:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume))

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	setting_changed.emit("fullscreen", enabled)

func set_vsync(enabled: bool) -> void:
	vsync_enabled = enabled
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED)
	setting_changed.emit("vsync_enabled", enabled)

func set_fps_cap(fps: int) -> void:
	fps_cap = max(30, fps)
	Engine.max_fps = fps_cap
	setting_changed.emit("fps_cap", fps_cap)

func save_settings() -> bool:
	var save_data = {
		"audio": {"master_volume": master_volume, "music_volume": music_volume, "sfx_volume": sfx_volume},
		"graphics": {"fullscreen": fullscreen, "vsync_enabled": vsync_enabled, "fps_cap": fps_cap},
		"accessibility": {"language": language, "text_scale": text_scale, "colorblind_mode": colorblind_mode},
	}
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		return true
	return false

func load_settings() -> bool:
	if not FileAccess.file_exists("user://settings.json"):
		return false
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.data
			if "audio" in data:
				set_master_volume(data["audio"].get("master_volume", 1.0))
				set_music_volume(data["audio"].get("music_volume", 0.8))
				set_sfx_volume(data["audio"].get("sfx_volume", 0.8))
			if "graphics" in data:
				set_fullscreen(data["graphics"].get("fullscreen", false))
				set_fps_cap(data["graphics"].get("fps_cap", 60))
			return true
	return false

func _apply_settings() -> void:
	set_master_volume(master_volume)
	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)
	set_fps_cap(fps_cap)
	set_vsync(vsync_enabled)
	load_settings()

func reset_to_defaults() -> void:
	set_master_volume(1.0)
	set_music_volume(0.8)
	set_sfx_volume(0.8)
	set_fullscreen(false)
	set_fps_cap(60)
