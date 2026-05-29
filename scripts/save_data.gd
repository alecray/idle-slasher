extends Node

const SAVE_PATH: String = "user://idle_slasher.cfg"

var pb_wave: int = 1
var points: int = 0
var stat_health: int = 0
var stat_damage: int = 0
var stat_luck: int = 0
var stat_start_wave: int = 0

func _ready() -> void:
	load_data()

func get_max_hp() -> int:
	return CONSTANTS.PLAYER_MAX_HP + stat_health * 2

func get_damage() -> int:
	return 1 + stat_damage

func get_heal_chance() -> float:
	return 0.20 + stat_luck * 0.05

func get_qte_chance() -> float:
	return 0.08 + stat_luck * 0.02

func get_start_wave() -> int:
	return 1 + stat_start_wave

func add_points(amount: int) -> void:
	points += amount
	save_data()

func try_spend_point(stat: String) -> bool:
	if points <= 0:
		return false
	points -= 1
	match stat:
		"health": stat_health += 1
		"damage": stat_damage += 1
		"luck": stat_luck += 1
		"start_wave": stat_start_wave += 1
	save_data()
	return true

func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "pb_wave", pb_wave)
	cfg.set_value("stats", "points", points)
	cfg.set_value("upgrades", "health", stat_health)
	cfg.set_value("upgrades", "damage", stat_damage)
	cfg.set_value("upgrades", "luck", stat_luck)
	cfg.set_value("upgrades", "start_wave", stat_start_wave)
	cfg.save(SAVE_PATH)

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	pb_wave = cfg.get_value("stats", "pb_wave", 1)
	points = cfg.get_value("stats", "points", 0)
	stat_health = cfg.get_value("upgrades", "health", 0)
	stat_damage = cfg.get_value("upgrades", "damage", 0)
	stat_luck = cfg.get_value("upgrades", "luck", 0)
	stat_start_wave = cfg.get_value("upgrades", "start_wave", 0)
