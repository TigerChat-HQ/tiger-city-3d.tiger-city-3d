extends Node3D

const GRID := 6
const BLOCK := 8.0
const ROAD := 3.0
const SAVE_PATH := "user://tiger_city_save.json"
const BUILD_COSTS := [250, 600, 1200]
const BUILD_SIZES := [Vector3(4, 4, 4), Vector3(5, 7, 5), Vector3(6, 13, 6)]
const BUILD_COLORS := [Color(0.78, 0.68, 0.52), Color(0.25, 0.48, 0.68), Color(0.35, 0.38, 0.43)]

var coins := 5000
var soldiers := 24
var supplies := 100
var selected_building := -1
var captured := 0
var status_label: Label
var stats_label: Label
var camera: Camera3D
var city_root: Node3D
var buildings: Array[Dictionary] = []
var yaw := 0.0
var pitch := 0.62
var camera_distance := 95.0
var active_touches: Dictionary = {}
var touch_start: Vector2
var touch_moved := false
var mouse_dragging := false
var last_touch_gap := 0.0
var last_pointer := Vector2.ZERO
var camera_target := Vector3.ZERO
var battle_root: Node3D
var battle_units: Array[Dictionary] = []
var battle_active := false
var battle_reserve := 0
var battle_order := "advance"
var battle_command_buttons: Array[Button] = []
var total_loot := 0
var city_citizens: Array[Node3D] = []
var city_vehicles: Array[Node3D] = []
var economy_clock := 0.0
var world_clock := 0.0
var sun_light: DirectionalLight3D
var service_levels := {"water": 0, "power": 0, "health": 0, "education": 0, "police": 0, "fire": 0}
var service_costs := {"water": 350, "power": 450, "health": 600, "education": 500, "police": 550, "fire": 500}
var emergency_incidents := 0
var last_economy_income := 0
var last_economy_expense := 0
var food_stock := 180
var goods_stock := 120
var city_happiness := 72
var citizen_needs: Array[Dictionary] = []
var last_trade_income := 0
var service_nodes: Dictionary = {}
var production_sites: Array[Dictionary] = []
var route_points: Array[Vector3] = []
var route_progress: Array[float] = []
var cargo_routes: Array = []
var factory_ore_stock := 0
var town_food_stock: Array[int] = [0, 0, 0, 0, 0]
var town_goods_stock: Array[int] = [0, 0, 0, 0, 0]
var delivered_food_total := 0
var delivered_ore_total := 0
var delivered_goods_total := 0

func _ready() -> void:
	_build_world()
	_build_ui()
	_load_game()
	_update_ui()
	_update_camera()

func _build_world() -> void:
	# Cinematic mobile-friendly world lighting and physically based material defaults.
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.12, 0.24, 0.39)
	sky_material.sky_horizon_color = Color(0.68, 0.76, 0.82)
	sky_material.ground_bottom_color = Color(0.12, 0.15, 0.13)
	sky_material.ground_horizon_color = Color(0.48, 0.53, 0.48)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.62
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.05
	environment.glow_enabled = true
	environment.glow_intensity = 0.18
	environment.ssr_enabled = false
	world_environment.environment = environment
	add_child(world_environment)
	city_root = Node3D.new()
	city_root.name = "GeneratedCity"
	add_child(city_root)
	_add_box("Ground", Vector3(0, -0.3, 0), Vector3(100, 0.5, 100), Color(0.20, 0.32, 0.20))
	for i in range(GRID + 1):
		var p := (float(i) - GRID / 2.0) * (BLOCK + ROAD)
		_add_box("RoadX", Vector3(0, 0.02, p), Vector3(100, 0.12, ROAD), Color(0.12, 0.13, 0.15))
		_add_box("RoadZ", Vector3(p, 0.02, 0), Vector3(ROAD, 0.12, 100), Color(0.12, 0.13, 0.15))
	_add_city_street_details()
	var rng := RandomNumberGenerator.new()
	rng.seed = 303
	for x in range(GRID):
		for z in range(GRID):
			var px := (float(x) - GRID / 2.0 + 0.5) * (BLOCK + ROAD)
			var pz := (float(z) - GRID / 2.0 + 0.5) * (BLOCK + ROAD)
			var h := rng.randf_range(4.0, 15.0)
			var building_size := Vector3(rng.randf_range(3.5, 6.0), h, rng.randf_range(3.5, 6.0))
			var building_color := Color(0.45, 0.48, 0.52).lerp(Color(0.72, 0.65, 0.52), rng.randf())
			_add_detailed_building("Capital block", Vector3(px, h / 2.0, pz), building_size, building_color)
	for i in range(5):
		var angle := TAU * float(i) / 5.0
		_add_box("Rival district", Vector3(cos(angle) * 62.0, 2.0, sin(angle) * 62.0), Vector3(9, 4, 9), Color(0.62, 0.18, 0.15))
	_build_neighbor_cities()
	_build_production_network()
	_add_box("Capital", Vector3(0, 3, 0), Vector3(12, 6, 12), Color(0.82, 0.64, 0.22))
	sun_light = DirectionalLight3D.new()
	sun_light.rotation_degrees = Vector3(-52, -30, 0)
	sun_light.light_energy = 1.4
	sun_light.shadow_enabled = true
	sun_light.directional_shadow_max_distance = 110.0
	sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun_light.light_angular_distance = 0.7
	add_child(sun_light)
	camera = Camera3D.new()
	camera.current = true
	add_child(camera)
	_spawn_city_life()

