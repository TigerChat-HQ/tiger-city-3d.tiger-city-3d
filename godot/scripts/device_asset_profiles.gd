extends RefCounted
class_name DeviceAssetProfiles

enum Tier { LOW, MEDIUM, HIGH }

static func choose_tier(memory_mb: int, screen_width: int, screen_height: int) -> Tier:
	if memory_mb > 0 and memory_mb < 3000:
		return Tier.LOW
	if memory_mb >= 6000 and maxi(screen_width, screen_height) >= 2000:
		return Tier.HIGH
	return Tier.MEDIUM

static func texture_candidates(base_path: String, tier: Tier) -> PackedStringArray:
	var suffix := "1k"
	match tier:
		Tier.LOW:
			suffix = "256"
		Tier.MEDIUM:
			suffix = "512"
		Tier.HIGH:
			suffix = "1k"
	var extension := base_path.get_extension()
	var stem := base_path.trim_suffix("." + extension)
	return PackedStringArray([stem + "_" + suffix + "." + extension, stem + "." + extension])

static func load_texture_variant(base_path: String, tier: Tier) -> Texture2D:
	for candidate in texture_candidates(base_path, tier):
		if ResourceLoader.exists(candidate):
			var resource: Resource = load(candidate)
			if resource is Texture2D:
				return resource
	return null

static func apply_lod_visibility(root: Node3D, distance: float, low_distance: float = 40.0, mid_distance: float = 90.0) -> void:
	if not is_instance_valid(root):
		return
	for child in root.get_children():
		if child is GeometryInstance3D:
			if distance > mid_distance:
				child.visibility_range_end = mid_distance
			elif distance > low_distance:
				child.visibility_range_end = mid_distance * 1.5
			else:
				child.visibility_range_end = 0.0
