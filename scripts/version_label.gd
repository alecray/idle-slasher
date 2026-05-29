extends Label

const _EGG_TEXT: String = "can i help you?"
const _CLICK_WINDOW: float = 1.2   # 5 clicks must land within this many seconds
const _EGG_DURATION: float = 3.0

var _version_text: String = ""
var _click_times: Array[float] = []
var _showing_egg: bool = false

func _ready() -> void:
	_version_text = "v" + ProjectSettings.get_setting("application/config/version", "0.0.0")
	text = _version_text
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			accept_event()
			_register_click()

func _register_click() -> void:
	if _showing_egg:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	_click_times.append(now)
	while _click_times.size() > 5:
		_click_times.pop_front()
	if _click_times.size() == 5 and now - _click_times[0] <= _CLICK_WINDOW:
		_trigger_egg()

func _trigger_egg() -> void:
	_showing_egg = true
	_click_times.clear()
	text = _EGG_TEXT
	get_tree().create_timer(_EGG_DURATION).timeout.connect(_revert)

func _revert() -> void:
	text = _version_text
	_showing_egg = false
