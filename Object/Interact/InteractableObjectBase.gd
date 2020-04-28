extends Node2D

export(String, FILE, "*.json") var speech_file;

var speech_data;

func show_speech(data: String):
	print(data)

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
	var flagvalue = GameData.get_flag(flagname, data.get("default", ""))
	if not data.has(flagvalue):
		printerr("Missing handler for flag value {} in checkflag: {}".format([
			flagvalue, speech_file]))
		return
	do_speech_dict(data[flagvalue])

func do_option(data: Dictionary):
	pass

func do_speech_dict(data: Dictionary):
	var tname = data.get("type", "print")
	match tname:
		"print":
			show_speech(data.get("value"))
		"option":
			do_option(data)
		"checkflag":
			do_checkflag(data)
		"setflag":
			do_setflag(data)
		_:
			printerr("Unknown speech action {}: {}, in {}".format([
				tname, data, speech_file]))

func do_speech_part(data):
	match typeof(data):
		TYPE_STRING:
			show_speech(data)
		TYPE_ARRAY:
			for elem in data:
				do_speech_part(elem)
		TYPE_DICTIONARY:
			do_speech_dict(data)
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
	load_speech()