func _build_neighbor_cities() -> void:
	var palettes := [[Color(0.68, 0.42, 0.22), Color(0.78, 0.66, 0.42)], [Color(0.24, 0.48, 0.38), Color(0.54, 0.68, 0.48)], [Color(0.34, 0.42, 0.62), Color(0.62, 0.68, 0.78)], [Color(0.58, 0.32, 0.26), Color(0.78, 0.54, 0.38)], [Color(0.48, 0.42, 0.58), Color(0.72, 0.66, 0.78)]]
	for city_index in range(5):
		var angle := TAU * float(city_index) / 5.0
		var center := Vector3(cos(angle) * 62.0, 0.0, sin(angle) * 62.0)
		var palette: Array = palettes[city_index]
		_add_box("Town plaza %d" % city_index, center, Vector3(22, 0.25, 22), Color(0.28, 0.30, 0.27))
		for building_index in range(7):
			var ring := float(building_index / 4)
			var slot := float(building_index % 4)
			var height := 4.0 + float((building_index * 3 + city_index) % 5) * 1.8
			var tint: Color = palette[building_index % 2]
			var local_pos := Vector3((slot - 1.5) * 5.0, height * 0.5, (ring - 0.5) * 8.0)
			_add_detailed_building("Town %d building %d" % [city_index, building_index], center + local_pos, Vector3(3.8, height, 4.2), tint)
		_add_detailed_building("Town %d landmark" % city_index, center + Vector3(0, 5.5, 0), Vector3(5, 11, 5), palette[1])

func _build_production_network() -> void:
	var specs := [
		["Farm", "food", Vector3(34, 1, 8), Vector3(10, 2, 8), Color(0.34, 0.56, 0.22)],
		["Mine", "ore", Vector3(-8, 1.2, -37), Vector3(9, 2.4, 9), Color(0.42, 0.43, 0.45)],
		["Factory", "goods", Vector3(-37, 1.8, -5), Vector3(12, 3.6, 10), Color(0.48, 0.52, 0.58)]
	]
	for spec in specs:
		var hub := _add_detailed_building(String(spec[0]), spec[2], spec[3], spec[4])
		production_sites.append({"name": spec[0], "kind": spec[1], "stock": 0, "node": hub})
	var factory_route: Array = [Vector3(-37, 0, -5)]
	for city_index in range(5):
		var city_angle := TAU * float(city_index) / 5.0
		factory_route.append(Vector3(cos(city_angle) * 62.0, 0, sin(city_angle) * 62.0))
	factory_route.append(Vector3(-37, 0, -5))
	cargo_routes = [
		[Vector3(34, 0, 8), Vector3(16, 0, 4), Vector3(0, 0, 0)],
		[Vector3(-8, 0, -37), Vector3(-22, 0, -22), Vector3(-37, 0, -5)],
		factory_route
	]
	for route in cargo_routes:
		for i in range(route.size() - 1):
			var start_point: Vector3 = route[i]
			var end_point: Vector3 = route[i + 1]
			var direction := end_point - start_point
			var road := _add_box("Intercity cargo road", (start_point + end_point) * 0.5 + Vector3(0, -0.05, 0), Vector3(3.2, 0.12, direction.length()), Color(0.14, 0.15, 0.17))
			road.rotation.y = atan2(direction.x, direction.z)
	for i in range(3):
		var truck := _create_truck(i)
		truck.position = cargo_routes[i][0]
		city_root.add_child(truck)
		city_vehicles.append(truck)
		route_progress.append(0.0)

func _create_truck(index: int) -> Node3D:
	var truck := Node3D.new()
	var paint := [Color(0.72, 0.18, 0.12), Color(0.16, 0.36, 0.68), Color(0.72, 0.62, 0.30)][index % 3]
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(2.8, 0.75, 1.45)
	body.mesh = body_mesh
	body.position.y = 0.15
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = paint
	body_material.metallic = 0.25
	body.material_override = body_material
	truck.add_child(body)
	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.05, 0.82, 1.35)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0.75, 0.9, 0)
	var cabin_material := StandardMaterial3D.new()
	cabin_material.albedo_color = Color(0.12, 0.25, 0.32)
	cabin.material_override = cabin_material
	truck.add_child(cabin)
	for x in [-0.9, 0.9]:
		for z in [-0.82, 0.82]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.34
			wheel_mesh.bottom_radius = 0.34
			wheel_mesh.height = 0.22
			wheel.mesh = wheel_mesh
			wheel.rotation_degrees.z = 90
			wheel.position = Vector3(x, -0.25, z)
			var rubber := StandardMaterial3D.new()
			rubber.albedo_color = Color(0.035, 0.04, 0.045)
			wheel.material_override = rubber
			truck.add_child(wheel)
	return truck

func _build_service(service_name: String) -> void:
	if not service_levels.has(service_name):
		return
	var cost := int(service_costs[service_name]) * (int(service_levels[service_name]) + 1)
	if coins < cost:
		status_label.text = "Not enough coins. Upgrade costs %d." % cost
		return
	coins -= cost
	service_levels[service_name] = int(service_levels[service_name]) + 1
	var service_positions := {"water": Vector3(-18, 2.5, 18), "power": Vector3(18, 3, 18), "health": Vector3(-18, 3.5, -18), "education": Vector3(18, 3, -18), "police": Vector3(-30, 3, 0), "fire": Vector3(30, 3, 0)}
	var service_colors := {"water": Color(0.16, 0.48, 0.78), "power": Color(0.88, 0.72, 0.18), "health": Color(0.78, 0.22, 0.24), "education": Color(0.28, 0.62, 0.38), "police": Color(0.12, 0.24, 0.72), "fire": Color(0.92, 0.28, 0.08)}
	var height := 5.0 + float(service_levels[service_name])
	var service_node: MeshInstance3D = service_nodes.get(service_name)
	if is_instance_valid(service_node):
		var service_mesh := BoxMesh.new()
		service_mesh.size = Vector3(5, height, 5)
		service_node.mesh = service_mesh
		service_node.position = service_positions[service_name]
	else:
		service_node = _add_box(service_name.capitalize() + " service", service_positions[service_name], Vector3(5, height, 5), service_colors[service_name])
		service_nodes[service_name] = service_node
	status_label.text = "%s service upgraded to level %d." % [service_name.capitalize(), service_levels[service_name]]
	_update_ui()
