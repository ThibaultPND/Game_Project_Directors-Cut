package main
import sa "core:container/small_array"
import "core:fmt"
import rl "vendor:raylib"

MAX_BUTTON :: 50


Button_State :: enum {
	NONE,
	HOVERED,
	PRESSED,
	HIDED,
}
Buttons_System :: struct {
	pos:        [MAX_BUTTON]v2,
	size:       [MAX_BUTTON]v2,
	text:       [MAX_BUTTON]cstring,
	base_color: [MAX_BUTTON]rl.Color,
	text_color: [MAX_BUTTON]rl.Color,
	state:      [MAX_BUTTON]Button_State,
	visible:    [MAX_BUTTON]bool,
	on_click:   [MAX_BUTTON]proc(_: rawptr),
	user_data:  [MAX_BUTTON]rawptr,
	count:      u32,
}

button_add :: proc(
	bs: ^Buttons_System,
	pos: v2,
	size: v2,
	text: cstring,
	base_color, text_color: rl.Color,
	on_click: proc(_: rawptr),
	user_data: rawptr,
) -> u32 {
	id := bs.count
	bs.count += 1

	bs.pos[id] = pos
	bs.size[id] = size
	bs.text[id] = text
	bs.base_color[id] = base_color
	bs.text_color[id] = text_color
	bs.state[id] = .NONE
	bs.visible[id] = true

	bs.on_click[id] = on_click
	bs.user_data[id] = user_data

	return id
}

load_buttons :: proc() -> ^Buttons_System {
	Buttons_System, err := new(Buttons_System)
	if true {
		// ! Traiter l'erreur
	}
	return Buttons_System
}

// TODO : Gérer la fonction avec des images
buttons_draw :: proc(bs: ^Buttons_System) {
	for i in 0 ..< bs.count {
		button_color: rl.Color

		switch bs.state[i] {
		case .NONE:
			button_color = bs.base_color[i]
		case .HOVERED:
			button_color = rl.RED
		case .PRESSED:
			button_color = rl.GREEN
		case .HIDED:
		}
		rl.DrawRectangle(
			i32(bs.pos[i].x),
			i32(bs.pos[i].y),
			i32(bs.size[i].x),
			i32(bs.size[i].y),
			button_color,
		)
		rl.DrawText(bs.text[i], i32(bs.pos[i].x), i32(bs.pos[i].y), 16, bs.text_color[i])
	}
}
buttons_update :: proc(bs: ^Buttons_System) {
	for i in 0 ..< bs.count {
		if cord_over_rect(
			rl.GetMousePosition(),
			rl.Rectangle {
				x = bs.pos[i].x,
				y = bs.pos[i].y,
				width = bs.size[i].x,
				height = bs.size[i].y,
			},
		) {
			if rl.IsMouseButtonDown(.LEFT) {
				bs.state[i] = .PRESSED
			} else do bs.state[i] = .HOVERED
			if rl.IsMouseButtonPressed(.LEFT) {
				bs.on_click[i](bs.user_data[i])
			}
		} else {
			bs.state[i] = .NONE
		}
	}
}

// Exemple d'event lors du clic
foo :: proc(dialog_system: rawptr) {
	dialog_system := (^Dialogs_System)(dialog_system)
	dialog_next(dialog_system)
}
