package main

import rl "vendor:raylib"

new_camera :: proc() -> ^rl.Camera2D {
	camera := new(rl.Camera2D)
	camera.rotation = 0
	camera.zoom = 1
	camera.offset = v2{WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2}
	return camera
}

camera_velocity: v2

camera_update :: proc(cam: ^rl.Camera2D, pos: v2, size: v2) {
	desired := v2{pos.x + size.x / 2, pos.y + size.y / 2}

	stiffness: f32 = 0.1
	damping: f32 = 0.5


	diff := desired - cam.target
	camera_velocity += diff * stiffness


	camera_velocity *= damping


	cam.target += camera_velocity
}
