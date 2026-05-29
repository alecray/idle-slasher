extends Node

const SAVE_PATH: String = "user://idle_slasher.cfg"

var pb_wave: int = 1
var pb_version: String = ""
var points: int = 0
var stat_health: int = 0
var stat_damage: int = 0
var stat_luck: int = 0
var stat_start_wave: int = 0

# Max level each stat can reach (bonus is capped at this level).
const MAX_LEVEL: Dictionary = {
	"health": 100,
	"damage": 200,
	"luck": 100,
	"start_wave": 30,
}

# Bonus value reached at MAX_LEVEL.
const HEALTH_CAP: int = 290     # +290 max HP at level 100
const DAMAGE_CAP: int = 10      # +10 damage at level 200 (~10 points per +1)
const LUCK_CAP: float = 30.0    # +30% luck at level 100
const START_WAVE_CAP: int = 29  # W30 (1 + 29) at level 30

func _ready() -> void:
	load_data()

func get_stat_level(stat: String) -> int:
	match stat:
		"health": return stat_health
		"damage": return stat_damage
		"luck": return stat_luck
		"start_wave": return stat_start_wave
	return 0

func is_stat_maxed(stat: String) -> bool:
	return get_stat_level(stat) >= MAX_LEVEL.get(stat, 0)

func get_health_bonus() -> int:
	return roundi(float(HEALTH_CAP) / MAX_LEVEL["health"] * stat_health)

func get_max_hp() -> int:
	return CONSTANTS.PLAYER_MAX_HP + get_health_bonus()

func get_damage_bonus() -> int:
	return roundi(float(DAMAGE_CAP) / MAX_LEVEL["damage"] * stat_damage)

func get_damage() -> int:
	return 1 + get_damage_bonus()

func get_luck_pct() -> float:
	return LUCK_CAP / MAX_LEVEL["luck"] * stat_luck

func get_heal_chance() -> float:
	return 0.20 + get_luck_pct() / 100.0

func get_qte_chance() -> float:
	return 0.08 + get_luck_pct() / 100.0 * 0.4

func get_start_wave_bonus() -> int:
	return roundi(float(START_WAVE_CAP) / MAX_LEVEL["start_wave"] * stat_start_wave)

func get_start_wave() -> int:
	return 1 + get_start_wave_bonus()

func add_points(amount: int) -> void:
	points += amount
	save_data()

func try_spend_point(stat: String) -> bool:
	if points <= 0:
		return false
	if is_stat_maxed(stat):
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
	cfg.set_value("stats", "pb_version", pb_version)
	cfg.set_value("stats", "points", points)
	cfg.set_value("upgrades", "health", stat_health)
	cfg.set_value("upgrades", "damage", stat_damage)
	cfg.set_value("upgrades", "luck", stat_luck)
	cfg.set_value("upgrades", "start_wave", stat_start_wave)
	cfg.save(SAVE_PATH)

func reset() -> void:
	pb_wave = 1
	pb_version = ""
	points = 0
	stat_health = 0
	stat_damage = 0
	stat_luck = 0
	stat_start_wave = 0
	save_data()

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	pb_wave = cfg.get_value("stats", "pb_wave", 1)
	pb_version = cfg.get_value("stats", "pb_version", "")
	points = cfg.get_value("stats", "points", 0)
	stat_health = cfg.get_value("upgrades", "health", 0)
	stat_damage = cfg.get_value("upgrades", "damage", 0)
	stat_luck = cfg.get_value("upgrades", "luck", 0)
	stat_start_wave = cfg.get_value("upgrades", "start_wave", 0)
