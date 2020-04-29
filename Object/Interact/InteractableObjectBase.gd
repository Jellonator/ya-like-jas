tool
extends KinematicBody2D

export(bool) var activate_on_load := false
export(String, FILE, "*.json") var speech_file;
export(int) var priority := 0
export(Vector2) var position_offset := Vector2(0, 32) setget set_position_offset, get_position_offset
var speech_data;

signal dialogue_finished();

func set_position_offset(value: Vector2):
	position_offset = value
	update()

func get_position_offset() -> Vector2:
	return position_offset

# The following code is fairly yield heavy, so I'm just going to explain what's
# happening:
#  * dialogue is displayed to the user, so signals have to be used to know when
#    the user has closed the dialogue.
#  * yielding to a signal from a function doesn't yield its parent, and instead
#    returns a GDScriptFunctionState class.
#  * The GDScriptFunctionState class does, however, have a signal of its own
#    called 'complete': You can know when a function is finished (i.e. it has
#    stopped yielding) by yielding again, except with the "complete" signal
#  * Only do_print and do_option are guaranteed to yield, since they always
#    display some kind of option. All others may or may not return a
#    GDScriptFunctionState, so the return value must be checked.

func do_print(data: String):
	DialogueViewer.show_dialogue(data)
	yield(DialogueViewer, "dialogue_finished")

func do_option(data: Dictionary):
	var text = data.get("value", "???")
	var options = data.get("options")
	if typeof(options) != TYPE_ARRAY:
		printerr("Tag 'options' should be an array in {}".format([speech_file]))
		return
	if options.size() == 0:
		printerr("Tag 'options' has no elements in {}".format([speech_file]))
		return
	DialogueViewer.show_options(text, options)
	var index = yield(DialogueViewer, "option_selected")
	var txt = str(index)
	if txt in data:
		var co = do_speech_part(data[txt])
		if co is GDScriptFunctionState:
			yield(co, "completed")
	else:
		printerr("Missing handler for index {} in option: {}".format([
			txt, speech_file]))
		return

func do_goto(data: Dictionary):
	if not data.has("target"):
		printerr("goto has no valid target in {}").format([speech_file])
		return
	var target = data["target"]
	var err = get_tree().change_scene(target)
	if err != OK:
		printerr("Encountered error {} when trying to change scene in {}".format([\
			err, speech_file]))

func do_setflag(data: Dictionary):
	if not data.has("flag"):
		printerr("Missing flag for setflag in {}".format([speech_file]))
		return
	if not data.has("value"):
		printerr("Missing value for setflag in {}".format([speech_file]))
		return
	GameData.set_flag(data["flag"], data["value"])

func do_checkflag(data: Dictionary):
	if not data.has("flag"):
		printerr("Missing flag for checkflag in {}".format([speech_file]))
		return
	var flagname = data.get("flag")
	var flagvalue = ">" + GameData.get_flag(flagname, data.get("default", ""))
	if not data.has(flagvalue):
		printerr("Missing handler for flag value {} in checkflag: {}".format([
			flagvalue, speech_file]))
		return
	var co = do_speech_part(data[flagvalue])
	if co is GDScriptFunctionState:
		yield(co, "completed")

func do_speech_dict(data: Dictionary):
	var tname = data.get("type", "print")
	match tname:
		"print":
			yield(do_print(data.get("value", "")), "completed")
		"option":
			var co = do_option(data)
			if co is GDScriptFunctionState:
				yield(co, "completed")
		"checkflag":
			var co = do_checkflag(data)
			if co is GDScriptFunctionState:
				yield(co, "completed")
		"setflag":
			var co = do_setflag(data)
			if co is GDScriptFunctionState:
				yield(co, "completed")
		"goto":
			do_goto(data)
		_:
			printerr("Unknown speech action {}: {}, in {}".format([
				tname, data, speech_file]))

func do_speech_part(data):
	match typeof(data):
		TYPE_STRING:
			yield(do_print(data), "completed")
		TYPE_ARRAY:
			for elem in data:
				var co = do_speech_part(elem)
				if co is GDScriptFunctionState:
					yield(co, "completed")
		TYPE_DICTIONARY:
			var co = do_speech_dict(data)
			if co is GDScriptFunctionState:
				yield(co, "completed")
		var v:
			printerr("Unknown speech part type {}: {}, in {}".format([
				v, data, speech_file]))

func load_speech():
	var fh := File.new()
	var err = fh.open(speech_file, File.READ)
	if err != OK:
		printerr("Error {}: Could not open '{}' for reading".format([
			err, speech_file]))
		return
	var res: JSONParseResult = JSON.parse(fh.get_as_text())
	if res.error != OK:
		printerr("Unable to load JSON data from {} on line {}: {}".format([
			speech_file, res.error_line, res.error_string]))
	speech_data = res.result

func _ready():
	if Engine.editor_hint:
		return
	load_speech()
	if activate_on_load:
		interact()
	else:
		connect("mouse_entered", self, "_on_mouse_entered")
		connect("mouse_exited", self, "_on_mouse_exited")

func _draw():
	if Engine.editor_hint:
		draw_circle(position_offset, 2.0, Color.white)
		draw_circle(position_offset, 1.0, Color.black)

func _on_mouse_entered():
	GameData.add_moused_object(self)

func _on_mouse_exited():
	GameData.remove_moused_object(self)

func interact():
	var co = do_speech_part(speech_data)
	if co is GDScriptFunctionState:
		yield(co, "completed")
	emit_signal("dialogue_finished")

func get_target_location() -> Vector2:
	return to_global(position_offset)
