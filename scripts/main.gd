extends Node2D

const ENEMY_SCENES: Array[PackedScene] = [
	preload("res://prefabs/enemy-1.tscn"),
	preload("res://prefabs/enemy-2.tscn"),
	preload("res://prefabs/enemy-3.tscn"),
	preload("res://prefabs/enemy-4.tscn"),
	preload("res://prefabs/enemy-5.tscn"),
	preload("res://prefabs/enemy-6.tscn"),
]

const DEATH_SHADER: Shader = preload("res://assets/shaders/water_text.gdshader")
const DEV_MENU_SCENE: PackedScene = preload("res://scenes/dev_menu.tscn")
const QTE_BAR_SCRIPT: GDScript = preload("res://scripts/qte_bar.gd")
const QTE_DOTS_SCRIPT: GDScript = preload("res://scripts/qte_dots.gd")
const SHAKE_MAX_OFFSET: float = 2.5
const SHAKE_DECAY: float = 5.0

@onready var _player: Node2D = $Player
@onready var _enemy_container: Node2D = $EnemyContainer
@onready var _wave_label: Label = $HUD/WaveLabel
@onready var _pb_label: Label = $HUD/PBLabel
@onready var _click_hint: Label = $HUD/ClickHint
@onready var _clicks_label: Label = $HUD/ClicksLabel
@onready var _kills_label: Label = $HUD/KillsLabel
@onready var _game_over_label: Label = $HUD/GameOverLabel
@onready var _continue_label: Button = $HUD/ContinueLabel
@onready var _retire_button: Button = $HUD/RetireButton

var _wave: int = 1
var _clicks: int = 0
var _speech_cooldown: float = 0.0
var _kills: int = 0
var _game_over: bool = false

var _enemies_this_wave: int = 0
var _enemies_spawned: int = 0
var _spawn_timer: float = 0.0
var _next_spawn_interval: float = 0.0
var _between_waves: bool = false
var _wave_pause_timer: float = 0.0

var _camera: Camera2D
var _damage_flash: ColorRect
var _shake_trauma: float = 0.0
var _death_mat: ShaderMaterial
var _qte_active: bool = false
var _dust: CPUParticles2D
var _continue_timer: float = -1.0
var _continue_wave: int = 0
var _death_zoom_tween: Tween
var _death_pos_tween: Tween
var _death_seq_tween: Tween

var _god_mode: bool = false
var _dev_menu_open: bool = false
var _dev_menu_layer: Node = null

func _ready() -> void:
	_camera = Camera2D.new()
	_camera.position = Vector2(160.0, 90.0)
	add_child(_camera)
	_camera.make_current()

	_damage_flash = ColorRect.new()
	_damage_flash.color = Color(0.553, 0.412, 0.478, 0.0)
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(_damage_flash)

	_game_over_label.visible = false
	_continue_label.visible = false
	_retire_button.visible = false
	var _empty2 := StyleBoxEmpty.new()
	for btn: Button in [_continue_label, _retire_button]:
		for state: String in ["normal", "hover", "pressed", "focus"]:
			btn.add_theme_stylebox_override(state, _empty2)
		btn.add_theme_color_override("font_color", Color(0.329, 0.306, 0.408))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.667, 0.369))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.831, 0.639))
	_retire_button.pressed.connect(_go_to_upgrade_menu)
	_continue_label.pressed.connect(_do_continue)
	_death_mat = ShaderMaterial.new()
	_death_mat.shader = DEATH_SHADER
	_death_mat.set_shader_parameter("wave_amount", 0.85)
	_game_over_label.material = _death_mat
	_player.connect("died", _on_player_died)
	_player.connect("hp_changed", _on_hp_changed)
	_setup_dust()
	_wave = SAVE_DATA.get_start_wave()
	_pb_label.text = _pb_text()
	_start_wave()

