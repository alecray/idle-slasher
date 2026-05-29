extends CanvasLayer

signal completed(success: bool)

const DOT_SCENE: PackedScene = preload("res://prefabs/qte_dot.tscn")

const _TIMER_DURATION: float = 4.5
const _TIMER_W: float = 240.0
const _TIMER_H: float = 6.0
const _TIMER_X: float = 40.0
const _TIMER_Y: float = 4.0
const _DOT_SIZE: float = 16.0
const _MIN_DOTS: int = 4
const _MAX_DOTS: int = 7

var _total_dots: int = 0
var _cleared_dots: int = 0
var _timer: float = 0.0
var _timer_fill: ColorRect
var _resolved: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 50
	get_tree().paused = true

	_total_dots = randi_range(_MIN_DOTS, _MAX_DOTS)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var timer_bg := ColorRect.new()
	timer_bg.color = Color(0.12, 0.12, 0.12)
	timer_bg.offset_left = _TIMER_X
	timer_bg.offset_top = _TIMER_Y
	timer_bg.offset_right = _TIMER_X + _TIMER_W
	timer_bg.offset_bottom = _TIMER_Y + _TIMER_H
	timer_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(timer_bg)

	_timer_fill = ColorRect.new()
	_timer_fill.color = Color(0.82, 0.18, 0.12)
	_timer_fill.offset_left = _TIMER_X
	_timer_fill.offset_top = _TIMER_Y
	_timer_fill.offset_right = _TIMER_X
	_timer_fill.offset_bottom = _TIMER_Y + _TIMER_H
	_timer_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_timer_fill)

	for i: int in _total_dots:
		_spawn_dot()

func _process(delta: float) -> void:
	if _resolved:
		return
	_timer += delta
	_timer_fill.offset_right = _TIMER_X + _TIMER_W * minf(_timer / _TIMER_DURATION, 1.0)
	if _timer >= _TIMER_DURATION:
		_resolve(false)

func _spawn_dot() -> void:
	var dot: Control = DOT_SCENE.instantiate() as Control
	var px: float = randf_range(55.0, 320.0 - _DOT_SIZE - 55.0)
	var py: float = randf_range(38.0, 180.0 - _DOT_SIZE - 38.0)
	dot.offset_left = px
	dot.offset_top = py
	dot.offset_right = px + _DOT_SIZE
	dot.offset_bottom = py + _DOT_SIZE
	dot.connect("dot_clicked", _on_dot_clicked)
	add_child(dot)

func _on_dot_clicked() -> void:
	if _resolved:
		return
	_cleared_dots += 1
	if _cleared_dots >= _total_dots:
		_resolve(true)

func _resolve(success: bool) -> void:
	if _resolved:
		return
	_resolved = true
	get_tree().paused = false
	completed.emit(success)
	queue_free()