func _add_detailed_building(label: String, pos: Vector3, size: Vector3, tint: Color) -> MeshInstance3D:
	var building := _add_box(label, pos, size, tint)
	var facade := StandardMaterial3D.new()
	facade.albedo_color = tint
	facade.roughness = 0.82
	facade.metallic = 0.04
	building.material_override = facade
	var window_material := StandardMaterial3D.new()
	window_material.albedo_color = Color(0.12, 0.25, 0.32)
	window_material.metallic = 0.48
	window_material.roughness = 0.16
	window_material.emission_enabled = true
	window_material.emission = Color(0.08, 0.13, 0.16)
	window_material.emission_energy_multiplier = 0.12
	var floors := maxi(1, int(size.y / 2.6))
	var columns := maxi(1, int(size.x / 1.5))
	for floor_index in range(floors):
		for column_index in range(columns):
			var window_mesh := MeshInstance3D.new()
			var window_shape := BoxMesh.new()
			window_shape.size = Vector3(0.42, 0.72, 0.07)
			window_mesh.mesh = window_shape
			window_mesh.position = Vector3(pos.x - size.x * 0.5 + 0.75 + float(column_index) * 1.15, 1.0 + float(floor_index) * 2.35, pos.z - size.z * 0.5 - 0.045)
			window_mesh.material_override = window_material
			city_root.add_child(window_mesh)
			var rear_window := MeshInstance3D.new()
			rear_window.mesh = window_shape
			rear_window.position = Vector3(pos.x - size.x * 0.5 + 0.75 + float(column_index) * 1.15, 1.0 + float(floor_index) * 2.35, pos.z + size.z * 0.5 + 0.045)
			rear_window.material_override = window_material
			city_root.add_child(rear_window)
	# A restrained parapet and rooftop plant room break up the toy-like flat roof silhouette.
	var parapet_material := StandardMaterial3D.new()
	parapet_material.albedo_color = tint.darkened(0.18)
	parapet_material.roughness = 0.9
	for edge in [-1.0, 1.0]:
		var parapet := MeshInstance3D.new()
		var parapet_mesh := BoxMesh.new()
		parapet_mesh.size = Vector3(size.x + 0.2, 0.42, 0.22)
		parapet.mesh = parapet_mesh
		parapet.position = pos + Vector3(0, size.y * 0.5 + 0.31, edge * size.z * 0.5)
		parapet.material_override = parapet_material
		city_root.add_child(parapet)
	var rooftop_unit := MeshInstance3D.new()
	var rooftop_mesh := BoxMesh.new()
	rooftop_mesh.size = Vector3(minf(1.8, size.x * 0.42), 0.65, minf(1.5, size.z * 0.42))
	rooftop_unit.mesh = rooftop_mesh
	rooftop_unit.position = pos + Vector3(size.x * 0.2, size.y * 0.5 + 0.55, 0)
	var rooftop_material := StandardMaterial3D.new()
	rooftop_material.albedo_color = Color(0.34, 0.37, 0.39)
	rooftop_material.metallic = 0.55
	rooftop_material.roughness = 0.52
	rooftop_unit.material_override = rooftop_material
	city_root.add_child(rooftop_unit)
	var roof := MeshInstance3D.new()
	var roof_shape := BoxMesh.new()
	roof_shape.size = Vector3(size.x + 0.35, 0.22, size.z + 0.35)
	roof.mesh = roof_shape
	roof.position = pos + Vector3(0, size.y * 0.5 + 0.12, 0)
	var roof_material := StandardMaterial3D.new()
	roof_material.albedo_color = tint.darkened(0.28)
	roof.material_override = roof_material
	city_root.add_child(roof)
	return building

func _add_city_street_details() -> void:
	var asphalt_marking := StandardMaterial3D.new()
	asphalt_marking.albedo_color = Color(0.82, 0.78, 0.62)
	asphalt_marking.roughness = 0.92
	var sidewalk_material := StandardMaterial3D.new()
	sidewalk_material.albedo_color = Color(0.48, 0.49, 0.46)
	sidewalk_material.roughness = 0.96
	for lane in range(GRID + 1):
		var road_pos := (float(lane) - GRID / 2.0) * (BLOCK + ROAD)
		for dash_index in range(-9, 10):
			var offset := float(dash_index) * 5.2
			var dash_x := MeshInstance3D.new()
			var dash_mesh := BoxMesh.new()
			dash_mesh.size = Vector3(2.2, 0.025, 0.12)
			dash_x.mesh = dash_mesh
			dash_x.position = Vector3(offset, 0.095, road_pos)
			dash_x.material_override = asphalt_marking
			city_root.add_child(dash_x)
			var dash_z := MeshInstance3D.new()
			var dash_z_mesh := BoxMesh.new()
			dash_z_mesh.size = Vector3(0.12, 0.025, 2.2)
			dash_z.mesh = dash_z_mesh
			dash_z.position = Vector3(road_pos, 0.095, offset)
			dash_z.material_override = asphalt_marking
			city_root.add_child(dash_z)
		for side in [-1.0, 1.0]:
			var curb_x := MeshInstance3D.new()
			var curb_mesh := BoxMesh.new()
			curb_mesh.size = Vector3(100, 0.32, 0.38)
			curb_x.mesh = curb_mesh
			curb_x.position = Vector3(0, 0.12, road_pos + side * (ROAD * 0.5 + 0.24))
			curb_x.material_override = sidewalk_material
			city_root.add_child(curb_x)
			var curb_z := MeshInstance3D.new()
			var curb_z_mesh := BoxMesh.new()
			curb_z_mesh.size = Vector3(0.38, 0.32, 100)
			curb_z.mesh = curb_z_mesh
			curb_z.position = Vector3(road_pos + side * (ROAD * 0.5 + 0.24), 0.12, 0)
			curb_z.material_override = sidewalk_material
			city_root.add_child(curb_z)
	for x in range(-3, 4):
		for z in range(-3, 4):
			if abs(x) == 3 or abs(z) == 3:
				continue
			if (x + z) % 2 == 0:
				_add_streetlight(Vector3(float(x) * (BLOCK + ROAD) + 2.4, 0, float(z) * (BLOCK + ROAD) - 2.4))

