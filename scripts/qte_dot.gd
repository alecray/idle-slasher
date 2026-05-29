extends Control

signal dot_clicked

@onready var _sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation("Idle"):
		_sprite.play("Idle")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			mouse_filter = MOUSE_FILTER_IGNORE
			dot_clicked.emit()
			_play_and_free()

func _play_and_free() -> void:
	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation("Hit"):
		_sprite.play("Hit")
		await _sprite.animation_finished
	queue_free()
