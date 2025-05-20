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

entity_update :: proc(es: ^Entities_System, rs: ^Room_System) {
	dt := rl.GetFrameTime()

	for i in 0 ..< es.count {
		delta := rl.Vector2Normalize(es.dir[i]) * (es.speed[i] * dt)

		delta = manage_colide(es, rs, delta, i)

		es.pos[i] += delta
	}
}

manage_colide :: proc(es: ^Entities_System, rs: ^Room_System, delta: v2, index: int) -> v2 {
	delta := delta

	active_room := rs.active_room_id

	layout := rs.templates[rs.instances[active_room].template_id].layout
	room_pos := rs.instances[active_room].position
	entity_pos := es.pos[index]
	entity_size := es.size[index]


	tile_size := v2{TILE_SIZE, TILE_SIZE}
	tile_w := layout.width
	tile_h := layout.height

	// Convertit la position du rectangle en indices de tuiles
	start_x := int(clamp(((entity_pos.x - room_pos.x) / TILE_SIZE) - 1, 0, f32(tile_w) - 1))
	end_x := int(
		clamp(((entity_pos.x + entity_size.x - room_pos.x) / TILE_SIZE) + 1, 0, f32(tile_w) - 1),
	)

	start_y := int(clamp(((entity_pos.y - room_pos.y) / TILE_SIZE) - 1, 0, f32(tile_h) - 1))
	end_y := int(
		clamp(((entity_pos.y + entity_size.y - room_pos.y) / TILE_SIZE) + 1, 0, f32(tile_h) - 1),
	)

	if delta.x != 0 {
		for j in 0 ..< es.count {
			if index == j do continue

			if !entity_overlap_y(es, index, j) do continue

			if delta.x > 0 {
				dist := es.pos[j].x - (entity_pos.x + entity_size.x)
				if dist >= 0 {
					delta.x = min(delta.x, dist)
				}
			} else {
				dist := (es.pos[j].x + es.size[j].x) - entity_pos.x
				if dist <= 0 {
					delta.x = max(delta.x, dist)
				}
			}
		}
		count := 0
		test_entity_pos := entity_pos + v2{delta.x, 0}
		for y in start_y ..= end_y {
			for x in start_x ..= end_x {
				count += 1
				tile := layout.tiles[y * tile_w + x]
				if tile.type != .WALL do continue

				tile_pos := room_pos + v2{f32(x * TILE_SIZE), f32(y * TILE_SIZE)}

				if !rl.CheckCollisionRecs(
					rl.Rectangle {
						x = test_entity_pos.x,
						y = test_entity_pos.y,
						width = entity_size.x,
						height = entity_size.y,
					},
					rl.Rectangle {
						x = tile_pos.x,
						y = tile_pos.y,
						width = TILE_SIZE,
						height = TILE_SIZE,
					},
				) {
					//fmt.println("No colide...")
					continue
				}
				dist: f32
				if delta.x > 0 {
					dist = tile_pos.x - (test_entity_pos.x + entity_size.x)
				} else {
					dist = (tile_pos.x + TILE_SIZE) - test_entity_pos.x
				}
				if dist >= 0 {
					delta.x = clamp(delta.x, 0, dist)
				} else {
					delta.x = clamp(delta.x, dist, 0)
				}
				if abs(delta.x) < EPSILON {
					delta.x = 0.0
				}
				fmt.printfln(
					"Colide on x ! : \nPlayer : %.2f\nTile   : %.2f",
					test_entity_pos.x,
					tile_pos.x,
				)
				fmt.printfln("  -> New delta.x = %f", delta.x)
			}
		}
		//fmt.printfln("Count = %d", count)
	}


	if delta.y != 0 {
		for j in 0 ..< es.count {
			if index == j do continue

			if !entity_overlap_x(es, index, j) do continue

			if delta.y > 0 {
				dist := es.pos[j].y - (entity_pos.y + entity_size.y)
				if dist >= 0 {
					delta.y = min(delta.y, dist)
				}
			} else {
				dist := (es.pos[j].y + es.size[j].y) - entity_pos.y
				if dist <= 0 {
					delta.y = max(delta.y, dist)
				}
			}
		}
		test_entity_pos := entity_pos + v2{0, delta.y}
		for y in start_y ..= end_y {
			for x in start_x ..= end_x {
				tile := layout.tiles[y * tile_w + x]
				if tile.type != .WALL do continue

				tile_pos := room_pos + v2{f32(x * TILE_SIZE), f32(y * TILE_SIZE)}

				if !rl.CheckCollisionRecs(
					rl.Rectangle {
						x = test_entity_pos.x,
						y = test_entity_pos.y,
						width = entity_size.x,
						height = entity_size.y,
					},
					rl.Rectangle {
						x = tile_pos.x,
						y = tile_pos.y,
						width = TILE_SIZE,
						height = TILE_SIZE,
					},
				) {
					continue
				}

				dist: f32
				if delta.y > 0 {
					dist = tile_pos.y - (test_entity_pos.y + entity_size.y)
				} else {
					dist = (tile_pos.y + TILE_SIZE) - test_entity_pos.y
				}
				if dist >= 0 {
					delta.y = clamp(delta.y, 0, dist)
				} else {
					delta.y = clamp(delta.y, dist, 0)
				}
				if abs(delta.x) < EPSILON {
					delta.x = 0
				}
			}
		}
	}
	return delta
}

entity_overlap_x :: proc(es: ^Entities_System, i, j: int) -> bool {
	return es.pos[i].x + es.size[i].x > es.pos[j].x && es.pos[i].x < es.pos[j].x + es.size[j].x
}

entity_overlap_y :: proc(es: ^Entities_System, i, j: int) -> bool {
	return es.pos[i].y + es.size[i].y > es.pos[j].y && es.pos[i].y < es.pos[j].y + es.size[j].y
}

entity_draw :: proc(es: ^Entities_System) {
	for i in 0 ..< es.count {
		if !es.active[i] do continue
		rl.DrawRectangleV(es.pos[i], es.size[i], es.color[i])
	}
}
draw_collision_tiles :: proc(start_x: int, end_x: int, start_y: int, end_y: int, room_pos: v2) {
	for y in start_y ..= end_y {
		for x in start_x ..= end_x {
			tile_pos := room_pos + v2{f32(x * TILE_SIZE), f32(y * TILE_SIZE)}
			draw_rect_outline(tile_pos, v2{TILE_SIZE, TILE_SIZE}, rl.RED)
		}
	}
}
