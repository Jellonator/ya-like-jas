extends CanvasLayer

const SCENE_BUTTON := preload("res://Gui/ButtonYellow.tscn")

const SAMPLETEXT := "According to all the known laws of aviation, there is no way that" +\
	" the bumblebee should be able to fly.\n" +\
	"The [color=#FFCC00]bee[/color], of course, flies anyways, because bees don't care what humans think" +\
	" is impossible." + "\n  teehee"

const MAXWIDTH := 992.0

var current_scroll := 0
var num_lines := 0
var num_visible_at_line := []
var is_in_option := false

onready var node_label: RichTextLabel = $Display/Label
onready var node_disp: Control = $Display
onready var node_options: Container = $Display/Option/VBox

signal dialogue_finished()
signal option_selected(index)

func _ready():
	node_disp.hide()
#	show_dialogue(SAMPLETEXT)

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
	var arr := split_text(text)
	while arr.size() % 3 != 0:
		arr.append("")
	node_label.clear()
	var s := ""
	var n := 0
	var is_in_bracket := false
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
	node_label.parse_bbcode(s)
	num_lines = arr.size()
	current_scroll = 0
	is_in_option = false

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

func _on_button_pressed(index: int):
	node_options.hide()
	node_disp.hide()
	is_in_option = false
	emit_signal("option_selected", index)

func finish_dialogue():
	node_disp.hide()
	emit_signal("dialogue_finished")
	is_in_option = false

func _physics_process(delta):
	var vis := node_label.visible_characters
	if vis < node_label.get_total_character_count():
		node_label.visible_characters += 1
	if Input.is_action_just_pressed("on_click"):
		current_scroll += 3
		if current_scroll >= num_lines:
			if not is_in_option:
				finish_dialogue()
		else:
			node_label.scroll_to_line(current_scroll)
			if num_visible_at_line.size() > current_scroll:
				node_label.visible_characters = num_visible_at_line[current_scroll]
