# Run this once as a tool script to generate and save the texture
@tool
extends EditorScript

func _run():
	var size = 256
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var tip_x = size / 2.0
	var tip_y = 0.0
	var half_angle_deg = 35.0  # adjust for wider/narrower cone
	var half_angle_rad = deg_to_rad(half_angle_deg)
	
	for y in range(size):
		for x in range(size):
			var dx = x - tip_x
			var dy = float(y) - tip_y
			
			if dy <= 0:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			
			var angle = abs(atan2(dx, dy))
			if angle > half_angle_rad:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				# Fade brightness with distance from tip
				var dist_falloff = 1.0 - (dy / size)
				var angle_falloff = 1.0 - (angle / half_angle_rad)
				var alpha = dist_falloff * angle_falloff
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	var texture = ImageTexture.create_from_image(image)
	ResourceSaver.save(texture, "res://street_light_cone.png")
