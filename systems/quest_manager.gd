extends Node

signal objective_updated(new_objective: String)
signal quest_completed(quest_id: String)

var current_objective: String = ""

func set_objective(text: String) -> void:
	current_objective = text
	objective_updated.emit(text)

func clear_objective() -> void:
	current_objective = ""
	objective_updated.emit("")
