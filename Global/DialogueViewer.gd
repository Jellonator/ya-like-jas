extends CanvasLayer

const TEXT := "According to all the known laws of aviation, there is no way that" +\
	" the bumblebee should be able to fly.\n" +\
	"The bee, of course, flies anyways, because bees don't care what humans think" +\
	" is impossible."

const MAXWIDTH := 992.0

var dialogue_stack := []

onready var node_label: RichTextLabel = $Display/Label

func read_from_dialogue_stack():
	node_label.visible_characters = 0
	node_label.clear()
	for i in range(min(3, dialogue_stack.size())):
		if i > 0:
			node_label.newline()
		node_label.add_text(dialogue_stack.pop_back())

func _ready():
	node_label.rect_clip_content = false
	show_dialogue(TEXT)
	$Talk.play()

func split_text(text: String) -> PoolStringArray:
	var ret := PoolStringArray()
	var font := node_label.get_font("normal_font") as Font
	var current_line := ""
	var current_size := 0.0
	for line in text.split('\n'):
		for word in line.split(' ', true):
			if word == "":
				word = " "
			if current_size == 0.0:
				current_size = font.get_string_size(word).x
				current_line = word
			else:
				var wordsize := font.get_string_size(" " + word).x
				if current_size + wordsize > MAXWIDTH:
					ret.append(current_line)
					current_size = font.get_string_size(word).x
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
	for i in range(arr.size()):
		dialogue_stack.push_back(arr[arr.size() - i - 1])
	read_from_dialogue_stack()

func show_options(text: String, options: Array):
	pass

func _physics_process(delta):
	var vis := node_label.visible_characters
	if vis < node_label.get_total_character_count():
		node_label.visible_characters += 1
	if Input.is_action_just_pressed("on_click"):
		$Talk.play()
		if dialogue_stack.size() == 0:
			print("FINISHED")
		else:
			read_from_dialogue_stack()
