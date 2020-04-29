extends CanvasLayer

const LINES_ON_SCREEN := 4
const SCENE_BUTTON := preload("res://Gui/ButtonYellow.tscn")

const MAXWIDTH := 992.0

var current_scroll := 0
var num_lines := 0
var num_visible_at_line := []
var is_in_option := false
var fade := 0.0 setget set_fade, get_fade

func set_fade(value: float):
	fade = value
	$Polygon2D.modulate = Color(0, 0, 0, value)

func get_fade() -> float:
	return fade

onready var node_label: RichTextLabel = $Display/Label
onready var node_disp: Control = $Display
onready var node_options: Container = $Display/Option/VBox
onready var node_continue: Control = $Display/IconContinue
onready var node_finish: Control = $Display/IconFinish
onready var sfx_bleep: AudioStreamPlayer = $AudioStreamPlayer

signal dialogue_finished()
signal option_selected(index)

func _ready():
	node_disp.hide()
#	show_dialogue(SAMPLETEXT)

func is_busy() -> bool:
	return node_disp.visible

func split_text(text: String) -> PoolStringArray:
	var ret := PoolStringArray()
	var font := node_label.get_font("normal_font") as Font
	var current_line := ""
	var current_size := 0.0
	var is_in_bracket := false
	for line in text.split('\n'):
		for word in line.split(' ', true):
			var visible_word := ""
			for c in word:
				if is_in_bracket:
					if c == ']':
						is_in_bracket = false
				else:
					if c == '[':
						is_in_bracket = true
					else:
						visible_word += c
			if current_size == 0.0:
				current_size = font.get_string_size(visible_word).x
				current_line = word
			else:
				var wordsize := font.get_string_size(" " + visible_word).x
				if current_size + wordsize > MAXWIDTH:
					ret.append(current_line)
					current_size = font.get_string_size(visible_word).x
					current_line = word
				else:
					current_size += wordsize
					current_line += " " + word
		if current_size != 0.0:
			ret.append(current_line)
			current_line = ""
			current_size = 0.0
	if current_size != 0.0:
		ret.append(current_line)
		current_line = ""
	return ret

func show_dialogue(text: String):
	node_options.hide()
	node_disp.show()
	node_label.clear()
	node_label.visible_characters = 0
	num_visible_at_line.clear()
	var arr := split_text(text)
	node_label.clear()
	var s := ""
	var n := 0
	var is_in_bracket := false
	# A line break is inserted between every three lines
	# so that their content doesn't bleed into each other.
	var line_number := 0
	num_lines = 0
	for i in range(arr.size()):
		num_visible_at_line.append(n)
		if i > 0:
			s += '\n'
		s += arr[i]
		for c in arr[i]:
			if is_in_bracket:
				if c == ']':
					is_in_bracket = false
			else:
				if c == '[':
					is_in_bracket = true
				else:
					n += 1
		line_number += 1
		num_lines += 1
		if line_number % (LINES_ON_SCREEN - 1) == 0:
			num_visible_at_line.append(n)
			s += '\n'
			num_lines += 1
	while num_lines % LINES_ON_SCREEN != 0:
		s += '\n'
		num_lines += 1
	node_label.parse_bbcode(s)
	current_scroll = 0
	is_in_option = false
	sfx_bleep.play()
	node_label.scroll_to_line(0)

func show_options(text: String, options: Array):
	show_dialogue(text)
	is_in_option = true
	for node in node_options.get_children():
		node.queue_free()
	var index := 0
	for item in options:
		var node: Button = SCENE_BUTTON.instance() as Button
		node.text = item
		node_options.add_child(node)
		node.connect("pressed", self, "_on_button_pressed", [index])
		index += 1
	node_options.show()
	node_continue.hide()
	node_finish.hide()

func _on_button_pressed(index: int):
	node_options.hide()
	node_disp.hide()
	is_in_option = false
	emit_signal("option_selected", index)

func finish_dialogue():
	node_disp.hide()
	emit_signal("dialogue_finished")
	is_in_option = false
	sfx_bleep.stop()

func _physics_process(delta):
	if not node_disp.visible:
		return
	var vis := node_label.visible_characters
	var maxchar := node_label.get_total_character_count()
	if current_scroll + LINES_ON_SCREEN < num_lines:
		maxchar = num_visible_at_line[current_scroll + LINES_ON_SCREEN]
	if vis < maxchar:
		node_label.visible_characters += 1
	else:
		sfx_bleep.stop()
	if Input.is_action_just_pressed("on_click"):
		if node_label.visible_characters < maxchar:
			node_label.visible_characters = maxchar
		else:
			current_scroll += LINES_ON_SCREEN
			if current_scroll >= num_lines:
				if not is_in_option:
					finish_dialogue()
			else:
				sfx_bleep.play()
				node_label.scroll_to_line(current_scroll)
				if num_visible_at_line.size() > current_scroll:
					node_label.visible_characters = num_visible_at_line[current_scroll]
	if not is_in_option:
		node_finish.visible = current_scroll+LINES_ON_SCREEN >= num_lines
		node_continue.visible = not node_finish.visible
