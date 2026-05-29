extends Control

@onready var _points_label: Label = $PointsLabel
@onready var _rows: Array[Control] = [
	$HealthRow, $DamageRow, $LuckRow, $StartWaveRow,
]

const _STAT_KEYS: Array[String] = ["health", "damage", "luck", "start_wave"]

func _ready() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)

	var empty := StyleBoxEmpty.new()
	for row: Control in _rows:
		var btn: Button = row.get_node("PlusButton")
		for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(state, empty)
		btn.add_theme_color_override("font_color", Color(1.0, 0.831, 0.639))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.925, 0.839))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.667, 0.369))
		btn.add_theme_color_override("font_disabled_color", Color(0.329, 0.306, 0.408))

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
		"+%d MAX HP" % (levels[0] * 2),
		"+%d DMG" % levels[1],
		"+%d%% LUCK" % (levels[2] * 7),
		"W%d START" % (1 + levels[3]),
	]
	for i: int in _rows.size():
		var row: Control = _rows[i]
		row.get_node("LevelLabel").text = "LV %d" % levels[i]
		row.get_node("EffectLabel").text = effects[i]
		row.get_node("PlusButton").disabled = SAVE_DATA.points <= 0

func _on_plus(stat: String) -> void:
	if SAVE_DATA.try_spend_point(stat):
		_refresh()

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
