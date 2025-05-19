package main

import "core:fmt"
import rl "vendor:raylib"

MAX_ENTITIES :: 100

Entity_Pos :: [MAX_ENTITIES]v2
Entity_Speed :: [MAX_ENTITIES]f32
Entity_Size :: [MAX_ENTITIES]v2
Entity_Dir :: [MAX_ENTITIES]v2
Entity_Color :: [MAX_ENTITIES]rl.Color

// ? Est-ce que je dois garder une entité si elle n'est plus affiché ?
// * Entity_Active :: [MAX_ENTITIES]bool 

Entities_System :: struct {
	pos:      [MAX_ENTITIES]v2,
	size:     [MAX_ENTITIES]v2,
	dir:      [MAX_ENTITIES]v2,
	speed:    [MAX_ENTITIES]f32,
	color:    [MAX_ENTITIES]rl.Color,
	active:   [MAX_ENTITIES]bool,
	tag:      [MAX_ENTITIES]Entity_Tag,
	userdata: [MAX_ENTITIES]rawptr,
	count:    int,
}
Entity_Tag :: enum {
	PLAYER,
	ENEMY,
	NPC,
}

new_entities_system :: proc() -> ^Entities_System {
	es := new(Entities_System)
	return es
}

add_entity :: proc(
	es: ^Entities_System,
	pos, size: v2,
	speed: f32,
	color: rl.Color,
	tag: Entity_Tag,
) -> i32 {
	index := es.count
	es.count += 1

	es.pos[index] = pos
	es.size[index] = size
	es.speed[index] = 300.0
	es.color[index] = color
	es.tag[index] = tag
	es.active[index] = true
	es.userdata[index] = nil

	return i32(es.count - 1)
}

entity_update :: proc(es: ^Entities_System) {
	dt := rl.GetFrameTime()

	for i in 0 ..< es.count {
		delta := rl.Vector2Normalize(es.dir[i]) * (es.speed[i] * dt)

		delta = manage_colide(es, delta, i)

		es.pos[i] += delta
	}
}

manage_colide :: proc(es: ^Entities_System, delta: v2, index: int) -> v2 {
	delta := delta
	if delta.x != 0 {
		for j in 0 ..< es.count {
			if index == j do continue

			if !overlap_y(es, index, j) do continue

			if delta.x > 0 {
				dist := es.pos[j].x - (es.pos[index].x + es.size[index].x)
				if dist >= 0 {
					delta.x = min(delta.x, dist)
				}
			} else {
				dist := (es.pos[j].x + es.size[j].x) - es.pos[index].x
				if dist <= 0 {
					delta.x = max(delta.x, dist)
				}
			}
		}
	}


	if delta.y != 0 {
		for j in 0 ..< es.count {
			if index == j do continue

			if !overlap_x(es, index, j) do continue

			if delta.y > 0 {
				dist := es.pos[j].y - (es.pos[index].y + es.size[index].y)
				if dist >= 0 {
					delta.y = min(delta.y, dist)
				}
			} else {
				dist := (es.pos[j].y + es.size[j].y) - es.pos[index].y
				if dist <= 0 {
					delta.y = max(delta.y, dist)
				}
			}
		}
	}
	return delta
}

overlap_x :: proc(es: ^Entities_System, i, j: int) -> bool {
	return es.pos[i].x + es.size[i].x > es.pos[j].x && es.pos[i].x < es.pos[j].x + es.size[j].x
}

overlap_y :: proc(es: ^Entities_System, i, j: int) -> bool {
	return es.pos[i].y + es.size[i].y > es.pos[j].y && es.pos[i].y < es.pos[j].y + es.size[j].y
}

entity_draw :: proc(es: ^Entities_System) {
	for i in 0 ..< es.count {
		if !es.active[i] do continue
		rl.DrawRectangleV(es.pos[i], es.size[i], es.color[i])
	}
}
