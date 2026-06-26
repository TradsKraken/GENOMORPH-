extends Node

## PlayerData — global autoload singleton.
## Access from any script: PlayerData.health, PlayerData.gain_exp(25), etc.

# ── Signals ───────────────────────────────────────────────────────────────────
signal health_changed(value: float, maximum: float)
signal stamina_changed(value: float, maximum: float)
signal exp_changed(value: float, needed: float)
signal level_changed(new_level: int)

# ── Stats ─────────────────────────────────────────────────────────────────────
var max_health: float  = 100.0
var health: float      = 100.0

var max_stamina: float = 100.0
var stamina: float     = 100.0

var level: int         = 1
var exp: float         = 0.0
var exp_to_next: float = 100.0


# ── Stamina API ───────────────────────────────────────────────────────────────

func gain_stamina(amount: float) -> void:
	stamina = minf(stamina + amount, max_stamina)
	stamina_changed.emit(stamina, max_stamina)


## Deducts stamina if enough is available. Returns true on success.
func use_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	stamina -= amount
	stamina_changed.emit(stamina, max_stamina)
	return true


## Call from player_s _physics_process to passively restore stamina.
func recover_stamina(delta: float, rate: float) -> void:
	if stamina < max_stamina:
		stamina = move_toward(stamina, max_stamina, rate * delta)
		stamina_changed.emit(stamina, max_stamina)


# ── Health API ────────────────────────────────────────────────────────────────

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)


# ── EXP / Level API ───────────────────────────────────────────────────────────

func gain_exp(amount: float) -> void:
	exp += amount
	while exp >= exp_to_next:
		_do_level_up()
	exp_changed.emit(exp, exp_to_next)


func _do_level_up() -> void:
	exp -= exp_to_next
	level += 1
	exp_to_next = 100.0 * pow(1.4, level - 1)
	level_changed.emit(level)
