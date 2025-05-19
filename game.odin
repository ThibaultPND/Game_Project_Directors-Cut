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
	}
	add_entity(
		game.es,
		pos = v2{200, 200},
		size = v2{200, 64},
		speed = 300,
		color = rl.BLUE,
		tag = .PLAYER,
	)
	add_entity(
		game.es,
		pos = v2{400, 400},
		size = v2{64, 64},
		speed = 300,
		color = rl.RED,
		tag = .ENEMY,
	)
	button_add(
		game.bs,
		pos = v2{100, 100},
		size = v2{100, 200},
		text = "click me",
		base_color = rl.BLUE,
		text_color = rl.WHITE,
		on_click = foo,
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
		entity_update(game.es)
		buttons_update(game.bs)
		dialog_update(game.ds)
		camera_update(
			game.cs,
			rl.Rectangle {
				game.es.pos[0].x,
				game.es.pos[0].y,
				game.es.size[0].x,
				game.es.size[0].y,
			},
		)
	}
}

game_render :: proc(game: ^Game) {
	rl.BeginMode2D(game.cs.camera)
	entity_draw(game.es)
	rl.EndMode2D()

	dialog_draw(game.ds)
	buttons_draw(game.bs)
	sprites_draw(game.ss)
	if game.paused {
		rl.DrawText("PAUSE", 350, 280, 50, rl.RED)
	}
}
