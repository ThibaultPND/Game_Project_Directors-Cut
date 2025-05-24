package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

//
// Constantes
//
TILE_SIZE :: 64
MAX_ROOM_TEMPLATE :: 8
MAX_ACTIVE_ROOM :: 10

//
// Énumérations
//
Tile_Type :: enum {
	EMPTY,
	WALL,
	FLOOR,
	DOOR,
	OBJECT,
}

//
// Structures de base
//
Tile :: struct {
	type:   Tile_Type,
	tex_id: int,
	data:   rawptr,
}

Room_Layout :: struct {
	width, height: int,
	tiles:         []Tile,
}

Room_Template :: struct {
	id:             int,
	layout:         Room_Layout,
	door_positions: [dynamic]v2, // NORTH > EAST > WEST > SOUTH
}

Room_Instance :: struct {
	template_id:       int,
	position:          v2,
	visited:           bool,
	active:            bool,
	enemie_alive:      int,
	objects_collected: int,
}

Room_Connection :: struct {
	from_room:       int,
	from_door_index: int,
	to_room:         int,
	to_door_index:   int,
}

Room_System :: struct {
	tile_tex:       rl.Texture2D,
	templates:      [MAX_ROOM_TEMPLATE]Room_Template,
	instances:      [MAX_ACTIVE_ROOM]Room_Instance,
	connections:    [dynamic]Room_Connection,
	template_count: int,
	instance_count: int,
	active_room_id: int,
}

//
// Initialisation
//
room_init :: proc() -> ^Room_System {
	rs := new(Room_System)
	rs.tile_tex = rl.LoadTexture("assets/tileset2.png")

	room0 := load_room_from_png(rs, "assets/piece1.png", v2{0, 0})
	room1 := load_room_from_png(rs, "assets/piece2.png", v2{1, 0})

	room_connect(rs, room0, 2, room1, 0)

	rs.active_room_id = room0
	rs.instances[room0].active = true

	return rs
}

quit_room_systme :: proc(rs: ^Room_System) {
	rl.UnloadTexture(rs.tile_tex)
	free(rs)
}
//
// Mise à jour logique des salles
//
room_update :: proc(rs: ^Room_System, player_pos: ^v2) {
	for i in 0 ..< rs.instance_count {
		room := &rs.instances[i]
		template := rs.templates[room.template_id]
		layout := template.layout
		local_pos := player_pos^ - room.position
		current_tile_id := get_tile_id_from_position(local_pos, layout.width)
		fmt.printfln(
			"La tuile actuelle est : %d , door = %d",
			layout.tiles[current_tile_id].type,
			Tile_Type.DOOR,
		)
		if room.active {
			room.visited = true

			if layout.tiles[current_tile_id].type == .DOOR {
				for conn in rs.connections {
					if conn.from_room == i &&
					   conn.from_door_index == get_door_id(layout.tiles, current_tile_id) {
						// * Changement de salle
						rs.instances[i].active = false
						next_room := &rs.instances[conn.to_room]
						next_room.active = true
						rs.active_room_id = conn.to_room

						target_template := rs.templates[next_room.template_id]
						door_pos := target_template.door_positions[conn.to_door_index]
						player_pos^ =
							next_room.position +
							(door_pos + get_floor_offset_from_door(door_pos, layout)) * TILE_SIZE
						return
					}
				}
			}

		}
	}
}
//
// Rendu visuel des salles
//
room_draw :: proc(rs: ^Room_System, entity_pos: v2) {
	active := &rs.instances[rs.active_room_id]
	template := &rs.templates[active.template_id]
	layout := &template.layout
	for y in 0 ..< layout.height {
		for x in 0 ..< layout.width {
			tile := layout.tiles[y * layout.width + x]
			pos := v2 {
				active.position.x + f32(x * TILE_SIZE),
				active.position.y + f32(y * TILE_SIZE),
			}
			draw_tile(rs.tile_tex, tile.tex_id, pos, 1.0)
		}
	}
}

