package main

import rl "vendor:raylib"
MAX_SPRITES :: 100

Sprite_System :: struct {
	positions:     [MAX_SPRITES]v2,
	scales:        [MAX_SPRITES]v2,
	current_frame: [MAX_SPRITES]int,
	total_frame:   [MAX_SPRITES]int,
	visible:       [MAX_SPRITES]bool,
	textures:      [MAX_SPRITES]rl.Texture2D,
	count:         int,
}

new_sprite_system :: proc() -> ^Sprite_System {
	return new(Sprite_System)
}

sprites_add :: proc(
	ss: ^Sprite_System,
	position, scale: v2,
	texture: rl.Texture2D,
	max_frames: int,
	visible: bool,
) -> int {
	ss.positions[ss.count] = position
	ss.scales[ss.count] = scale
	ss.total_frame[ss.count] = max_frames
	ss.visible[ss.count] = visible
	ss.textures[ss.count] = texture

	ss.count += 1
	return ss.count
}

sprites_update :: proc(ss: ^Sprite_System) {
	for i in 0 ..< ss.count {
		if ss.visible[i] {
			ss.current_frame[i] = (ss.current_frame[i] + 1) % ss.total_frame[i]
		}
	}
}

sprites_draw :: proc(ss: ^Sprite_System) {
	for i in 0 ..< ss.count {
		if ss.visible[i] {
			frame := ss.current_frame[i]
			pos := ss.positions[i]
			scale := ss.scales[i]
			tex := ss.textures[i]

			frame_width := int(tex.width) / 5 // ! Changer
			source_rec := rl.Rectangle {
				x      = f32(frame * frame_width),
				y      = 0,
				width  = f32(frame_width),
				height = f32(tex.height),
			}
			dest_rec := rl.Rectangle {
				x      = pos.x,
				y      = pos.x,
				width  = f32(tex.width) * scale.x,
				height = f32(tex.height) * scale.y,
			}
			origin := v2{0, 0}
			rl.DrawTexturePro(tex, source_rec, dest_rec, origin, 0, rl.WHITE)
		}
	}
}
