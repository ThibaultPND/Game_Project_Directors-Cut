package main

import rl "vendor:raylib"
import "core:fmt"
MAX_SPRITES :: 256

Sprites_System :: struct {
	count:         int,
	positions:     [MAX_SPRITES]v2,
	scales:        [MAX_SPRITES]v2,
	textures:      [MAX_SPRITES]rl.Texture2D,
	visible:       [MAX_SPRITES]bool,
	//
	current_frame: [MAX_SPRITES]int,
	total_frame:   [MAX_SPRITES]int,
	//
	frame_timer:   [MAX_SPRITES]f32,
	frame_delay:   [MAX_SPRITES]f32,
	//
	frame_size:    [MAX_SPRITES]v2,
}

new_sprites_system :: proc() -> ^Sprites_System {
	return new(Sprites_System)
}

init_sprites_system :: proc() -> Sprites_System {
	ss: Sprites_System
	ss.count = 0
	return ss
}

sprites_add :: proc(
	ss: ^Sprites_System,
	position, scale: v2,
	texture: rl.Texture2D,
	frame_size: v2, // Dimensions
	max_frames: int, // Nombre d'images dans la texture
	frame_delay: f32, // Temps de l'animation
	visible: bool,
) -> int {
	if ss.count >= MAX_SPRITES do return -1

	index := ss.count

	ss.positions[index] = position
	ss.scales[index] = scale
	ss.textures[index] = texture
	ss.visible[index] = visible

	ss.current_frame[index] = 0
	ss.total_frame[index] = max_frames
	ss.frame_delay[index] = frame_delay
	ss.frame_timer[index] = 0.0

	ss.frame_size[index] = {frame_size.x, frame_size.y}

	ss.count += 1
	return index
}

sprites_update :: proc(ss: ^Sprites_System) {
	dt := rl.GetFrameTime()
	for i in 0 ..< ss.count {
		if !ss.visible[i] || ss.total_frame[i] <= 1 do continue

		ss.frame_timer[i] += dt
		if ss.frame_timer[i] >= ss.frame_delay[i] {
			ss.frame_timer[i] = 0
			if ss.current_frame[i] == ss.total_frame[i] - 1 {
				ss.visible[i] = false
				ss.current_frame[i] = 0
			} else {
				ss.current_frame[i] = (ss.current_frame[i] + 1) % ss.total_frame[i]
			}

		}
	}
}

sprites_draw :: proc(ss: ^Sprites_System) {
	for i in 0 ..< ss.count {
		if !ss.visible[i] do continue

		frame := ss.current_frame[i]
		pos := ss.positions[i]
		scale := ss.scales[i]
		tex := ss.textures[i]
		frame_size := ss.frame_size[i]

		source_rec := rl.Rectangle {
			x      = f32(f32(frame) * frame_size.x),
			y      = 0,
			width  = f32(frame_size.x),
			height = f32(frame_size.y),
		}
		dest_rec := rl.Rectangle {
			x      = pos.x,
			y      = pos.y,
			width  = f32(frame_size.x) * scale.x,
			height = f32(frame_size.y) * scale.y,
		}
		origin := rl.Vector2{0, 0}
		rl.DrawTexturePro(tex, source_rec, dest_rec, origin, 0.0, rl.WHITE)
	}
}