extends CanvasLayer

signal completed(success: bool)

const _BAR_W: float = 200.0
const _BAR_H: float = 12.0
const _DOT_W: float = 8.0
const _ZONE_W: float = 38.0
const _DOT_SPEED: float = 155.0
const _BAR_X: float = 60.0
const _BAR_Y: float = 83.0

var _dot_pos: float = 0.0
var _dot_vel: float = 0.0
var _zone_left: float = 0.0
var _dot_ctrl: ColorRect
var _resolved: bool = false
var _accepting_input: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 50
	get_tree().paused = true

	_zone_left = randf_range(8.0, _BAR_W - _ZONE_W - 8.0)
	_dot_pos = _BAR_W * 0.5
	_dot_vel = _DOT_SPEED * (1.0 if randf() > 0.5 else -1.0)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.5)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.12, 0.12, 0.12)
	bar_bg.offset_left = _BAR_X
	bar_bg.offset_top = _BAR_Y
	bar_bg.offset_right = _BAR_X + _BAR_W
	bar_bg.offset_bottom = _BAR_Y + _BAR_H
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar_bg)

	var zone := ColorRect.new()
	zone.color = Color(0.18, 0.68, 0.22)
	zone.offset_left = _BAR_X + _zone_left
	zone.offset_top = _BAR_Y
	zone.offset_right = _BAR_X + _zone_left + _ZONE_W
	zone.offset_bottom = _BAR_Y + _BAR_H
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(zone)

	for edge_x: float in [_zone_left, _zone_left + _ZONE_W]:
		var marker := ColorRect.new()
		marker.color = Color(1.0, 1.0, 1.0)
		marker.offset_left = _BAR_X + edge_x - 1.0
		marker.offset_top = _BAR_Y - 2.0
		marker.offset_right = _BAR_X + edge_x + 1.0
		marker.offset_bottom = _BAR_Y + _BAR_H + 2.0
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(marker)

	_dot_ctrl = ColorRect.new()
	_dot_ctrl.color = Color(0.95, 0.95, 0.95)
	_dot_ctrl.offset_top = _BAR_Y + 1.0
	_dot_ctrl.offset_bottom = _BAR_Y + _BAR_H - 1.0
	_dot_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dot_ctrl)
	_update_dot()

func _process(delta: float) -> void:
	if not _accepting_input:
		_accepting_input = true
		return
	if _resolved:
		return
	_dot_pos += _dot_vel * delta
	if _dot_pos <= 0.0:
		_dot_pos = 0.0
		_dot_vel = absf(_dot_vel)
	elif _dot_pos >= _BAR_W - _DOT_W:
		_dot_pos = _BAR_W - _DOT_W
		_dot_vel = -absf(_dot_vel)
	_update_dot()

func _update_dot() -> void:
	_dot_ctrl.offset_left = _BAR_X + _dot_pos
	_dot_ctrl.offset_right = _BAR_X + _dot_pos + _DOT_W

func _input(event: InputEvent) -> void:
	if not _accepting_input or _resolved:
		return
	var fired := false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		fired = mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed
	elif event is InputEventKey:
		var k := event as InputEventKey
		fired = k.pressed and not k.echo and k.physical_keycode == KEY_SPACE
	if not fired:
		return
	get_viewport().set_input_as_handled()
	_resolve()

func _resolve() -> void:
	_resolved = true
	var success: bool = _dot_pos >= _zone_left and (_dot_pos + _DOT_W) <= (_zone_left + _ZONE_W)
	var result_label := Label.new()
	result_label.text = "HIT!" if success else "MISS!"
	result_label.add_theme_font_size_override("font_size", 8)
	result_label.add_theme_color_override("font_color", Color(0.3, 0.95, 0.4) if success else Color(0.95, 0.25, 0.25))
	result_label.offset_left = 0.0
	result_label.offset_top = 98.0
	result_label.offset_right = 320.0
	result_label.offset_bottom = 108.0
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(result_label)
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_callback(func() -> void:
		get_tree().paused = false
		completed.emit(success)
		queue_free()
	)