func _add_streetlight(pos: Vector3) -> void:
	var pole_material := StandardMaterial3D.new()
	pole_material.albedo_color = Color(0.18, 0.20, 0.21)
	pole_material.metallic = 0.72
	pole_material.roughness = 0.38
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.055
	pole_mesh.bottom_radius = 0.09
	pole_mesh.height = 5.4
	pole.mesh = pole_mesh
	pole.position = pos + Vector3(0, 2.7, 0)
	pole.material_override = pole_material
	city_root.add_child(pole)
	var arm := MeshInstance3D.new()
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(1.1, 0.08, 0.08)
	arm.mesh = arm_mesh
	arm.position = pos + Vector3(0.48, 5.25, 0)
	arm.material_override = pole_material
	city_root.add_child(arm)
	var lamp := MeshInstance3D.new()
	var lamp_mesh := BoxMesh.new()
	lamp_mesh.size = Vector3(0.42, 0.16, 0.24)
	lamp.mesh = lamp_mesh
	lamp.position = pos + Vector3(0.94, 5.17, 0)
	var lamp_material := StandardMaterial3D.new()
	lamp_material.albedo_color = Color(0.98, 0.82, 0.55)
	lamp_material.emission_enabled = true
	lamp_material.emission = Color(1.0, 0.66, 0.28)
	lamp_material.emission_energy_multiplier = 1.4
	lamp.material_override = lamp_material
	city_root.add_child(lamp)

func _add_box(label: String, pos: Vector3, size: Vector3, tint: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var item := MeshInstance3D.new()
	item.name = label
	item.mesh = mesh
	item.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	item.material_override = material
	city_root.add_child(item)
	return item

func _update_camera() -> void:
	if camera == null:
		return
	var target := camera_target
	var horizontal := camera_distance * cos(pitch)
	camera.position = target + Vector3(sin(yaw) * horizontal, camera_distance * sin(pitch), cos(yaw) * horizontal)
	camera.look_at(target, Vector3.UP)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(290, 0)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var heading := Label.new()
	heading.text = "TIGER CITY 3D"
	heading.add_theme_font_size_override("font_size", 25)
	column.add_child(heading)
	stats_label = Label.new()
	column.add_child(stats_label)
	for pair in [["HOUSE", 0], ["SHOP", 1], ["OFFICE", 2]]:
		var button := Button.new()
		button.text = "SELECT " + pair[0]
		var kind: int = pair[1]
		button.pressed.connect(func(): _select_building(kind))
		column.add_child(button)
	var recruit := Button.new()
	recruit.text = "RECRUIT 5 SOLDIERS (-20)"
	recruit.pressed.connect(_recruit)
	column.add_child(recruit)
	var attack := Button.new()
	attack.text = "ATTACK NEIGHBOUR (-15)"
	attack.pressed.connect(_attack)
	column.add_child(attack)
	var command_row := HBoxContainer.new()
	column.add_child(command_row)
	for command in [["ADVANCE", "advance"], ["HOLD", "hold"], ["RETREAT", "retreat"]]:
		var command_button := Button.new()
		command_button.text = command[0]
		command_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var order: String = command[1]
		command_button.pressed.connect(func(): _set_battle_order(order))
		command_row.add_child(command_button)
		command_button.visible = false
		battle_command_buttons.append(command_button)
	var air_support := Button.new()
	air_support.text = "AIR SUPPORT (-900 COINS)"
	air_support.pressed.connect(_battle_air_support)
	column.add_child(air_support)
	air_support.visible = false
	battle_command_buttons.append(air_support)
	for service_name in ["water", "power", "health", "education"]:
		var service_button := Button.new()
		service_button.text = "UPGRADE " + service_name.to_upper()
		service_button.pressed.connect(func(): _build_service(service_name))
		column.add_child(service_button)
	var save_button := Button.new()
	save_button.text = "SAVE GAME"
	save_button.pressed.connect(_save_game)
	column.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "LOAD GAME"
	load_button.pressed.connect(_load_game)
	column.add_child(load_button)
	status_label = Label.new()
	status_label.text = "Drag to rotate • Pinch to zoom • Select a building, then tap the city."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)

func _spawn_city_life() -> void:
	# Lightweight placeholder pedestrians and traffic make the city feel inhabited.
	for i in range(14):
		var person := Node3D.new()
		var shape := CapsuleMesh.new()
		shape.radius = 0.22
		shape.height = 1.25
		var torso := MeshInstance3D.new()
		torso.mesh = shape
		torso.position.y = 0.35
		person.add_child(torso)
		var material := StandardMaterial3D.new()
		material.albedo_color = [Color(0.75, 0.38, 0.22), Color(0.18, 0.42, 0.68), Color(0.68, 0.62, 0.42)][i % 3]
		torso.material_override = material
		var head := MeshInstance3D.new()
		var head_shape := SphereMesh.new()
		head_shape.radius = 0.19
		head_shape.height = 0.38
		head.mesh = head_shape
		head.position.y = 1.0
		head.material_override = material
		person.add_child(head)
		person.position = Vector3(-33.0 + float(i % 7) * 11.0, 0.72, -42.0 + float(i) * 6.0)
		city_root.add_child(person)
		city_citizens.append(person)
		citizen_needs.append({"hunger": 0.0, "health": 80.0, "education": 20.0, "happiness": 72.0})
	for i in range(5):
		var car := _create_truck(i)
		car.scale = Vector3(0.62, 0.62, 0.62)
		car.position = Vector3(-48.0 + float(i) * 12.0, 0.58, [-33.0, -22.0, -11.0, 0.0, 11.0, 22.0, 33.0, 0.0][i])
		city_root.add_child(car)
		city_vehicles.append(car)

