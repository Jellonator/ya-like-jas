extends Node

var flags := {}

func get_flag(name: String, default = null) -> String:
	return flags.get(name, default)

func set_flag(name: String, value: String):
	flags[name] = value
