extends "res://World/LevelBase.gd"

var target_fade := 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	DialogueViewer.fade = 1.0

func _on_Initialize_dialogue_finished():
	target_fade = 0.0
	$Soundtrack/BackgroundMusic.play()

func _physics_process(delta):
	if target_fade > DialogueViewer.fade:
		DialogueViewer.fade = clamp(DialogueViewer.fade + delta, 0.0, 1.0)
	elif target_fade < DialogueViewer.fade:
		DialogueViewer.fade = clamp(DialogueViewer.fade - delta, 0.0, 1.0)
