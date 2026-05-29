extends Control

@onready var _points_label: Label = $PointsLabel
@onready var _rows: Array[Control] = [
	$HealthRow, $DamageRow, $LuckRow, $StartWaveRow,
]

const _STAT_KEYS: Array[String] = ["health", "damage", "luck", "start_wave"]

func _ready() -> void:

	var empty := StyleBoxEmpty.new()
	for row: Control in _rows:
		var btn: Button = row.get_node("PlusButton")
		for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(state, empty)
		btn.add_theme_color_override("font_color", Color(1.0, 0.831, 0.639))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.925, 0.839))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.667, 0.369))
		btn.add_theme_color_override("font_disabled_color", Color(0.553, 0.412, 0.478))

	var play_btn: Button = $PlayButton
	for state: String in ["normal", "hover", "pressed", "focus"]:
		play_btn.add_theme_stylebox_override(state, empty)
	play_btn.add_theme_color_override("font_color", Color(1.0, 0.667, 0.369))
	play_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.925, 0.839))
	play_btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.831, 0.639))

	for i: int in _rows.size():
		var key: String = _STAT_KEYS[i]
		var btn: Button = _rows[i].get_node("PlusButton")
		btn.pressed.connect(func() -> void: _on_plus(key))
	play_btn.pressed.connect(_on_play)

	_refresh()

func _refresh() -> void:
	_points_label.text = "%d POINTS" % SAVE_DATA.points
	var levels: Array[int] = [
		SAVE_DATA.stat_health,
		SAVE_DATA.stat_damage,
		SAVE_DATA.stat_luck,
		SAVE_DATA.stat_start_wave,
	]
	var effects: Array[String] = [
		"+%d MAX HP" % SAVE_DATA.get_health_bonus(),
		"+%d DMG" % SAVE_DATA.get_damage_bonus(),
		"+%.1f%% LUCK" % SAVE_DATA.get_luck_pct(),
		"W%d START" % SAVE_DATA.get_start_wave(),
	]
	for i: int in _rows.size():
		var row: Control = _rows[i]
		var key: String = _STAT_KEYS[i]
		var maxed: bool = SAVE_DATA.is_stat_maxed(key)
		var max_lv: int = SAVE_DATA.MAX_LEVEL[key]
		row.get_node("LevelLabel").text = "MAX" if maxed else "LV %d/%d" % [levels[i], max_lv]
		row.get_node("EffectLabel").text = effects[i]
		var btn: Button = row.get_node("PlusButton")
		btn.disabled = SAVE_DATA.points <= 0 or maxed
		btn.text = "-" if maxed else "+"

func _on_plus(stat: String) -> void:
	if SAVE_DATA.try_spend_point(stat):
		_refresh()

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
