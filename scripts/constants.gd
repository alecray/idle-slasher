extends Node

const GROUND_Y: float = 120.0

const PLAYER_MAX_HP: int = 10
const PLAYER_ATTACK_RANGE: float = 20.0

const ENEMY_SPAWN_X: float = 330.0
const ENEMY_ATTACK_RANGE: float = 16.0
const ENEMY_BASE_SPEED: float = 30.0
const ENEMY_SPEED_PER_WAVE: float = 9.0
const ENEMY_HP_PER_WAVE: float = 0.3
const ENEMY_ATTACK_INTERVAL: float = 1.5
const ENEMY_ATTACK_DAMAGE: int = 1

const ENEMY_SPAWN_INTERVAL: float = 1.2
const ENEMY_SPAWN_INTERVAL_MIN: float = 0.22
const ENEMY_SPAWN_INTERVAL_SCALE: float = 0.30

const WAVE_BASE_COUNT: int = 5
const WAVE_COUNT_INCREMENT: int = 4
const WAVE_PAUSE: float = 2.5

const ENEMY_UNLOCK_WAVE: int = 3
