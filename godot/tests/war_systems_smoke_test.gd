extends SceneTree

const CampaignScript = preload("res://scripts/campaign_director.gd")
const BattlefieldScript = preload("res://scripts/battlefield_systems.gd")

func _initialize() -> void:
	call_deferred("_run_tests")

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("WAR SYSTEM TEST FAILED: " + message)
		quit(1)

func _run_tests() -> void:
	var campaign = CampaignScript.new()
	root.add_child(campaign)
	campaign.start_new_campaign()
	_check(campaign.turn_number == 1, "campaign starts at turn one")
	_check(campaign.territories.size() >= 6, "campaign creates capital and rival regions")
	campaign.advance_turn()
	_check(campaign.turn_number == 2, "campaign turn advances and rival AI executes")
	_check(campaign.factions.has("north_union"), "rival faction state exists")
	_check(campaign.capture_territory("region_00", "player"), "player can capture a region")
	_check(campaign.territories["region_00"]["owner"] == "player", "captured territory ownership persists in state")

	var battlefield = BattlefieldScript.new()
	root.add_child(battlefield)
	var path: PackedVector3Array = battlefield.find_path(Vector3(-12, 0, 0), Vector3(12, 0, 0))
	_check(path.size() > 1, "A-star returns a route across the battle map")
	battlefield.set_obstacle(Vector3(0, 0, 0), true)
	var detour: PackedVector3Array = battlefield.find_path(Vector3(-12, 0, 0), Vector3(12, 0, 0))
	_check(detour.size() > 1, "A-star routes around a blocked cell")
	var avoided_block := true
	for point in detour:
		if battlefield.world_to_cell(point) == Vector2i.ZERO:
			avoided_block = false
	_check(avoided_block, "A-star does not route through the blocked cell")

	var squad: Array[Node3D] = []
	for index in range(6):
		var soldier := Node3D.new()
		root.add_child(soldier)
		squad.append(soldier)
	battlefield.apply_formation(squad, Vector3(-10, 0, 0), Vector3.RIGHT, BattlefieldScript.Formation.WEDGE, 2.0)
	_check(squad[0].has_meta("formation_destination"), "wedge formation assigns unit destinations")

	var game_scene := load("res://Main.tscn") as PackedScene
	_check(game_scene != null, "main game scene loads")
	var game := game_scene.instantiate()
	root.add_child(game)
	_check(is_instance_valid(game.campaign_director), "campaign director is connected to main game")
	_check(is_instance_valid(game.battlefield_systems), "battlefield systems are connected to main game")
	game._advance_campaign_turn()
	_check(game.campaign_director.turn_number >= 2, "main UI campaign turn action works")
	game._start_battle()
	_check(game.battle_active, "main game starts a battle")
	_check(game.battle_units.size() > 0, "battle spawns combat units")
	game._set_battle_order("hold")
	_check(game.battle_order == "hold", "battle hold order is accepted")
	game._set_battle_order("advance")
	_check(game.battle_order == "advance", "battle advance order is accepted")
	game._finish_battle(false)
	_check(not game.battle_active, "battle can finish and return to city")
	print("WAR SYSTEM SMOKE TESTS PASSED")
	quit(0)
