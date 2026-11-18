extends Node3D
class_name BattlefieldSystems

signal unit_ordered(unit: Node3D, order: String)
signal object_destroyed(object_node: Node3D)

enum Formation { LINE, COLUMN, WEDGE, CIRCLE }
enum VehicleDomain { LAND, AIR, SEA }

var navigation_grid := AStarGrid2D.new()
var grid_origin := Vector2i(-32, -32)
var grid_size := Vector2i(64, 64)
var cell_size := 2.0
var blocked_cells: Dictionary = {}
var cover_objects: Array[Node3D] = []
var destructible_health: Dictionary = {}
var unit_groups: Dictionary = {}

func _init() -> void:
	_configure_navigation_grid()

func _ready() -> void:
	_ensure_navigation_grid()

func _configure_navigation_grid() -> void:
	navigation_grid.region = Rect2i(grid_origin, grid_size)
	navigation_grid.cell_size = Vector2(cell_size, cell_size)
	navigation_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	navigation_grid.update()

func _ensure_navigation_grid() -> void:
	if navigation_grid.is_dirty():
		navigation_grid.update()

func world_to_cell(world_position: Vector3) -> Vector2i:
	return Vector2i(roundi(world_position.x / cell_size), roundi(world_position.z / cell_size))

func cell_to_world(cell: Vector2i, height: float = 0.0) -> Vector3:
	return Vector3(float(cell.x) * cell_size, height, float(cell.y) * cell_size)

func set_obstacle(world_position: Vector3, blocked: bool) -> void:
	_ensure_navigation_grid()
	var cell := world_to_cell(world_position)
	if not navigation_grid.is_in_boundsv(cell):
		return
	navigation_grid.set_point_solid(cell, blocked)
	if blocked:
		blocked_cells[cell] = true
	else:
		blocked_cells.erase(cell)

func find_path(start: Vector3, goal: Vector3) -> PackedVector3Array:
	_ensure_navigation_grid()
	var from_cell := world_to_cell(start)
	var to_cell := world_to_cell(goal)
	if not navigation_grid.is_in_boundsv(from_cell) or not navigation_grid.is_in_boundsv(to_cell):
		return PackedVector3Array()
	if navigation_grid.is_point_solid(to_cell):
		return PackedVector3Array()
	var points := PackedVector3Array()
	for cell in navigation_grid.get_id_path(from_cell, to_cell):
		points.append(cell_to_world(cell, start.y))
	return points

func apply_formation(units: Array[Node3D], center: Vector3, facing: Vector3, formation: Formation, spacing: float = 2.2) -> void:
	if units.is_empty():
		return
	var forward := Vector3(facing.x, 0, facing.z).normalized()
	if forward.length_squared() < 0.01:
		forward = Vector3.FORWARD
	var right := forward.cross(Vector3.UP).normalized()
	var count := units.size()
	for i in range(count):
		var offset := Vector3.ZERO
		match formation:
			Formation.LINE:
				offset = right * (float(i) - float(count - 1) * 0.5) * spacing
			Formation.COLUMN:
				offset = -forward * float(i) * spacing
			Formation.WEDGE:
				var row := int(ceil((sqrt(8.0 * float(i) + 1.0) - 1.0) / 2.0))
				var side := i - row * (row + 1) / 2
				offset = -forward * float(row) * spacing + right * (float(side) - float(row) * 0.5) * spacing
			Formation.CIRCLE:
				var angle := TAU * float(i) / float(count)
				offset = (right * cos(angle) + forward * sin(angle)) * spacing * maxf(1.0, float(count) / TAU)
		units[i].set_meta("formation_destination", center + offset)
		unit_ordered.emit(units[i], "move_to_formation")

func has_line_of_sight(from: Vector3, to: Vector3, exclude: Array[RID] = []) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = exclude
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty()

func find_nearest_cover(position: Vector3, threat_position: Vector3, max_distance: float = 24.0) -> Vector3:
	var best := Vector3.ZERO
	var best_distance := max_distance
	for cover in cover_objects:
		if not is_instance_valid(cover):
			continue
		var distance := position.distance_to(cover.global_position)
		if distance < best_distance and not has_line_of_sight(cover.global_position + Vector3.UP, threat_position + Vector3.UP):
			best = cover.global_position
			best_distance = distance
	return best

func register_destructible(object_node: Node3D, hit_points: float) -> void:
	if is_instance_valid(object_node):
		destructible_health[object_node.get_instance_id()] = {"node": object_node, "hp": maxf(1.0, hit_points)}

func damage_object(object_node: Node3D, damage: float) -> bool:
	if not is_instance_valid(object_node):
		return false
	var key := object_node.get_instance_id()
	if not destructible_health.has(key):
		return false
	var state: Dictionary = destructible_health[key]
	state["hp"] = float(state["hp"]) - maxf(0.0, damage)
	if float(state["hp"]) <= 0.0:
		destructible_health.erase(key)
		set_obstacle(object_node.global_position, false)
		object_node.queue_free()
		object_destroyed.emit(object_node)
		return true
	destructible_health[key] = state
	return false

func move_vehicle(vehicle: Node3D, input_axis: Vector2, speed: float, delta: float, domain: VehicleDomain) -> void:
	if not is_instance_valid(vehicle):
		return
	var axis := Vector3(input_axis.x, 0.0, input_axis.y)
	if domain == VehicleDomain.AIR:
		axis.y = clampf(input_axis.y, -1.0, 1.0)
	elif domain == VehicleDomain.SEA:
		axis.y = 0.0
	var direction := axis.normalized()
	vehicle.global_position += direction * speed * delta
	if direction.length_squared() > 0.01:
		var flat := Vector3(direction.x, 0, direction.z)
		if flat.length_squared() > 0.01:
			vehicle.look_at(vehicle.global_position + flat, Vector3.UP)

func apply_distance_lod(root: Node3D, camera_position: Vector3, near_distance: float = 45.0, far_distance: float = 110.0) -> void:
	if not is_instance_valid(root):
		return
	var distance := root.global_position.distance_to(camera_position)
	var detail := 0
	if distance > far_distance:
		detail = 2
	elif distance > near_distance:
		detail = 1
	root.set_meta("lod_level", detail)
	for child in root.get_children():
		if child is GeometryInstance3D:
			child.visibility_range_end = far_distance * (1.4 if detail == 0 else 1.0)
