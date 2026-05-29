extends Node2D

var _selected: int = -1
var _navigating: bool = false
var _btns: Array = []

@onready var _btn_play: Button = $HUD/BtnPlay
@onready var _btn_quit: Button = $HUD/BtnQuit

func _ready() -> void:
	_setup_ui()
	_spawn_particles()
	_fade_in()

func _setup_ui() -> void:
	_btns = [_btn_play, _btn_quit]
	for i: int in _btns.size():
		var idx := i
		var btn: Button = _btns[i]
		btn.mouse_entered.connect(func() -> void:
			if not _navigating:
				_selected = idx
				_refresh_buttons()
		)
		btn.mouse_exited.connect(func() -> void:
			if not _navigating and _selected == idx:
				_selected = -1
				_refresh_buttons()
		)
		btn.pressed.connect(func() -> void:
			if not _navigating:
				_selected = idx
				_animate_click(btn, idx)
		)
	_refresh_buttons()

func _unhandled_input(event: InputEvent) -> void:
	if _navigating:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP, KEY_W:
				_move_selection(-1)
				get_viewport().set_input_as_handled()
			KEY_DOWN, KEY_S:
				_move_selection(1)
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_confirm()
				get_viewport().set_input_as_handled()

func _move_selection(dir: int) -> void:
	if _selected < 0:
		_selected = 0 if dir > 0 else _btns.size() - 1
	else:
		_selected = (_selected + dir + _btns.size()) % _btns.size()
	_refresh_buttons()

func _refresh_buttons() -> void:
	for i: int in _btns.size():
		_style_btn(_btns[i], i == _selected)

func _confirm() -> void:
	var idx := maxi(_selected, 0)
	_animate_click(_btns[idx], idx)

func _animate_click(btn: Button, idx: int) -> void:
	if _navigating:
		return
	_navigating = true
	_selected = idx
	_refresh_buttons()
	btn.pivot_offset = btn.size * 0.5
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(1.12, 0.80), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(btn, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.07)
	tw.set_parallel(false)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.14)
	tw.set_parallel(false)
	tw.tween_callback(func() -> void:
		if idx == 0:
			_do_play()
		else:
			get_tree().quit()
	)

func _style_btn(btn: Button, active: bool) -> void:
	var s := StyleBoxFlat.new()
	if active:
		s.bg_color = Color(0.08, 0.22, 0.35, 0.88)
		s.border_width_left = 3
		s.border_color = Color(0.553, 0.412, 0.478)
		s.content_margin_left = 14.0
		s.content_margin_top = 5.0
		s.content_margin_right = 8.0
		s.content_margin_bottom = 5.0
	else:
		s.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		s.content_margin_left = 17.0
		s.content_margin_top = 5.0
		s.content_margin_right = 8.0
		s.content_margin_bottom = 5.0
	for style_name: String in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(style_name, s)
	var col := Color(1.0, 0.667, 0.369) if active else Color(1.0, 0.831, 0.639)
	for col_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(col_name, col)

func _spawn_particles() -> void:
	var p := CPUParticles2D.new()
	p.amount = 30
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.randomness = 0.4
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(160.0, 90.0)
	p.position = Vector2(160.0, 90.0)
	p.direction = Vector2(-1.0, 0.0)
	p.spread = 12.0
	p.gravity = Vector2(0.0, 0.4)
	p.initial_velocity_min = 12.0
	p.initial_velocity_max = 45.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 1.2
	var grad := Gradient.new()
	grad.set_color(0, Color(0.816, 0.506, 0.349, 0.55))
	grad.add_point(0.4, Color(1.0, 0.667, 0.369, 0.35))
	grad.add_point(1.0, Color(1.0, 0.925, 0.839, 0.0))
	p.color_ramp = grad
	add_child(p)

func _fade_in() -> void:
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 99
	add_child(fade_layer)
	var rect := ColorRect.new()
	rect.color = Color(0.051, 0.169, 0.271)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(rect)
	var tw := rect.create_tween()
	tw.tween_property(rect, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(fade_layer.queue_free)

func _do_play() -> void:
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 99
	get_tree().root.add_child(fade_layer)
	var rect := ColorRect.new()
	rect.color = Color(0.051, 0.169, 0.271)
	rect.modulate.a = 0.0
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(rect)
	var tw := rect.create_tween()
	tw.tween_property(rect, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/main.tscn"))
	tw.tween_property(rect, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(fade_layer.queue_free)