func _setup_dust() -> void:
	_dust = CPUParticles2D.new()
	_dust.position = Vector2(340.0, 90.0)
	_dust.amount = 55
	_dust.lifetime = 3.5
	_dust.explosiveness = 0.0
	_dust.randomness = 0.2
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(4.0, 95.0)
	_dust.direction = Vector2(-1.0, 0.0)
	_dust.spread = 7.0
	_dust.gravity = Vector2(0.0, 0.8)
	_dust.scale_amount_min = 0.2
	_dust.scale_amount_max = 0.9
	var grad := Gradient.new()
	grad.set_color(0, Color(0.816, 0.506, 0.349, 0.9))
	grad.add_point(0.35, Color(1.0, 0.667, 0.369, 0.7))
	grad.add_point(0.7, Color(1.0, 0.831, 0.639, 0.35))
	grad.add_point(1.0, Color(1.0, 0.925, 0.839, 0.0))
	_dust.color_ramp = grad
	add_child(_dust)
	move_child(_dust, _player.get_index())

func _update_dust_for_wave() -> void:
	_dust.initial_velocity_min = minf(80.0 + _wave * 6.0, 220.0)
	_dust.initial_velocity_max = minf(180.0 + _wave * 10.0, 380.0)

func _pb_text() -> String:
	if SAVE_DATA.pb_version.is_empty():
		return "(PB: %d)" % SAVE_DATA.pb_wave
	return "(PB: %d v%s)" % [SAVE_DATA.pb_wave, SAVE_DATA.pb_version]

func _start_wave() -> void:
	_enemies_this_wave = CONSTANTS.WAVE_BASE_COUNT + (_wave - 1) * CONSTANTS.WAVE_COUNT_INCREMENT
	_enemies_spawned = 0
	_spawn_timer = 0.0
	_next_spawn_interval = _random_spawn_interval()
	_between_waves = false
	_wave_label.text = "Wave %d" % _wave
	if _wave > SAVE_DATA.pb_wave:
		SAVE_DATA.pb_wave = _wave
		SAVE_DATA.pb_version = ProjectSettings.get_setting("application/config/version", "")
		SAVE_DATA.save_data()
		_pb_label.text = _pb_text()
	if _wave > SAVE_DATA.get_start_wave():
		SAVE_DATA.add_points(1)
	_wave_label.scale = Vector2(1.35, 1.35)
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
		.tween_property(_wave_label, "scale", Vector2.ONE, 0.45)
	_update_dust_for_wave()

func _process(delta: float) -> void:
	if _dev_menu_open:
		return
	_speech_cooldown = maxf(0.0, _speech_cooldown - delta)
	_shake_trauma = maxf(0.0, _shake_trauma - SHAKE_DECAY * delta)
	var shake: float = _shake_trauma * _shake_trauma
	_camera.offset = Vector2(
		randf_range(-SHAKE_MAX_OFFSET, SHAKE_MAX_OFFSET) * shake,
		randf_range(-SHAKE_MAX_OFFSET, SHAKE_MAX_OFFSET) * shake
	)

	if _game_over:
		if _continue_timer >= 0.0:
			_continue_timer -= delta
			_continue_label.text = "continue %ds" % maxi(0, ceili(_continue_timer))
			if _continue_timer <= 0.0:
				_continue_timer = -1.0
				_go_to_upgrade_menu()
		return
	if _between_waves:
		_wave_pause_timer -= delta
		if _wave_pause_timer <= 0.0:
			_wave += 1
			_start_wave()
		return
	if _enemies_spawned < _enemies_this_wave:
		_spawn_timer += delta
		if _spawn_timer >= _next_spawn_interval:
			_spawn_timer = 0.0
			_next_spawn_interval = _random_spawn_interval()
			_spawn_enemy()
	elif get_tree().get_nodes_in_group("enemies").is_empty():
		_between_waves = true
		_wave_pause_timer = CONSTANTS.WAVE_PAUSE
		_spawn_wave_cleared()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			match k.physical_keycode:
				KEY_U:
					if _dev_menu_open:
						_close_dev_menu()
					elif not _game_over and not _qte_active:
						_open_dev_menu()
					return
				KEY_ESCAPE:
					if _dev_menu_open:
						_close_dev_menu()
					return
			if not _dev_menu_open and not _game_over and not _qte_active:
				if k.physical_keycode in [KEY_W, KEY_A, KEY_S, KEY_D]:
					if _speech_cooldown <= 0.0:
						_spawn_player_speech("nah i dont need to move")
						_speech_cooldown = 3.0
	if _dev_menu_open or _game_over or _qte_active:
		return
	if event is InputEventKey:
		return
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	_click_hint.visible = false
	_clicks += 1
	_clicks_label.text = "Clicks: %d" % _clicks
	_player.call("attack")
	var player_x: float = (_player as Node2D).global_position.x
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.call("rush", player_x)
	if _god_mode:
		for enemy: Node in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(enemy):
				enemy.call("take_damage", 9999)

