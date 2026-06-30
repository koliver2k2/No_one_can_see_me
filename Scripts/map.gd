#extends TileMapLayer
#
#class DoorInfo:
	#var source_id: int
	#var atlas_coords: Vector2i
	#var closed_alt: int
	#var open_alt: int
	#var is_open: bool = false
#
#var doors: Dictionary = {} # Vector2i -> DoorInfo
#var player: Node2D = null
#
#const DETECTION_RADIUS := 30.0
#const OCCLUSION_LAYER_INDEX := 0
#
#func _ready():
	#for cell_pos in get_used_cells():
		#var tile_data = get_cell_tile_data(cell_pos)
		#if not tile_data:
			#continue
#
		#var name_data = tile_data.get_custom_data("door")
		#if name_data is String and "door" in name_data:
			#var info = DoorInfo.new()
			#info.source_id = get_cell_source_id(cell_pos)
			#info.atlas_coords = get_cell_atlas_coords(cell_pos)
			#info.closed_alt = get_cell_alternative_tile(cell_pos)
			#info.open_alt = _get_or_create_open_alt(info.source_id, info.atlas_coords, info.closed_alt)
			#doors[cell_pos] = info
#
	#_find_player()
#
#func _get_or_create_open_alt(source_id: int, atlas_coords: Vector2i, closed_alt: int) -> int:
	#var source := tile_set.get_source(source_id) as TileSetAtlasSource
	#if not source:
		#return closed_alt
#
	#for i in source.get_alternative_tiles_count(atlas_coords):
		#var alt_id = source.get_alternative_tile_id(atlas_coords, i)
		#if alt_id == closed_alt:
			#continue
		#var alt_data = source.get_tile_data(atlas_coords, alt_id)
		#if alt_data and alt_data.get_occluder(OCCLUSION_LAYER_INDEX) == null:
			#return alt_id
#
	#return source.create_alternative_tile(atlas_coords)
#
#func _process(_delta):
	#if not player:
		#return
#
	#for door_pos in doors:
		#var info: DoorInfo = doors[door_pos]
		#var world_pos = map_to_local(door_pos)
		#var is_near = player.global_position.distance_to(world_pos) < DETECTION_RADIUS
#
		#if is_near != info.is_open:
			#info.is_open = is_near
			#var alt = info.open_alt if is_near else info.closed_alt
			#set_cell(door_pos, info.source_id, info.atlas_coords, alt)
#
#func _find_player() -> void:
	#var players = get_tree().get_nodes_in_group("player")
	#if players.size() > 0:
		#player = players[0]
	#else:
		#push_warning("NPC couldn't find a player node in the 'player' group!")