//
// Chargement de salle depuis image PNG
//
load_room_from_png :: proc(rs: ^Room_System, path: cstring, pos: v2) -> int {
	image := rl.LoadImage(path)
	defer rl.UnloadImage(image)

	width := int(image.width)
	height := int(image.height)
	pixels := rl.LoadImageColors(image)
	defer rl.UnloadImageColors(pixels)

	tiles := make([]Tile, width * height)
	doors := [dynamic]v2{}

	for y in 0 ..< height {
		for x in 0 ..< width {
			idx := y * width + x
			pxl := pixels[idx]
			tex_id := pxl.r / 16
			tile_type := tex_id_to_tile_type(int(tex_id))
			tiles[idx].type = tile_type
			tiles[idx].tex_id = int(tex_id)

			if tile_type == .DOOR {
				append(&doors, v2{f32(x), f32(y)})
			}
		}
	}

	template_id := rs.template_count
	rs.template_count += 1

	rs.templates[template_id] = Room_Template {
		id = template_id,
		layout = Room_Layout{width = width, height = height, tiles = tiles},
		door_positions = doors,
	}

	instance_id := rs.instance_count
	rs.instance_count += 1

	rs.instances[instance_id] = Room_Instance {
		template_id       = template_id,
		position          = pos,
		visited           = false,
		active            = false,
		enemie_alive      = 0,
		objects_collected = 0,
	}

	return instance_id
}

//
// Conversion couleur -> type de tile
//
tex_id_to_tile_type :: proc(id: int) -> Tile_Type {
	if id == 15 do return .EMPTY
	if id > 2 do return .WALL
	if id == 0 do return .FLOOR
	if id < 3 do return .DOOR
	return .OBJECT
}

//
// Connexion entre salles
//
room_connect :: proc(rs: ^Room_System, from_room, from_door, to_room, to_door: int) {
	append(
		&rs.connections,
		Room_Connection {
			from_room = from_room,
			from_door_index = from_door,
			to_room = to_room,
			to_door_index = to_door,
		},
	)
	append(
		&rs.connections,
		Room_Connection {
			from_room = to_room,
			from_door_index = to_door,
			to_room = from_room,
			to_door_index = from_door,
		},
	)
}

//
// Changement de salle par une porte
//
room_try_change :: proc(rs: ^Room_System, door_position: v2) {
	active_id := rs.active_room_id

	for conn in rs.connections {
		if conn.from_room == active_id {
			template := rs.templates[rs.instances[active_id].template_id]
			if door_position == template.door_positions[conn.from_door_index] {
				rs.instances[active_id].active = false
				rs.instances[conn.to_room].active = true
				rs.active_room_id = conn.to_room
				break
			}
		}
	}
}

draw_tile :: proc(tex: rl.Texture2D, tile_id: int, screen_pos: v2, scale: f32) {
	source_size := v2{TILE_SIZE / 4, TILE_SIZE / 4}
	tiles_per_row := int(tex.width / i32(source_size.x))
	frame_x := tile_id % tiles_per_row
	frame_y := tile_id / tiles_per_row

	source := rl.Rectangle {
		x      = f32(frame_x) * source_size.x,
		y      = f32(frame_y) * source_size.y,
		width  = source_size.x,
		height = source_size.y,
	}
	dest := rl.Rectangle {
		x      = screen_pos.x,
		y      = screen_pos.y,
		width  = TILE_SIZE * scale,
		height = TILE_SIZE * scale,
	}
	origin := v2{0, 0}
	rl.DrawTexturePro(tex, source, dest, origin, 0.0, rl.WHITE)
}

get_tile_id_from_position :: proc(player_pos: v2, room_width: int) -> int {
	tile_x := int(player_pos.x + 15) / TILE_SIZE
	tile_y := int(player_pos.y + 15) / TILE_SIZE
	return tile_y * room_width + tile_x
}


get_door_id :: proc(tiles: []Tile, tile_id: int) -> int {
	count := 0
	for i in 0 ..< tile_id {
		if tiles[i].type == .DOOR {
			count += 1
		}
	}
	return count
}

get_floor_offset_from_door :: proc(door_pos: v2, layout: Room_Layout) -> v2 {
	x := int(door_pos.x)
	y := int(door_pos.y)
	width := layout.width
	height := layout.height
	tiles := layout.tiles

	offsets := [4]v2 {
		v2{0, -1}, // nord
		v2{1, 0}, // est
		v2{0, 1}, // sud
		v2{-1, 0}, // ouest
	}

	for offset in offsets {
		nx := x + int(offset.x)
		ny := y + int(offset.y)

		if nx < 0 || ny < 0 || nx >= width || ny >= height {
			continue
		}

		index := ny * width + nx
		if tiles[index].type == .FLOOR {
			return offset
		}
	}

	return v2{0, 0} // Aucun sol trouvé autour
}