func _skip_waves(count: int) -> void:
	_wave += count
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		enemy.remove_from_group("enemies")
	for child: Node in _enemy_container.get_children():
		child.hide()
		child.queue_free()
	_start_wave()

func _spawn_interval() -> float:
	return maxf(CONSTANTS.ENEMY_SPAWN_INTERVAL_MIN, CONSTANTS.ENEMY_SPAWN_INTERVAL / (1.0 + (_wave - 1) * CONSTANTS.ENEMY_SPAWN_INTERVAL_SCALE))

func _random_spawn_interval() -> float:
	return _spawn_interval() * randf_range(0.3, 1.8)

func _pick_enemy_type() -> int:
	var unlocked: int = mini(int(_wave / float(CONSTANTS.ENEMY_UNLOCK_WAVE)) + 1, ENEMY_SCENES.size())
	return randi() % unlocked

const _ENEMY_6_FLY_OFFSET: float = -28.0

func _spawn_enemy() -> void:
	var type_idx: int = _pick_enemy_type()
	var enemy: Node2D = ENEMY_SCENES[type_idx].instantiate() as Node2D
	var spawn_y: float = CONSTANTS.GROUND_Y + (
		_ENEMY_6_FLY_OFFSET if type_idx == ENEMY_SCENES.size() - 1 else 0.0)
	enemy.position = Vector2(CONSTANTS.ENEMY_SPAWN_X, spawn_y)
	_enemy_container.add_child(enemy)
	enemy.call("init", _wave, type_idx + 1)
	enemy.connect("killed", _on_enemy_killed)
	_enemies_spawned += 1

func _on_hp_changed(new_hp: int) -> void:
	_shake_trauma = minf(1.0, _shake_trauma + 0.5)
	_damage_flash.color.a = 0.4
	var tween: Tween = create_tween()
	tween.tween_property(_damage_flash, "color:a", 0.0, 0.25)
	if _god_mode and new_hp < SAVE_DATA.get_max_hp() and not _game_over:
		_player.call("heal", SAVE_DATA.get_max_hp())

func _on_enemy_killed(spawns_qte: bool) -> void:
	_kills += 1
	_kills_label.text = "Kills: %d" % _kills
	if randf() < SAVE_DATA.get_heal_chance():
		_player.call("heal", 1)
		_spawn_heal_popup(1)
	if spawns_qte and not _qte_active and not _game_over:
		_trigger_qte()

func _trigger_qte() -> void:
	_qte_active = true
	var pick: int = randi() % 2
	var qte: Node = (QTE_BAR_SCRIPT if pick == 0 else QTE_DOTS_SCRIPT).new()
	add_child(qte)
	qte.connect("completed", _on_qte_completed)

