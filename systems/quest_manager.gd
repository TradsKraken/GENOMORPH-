extends Node

signal objective_updated(new_objective: String, new_desc: String)
signal quest_completed(quest_id: String)

var current_objective: String = ""
var current_description: String = ""

func set_objective(text: String, desc: String = "") -> void:
	current_objective = text
	current_description = desc
	objective_updated.emit(text, desc)

func clear_objective() -> void:
	current_objective = ""
	current_description = ""
	objective_updated.emit("", "")
