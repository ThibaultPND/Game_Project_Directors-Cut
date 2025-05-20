package main

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
	type: Tile_Type,
	data: rawptr,
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

	room0 := load_room_from_png(rs, "assets/piece1.png", v2{0, 0})
	room1 := load_room_from_png(rs, "assets/piece1.png", v2{1, 0})

	room_connect(rs, room0, 1, room1, 2)

	rs.active_room_id = 0
	rs.instances[0].active = true

	return rs
}

//
// Mise à jour logique des salles
//
room_update :: proc(rs: ^Room_System) {
	for i in 0 ..< rs.instance_count {
		room := &rs.instances[i]
		if room.active {
			room.visited = true

			if room.enemie_alive <= 0 {
				// Exemple de logique supplémentaire ici
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

			switch tile.type {
			case .WALL:
				rl.DrawRectangle(i32(pos.x), i32(pos.y), TILE_SIZE, TILE_SIZE, rl.DARKGRAY)
			case .FLOOR:
				rl.DrawRectangle(i32(pos.x), i32(pos.y), TILE_SIZE, TILE_SIZE, rl.LIGHTGRAY)
			case .DOOR:
				rl.DrawRectangle(i32(pos.x), i32(pos.y), TILE_SIZE, TILE_SIZE, rl.BROWN)
			case .OBJECT:
				rl.DrawCircleV(pos + TILE_SIZE / 2, TILE_SIZE / 4, rl.GOLD)
			case .EMPTY:
			// Ne rien dessiner
			}
		}
	}
	room_pos := rs.instances[rs.active_room_id].position
	layout_ := rs.templates[rs.instances[rs.active_room_id].template_id].layout
	tile_w := f32(layout_.width)
	tile_h := f32(layout_.height)

	start_x: f32 = clamp(((entity_pos.x - room_pos.x) / TILE_SIZE) - 1, 0, tile_w - 1)
	end_x: f32 = clamp(((entity_pos.x + 128 - room_pos.x) / TILE_SIZE) + 1, 0, tile_w - 1)

	start_y := clamp(((entity_pos.y - room_pos.y) / TILE_SIZE) - 1, 0, tile_h - 1)
	end_y := clamp(((entity_pos.y + 128 - room_pos.y) / TILE_SIZE) + 1, 0, tile_h - 1)

	draw_collision_tiles(int(start_x), int(end_x), int(start_y), int(end_y), room_pos)
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
			tile_type := color_to_tile_type(pixels[idx])
			tiles[idx].type = tile_type

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
color_to_tile_type :: proc(c: rl.Color) -> Tile_Type {
	if c == rl.BLACK do return .WALL
	if c == rl.GRAY do return .FLOOR
	if c == rl.WHITE do return .EMPTY
	if c == rl.GREEN do return .DOOR
	if c == rl.YELLOW do return .OBJECT

	return .EMPTY
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
