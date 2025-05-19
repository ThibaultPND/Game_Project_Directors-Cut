package main

import rl "vendor:raylib"

Camera_System :: struct {
	camera:    rl.Camera2D,
	velocity:  v2,
	stiffness: f32,
	damping:   f32,
}

new_camera :: proc() -> ^Camera_System {
	cs := new(Camera_System)
	cs.camera.rotation = 0
	cs.camera.zoom = 1
	cs.camera.offset = v2{WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2}

	cs.velocity = v2{0, 0}
	cs.stiffness = 0.1
	cs.damping = 0.5

	return cs
}

camera_velocity: v2

camera_update :: proc(cs: ^Camera_System, target_rect: rl.Rectangle) {
	desired := v2{target_rect.x + target_rect.width / 2, target_rect.y + target_rect.height / 2}

	stiffness: f32 = 0.1
	damping: f32 = 0.5


	diff := desired - cs.camera.target
	camera_velocity += diff * stiffness


	camera_velocity *= damping


	cs.camera.target += camera_velocity
}