func _update_city_life(delta: float) -> void:
	for i in range(city_citizens.size()):
		var person := city_citizens[i]
		if is_instance_valid(person):
			person.position.z += delta * (0.65 + float(i % 4) * 0.12)
			if person.position.z > 48.0:
				person.position.z = -48.0
	for i in range(city_vehicles.size()):
		var vehicle := city_vehicles[i]
		if not is_instance_valid(vehicle):
			continue
		if i < cargo_routes.size():
			var route: Array = cargo_routes[i]
			var old_progress := route_progress[i]
			route_progress[i] = fposmod(old_progress + delta * 0.035, 1.0)
			var old_segment := mini(int(old_progress * float(route.size() - 1)), route.size() - 2)
			var scaled_progress := route_progress[i] * float(route.size() - 1)
			var segment := mini(int(scaled_progress), route.size() - 2)
			if route_progress[i] < old_progress and i < 2:
				_deliver_cargo(i)
			elif i == 2 and segment > old_segment and segment <= 5:
				_deliver_goods_to_town(segment - 1)
			var point: Vector3 = route[segment].lerp(route[segment + 1], scaled_progress - float(segment))
			vehicle.position = point
			vehicle.look_at(route[segment + 1], Vector3.UP)
		else:
			vehicle.position.x += delta * 2.5
			if vehicle.position.x > 52.0:
				vehicle.position.x = -52.0
	economy_clock += delta
	if economy_clock >= 8.0:
		economy_clock = 0.0
		var shop_count := 0
		var office_count := 0
		for entry in buildings:
			if int(entry.get("kind", -1)) == 1:
				shop_count += 1
			elif int(entry.get("kind", -1)) == 2:
				office_count += 1
		var service_total := 0
		for level in service_levels.values():
			service_total += int(level)
		var population := city_citizens.size()
		var water_coverage := mini(100, 35 + int(service_levels["water"]) * 20)
		var power_coverage := mini(100, 35 + int(service_levels["power"]) * 20)
		var health_coverage := mini(100, 25 + int(service_levels["health"]) * 25)
		var education_coverage := mini(100, 20 + int(service_levels["education"]) * 25)
		var police_coverage := mini(100, int(service_levels["police"]) * 30)
		var fire_coverage := mini(100, int(service_levels["fire"]) * 30)
		var food_produced := 8 + shop_count * 3
		var factory_goods := 0
		for site_index in range(production_sites.size()):
			var site: Dictionary = production_sites[site_index]
			match String(site.get("kind", "")):
				"food":
					food_produced += 18
					site["stock"] = mini(300, int(site.get("stock", 0)) + 18)
				"ore":
					site["stock"] = mini(300, int(site.get("stock", 0)) + 12)
				"goods":
					factory_goods = mini(14, factory_ore_stock)
					factory_ore_stock -= factory_goods
					site["stock"] = mini(300, int(site.get("stock", 0)) + factory_goods)
			production_sites[site_index] = site
		var goods_produced := 5 + shop_count * 4 + office_count * 2
		food_stock = clampi(food_stock + food_produced - population * 2, 0, 500)
		goods_stock = clampi(goods_stock + goods_produced - population, 0, 500)
		for town_index in range(5):
			town_food_stock[town_index] = maxi(0, town_food_stock[town_index] - 3)
			town_goods_stock[town_index] = maxi(0, town_goods_stock[town_index] - 2)
		var food_shortage := food_stock < 20
		var goods_shortage := goods_stock < 15
		for i in range(citizen_needs.size()):
			var needs: Dictionary = citizen_needs[i]
			needs["hunger"] = clampf(float(needs["hunger"]) + (1.0 if food_shortage else -0.35), 0.0, 100.0)
			needs["health"] = clampf(float(needs["health"]) + (float(health_coverage) - 55.0) * 0.035 - (2.0 if food_shortage else 0.0), 0.0, 100.0)
			needs["education"] = clampf(float(needs["education"]) + float(education_coverage) * 0.012, 0.0, 100.0)
			var citizen_happiness := 68.0 + float(water_coverage + power_coverage) * 0.10 + float(health_coverage + education_coverage) * 0.06
			if food_shortage:
				citizen_happiness -= 18.0
			if goods_shortage:
				citizen_happiness -= 8.0
			needs["happiness"] = clampf(citizen_happiness - float(needs["hunger"]) * 0.25, 0.0, 100.0)
			citizen_needs[i] = needs
		var happiness_total := 0.0
		for needs in citizen_needs:
			happiness_total += float(needs["happiness"])
		if citizen_needs.size() > 0:
			city_happiness = int(happiness_total / citizen_needs.size())
		if randf() < 0.12:
			var fire_event := randf() < 0.5
			var response_coverage := fire_coverage if fire_event else police_coverage
			var incident_loss := maxi(0, 180 - response_coverage * 2)
			coins -= incident_loss
			city_happiness = maxi(0, city_happiness - (2 if response_coverage >= 60 else 6))
			emergency_incidents += 1
			status_label.text = ("Fire emergency handled by the fire service." if fire_event else "Security incident handled by the police.") if response_coverage >= 60 else ("Fire emergency! Upgrade the fire station." if fire_event else "Security incident! Upgrade the police station.")
		var business_income := 10 + shop_count * 18 + office_count * 28
		var taxes := int(population * (0.5 + float(city_happiness) / 100.0))
		last_trade_income = 0
		if captured > 0:
			last_trade_income = captured * (12 + shop_count * 3 + int(power_coverage / 20))
		var maintenance := buildings.size() * 2 + service_total * 7 + 8
		last_economy_income = business_income + taxes + service_total * 4 + last_trade_income
		last_economy_expense = maintenance
		coins += last_economy_income - last_economy_expense
		if supplies < 200:
			supplies += 1
		_update_ui()
	world_clock = fmod(world_clock + delta, 180.0)
	if is_instance_valid(sun_light):
		var daylight := (sin(world_clock / 180.0 * TAU - PI / 2.0) + 1.0) * 0.5
		sun_light.rotation_degrees = Vector3(-15.0 - daylight * 55.0, -30.0, 0.0)
		sun_light.light_energy = 0.18 + daylight * 1.35

func _deliver_goods_to_town(town_index: int) -> void:
	if production_sites.size() < 3 or town_index < 0 or town_index >= town_goods_stock.size():
		return
	var factory: Dictionary = production_sites[2]
	var goods_load := mini(12, int(factory.get("stock", 0)))
	factory["stock"] = int(factory.get("stock", 0)) - goods_load
	production_sites[2] = factory
	town_goods_stock[town_index] = mini(500, town_goods_stock[town_index] + goods_load)
	delivered_goods_total += goods_load
	status_label.text = "Factory truck delivered %d goods to Town %d." % [goods_load, town_index + 1]

