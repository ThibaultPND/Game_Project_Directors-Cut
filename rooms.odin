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
	room1 := load_room_from_png(rs, "assets/piece1.png", v2{1, 0})

	room_connect(rs, room0, 1, room1, 2)

	rs.active_room_id = 0
	rs.instances[0].active = true

	return rs
}

quit_room_systme :: proc(rs: ^Room_System) {
	rl.UnloadTexture(rs.tile_tex)
	free(rs)
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
			tile_type := color_to_tile_type(pxl)
			tex_id := pxl.r
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
color_to_tile_type :: proc(c: rl.Color) -> Tile_Type {
	if c.r > 0 do return .WALL
	if c.r == 0 do return .FLOOR
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
