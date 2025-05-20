package main

import "core:fmt"
import rl "vendor:raylib"

EPSILON :: 0.01

// Collide rect and mouse
cord_over_rect :: proc(pos: v2, rect: rl.Rectangle) -> bool {
	return(
		rect.x < pos.x &&
		rect.x + rect.width > pos.x &&
		rect.y < pos.y &&
		pos.y < rect.y + rect.height \
	)
}

// Collide rect and rect
rects_overlap :: proc(a, b: rl.Rectangle) -> bool {
	return(
		a.x <= b.x + b.width &&
		a.x + a.width >= b.x &&
		a.y <= b.y + b.height &&
		a.y + a.height >= b.y \
	)
}
rectangles_overlap_x :: proc(pos1, size1, pos2, size2: v2) -> bool {
	return pos1.x < pos2.x + size2.x && pos1.x + size1.x > pos2.x
}

rectangles_overlap_y :: proc(pos1, size1, pos2, size2: v2) -> bool {
	return pos1.y < pos2.y + size2.y && pos1.y + size1.y > pos2.y
}


// distance btw 2 pts
dist :: proc(x, y, x2, y2: i32) -> i32 {
	return abs(y2 - y) + abs(x2 - x)
}

// Fonction de lerp
lerp :: proc(a, b, t: f32) -> f32 {
	return a + t * (b - a)
}

// signe d'un flotant
sign_f32 :: proc(x: f32) -> f32 {
	if x > 0.0 {return 1.0}
	if x < 0.0 {return -1.0}
	return 0.0
}

draw_rect_outline :: proc(pos: v2, size: v2, color: rl.Color) {
	pos := pos
	size := size
	rl.DrawLine(i32(pos.x), i32(pos.y), i32(pos.x) + i32(size.x), i32(pos.y), color) // haut
	rl.DrawLine(
		i32(pos.x) + i32(size.x),
		i32(pos.y),
		i32(pos.x) + i32(size.x),
		i32(pos.y) + i32(size.y),
		color,
	) // droite
	rl.DrawLine(
		i32(pos.x) + i32(size.x),
		i32(pos.y) + i32(size.y),
		i32(pos.x),
		i32(pos.y) + i32(size.y),
		color,
	) // bas
	rl.DrawLine(i32(pos.x), i32(pos.y) + i32(size.y), i32(pos.x), i32(pos.y), color) // gauche
}
