package main

import sa "core:container/small_array"
import "core:fmt"
import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Jason-Jam (JJ)")
	rl.SetTargetFPS(60)
	rl.SetExitKey(.KEY_NULL)

	game_init()
	ds := load_dialog("assets/french.json")
	defer delete_dialog(ds)

	es: EntitySystem
	player_id := add_entity(
		&es,
		Entity{pos = rl.Vector2{200, 200}, size = rl.Vector2{200, 64}, color = rl.BLUE},
	)
	add_entity(&es, Entity{pos = rl.Vector2{400, 400}, size = rl.Vector2{64, 64}, color = rl.RED})

	buttons: Buttons
	// TODO : Créer une fonction qui gère l'ajout de bouton
	sa.push_back(
		&buttons,
		button_init(rl.Vector2{50, 80}, rl.Vector2{140, 30}, "Dialogue suivant", rl.BLACK, rl.WHITE, foo),
	)

	for !rl.WindowShouldClose() {
		game_update(&es, player_id)

		if !state.paused {
			entity_update(&es)
			buttons_update(&buttons,ds)
			dialog_update(ds)
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		dialog_draw(ds)
		entity_draw(&es)
		buttons_draw(&buttons)
		if state.paused {
			rl.DrawText("PAUSE", 350, 280, 50, rl.RED)
		}
		rl.EndDrawing()
	}
	rl.CloseWindow()
}
