extends Node
class_name CampaignDirector

signal territory_changed(territory_id: String, owner: String)
signal campaign_objective_completed(objective_id: String)

const SAVE_PATH := "user://campaign_state.json"
const PLAYER := "player"
const FACTIONS := ["north_union", "coastal_league", "highland_pact", "eastern_front", "southern_republic"]

var turn_number := 1
var active_campaign := "the_five_fronts"
var territories: Dictionary = {}
var factions: Dictionary = {}
var objectives: Array[Dictionary] = []

func _ready() -> void:
	if not load_campaign():
		start_new_campaign()

func start_new_campaign() -> void:
	turn_number = 1
	territories.clear()
	factions.clear()
	for i in range(FACTIONS.size()):
		var faction: String = FACTIONS[i]
		factions[faction] = {"coins": 1800, "food": 900, "strength": 60 + i * 7, "aggression": 0.35 + float(i) * 0.1, "relations": {}}
		territories["region_%02d" % i] = {"owner": faction, "neighbors": _neighbors_for(i), "value": 100 + i * 25, "fortification": 1, "population": 800 + i * 250}
	territories["capital"] = {"owner": PLAYER, "neighbors": ["region_00", "region_01"], "value": 500, "fortification": 3, "population": 5000}
	factions[PLAYER] = {"coins": 5000, "food": 1800, "strength": 100, "aggression": 0.5, "relations": {}}
	objectives = [
		{"id":"secure_north", "title":"Secure the northern frontier", "target":"region_00", "completed":false},
		{"id":"control_trade", "title":"Capture a trade region", "target":"region_02", "completed":false},
		{"id":"unify_fronts", "title":"Control three rival regions", "target":"", "completed":false}
	]
	save_campaign()

func _neighbors_for(index: int) -> Array[String]:
	var result: Array[String] = []
	result.append("capital")
	result.append("region_%02d" % ((index + 1) % FACTIONS.size()))
	result.append("region_%02d" % ((index + FACTIONS.size() - 1) % FACTIONS.size()))
	return result

func capture_territory(region_id: String, new_owner: String) -> bool:
	if not territories.has(region_id) or not factions.has(new_owner):
		return false
	territories[region_id]["owner"] = new_owner
	territories[region_id]["fortification"] = maxi(0, int(territories[region_id].get("fortification", 0)) - 1)
	territory_changed.emit(region_id, new_owner)
	_check_objectives()
	save_campaign()
	return true

func advance_turn() -> void:
	turn_number += 1
	for faction_id in factions:
		var data: Dictionary = factions[faction_id]
		data["coins"] = int(data.get("coins", 0)) + _territory_income(faction_id)
		data["food"] = int(data.get("food", 0)) + _territory_food(faction_id)
		factions[faction_id] = data
	for faction_id in FACTIONS:
		_run_rival_strategy(faction_id)
	save_campaign()

func _territory_income(faction_id: String) -> int:
	var total := 0
	for region in territories.values():
		if region.get("owner", "") == faction_id:
			total += int(region.get("value", 0)) / 5
	return total

func _territory_food(faction_id: String) -> int:
	var total := 0
	for region in territories.values():
		if region.get("owner", "") == faction_id:
			total += int(region.get("population", 0)) / 80
	return total

func _run_rival_strategy(faction_id: String) -> void:
	var owned: Array[String] = []
	for region_id in territories:
		if territories[region_id].get("owner", "") == faction_id:
			owned.append(region_id)
	if owned.is_empty():
		return
	var best_target := ""
	var best_score := -INF
	for region_id in territories:
		if territories[region_id].get("owner", "") == faction_id:
			continue
		var adjacent := false
		for home in owned:
			if region_id in territories[home].get("neighbors", []):
				adjacent = true
				break
		if not adjacent:
			continue
		var target: Dictionary = territories[region_id]
		var score := float(target.get("value", 0)) - float(target.get("fortification", 0)) * 35.0
		score += float(factions[faction_id].get("aggression", 0.5)) * 70.0
		if target.get("owner", "") == PLAYER:
			score += 12.0
		if score > best_score:
			best_score = score
			best_target = region_id
	if best_target == "":
		return
	var strength := int(factions[faction_id].get("strength", 0))
	var defense := 35 + int(territories[best_target].get("fortification", 0)) * 20
	if strength > defense and randf() < clampf(float(factions[faction_id].get("aggression", 0.5)), 0.1, 0.9):
		capture_territory(best_target, faction_id)
		factions[faction_id]["strength"] = maxi(20, strength - 12)

func _check_objectives() -> void:
	var player_regions := 0
	for region_id in territories:
		if territories[region_id].get("owner", "") == PLAYER and region_id != "capital":
			player_regions += 1
	for objective in objectives:
		if objective["completed"]:
			continue
		var done := false
		if objective["id"] == "unify_fronts":
			done = player_regions >= 3
		elif territories.has(objective["target"]):
			done = territories[objective["target"]].get("owner", "") == PLAYER
		if done:
			objective["completed"] = true
			campaign_objective_completed.emit(objective["id"])

func save_campaign() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"turn":turn_number, "campaign":active_campaign, "territories":territories, "factions":factions, "objectives":objectives}))

func load_campaign() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	turn_number = int(parsed.get("turn", 1))
	active_campaign = str(parsed.get("campaign", "the_five_fronts"))
	territories = parsed.get("territories", {})
	factions = parsed.get("factions", {})
	var loaded_objectives: Variant = parsed.get("objectives", [])
	objectives.clear()
	if loaded_objectives is Array:
		for item in loaded_objectives:
			if item is Dictionary:
				objectives.append(item)
	return not territories.is_empty()
