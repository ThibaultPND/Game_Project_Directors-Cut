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

	game := game_init()

	// ? Temporaire
	sprites_add(
		game.ss,
		v2{200, 500},
		v2{1, 1},
		rl.LoadTexture("assets/sprites/sprite_test.png"),
		v2{100,100},
		5,
		0.1,
		true,
	)
	// ?

	for !rl.WindowShouldClose() {
		game_update(&game)

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		game_render(&game)

		rl.EndDrawing()
	}
	rl.CloseWindow()
	game_exit(&game)
}
