extends CanvasLayer

signal close_requested
signal skip_waves_requested(count: int)
signal god_mode_toggled(enabled: bool)
signal reset_requested

var _god_mode: bool = false

@onready var _btn_god: Button = $BtnGod

func _ready() -> void:
	var empty := StyleBoxEmpty.new()
	for btn: Button in [$BtnSkip, $BtnGod, $BtnReset]:
		for state: String in ["normal", "hover", "pressed", "focus"]:
			btn.add_theme_stylebox_override(state, empty)
		btn.add_theme_font_size_override("font_size", 6)
		btn.add_theme_color_override("font_color", Color(1.0, 0.925, 0.839))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.667, 0.369))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.831, 0.639))
	$BtnSkip.pressed.connect(_on_skip_pressed)
	$BtnGod.pressed.connect(_on_god_pressed)
	$BtnReset.pressed.connect(_on_reset_pressed)
	_refresh_god_btn()

func init(god_mode_state: bool) -> void:
	_god_mode = god_mode_state
	_refresh_god_btn()

func _refresh_god_btn() -> void:
	_btn_god.text = "god mode: %s" % ("ON" if _god_mode else "OFF")
	_btn_god.add_theme_color_override("font_color",
		Color(1.0, 0.667, 0.369) if _god_mode else Color(1.0, 0.925, 0.839))

func _on_skip_pressed() -> void:
	close_requested.emit()
	skip_waves_requested.emit(5)

func _on_god_pressed() -> void:
	_god_mode = !_god_mode
	_refresh_god_btn()
	god_mode_toggled.emit(_god_mode)

func _on_reset_pressed() -> void:
	close_requested.emit()
	reset_requested.emit()
