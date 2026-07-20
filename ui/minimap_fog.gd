extends Node

const FOG_SIZE = 512
const WORLD_SIZE = 500.0 # 500 meters across
const REVEAL_RADIUS = 25.0 # 25 meters radius

var _fog_image: Image
var _fog_texture: ImageTexture
var _last_update_pos: Vector2

func _ready() -> void:
	# Create a fully opaque white image (white = fog, black = clear)
	_fog_image = Image.create(FOG_SIZE, FOG_SIZE, false, Image.FORMAT_L8)
	_fog_image.fill(Color.WHITE)
	_fog_texture = ImageTexture.create_from_image(_fog_image)
	_last_update_pos = Vector2(-9999, -9999)
	
func get_texture() -> Texture2D:
	return _fog_texture
	
func update_fog(player_pos: Vector3) -> void:
	# Map world position to image coordinates
	# Assuming world (0,0) is center of image (256, 256)
	var px = int((player_pos.x / WORLD_SIZE) * FOG_SIZE + (FOG_SIZE / 2.0))
	var py = int((player_pos.z / WORLD_SIZE) * FOG_SIZE + (FOG_SIZE / 2.0))
	
	var current_pos = Vector2(px, py)
	if current_pos.distance_to(_last_update_pos) < 2.0:
		return # Optimization: don't update if haven't moved enough
		
	_last_update_pos = current_pos
	
	var pixel_radius = int((REVEAL_RADIUS / WORLD_SIZE) * FOG_SIZE)
	
	# Draw a soft anti-aliased circle
	var r_sq = pixel_radius * pixel_radius
	var r_inner_sq = (pixel_radius * 0.4) * (pixel_radius * 0.4)
	
	for y in range(max(0, py - pixel_radius), min(FOG_SIZE, py + pixel_radius)):
		for x in range(max(0, px - pixel_radius), min(FOG_SIZE, px + pixel_radius)):
			var dx = x - px
			var dy = y - py
			var dist_sq = dx*dx + dy*dy
			if dist_sq < r_sq:
				var current_val = _fog_image.get_pixel(x, y).r
				var paint_val = 0.0
				
				if dist_sq > r_inner_sq:
					# Gradient edge
					var dist = sqrt(float(dist_sq))
					var factor = (dist - (pixel_radius * 0.4)) / (pixel_radius * 0.6)
					paint_val = factor
					
				# Only darken, never lighten
				if paint_val < current_val:
					_fog_image.set_pixel(x, y, Color(paint_val, paint_val, paint_val, 1.0))
					
	_fog_texture.update(_fog_image)
