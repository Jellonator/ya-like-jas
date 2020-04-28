extends Navigation2D

const MAX_NAV_DISTANCE = 2.0

func get_navigation_point(point: Vector2) -> Vector2:
	return get_closest_point(point)

func can_navigate_to(point: Vector2) -> bool:
	var dis2 := get_navigation_point(point).distance_squared_to(point)
	return dis2 < MAX_NAV_DISTANCE * MAX_NAV_DISTANCE

func get_navigation_path(start: Vector2, destination: Vector2):
	destination = get_navigation_point(destination)
	return get_simple_path(start, destination)
