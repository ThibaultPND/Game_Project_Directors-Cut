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
	ds := load_dialog("assets/french.json")
	defer delete_dialog(ds)

	es := load_entity()
	defer free(es)
	player_id := add_entity(es, Entity{pos = v2{200, 200}, size = v2{200, 64}, color = rl.BLUE})
	add_entity(es, Entity{pos = v2{400, 400}, size = v2{64, 64}, color = rl.RED})

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
			entity_update(es)
			buttons_update(buttons, ds)
			dialog_update(ds)
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		dialog_draw(ds)
		entity_draw(es)
		buttons_draw(buttons)
		if state.paused {
			rl.DrawText("PAUSE", 350, 280, 50, rl.RED)
		}
		rl.EndDrawing()
	}
	rl.CloseWindow()
}
