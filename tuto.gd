extends Node
var health = 10:
	set(value):
		health= clamp(value,0,100)
	get:
		return health
var health_pcr:
	get:
		return health
	
func _ready():
	print(health,"%")
	
	
















































'''Perfect 👍
Let’s practice getters & setters the RIGHT way, using real game-style mini exercises.

I’ll give:
1️⃣ a goal
2️⃣ a starter code
3️⃣ what you should try to do
4️⃣ then the solution (after)

You can try first, then check.

🟢 EXERCISE 1 — HEALTH SYSTEM (CORE GAME SKILL)
🎯 Goal

Health should never go below 0 or above max

UI should always show correct health %

🧩 Starter Code (YOU FILL)
extends Node

var max_health = 100
var _health = 100

var health:
	set(value):
		# TODO: clamp and store
	get:
		# TODO: return stored value

var health_percent:
	get:
		# TODO: return % value

func _ready():
	health -= 30
	print(health)          # expect 70
	print(health_percent)  # expect 70


👉 Try before scrolling 👇

✅ Solution
var health:
	set(value):
		_health = clamp(value, 0, max_health)
	get:
		return _health

var health_percent:
	get:
		return float(_health) / max_health * 100

🟢 EXERCISE 2 — PLAYER SPEED WITH POWER-UP
🎯 Goal

Player has base speed

Power-up increases speed temporarily

Speed is always calculated correctly

🧩 Starter Code
var base_speed = 200
var speed_bonus = 0.0

var speed:
	get:
		# TODO

func _ready():
	speed_bonus = 0.5   # +50% speed
	print(speed)        # expect 300

✅ Solution
var speed:
	get:
		return base_speed * (1 + speed_bonus)

🟢 EXERCISE 3 — CRITICAL HIT CHANCE (YOU SAW THIS IRL)
🎯 Goal

Crit chance stored as 0–1

UI shows percent

Cannot exceed 100%

🧩 Starter Code
var _crit = 0.2

var crit:
	set(value):
		# TODO clamp between 0–1
	get:
		# TODO return value

var crit_percent:
	get:
		# TODO return percent

func _ready():
	crit = 1.5
	print(crit_percent)  # expect 100

✅ Solution
var crit:
	set(value):
		_crit = clamp(value, 0.0, 1.0)
	get:
		return _crit

var crit_percent:
	get:
		return _crit * 100

🟢 EXERCISE 4 — XP → LEVEL (NO IF-ELSE)
🎯 Goal

Level automatically updates from XP

UI always correct

🧩 Starter Code
var xp = 17
var xp_per_level = 5

var level:
	get:
		# TODO

func _ready():
	print(level)  # expect 4

✅ Solution
var level:
	get:
		return int(xp / xp_per_level) + 1

🟢 EXERCISE 5 — MUTED SETTER (COMMON BUG FIX)
🎯 Goal

Volume always 0–1

Avoid recursion

🧩 Starter Code
var _volume = 0.5

var volume:
	set(value):
		# TODO clamp safely
	get:
		# TODO return value

✅ Solution
var volume:
	set(value):
		_volume = clamp(value, 0.0, 1.0)
	get:
		return _volume

🧠 FINAL MENTAL MODEL (MEMORIZE)
Thing	Use
Getter	Calculated / derived values
Setter	Validation / limits
Backing var	Store real data
Getter + UI	Always fresh
Setter + signals	React to change'''
	

	
	