func _deliver_cargo(truck_index: int) -> void:
	if production_sites.size() < 3:
		return
	if truck_index == 0:
		var farm: Dictionary = production_sites[0]
		var food_load := mini(30, int(farm.get("stock", 0)))
		farm["stock"] = int(farm.get("stock", 0)) - food_load
		production_sites[0] = farm
		var capital_share := int(food_load * 0.6)
		var town_share := food_load - capital_share
		food_stock = clampi(food_stock + capital_share, 0, 500)
		town_food_stock[0] = mini(500, town_food_stock[0] + town_share)
		delivered_food_total += food_load
		status_label.text = "Farm truck delivered %d food: %d to capital, %d to Town 1." % [food_load, capital_share, town_share]
	elif truck_index == 1:
		var mine: Dictionary = production_sites[1]
		var ore_load := mini(24, int(mine.get("stock", 0)))
		mine["stock"] = int(mine.get("stock", 0)) - ore_load
		production_sites[1] = mine
		factory_ore_stock = mini(200, factory_ore_stock + ore_load)
		delivered_ore_total += ore_load
		status_label.text = "Mine truck delivered %d ore to the factory." % ore_load
	elif truck_index == 2:
		var factory: Dictionary = production_sites[2]
		var goods_load := mini(24, int(factory.get("stock", 0)))
		factory["stock"] = int(factory.get("stock", 0)) - goods_load
		production_sites[2] = factory
		town_goods_stock[0] = mini(500, town_goods_stock[0] + goods_load)
		delivered_goods_total += goods_load
		status_label.text = "Factory truck delivered %d goods to the neighbouring town." % goods_load

func _select_building(kind: int) -> void:
	selected_building = kind
	status_label.text = "Selected " + ["House", "Shop", "Office"][kind] + ". Tap an open place in the city to build."

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			active_touches[touch.index] = touch.position
			if active_touches.size() == 1:
				touch_start = touch.position
				touch_moved = false
			elif active_touches.size() == 2:
				var points: Array = active_touches.values()
				last_touch_gap = points[0].distance_to(points[1])
		else:
			active_touches.erase(touch.index)
			if active_touches.is_empty() and not touch_moved and selected_building >= 0:
				_try_place_at(touch.position)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		active_touches[drag.index] = drag.position
		if active_touches.size() >= 2:
			var points: Array = active_touches.values()
			var current_gap: float = points[0].distance_to(points[1])
			if last_touch_gap > 0.0:
				camera_distance = clampf(camera_distance - (current_gap - last_touch_gap) * 0.12, 38.0, 145.0)
			last_touch_gap = current_gap
			touch_moved = true
		else:
			yaw -= drag.relative.x * 0.006
			pitch = clampf(pitch + drag.relative.y * 0.004, 0.18, 1.25)
			touch_moved = true
		_update_camera()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			mouse_dragging = mouse.pressed
			last_pointer = mouse.position
			if mouse.pressed:
				touch_moved = false
			if not mouse.pressed and not touch_moved and selected_building >= 0:
				_try_place_at(mouse.position)
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			camera_distance = maxf(38.0, camera_distance - 5.0)
			_update_camera()
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			camera_distance = minf(145.0, camera_distance + 5.0)
			_update_camera()
	elif event is InputEventMouseMotion and mouse_dragging:
		var motion := event as InputEventMouseMotion
		yaw -= motion.relative.x * 0.006
		pitch = clampf(pitch + motion.relative.y * 0.004, 0.18, 1.25)
		touch_moved = true
		_update_camera()

func _try_place_at(screen_position: Vector2) -> void:
	if selected_building < 0 or coins < BUILD_COSTS[selected_building]:
		status_label.text = "Select a building and make sure you have enough coins."
		return
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var ground := Plane(Vector3.UP, 0.0)
	var hit = ground.intersects_ray(origin, direction)
	if hit == null:
		return
	var point: Vector3 = hit
	if absf(point.x) > 43.0 or absf(point.z) > 43.0:
		status_label.text = "Choose a building site inside the city."
		return
	var size: Vector3 = BUILD_SIZES[selected_building]
	var snapped := Vector3(roundf(point.x / 2.0) * 2.0, size.y / 2.0, roundf(point.z / 2.0) * 2.0)
	for entry in buildings:
		var existing: Vector3 = entry.position
		if Vector2(existing.x, existing.z).distance_to(Vector2(snapped.x, snapped.z)) < 6.0:
			status_label.text = "That building site is occupied."
			return
	var item := _add_box("Player building", snapped, size, BUILD_COLORS[selected_building])
	buildings.append({"position": snapped, "kind": selected_building, "node": item})
	coins -= BUILD_COSTS[selected_building]
	status_label.text = "Building placed. Save your city to keep your progress."
	_update_ui()

func _recruit() -> void:
	if supplies < 20:
		status_label.text = "Not enough supplies to recruit."
		return
	supplies -= 20
	soldiers += 5
	status_label.text = "Five soldiers joined your army."
	_update_ui()

func _attack() -> void:
	if battle_active:
		status_label.text = "A battle is already in progress."
		return
	if supplies < 15 or soldiers < 8 or captured >= 5:
		status_label.text = "Need 8 soldiers, 15 supplies, and an uncaptured district."
		return
	supplies -= 15
	_start_battle()
	_update_ui()

func _start_battle() -> void:
	battle_active = true
	battle_order = "advance"
	for command_button in battle_command_buttons:
		command_button.visible = true
	battle_units.clear()
	battle_reserve = maxi(0, soldiers - 12)
	battle_root = Node3D.new()
	battle_root.name = "LiveBattlefield"
	add_child(battle_root)
	var floor_mesh := MeshInstance3D.new()
	var floor_shape := BoxMesh.new()
	floor_shape.size = Vector3(48, 0.5, 34)
	floor_mesh.mesh = floor_shape
	floor_mesh.position = Vector3(0, -0.3, 0)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.24, 0.29, 0.20)
	floor_mesh.material_override = floor_material
	battle_root.add_child(floor_mesh)
	for row in range(5):
		var line := MeshInstance3D.new()
		var line_mesh := BoxMesh.new()
		line_mesh.size = Vector3(0.12, 0.03, 30)
		line.mesh = line_mesh
		line.position = Vector3(-20.0 + row * 10.0, 0.0, 0.0)
		var line_material := StandardMaterial3D.new()
		line_material.albedo_color = Color(0.55, 0.53, 0.38, 0.45)
		line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		line.material_override = line_material
		battle_root.add_child(line)
	var deployed := mini(12, soldiers)
	for i in range(deployed):
		_spawn_battle_unit(0, i)
	for i in range(12 + captured * 2):
		_spawn_battle_unit(1, i)
	camera_target = Vector3.ZERO
	camera_distance = 43.0
	pitch = 0.82
	yaw = 0.0
	_update_camera()
	status_label.text = "Battle started! Choose ADVANCE, HOLD or RETREAT. Air support costs 900 coins."
	_update_ui()

