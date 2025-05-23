package main

import "core:fmt"
import rl "vendor:raylib"

Game :: struct {
	paused:      bool,
	frame_count: u32,
	ds:          ^Dialogs_System,
	cs:          ^Camera_System,
	es:          ^Entities_System,
	ss:          ^Sprites_System,
	bs:          ^Buttons_System,
	rs:          ^Room_System,
}

game_init :: proc() -> Game {
	game := Game {
		paused      = false,
		frame_count = 0,
		ds          = new_dialog_system("assets/dialogues/french.json"),
		cs          = new_camera(),
		es          = new_entities_system(),
		ss          = new_sprites_system(),
		bs          = load_buttons(),
		rs          = room_init(),
	}
	add_entity(
		game.es,
		pos = v2{200, 200},
		size = v2{64, 64},
		speed = 300,
		color = rl.BLUE,
		tag = .PLAYER,
	)
	add_entity(
		game.es,
		pos = v2{264, 500},
		size = v2{64, 64},
		speed = 300,
		color = rl.BLUE,
		tag = .NPC,
	)
	add_entity(
		game.es,
		pos = v2{200, 436},
		size = v2{64, 64},
		speed = 300,
		color = rl.BLUE,
		tag = .NPC,
	)
	button_add(
		game.bs,
		pos = v2{500, 20},
		size = v2{80, 50},
		text = "dialogue",
		base_color = rl.ORANGE,
		text_color = rl.WHITE,
		on_click = foo,
		user_data = game.ds,
	)
	button_add(
		game.bs,
		pos = v2{200, 20},
		size = v2{70, 50},
		text = "TRY ME",
		base_color = rl.ORANGE,
		text_color = rl.WHITE,
		on_click = explosion_button,
		user_data = game.ds,
	)
	return game
}

game_exit :: proc(game: ^Game) {
	delete_dialog(game.ds)
	free(game.cs)
	free(game.es)
	free(game.ss)
	free(game.bs)
	quit_room_systme(game.rs)
	free(game.ds)
}

game_update :: proc(game: ^Game) {
	game.frame_count += 1

	if rl.IsKeyPressed(.ESCAPE) do game.paused = !game.paused

	// Player movements
	dir := rl.Vector2{0, 0}
	if rl.IsKeyDown(.D) do dir.x += 1
	if rl.IsKeyDown(.A) do dir.x -= 1
	if rl.IsKeyDown(.S) do dir.y += 1
	if rl.IsKeyDown(.W) do dir.y -= 1
	game.es.dir[0] = dir

	if !game.paused {
		sprites_update(game.ss)
		entity_update(game.es, game.rs)
		buttons_update(game.bs, game.ss)
		dialog_update(game.ds)
		room_update(game.rs)
		camera_update(
			game.cs,
			rl.Rectangle{game.es.pos[0].x, game.es.pos[0].y, game.es.size[0].x, game.es.size[0].y},
		)
	}
}

game_render :: proc(game: ^Game) {

	rl.BeginMode2D(game.cs.camera)
	room_draw(game.rs, game.es.pos[0])
	entity_draw(game.es)
	rl.EndMode2D()

	dialog_draw(game.ds)
	buttons_draw(game.bs)
	sprites_draw(game.ss)
	if game.paused {
		rl.DrawText("PAUSE", 350, 280, 50, rl.RED)
	}
}