func _on_qte_completed(success: bool) -> void:
	_qte_active = false
	if success:
		if _player.call("get_hp") >= CONSTANTS.PLAYER_MAX_HP:
			_skip_waves(1)
			_spawn_floating_text("already full hp - wave skipped!")
		else:
			_player.call("heal", 4)
			_spawn_heal_popup(4)
	else:
		_player.call("take_damage", 2)
		_spawn_failure_popup()

func _spawn_failure_popup() -> void:
	_shake_trauma = 1.0
	var label := Label.new()
	label.text = "MISS!"
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.553, 0.412, 0.478))
	label.offset_left = 0.0
	label.offset_top = 60.0
	label.offset_right = 320.0
	label.offset_bottom = 100.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.pivot_offset = Vector2(160.0, 20.0)
	label.scale = Vector2(1.6, 1.6)
	$HUD.add_child(label)
	var t := create_tween()
	t.tween_property(label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.2)
	t.tween_property(label, "modulate:a", 0.0, 0.35)
	t.tween_callback(label.queue_free)

func _spawn_heal_popup(amount: int) -> void:
	var label := Label.new()
	label.text = "+%d hp" % amount
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.925, 0.839))
	label.offset_left = 140.0
	label.offset_top = 86.0
	label.offset_right = 180.0
	label.offset_bottom = 96.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$HUD.add_child(label)
	var hp_bar_pos: Vector2 = Vector2(52.0, 94.0)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(label, "position", hp_bar_pos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(label, "modulate:a", 0.0, 0.6)
	t.chain().tween_callback(label.queue_free)

func _spawn_player_speech(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 5)
	label.add_theme_color_override("font_color", Color(1.0, 0.925, 0.839))
	label.offset_left = 68.0
	label.offset_top = 108.0
	label.offset_right = 220.0
	label.offset_bottom = 116.0
	$HUD.add_child(label)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(label, "position", Vector2(68.0, 98.0), 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 0.0, 1.8)
	t.chain().tween_callback(label.queue_free)

func _spawn_wave_cleared() -> void:
	var label := Label.new()
	label.text = "wave cleared"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1.0, 0.831, 0.639))
	label.offset_left = 0.0
	label.offset_top = 82.0
	label.offset_right = 320.0
	label.offset_bottom = 98.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.pivot_offset = Vector2(160.0, 8.0)
	label.scale = Vector2(1.3, 1.3)
	$HUD.add_child(label)
	var t := create_tween()
	t.tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.2)
	t.tween_property(label, "modulate:a", 0.0, 0.4)
	t.tween_callback(label.queue_free)

