extends Control

@onready var primary_btn: Button = $PrimaryAttack
@onready var skill1_btn: Button = $Skill1
@onready var skill2_btn: Button = $Skill2
@onready var skill3_btn: Button = $Skill3

func _ready() -> void:
	# Skill 3 (Cutaneous Respiration - Ultimate)
	# Zones 1–3 (Locked State): visually greyed out, transparent, completely unclickable.
	skill3_btn.disabled = true
	skill3_btn.modulate = Color(0.5, 0.5, 0.5, 0.5)

# The following methods will be connected to button signals later
func _on_primary_attack_pressed() -> void:
	pass

func _on_skill1_pressed() -> void:
	pass

func _on_skill2_pressed() -> void:
	pass

func _on_skill3_pressed() -> void:
	pass
