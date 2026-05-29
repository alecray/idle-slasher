extends Node2D

signal died
signal hp_changed(new_hp: int)

@onready var _body: AnimatedSprite2D = $Body
@onready var _weapon: AnimatedSprite2D = $Weapon

var _hp: int = SAVE_DATA.get_max_hp()
var _hp_bar_alpha: float = 1.0
var _dead: bool = false
var _is_attacking: bool = false
var _hit_this_swing: Array = []

func _play_body(anim: String) -> void:
	if _body.sprite_frames == null or not _body.sprite_frames.has_animation(anim):
		return
	_body.play(anim)

func _play_weapon(anim: String) -> void:
	if _weapon.sprite_frames == null or not _weapon.sprite_frames.has_animation(anim):
		return
	_weapon.play(anim)

func _ready() -> void:
	add_to_group("player")
	_play_body("Idle")
	_play_weapon("Idle")
	_weapon.animation_finished.connect(_on_weapon_animation_finished)

func _on_weapon_animation_finished() -> void:
	if not _is_attacking:
		return
	_is_attacking = false
	_play_weapon("Idle")
	queue_redraw()

func _process(_delta: float) -> void:
	if not _is_attacking:
		return
	var weapon_rect: Rect2 = _get_weapon_global_rect()
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy in _hit_this_swing:
			continue
		if weapon_rect.has_point((enemy as Node2D).global_position):
			_hit_this_swing.append(enemy)
			enemy.call("take_damage", SAVE_DATA.get_damage())

func _get_weapon_global_rect() -> Rect2:
	if _weapon.sprite_frames == null:
		return Rect2()
	var tex: Texture2D = _weapon.sprite_frames.get_frame_texture(_weapon.animation, _weapon.frame)
	if tex == null:
		return Rect2()
	var size: Vector2 = tex.get_size()
	var origin: Vector2 = _weapon.offset - (size * 0.5 if _weapon.centered else Vector2.ZERO)
	var tl: Vector2 = _weapon.to_global(origin)
	var br: Vector2 = _weapon.to_global(origin + size)
	return Rect2(tl, (br - tl).abs())

func attack() -> void:
	if _dead:
		return
	_is_attacking = true
	_hit_this_swing.clear()
	_weapon.stop()
	_play_weapon("Attack")
	queue_redraw()

func get_hp() -> int:
	return _hp

func reset() -> void:
	_hp = SAVE_DATA.get_max_hp()
	_hp_bar_alpha = 1.0
	_dead = false
	_is_attacking = false
	_hit_this_swing.clear()
	_weapon.visible = true
	set_process(true)
	_play_body("Idle")
	_play_weapon("Idle")
	hp_changed.emit(_hp)
	queue_redraw()

func heal(amount: int) -> void:
	if _dead:
		return
	_hp = mini(_hp + amount, SAVE_DATA.get_max_hp())
	hp_changed.emit(_hp)
	queue_redraw()

func take_damage(amount: int) -> void:
	if _dead:
		return
	_hp = maxi(_hp - amount, 0)
	hp_changed.emit(_hp)
	if _hp == 0:
		_dead = true
		_start_death()
		died.emit()
	queue_redraw()

func _start_death() -> void:
	set_process(false)
	_is_attacking = false
	_play_body("Death")
	if _weapon.sprite_frames != null and _weapon.sprite_frames.has_animation("Death"):
		_play_weapon("Death")
	else:
		_weapon.visible = false
	create_tween().tween_method(func(a: float) -> void:
		_hp_bar_alpha = a
		queue_redraw()
	, 1.0, 0.0, 0.4)

func _draw() -> void:
	var t: float = float(_hp) / float(SAVE_DATA.get_max_hp())
	var bar_fill: Color = Color(1.0, 0.831, 0.639).lerp(Color(0.553, 0.412, 0.478), 1.0 - t)
	bar_fill.a = _hp_bar_alpha
	draw_rect(Rect2(-8.0, -26.0, 16.0, 2.0), Color(0.051, 0.169, 0.271, _hp_bar_alpha))
	draw_rect(Rect2(-8.0, -26.0, 16.0 * t, 2.0), bar_fill)
	if _body.sprite_frames != null and not _body.sprite_frames.get_animation_names().is_empty():
		return
	var body_color: Color = Color(0.051, 0.169, 0.271)
	draw_circle(Vector2(0, -14), 3, body_color)
	draw_line(Vector2(0, -11), Vector2(0, -4), body_color, 1.0)
	if _is_attacking:
		draw_line(Vector2(0, -9), Vector2(-4, -12), body_color, 1.0)
		draw_line(Vector2(0, -9), Vector2(6, -7), body_color, 1.0)
		draw_line(Vector2(6, -7), Vector2(CONSTANTS.PLAYER_ATTACK_RANGE * 0.55, -3.0), Color(0.329, 0.306, 0.408), 1.0)
	else:
		draw_line(Vector2(0, -9), Vector2(-4, -5), body_color, 1.0)
		draw_line(Vector2(0, -9), Vector2(4, -5), body_color, 1.0)
	draw_line(Vector2(0, -4), Vector2(-3, 0), body_color, 1.0)
	draw_line(Vector2(0, -4), Vector2(3, 0), body_color, 1.0)
