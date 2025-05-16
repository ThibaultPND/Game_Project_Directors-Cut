package main

import sa "core:container/small_array"
import "core:fmt"
import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600

v2 :: rl.Vector2

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Jason-Jam (JJ)")
	rl.SetTargetFPS(60)
	rl.SetExitKey(.KEY_NULL)

	game_init()
	ds := load_dialog("assets/dialogues/french.json")
	defer delete_dialog(ds)

	cam := new_camera()
	defer free(cam)

	es := load_entity()
	defer free(es)
	player_id := add_entity(es, Entity{pos = v2{200, 200}, size = v2{200, 64}, color = rl.BLUE})
	add_entity(es, Entity{pos = v2{400, 400}, size = v2{64, 64}, color = rl.RED})

	ss := new_sprite_system()
	defer free(ss)

	sprites_add(
		ss,
		v2{200, 500},
		v2{1, 1},
		rl.LoadTexture("assets/sprites/sprite_test.png"),
		5,
		true,
	)

	buttons := load_buttons()
	defer free(buttons)
	button_add(
		buttons,
		pos = v2{100, 100},
		size = v2{100, 200},
		text = "click me",
		color = rl.BLUE,
		text_color = rl.WHITE,
		callback = foo,
	)

	for !rl.WindowShouldClose() {
		game_update(es, player_id)

		if !state.paused {
			sprites_update(ss)
			entity_update(es)
			buttons_update(buttons, ds)
			dialog_update(ds)
			camera_update(cam, es.pos[player_id], es.size[player_id])
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		rl.BeginMode2D(cam^)
		entity_draw(es)
		rl.EndMode2D()

		dialog_draw(ds)
		buttons_draw(buttons)
		sprites_draw(ss)
		if state.paused {
			rl.DrawText("PAUSE", 350, 280, 50, rl.RED)
		}
		rl.EndDrawing()
	}
	rl.CloseWindow()
}
