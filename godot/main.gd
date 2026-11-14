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
	city_root = Node3D.new()
	city_root.name = "GeneratedCity"
	add_child(city_root)
	_add_box("Ground", Vector3(0, -0.3, 0), Vector3(100, 0.5, 100), Color(0.20, 0.32, 0.20))
	for i in range(GRID + 1):
		var p := (float(i) - GRID / 2.0) * (BLOCK + ROAD)
		_add_box("RoadX", Vector3(0, 0.02, p), Vector3(100, 0.12, ROAD), Color(0.12, 0.13, 0.15))
		_add_box("RoadZ", Vector3(p, 0.02, 0), Vector3(ROAD, 0.12, 100), Color(0.12, 0.13, 0.15))
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
	var window_material := StandardMaterial3D.new()
	window_material.albedo_color = Color(0.22, 0.48, 0.62)
	window_material.metallic = 0.22
	window_material.roughness = 0.28
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
	for service_name in ["water", "power", "health", "education", "police", "fire"]:
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
	status_label.text = "Battle started! Watch your soldiers advance and fight."
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
			actor.position += direction * delta * (2.4 if side == 0 else 2.1)
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
	if enemy_alive == 0 or friendly_alive == 0:
		_finish_battle(friendly_alive > 0 and enemy_alive == 0)

func _finish_battle(victory: bool) -> void:
	var survivors := 0
	for unit in battle_units:
		if int(unit.get("side", 0)) == 0 and not bool(unit.get("dead", false)):
			survivors += 1
	battle_active = false
	soldiers = battle_reserve + survivors
	if victory:
		captured += 1
		status_label.text = "Victory! Your surviving soldiers captured the neighbouring territory."
	else:
		status_label.text = "Defeat. Your surviving soldiers retreat to the capital."
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
	var data := {"coins": coins, "soldiers": soldiers, "supplies": supplies, "captured": captured, "buildings": saved_buildings, "service_levels": service_levels, "food_stock": food_stock, "goods_stock": goods_stock, "city_happiness": city_happiness, "citizen_needs": citizen_needs, "emergency_incidents": emergency_incidents, "factory_ore_stock": factory_ore_stock, "town_food_stock": town_food_stock, "town_goods_stock": town_goods_stock, "production_stocks": saved_production}
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
	captured = int(parsed.get("captured", 0))
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
		stats_label.text = "Coins: %d\nSoldiers: %d\nSupplies: %d\nDistricts captured: %d/5\nServices: %s\nPeople: %d | Happiness: %d%%\nEmergency incidents: %d\nCapital food: %d | Goods: %d | Factory ore: %d\nDelivered F/O/G: %d/%d/%d\nTown 1 stocks: F%d G%d\nCycle: +%d / -%d | Trade: +%d" % [coins, soldiers, supplies, captured, service_summary, city_citizens.size(), city_happiness, emergency_incidents, food_stock, goods_stock, factory_ore_stock, delivered_food_total, delivered_ore_total, delivered_goods_total, town_food_stock[0], town_goods_stock[0], last_economy_income, last_economy_expense, last_trade_income]
