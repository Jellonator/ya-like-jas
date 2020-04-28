extends CanvasLayer

const SAMPLETEXT := "According to all the known laws of aviation, there is no way that" +\
	" the bumblebee should be able to fly.\n" +\
	"The [color=#FFCC00]bee[/color], of course, flies anyways, because bees don't care what humans think" +\
	" is impossible." + "\n  teehee"

const MAXWIDTH := 992.0

var current_scroll := 0
var num_lines := 0
var num_visible_at_line := []

onready var node_label: RichTextLabel = $Display/Label
onready var node_disp: Control = $Display

func _ready():
	show_dialogue(SAMPLETEXT)

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
	node_label.clear()
	var arr := split_text(text)
	while arr.size() % 3 != 0:
		arr.append("a")
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

func show_options(text: String, options: Array):
	pass

func finish_dialogue():
	node_disp.hide()

func _physics_process(delta):
	var vis := node_label.visible_characters
	if vis < node_label.get_total_character_count():
		node_label.visible_characters += 1
	if Input.is_action_just_pressed("on_click"):
		current_scroll += 3
		if current_scroll >= num_lines:
			finish_dialogue()
		else:
			node_label.scroll_to_line(current_scroll)
			if num_visible_at_line.size() > current_scroll:
				node_label.visible_characters = num_visible_at_line[current_scroll]
