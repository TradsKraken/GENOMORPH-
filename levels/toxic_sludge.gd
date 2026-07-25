extends Area3D
class_name ToxicSludge

@export var dps: float = 5.0

var _players_inside: Array[Node3D] = []

func _ready() -> void:
	add_to_group("toxic_sludge")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func cleanse() -> void:
	AudioManager.play_sfx("splash")
	queue_free()

func _process(delta: float) -> void:
	if _players_inside.size() > 0:
		for player in _players_inside:
			if is_instance_valid(player) and player.has_method("take_damage"):
				player.take_damage(dps * delta)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if not _players_inside.has(body):
			_players_inside.append(body)
			PlayerData.unlock_knowledge("toxic_sludge")

func _on_body_exited(body: Node3D) -> void:
	if _players_inside.has(body):
		_players_inside.erase(body)
