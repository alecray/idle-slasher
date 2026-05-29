# idle-slasher

A wave-based idle clicker built with Godot 4.6. Click to attack enemies walking from the right, survive as many waves as possible, and spend earned points on permanent upgrades between runs.

## Gameplay

- **Left-click** anywhere to trigger an attack swing — any enemy in weapon range takes damage
- Enemies march from the right toward the player; clicking also makes nearby enemies rush forward
- Survive waves of increasing size and speed; the goal is to beat your personal best wave
- On death, press "retire + upgrade" to open the upgrade menu and spend earned points on permanent stat boosts
- QTE events trigger randomly on certain enemy kills — succeed to heal, fail to take damage

## Controls

| Input | Action |
|-------|--------|
| Left click | Attack (triggers swing + enemies rush) |
| U | Open / close developer menu |
| ESC | Close developer menu |

## Waves

Waves are continuous and grow in size and difficulty over time.

| Property | Value |
|----------|-------|
| Enemies per wave | 5 + (wave − 1) × 2 |
| Spawn interval | Decreases with wave (min 0.35 s) |
| Between waves | 2.5 s pause |

A "wave cleared" popup appears briefly when all enemies are defeated. One point is awarded per wave cleared beyond the player's current starting wave.

## Enemy Types

Enemies unlock every 3 waves. HP = `enemy_type × 2`. All enemies walk toward the player and attack in melee range.

| # | HP | Unlocks at wave | Notes |
|---|----|-----------------|-------|
| 1 | 2  | 1  | |
| 2 | 4  | 3  | |
| 3 | 6  | 6  | |
| 4 | 8  | 9  | |
| 5 | 10 | 12 | |
| 6 | 12 | 15 | Spawns higher — appears to fly |

Certain enemies are designated **QTE enemies** at spawn (warm orange tint with floating particles). Killing them triggers a QTE event.

## QTE System

Two QTE types appear randomly after a QTE enemy is killed:

- **Bar QTE** — click when the moving bar aligns with the target zone
- **Dots QTE** — click the correct dot in the correct sequence

| Outcome | Effect |
|---------|--------|
| Success (HP already full) | Skip 1 wave |
| Success | Heal 4 HP |
| Failure | Take 2 damage + camera shake |

## Meta-Progression

After dying, the retire button opens the upgrade menu. Spend **points** earned during the run on permanent upgrades that persist across all future runs.

| Upgrade | Effect per level |
|---------|----------------|
| Health | +2 max HP |
| Damage | +1 damage per swing |
| Luck | +7% on-kill heal chance; +2% QTE enemy spawn chance |
| Start Wave | Begin each run 1 wave higher |

## Save Data

Stored in `user://idle_slasher.cfg`.

| Field | Description |
|-------|-------------|
| `pb_wave` | Personal best wave reached |
| `pb_version` | Game version when the PB was set |
| `points` | Unspent upgrade points |
| `stat_health / damage / luck / start_wave` | Current upgrade levels |

## Developer Menu (U)

Opens a pause overlay that freezes the game loop.

| Option | Effect |
|--------|--------|
| Skip 5 waves | Instantly advance 5 waves |
| God mode | Player is invincible; every click insta-kills all enemies on screen |
| Reset game | Wipes all save data and returns to the title screen |

## Installation

1. Install [Godot 4.6](https://godotengine.org/download)
2. Clone the repository
3. Open Godot, click **Import**, and select the `project.godot` file
4. Press **F5** or click the Play button to run

> Sprite sheets are embedded directly in `.tscn` files via the [AsepriteWizard](https://github.com/viniciusgerevini/godot-aseprite-wizard) plugin. To add new sprites, open the scene in the editor, select the AnimatedSprite2D node, and use the plugin panel to import from the source `.aseprite` file.

## Project Structure

```
scenes/
  title_screen.tscn    # Main menu
  main.tscn            # Gameplay scene
  upgrade_menu.tscn    # Post-death upgrade screen
  dev_menu.tscn        # Developer overlay (U key)

scripts/
  main.gd              # Core game loop — wave spawning, input, QTE orchestration, dev menu
  player.gd            # Player HP, attack hitbox, animations, draw calls
  enemy.gd             # Enemy AI — walk, rush, attack, QTE marker, death
  save_data.gd         # Autoload — persistent stats, save/load/reset
  constants.gd         # Autoload — all tuning values
  title_screen.gd      # Main menu — button nav, fade transitions, ambient particles
  upgrade_menu.gd      # Upgrade screen — point spending, stat display
  dev_menu.gd          # Developer overlay — emits signals back to main.gd
  qte_bar.gd           # Bar-style QTE minigame
  qte_dots.gd          # Dots-style QTE minigame
  version_label.gd     # Auto-sets label text from project version setting

prefabs/
  enemy-1.tscn … enemy-6.tscn   # Per-type enemy scenes with embedded sprite sheets

assets/
  aseprite/            # Source .aseprite files (sprites embedded in prefabs at import time)
  shaders/             # Water-distortion text shader used on the death screen
  theme.tres           # Global UI theme (pixel font, default colors)

addons/
  AsepriteWizard/      # Sprite sheet import plugin
```

## Development

**Engine:** Godot 4.6  
**Renderer:** GL Compatibility  
**Language:** GDScript (typed)  
**Canvas:** 320 × 180, scaled 4× to 1280 × 720 (integer scale)  
**Art:** Aseprite sprites embedded in `.tscn` files via AsepriteWizard

# name-ideas
- Blade Clicker
- Idle Blade
- Blade: Idle Clicker
