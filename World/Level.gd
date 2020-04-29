extends "res://World/LevelBase.gd"

const REQUIRED_FLAGS = [
	"NPC1_CHECK",
	"NPC2_CHECK",
	"NPC3_CHECK"
]

func does_have_required_flags() -> bool:
	for flag in REQUIRED_FLAGS:
		if GameData.get_flag(flag, "") == "":
			return false
	return true

var has_played_end := false
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
	if not has_played_end and not DialogueViewer.is_busy() and does_have_required_flags():
		$Ending.interact()
		has_played_end = true
		target_fade = 1.0

