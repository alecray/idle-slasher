extends Node2D

signal killed(spawns_qte: bool)


@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _speed: float = CONSTANTS.ENEMY_BASE_SPEED
var _dying: bool = false
var _attacking: bool = false
var _attack_timer: float = 0.0
var _stop_offset: float = 0.0
var _max_hp: int = 1
var _hp: int = 1
var _show_hp_bar: bool = false
var _is_qte_enemy: bool = false
var _celebrating: bool = false
var _wander_vel: Vector2 = Vector2.ZERO
var _taunt_timer: float = 0.0
var _is_talker: bool = false
var _live_taunt_timer: float = 0.0

const _TAUNTS: Array[String] = [
	"???", "sit", "noob", "lmao", "ez", "L", "git gud",
	"lol", "bozo", "cope", "skill issue", "gg ez", "ratio", "owned",
]

const _LIVE_TAUNTS: Array[String] = [
	"too slow", "weak", "is that all?", "pathetic", "give up",
	"you'll die", "come closer", "easy prey", "miss me?", "yawn",
	"try harder", "you're done", "last wave?", "can't touch me", "scared?",
]

func _ready() -> void:
	add_to_group("enemies")
	_stop_offset = randf_range(0.0, 6.0)
	position.y += randf_range(-2.0, 2.0)
	_play("Walk")
	_is_talker = randf() < 0.25
	_live_taunt_timer = randf_range(3.0, 10.0)

func init(wave: int, enemy_type: int) -> void:
	_speed = CONSTANTS.ENEMY_BASE_SPEED + (wave - 1) * CONSTANTS.ENEMY_SPEED_PER_WAVE
	_max_hp = enemy_type * 2 + int((wave - 1) * CONSTANTS.ENEMY_HP_PER_WAVE)
	_hp = _max_hp
	if randf() < SAVE_DATA.get_qte_chance():
		_is_qte_enemy = true
		_setup_qte_visuals()

func _setup_qte_visuals() -> void:
	modulate = Color(1.0, 0.925, 0.839)
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 18
	particles.lifetime = 0.8
	particles.explosiveness = 0.0
	particles.randomness = 0.8
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 8.0
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 55.0
	particles.gravity = Vector2(0.0, -20.0)
	particles.initial_velocity_min = 8.0
	particles.initial_velocity_max = 24.0
	particles.scale_amount_min = 0.8
	particles.scale_amount_max = 2.2
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.925, 0.839))
	grad.add_point(0.5, Color(1.0, 0.667, 0.369))
	grad.add_point(1.0, Color(1.0, 0.667, 0.369, 0.0))
	particles.color_ramp = grad
	add_child(particles)

const _RUSH_MIN_DIST: float = 100.0
const _RUSH_STOP_DIST: float = 75.0

func rush(player_x: float) -> void:
	if _dying:
		return
	var dx: float = position.x - player_x
	if dx <= _RUSH_MIN_DIST:
		return
	var dest_x: float = player_x + _RUSH_STOP_DIST + _stop_offset
	create_tween().tween_property(self, "position:x", dest_x, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func start_celebrating() -> void:
	if _dying or _celebrating:
		return
	_celebrating = true
	_attacking = false
	_sprite.flip_h = false
	_play("Walk")
	_wander_vel = Vector2(randf_range(-38.0, -18.0), randf_range(-5.0, 5.0))
	_taunt_timer = randf_range(0.2, 2.8)

func _process(delta: float) -> void:
	if _dying:
		return
	if _celebrating:
		position += _wander_vel * delta
		_taunt_timer -= delta
		if _taunt_timer <= 0.0:
			_taunt_timer = randf_range(1.6, 3.2)
			_spawn_taunt(_TAUNTS[randi() % _TAUNTS.size()])
		if position.x < -20.0:
			queue_free()
		return
	if _is_talker:
		_live_taunt_timer -= delta
		if _live_taunt_timer <= 0.0:
			_live_taunt_timer = randf_range(6.0, 14.0)
			_spawn_taunt(_LIVE_TAUNTS[randi() % _LIVE_TAUNTS.size()])
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		return
	var dx: float = global_position.x - player.global_position.x
	if dx <= CONSTANTS.ENEMY_ATTACK_RANGE + _stop_offset:
		if not _attacking:
			_attacking = true
			_attack_timer = CONSTANTS.ENEMY_ATTACK_INTERVAL
			_play("Attack")
		_attack_timer += delta
		if _attack_timer >= CONSTANTS.ENEMY_ATTACK_INTERVAL:
			_attack_timer = 0.0
			player.call("take_damage", CONSTANTS.ENEMY_ATTACK_DAMAGE)
			_play("Attack")
	else:
		position.x -= _speed * delta

func take_damage(amount: int) -> void:
	if _dying:
		return
	_hp = maxi(_hp - amount, 0)
	_show_hp_bar = true
	queue_redraw()
	if _hp > 0:
		return
	_show_hp_bar = false
	queue_redraw()
	_dying = true
	set_process(false)
	remove_from_group("enemies")
	killed.emit(_is_qte_enemy)
	_die()

func _draw() -> void:
	if not _show_hp_bar:
		return
	var bar_w: float = 14.0
	var bar_h: float = 2.0
	var bar_x: float = -bar_w * 0.5
	var bar_y: float = -22.0
	var t: float = float(_hp) / float(_max_hp)
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.051, 0.169, 0.271))
	draw_rect(Rect2(bar_x, bar_y, bar_w * t, bar_h), Color(1.0, 0.831, 0.639).lerp(Color(0.553, 0.412, 0.478), 1.0 - t))

func _die() -> void:
	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation("Death"):
		_play("Death")
		await _sprite.animation_finished
	queue_free()

func _spawn_taunt(msg: String) -> void:
	var label := Label.new()
	label.text = msg
	label.add_theme_font_size_override("font_size", 3)
	label.add_theme_color_override("font_color", Color(1.0, 0.925, 0.839))
	label.size = Vector2(48.0, 6.0)
	label.position = Vector2(-24.0, -14.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(label, "position:y", -22.0, 3.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 0.0, 3.2)
	t.chain().tween_callback(label.queue_free)

func _play(anim: String) -> void:
	if _sprite.sprite_frames == null or not _sprite.sprite_frames.has_animation(anim):
		return
	_sprite.play(anim)
