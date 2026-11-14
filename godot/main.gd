extends Node3D

const GRID := 6
const BLOCK := 8.0
const ROAD := 3.0

var coins := 5000
var soldiers := 24
var supplies := 100
var selected_building := 0
var captured := 0
var status_label: Label
var stats_label: Label
var camera: Camera3D
var city_root: Node3D
var buildings: Array[Node3D] = []

func _ready() -> void:
	_build_world()
	_build_ui()
	_update_ui()

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
			_add_box("Building", Vector3(px, h / 2.0, pz), Vector3(rng.randf_range(3.5, 6.0), h, rng.randf_range(3.5, 6.0)), Color(0.45, 0.48, 0.52).lerp(Color(0.72, 0.65, 0.52), rng.randf()))
	for i in range(5):
		var angle := TAU * float(i) / 5.0
		var pos := Vector3(cos(angle) * 62.0, 2.0, sin(angle) * 62.0)
		_add_box("Rival district", pos, Vector3(9, 4, 9), Color(0.62, 0.18, 0.15))
	_add_box("Capital", Vector3(0, 3, 0), Vector3(12, 6, 12), Color(0.82, 0.64, 0.22))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -30, 0)
	sun.light_energy = 1.4
	add_child(sun)
	camera = Camera3D.new()
	camera.position = Vector3(0, 58, 78)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true
	add_child(camera)

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

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(300, 0)
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
		button.text = "BUILD " + pair[0]
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
	status_label = Label.new()
	status_label.text = "Build your capital and prepare to defend it."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)

func _select_building(kind: int) -> void:
	selected_building = kind
	status_label.text = "Selected building: " + ["House", "Shop", "Office"][kind] + ". Tap BUILD SITE to place."
	_place_building()

func _place_building() -> void:
	var costs := [250, 600, 1200]
	if coins < costs[selected_building]:
		status_label.text = "Not enough coins."
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var height := [4.0, 7.0, 13.0][selected_building]
	var pos := Vector3(rng.randf_range(-22, 22), height / 2.0, rng.randf_range(-22, 22))
	var size := [Vector3(4,4,4), Vector3(5,7,5), Vector3(6,13,6)][selected_building]
	var building := _add_box("Player building", pos, size, [Color.SANDY_BROWN, Color.STEEL_BLUE, Color.SLATE_GRAY][selected_building])
	buildings.append(building)
	coins -= costs[selected_building]
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
	if supplies < 15 or soldiers < 8:
		status_label.text = "You need 8 soldiers and 15 supplies to attack."
		return
	supplies -= 15
	var strength := soldiers + randi_range(-8, 8)
	if strength >= 20 + captured * 3:
		captured += 1
		soldiers = maxi(4, soldiers - 5)
		status_label.text = "Victory! You captured a neighbouring district."
	else:
		soldiers = maxi(2, soldiers - 8)
		status_label.text = "The invasion failed. Regroup and recruit more soldiers."
	_update_ui()

func _update_ui() -> void:
	if stats_label:
		stats_label.text = "Coins: %d\nSoldiers: %d\nSupplies: %d\nDistricts captured: %d/5" % [coins, soldiers, supplies, captured]