func _spawn_floating_text(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", Color(1.0, 0.667, 0.369))
	label.offset_left = 0.0
	label.offset_top = 82.0
	label.offset_right = 320.0
	label.offset_bottom = 92.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$HUD.add_child(label)
	var angle: float = randf_range(deg_to_rad(-150.0), deg_to_rad(-30.0))
	var dist: float = randf_range(18.0, 28.0)
	var end_pos: Vector2 = Vector2(0.0, 82.0) + Vector2(cos(angle), sin(angle)) * dist
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(label, "position", end_pos, 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 0.0, 1.3)
	t.chain().tween_callback(label.queue_free)

const DEATH_MESSAGES: Array[String] = [
	"YOU PERISHED.",
	"OBLITERATED.",
	"ENDED.",
	"ANNIHILATED.",
	"ANOTHER CORPSE.",
	"FORGOTTEN.",
	"YOU WERE DEVOURED.",
	"SLAIN.",
	"CONSUMED.",
	"YOU DIED.",
	"RIP BOZO.",
]

const DEATH_ZOOM: Vector2 = Vector2(2.5, 2.5)
const DEATH_ZOOM_DURATION: float = 1.4

func _on_player_died() -> void:
	_game_over = true
	_continue_wave = maxi(SAVE_DATA.get_start_wave(), _wave - 1)
	_shake_trauma = minf(1.0, _shake_trauma + 0.8)
	_death_zoom_tween = create_tween()
	_death_zoom_tween.tween_property(_camera, "zoom", DEATH_ZOOM, DEATH_ZOOM_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_death_pos_tween = create_tween()
	_death_pos_tween.tween_property(_camera, "position", _player.global_position, DEATH_ZOOM_DURATION * 0.7) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_death_seq_tween = create_tween()
	_death_seq_tween.tween_interval(0.6)
	_death_seq_tween.tween_callback(func() -> void:
		_game_over_label.text = DEATH_MESSAGES[randi() % DEATH_MESSAGES.size()]
		_game_over_label.visible = true
	)
	_death_seq_tween.tween_interval(1.0)
	_death_seq_tween.tween_callback(func() -> void:
		var waves_lost: int = _wave - _continue_wave
		_continue_label.visible = true
		_retire_button.visible = true
		_continue_timer = 10.0
		if waves_lost > 0:
			_spawn_wave_loss_popup(waves_lost)
	)
	_death_seq_tween.tween_interval(0.1)
	_death_seq_tween.tween_method(func(v: float) -> void: _death_mat.set_shader_parameter("wave_amount", v), 0.85, 0.0, 1.2)

func _go_to_upgrade_menu() -> void:
	_continue_label.visible = false
	var overlay := ColorRect.new()
	overlay.color = Color(0.051, 0.169, 0.271, 0.0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(overlay)
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.6)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/upgrade_menu.tscn"))

func _do_continue() -> void:
	if _continue_timer < 0.0:
		return
	_continue_timer = -1.0
	_restart_from_wave(_continue_wave)

func _restart_from_wave(wave: int) -> void:
	if _death_zoom_tween:
		_death_zoom_tween.kill()
	if _death_pos_tween:
		_death_pos_tween.kill()
	if _death_seq_tween:
		_death_seq_tween.kill()
	_wave = wave
	_clicks = 0
	_kills = 0
	_game_over = false
	_qte_active = false
	_shake_trauma = 0.0
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		enemy.remove_from_group("enemies")
	for child: Node in _enemy_container.get_children():
		child.hide()
		child.queue_free()
	_camera.zoom = Vector2.ONE
	_camera.position = Vector2(160.0, 90.0)
	_player.call("reset")
	_game_over_label.visible = false
	_continue_label.visible = false
	_retire_button.visible = false
	_clicks_label.text = "Clicks: 0"
	_kills_label.text = "Kills: 0"
	_death_mat.set_shader_parameter("wave_amount", 0.85)
	_start_wave()

func _spawn_wave_loss_popup(lost: int) -> void:
	var label := Label.new()
	label.text = "-%d" % lost
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.553, 0.412, 0.478))
	label.offset_left = 4.0
	label.offset_top = 4.0
	label.offset_right = 80.0
	label.offset_bottom = 14.0
	$HUD.add_child(label)
	var end_pos: Vector2 = Vector2(4.0, 4.0) + Vector2(randf_range(12.0, 24.0), randf_range(-14.0, -8.0))
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(label, "position", end_pos, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 0.0, 1.2)
	t.chain().tween_callback(label.queue_free)

func _open_dev_menu() -> void:
	_dev_menu_open = true
	_dev_menu_layer = DEV_MENU_SCENE.instantiate()
	add_child(_dev_menu_layer)
	_dev_menu_layer.init(_god_mode)
	_dev_menu_layer.connect("close_requested", _close_dev_menu)
	_dev_menu_layer.connect("skip_waves_requested", _skip_waves)
	_dev_menu_layer.connect("god_mode_toggled", func(v: bool) -> void: _god_mode = v)
	_dev_menu_layer.connect("reset_requested", _dev_reset_game)

func _close_dev_menu() -> void:
	if not _dev_menu_open:
		return
	_dev_menu_open = false
	if is_instance_valid(_dev_menu_layer):
		_dev_menu_layer.queue_free()
	_dev_menu_layer = null

func _dev_reset_game() -> void:
	_close_dev_menu()
	SAVE_DATA.reset()
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