func _spawn_battle_unit(side: int, index: int) -> void:
	var unit_node := Node3D.new()
	unit_node.name = "FriendlySoldier" if side == 0 else "EnemySoldier"
	var body := MeshInstance3D.new()
	var body_shape := CapsuleMesh.new()
	body_shape.radius = 0.38
	body_shape.height = 1.45
	body.mesh = body_shape
	body.position.y = 0.85
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.16, 0.34, 0.78) if side == 0 else Color(0.72, 0.16, 0.12)
	body_material.metallic = 0.18
	body_material.roughness = 0.62
	body.material_override = body_material
	unit_node.add_child(body)
	var head := MeshInstance3D.new()
	var head_shape := SphereMesh.new()
	head_shape.radius = 0.25
	head_shape.height = 0.5
	head.mesh = head_shape
	head.position.y = 1.72
	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = Color(0.72, 0.53, 0.39)
	head.material_override = head_material
	unit_node.add_child(head)
	var weapon := MeshInstance3D.new()
	var weapon_shape := BoxMesh.new()
	weapon_shape.size = Vector3(0.12, 0.12, 0.9)
	weapon.mesh = weapon_shape
	weapon.position = Vector3(0.42, 1.12, -0.1)
	var weapon_material := StandardMaterial3D.new()
	weapon_material.albedo_color = Color(0.18, 0.19, 0.20)
	weapon.material_override = weapon_material
	unit_node.add_child(weapon)
	var column := index % 4
	var row := index / 4
	var start_x := -16.0 if side == 0 else 16.0
	unit_node.position = Vector3(start_x, 0.0, float(column - 2) * 2.1 + (float(row) - 1.0) * 0.7)
	battle_root.add_child(unit_node)
	battle_units.append({"node": unit_node, "side": side, "hp": 100.0, "cooldown": randf_range(0.1, 0.8), "dead": false})

