extends Node

var flags := {}

var moused_objects = []

func get_flag(name: String, default = null) -> String:
	return flags.get(name, default)

func set_flag(name: String, value: String):
	flags[name] = value

func _cmp_object(a, b):
	if a.priority != b.priority:
		return a.priority > b.priority
	else:
		return a.get_instance_id() > b.get_instance_id()

func add_moused_object(value):
	var index = moused_objects.bsearch_custom(value, self, "_cmp_object")
	moused_objects.insert(index, value)
#	moused_objects.append(value)

func remove_moused_object(value):
	moused_objects.erase(value)

func get_moused_object():
	if moused_objects.size() > 0:
		return moused_objects[0]
	else:
		return null
