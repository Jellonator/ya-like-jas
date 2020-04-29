extends Node2D

const SPEED = 250.0

onready var level = get_owner()
var path: PoolVector2Array
var path_position: float = 0.0
var path_index: int = 0
var path_is_following: bool = false
var can_change_path: bool = true
var object_select

func set_on_path(newpath: PoolVector2Array):
	path = newpath
	path_position = 0.0
	path_index = 0
	path_is_following = true

func _physics_process(delta):
	var oldpos = global_position
	var obj = GameData.get_moused_object()
	if level.can_navigate_to(get_global_mouse_position()) or obj != null:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if path_is_following:
		if path_index >= path.size() - 1:
			path_is_following = false
			can_change_path = true
			if object_select != null:
				object_select.interact()
				object_select = null
		else:
			var p1 := path[path_index]
			var p2 := path[path_index+1]
			var dis := p1.distance_to(p2)
			if dis <= SPEED * delta:
				# Weird edge case where distance can be really small
				global_position = p2
				path_index += 1
				path_position = 0.0
			else:
				path_position += (SPEED * delta) / dis
				if path_position >= 1.0:
					global_position = p2
					path_index += 1
					path_position = 0.0
				else:
					global_position = p1.linear_interpolate(p2, path_position)
	var newpos = global_position
	if newpos.x > oldpos.x:
		$Beetective.flip_h = false
	elif newpos.x < oldpos.x:
		$Beetective.flip_h = true

func _unhandled_input(event):
	if event.is_action_pressed("on_click") and can_change_path:
		var obj = GameData.get_moused_object()
		if obj != null:
			object_select = obj
			set_on_path(level.get_navigation_path(global_position, obj.get_target_location()))
		else:
			var pos = get_global_mouse_position()
			if level.can_navigate_to(pos):
				set_on_path(level.get_navigation_path(global_position, pos))