func _process(delta: float) -> void:
	_update_city_life(delta)
	if not battle_active:
		return
	var friendly_alive := 0
	var enemy_alive := 0
	for i in range(battle_units.size()):
		var unit: Dictionary = battle_units[i]
		if bool(unit.get("dead", false)):
			continue
		var actor: Node3D = unit.get("node")
		if not is_instance_valid(actor):
			unit["dead"] = true
			battle_units[i] = unit
			continue
		var side := int(unit.get("side", 0))
		if side == 0:
			friendly_alive += 1
		else:
			enemy_alive += 1
		var nearest: Node3D
		var nearest_distance := INF
		for opponent in battle_units:
			if bool(opponent.get("dead", false)) or int(opponent.get("side", 0)) == side:
				continue
			var opponent_node: Node3D = opponent.get("node")
			if not is_instance_valid(opponent_node):
				continue
			var distance := actor.position.distance_to(opponent_node.position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = opponent_node
		if nearest == null:
			continue
		var cooldown := maxf(0.0, float(unit.get("cooldown", 0.0)) - delta)
		if nearest_distance > 1.8:
			var direction := (nearest.position - actor.position).normalized()
			if side == 1 or battle_order == "advance":
				actor.position += direction * delta * (2.4 if side == 0 else 2.1)
			elif side == 0 and battle_order == "retreat":
				actor.position -= direction * delta * 3.0
			actor.look_at(Vector3(nearest.position.x, actor.position.y, nearest.position.z), Vector3.UP)
		elif cooldown <= 0.0:
			for j in range(battle_units.size()):
				var target: Dictionary = battle_units[j]
				if target.get("node") == nearest and not bool(target.get("dead", false)):
					target["hp"] = float(target.get("hp", 100.0)) - (14.0 if side == 0 else 11.0)
					if float(target["hp"]) <= 0.0:
						target["dead"] = true
						var target_node: Node3D = target.get("node")
						if is_instance_valid(target_node):
							target_node.queue_free()
					battle_units[j] = target
					break
			cooldown = 0.65
		unit["cooldown"] = cooldown
		battle_units[i] = unit
	if battle_order == "retreat" and friendly_alive > 0:
		var all_friendly_retreated := true
		for unit in battle_units:
			if int(unit.get("side", 0)) == 0 and not bool(unit.get("dead", false)):
				var retreating_actor: Node3D = unit.get("node")
				if is_instance_valid(retreating_actor) and retreating_actor.position.x > -21.0:
					all_friendly_retreated = false
		if all_friendly_retreated:
			_finish_battle(false)
			return
	if enemy_alive == 0 or friendly_alive == 0:
		_finish_battle(friendly_alive > 0 and enemy_alive == 0)

func _set_battle_order(order: String) -> void:
	if not battle_active or not ["advance", "hold", "retreat"].has(order):
		return
	battle_order = order
	match order:
		"advance":
			status_label.text = "Order issued: advance and engage the enemy."
		"hold":
			status_label.text = "Order issued: hold position and defend. Enemy must approach."
		"retreat":
			status_label.text = "Order issued: retreat to the capital. Territory will not be captured."

func _battle_air_support() -> void:
	if not battle_active:
		return
	if coins < 900:
		status_label.text = "Air support requires 900 coins."
		return
	coins -= 900
	var hits := 0
	for i in range(battle_units.size()):
		var target: Dictionary = battle_units[i]
		if int(target.get("side", 0)) != 1 or bool(target.get("dead", false)):
			continue
		target["hp"] = float(target.get("hp", 100.0)) - 42.0
		if float(target["hp"]) <= 0.0:
			target["dead"] = true
			var target_node: Node3D = target.get("node")
			if is_instance_valid(target_node):
				target_node.queue_free()
		battle_units[i] = target
		hits += 1
		if hits >= 5:
			break
	status_label.text = "Air support struck %d enemy units. 900 coins spent." % hits
	_update_ui()

func _finish_battle(victory: bool) -> void:
	var survivors := 0
	for unit in battle_units:
		if int(unit.get("side", 0)) == 0 and not bool(unit.get("dead", false)):
			survivors += 1
	battle_active = false
	soldiers = battle_reserve + survivors
	if victory:
		captured += 1
		var loot := 1200 + captured * 350
		coins += loot
		total_loot += loot
		supplies = mini(500, supplies + 20)
		food_stock = mini(500, food_stock + 12)
		status_label.text = "Victory! Territory captured. Loot: %d coins, +20 supplies and +12 food." % loot
	else:
		status_label.text = "Defeat or retreat. Your surviving soldiers return to the capital; no territory loot."
	for command_button in battle_command_buttons:
		command_button.visible = false
	if is_instance_valid(battle_root):
		battle_root.queue_free()
	battle_root = null
	battle_units.clear()
	camera_target = Vector3.ZERO
	camera_distance = 95.0
	pitch = 0.62
	_update_camera()
	_update_ui()

func _save_game() -> void:
	var saved_buildings: Array[Dictionary] = []
	for entry in buildings:
		var p: Vector3 = entry.position
		saved_buildings.append({"x": p.x, "z": p.z, "kind": entry.kind})
	var saved_production: Array[Dictionary] = []
	for site in production_sites:
		saved_production.append({"kind": site.get("kind", ""), "stock": int(site.get("stock", 0))})
	var data := {"coins": coins, "soldiers": soldiers, "supplies": supplies, "captured": captured, "buildings": saved_buildings, "service_levels": service_levels, "food_stock": food_stock, "goods_stock": goods_stock, "city_happiness": city_happiness, "citizen_needs": citizen_needs, "emergency_incidents": emergency_incidents, "factory_ore_stock": factory_ore_stock, "town_food_stock": town_food_stock, "town_goods_stock": town_goods_stock, "production_stocks": saved_production, "total_loot": total_loot}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		status_label.text = "Could not save the game on this device."
		return
	file.store_string(JSON.stringify(data))
	status_label.text = "Game saved on this device."
	file.close()

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		status_label.text = "No saved game found yet."
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		status_label.text = "Could not read the saved game."
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		status_label.text = "Saved game data is invalid."
		return
	coins = int(parsed.get("coins", 5000))
	soldiers = int(parsed.get("soldiers", 24))
	supplies = int(parsed.get("supplies", 100))
	captured = clampi(int(parsed.get("captured", 0)), 0, 5)
	total_loot = maxi(0, int(parsed.get("total_loot", 0)))
	var saved_services: Dictionary = parsed.get("service_levels", {})
	for service_name in service_levels.keys():
		service_levels[service_name] = maxi(0, int(saved_services.get(service_name, 0)))
	food_stock = maxi(0, int(parsed.get("food_stock", 180)))
	goods_stock = maxi(0, int(parsed.get("goods_stock", 120)))
	factory_ore_stock = maxi(0, int(parsed.get("factory_ore_stock", 0)))
	var saved_town_food: Array = parsed.get("town_food_stock", [])
	var saved_town_goods: Array = parsed.get("town_goods_stock", [])
	for town_index in range(5):
		if town_index < saved_town_food.size():
			town_food_stock[town_index] = maxi(0, int(saved_town_food[town_index]))
		if town_index < saved_town_goods.size():
			town_goods_stock[town_index] = maxi(0, int(saved_town_goods[town_index]))
	var saved_production: Array = parsed.get("production_stocks", [])
	for site_index in range(mini(production_sites.size(), saved_production.size())):
		var saved_site: Dictionary = saved_production[site_index]
		var site: Dictionary = production_sites[site_index]
		site["stock"] = maxi(0, int(saved_site.get("stock", 0)))
		production_sites[site_index] = site
	city_happiness = clampi(int(parsed.get("city_happiness", 72)), 0, 100)
	emergency_incidents = maxi(0, int(parsed.get("emergency_incidents", 0)))
	var saved_needs: Array = parsed.get("citizen_needs", [])
	for i in range(mini(citizen_needs.size(), saved_needs.size())):
		if saved_needs[i] is Dictionary:
			citizen_needs[i] = saved_needs[i].duplicate(true)
	for item in buildings:
		var node = item.get("node")
		if is_instance_valid(node):
			node.queue_free()
	buildings.clear()
	for entry in parsed.get("buildings", []):
		var kind := clampi(int(entry.get("kind", 0)), 0, 2)
		var size: Vector3 = BUILD_SIZES[kind]
		var pos := Vector3(float(entry.get("x", 0.0)), size.y / 2.0, float(entry.get("z", 0.0)))
		var node := _add_box("Player building", pos, size, BUILD_COLORS[kind])
		buildings.append({"position": pos, "kind": kind, "node": node})
	status_label.text = "Saved city loaded."
	_update_ui()

func _update_ui() -> void:
	if stats_label:
		var service_summary := "Water %d | Power %d | Health %d | School %d | Police %d | Fire %d" % [service_levels["water"], service_levels["power"], service_levels["health"], service_levels["education"], service_levels["police"], service_levels["fire"]]
		stats_label.text = "Coins: %d\nSoldiers: %d\nSupplies: %d\nDistricts captured: %d/5\nTotal loot: %d\nServices: %s\nPeople: %d | Happiness: %d%%\nEmergency incidents: %d\nCapital food: %d | Goods: %d | Factory ore: %d\nDelivered F/O/G: %d/%d/%d\nTown 1 stocks: F%d G%d\nCycle: +%d / -%d | Trade: +%d" % [coins, soldiers, supplies, captured, total_loot, service_summary, city_citizens.size(), city_happiness, emergency_incidents, food_stock, goods_stock, factory_ore_stock, delivered_food_total, delivered_ore_total, delivered_goods_total, town_food_stock[0], town_goods_stock[0], last_economy_income, last_economy_expense, last_trade_income]
