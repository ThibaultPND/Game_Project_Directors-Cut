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
	rect:       [MAX_BUTTON]rl.Rectangle,
	text:       [MAX_BUTTON]cstring,
	color:      [MAX_BUTTON]rl.Color,
	text_color: [MAX_BUTTON]rl.Color,
	state:      [MAX_BUTTON]Button_State,
	on_click:   [MAX_BUTTON]proc(ds: ^Dialogs_System),
	count:      u32,
}

button_add :: proc(
	Buttons_System: ^Buttons_System,
	pos: v2,
	size: v2,
	text: cstring,
	color: rl.Color,
	text_color: rl.Color,
	callback: proc(ds: ^Dialogs_System),
) -> u32{
	id := Buttons_System.count

	Buttons_System.rect[id] = rl.Rectangle {
		x      = pos.x,
		y      = pos.y,
		width  = size.x,
		height = size.y,
	}
	Buttons_System.state[id] = .NONE
	Buttons_System.text[id] = text
	Buttons_System.color[id] = color
	Buttons_System.text_color[id] = text_color
	Buttons_System.on_click[id] = callback
	
	Buttons_System.count += 1
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
buttons_draw :: proc(Buttons_System: ^Buttons_System) {
	for i in 0 ..< Buttons_System.count {
		button_color: rl.Color

		switch Buttons_System.state[i] {
		case .NONE:
			button_color = rl.BLUE
		case .HOVERED:
			button_color = rl.RED
		case .PRESSED:
			button_color = rl.GREEN
		case .HIDED:
		}
		rl.DrawRectangle(
			i32(Buttons_System.rect[i].x),
			i32(Buttons_System.rect[i].y),
			i32(Buttons_System.rect[i].width),
			i32(Buttons_System.rect[i].height),
			button_color,
		)
		rl.DrawText(
			Buttons_System.text[i],
			i32(Buttons_System.rect[i].x),
			i32(Buttons_System.rect[i].y),
			16,
			Buttons_System.text_color[i],
		)
	}
}
buttons_update :: proc(Buttons_System: ^Buttons_System, ds: ^Dialogs_System) {
	for i in 0 ..< Buttons_System.count {
		if cord_over_rect(rl.GetMousePosition(), Buttons_System.rect[i]) {
			if rl.IsMouseButtonDown(.LEFT) {
				Buttons_System.state[i] = .PRESSED
			} else do Buttons_System.state[i] = .HOVERED
			if rl.IsMouseButtonPressed(.LEFT) {
				Buttons_System.on_click[i](ds)
			}
		} else {
			Buttons_System.state[i] = .NONE
		}
	}
}

// Exemple d'event lors du clic
foo :: proc(ds: ^Dialogs_System) {
	dialog_next(ds)
}
