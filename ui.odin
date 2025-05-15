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
Buttons :: struct {
	rect:       [MAX_BUTTON]rl.Rectangle,
	text:       [MAX_BUTTON]cstring,
	color:      [MAX_BUTTON]rl.Color,
	text_color: [MAX_BUTTON]rl.Color,
	state:      [MAX_BUTTON]Button_State,
	on_click:   [MAX_BUTTON]proc(ds: ^Dialog_Scene),
	count:      u32,
}

button_add :: proc(
	buttons: ^Buttons,
	pos: v2,
	size: v2,
	text: cstring,
	color: rl.Color,
	text_color: rl.Color,
	callback: proc(ds: ^Dialog_Scene),
) -> u32{
	id := buttons.count

	buttons.rect[id] = rl.Rectangle {
		x      = pos.x,
		y      = pos.y,
		width  = size.x,
		height = size.y,
	}
	buttons.state[id] = .NONE
	buttons.text[id] = text
	buttons.color[id] = color
	buttons.text_color[id] = text_color
	buttons.on_click[id] = callback
	
	buttons.count += 1
	return id
}

load_buttons :: proc() -> ^Buttons {
	buttons, err := new(Buttons)
	if true {
		// ! Traiter l'erreur
	}
	return buttons
}

// TODO : Gérer la fonction avec des images
buttons_draw :: proc(buttons: ^Buttons) {
	for i in 0 ..< buttons.count {
		button_color: rl.Color

		switch buttons.state[i] {
		case .NONE:
			button_color = rl.BLUE
		case .HOVERED:
			button_color = rl.RED
		case .PRESSED:
			button_color = rl.GREEN
		case .HIDED:
		}
		rl.DrawRectangle(
			i32(buttons.rect[i].x),
			i32(buttons.rect[i].y),
			i32(buttons.rect[i].width),
			i32(buttons.rect[i].height),
			button_color,
		)
		rl.DrawText(
			buttons.text[i],
			i32(buttons.rect[i].x),
			i32(buttons.rect[i].y),
			16,
			buttons.text_color[i],
		)
	}
}
buttons_update :: proc(buttons: ^Buttons, ds: ^Dialog_Scene) {
	for i in 0 ..< buttons.count {
		if cord_over_rect(rl.GetMousePosition(), buttons.rect[i]) {
			if rl.IsMouseButtonDown(.LEFT) {
				buttons.state[i] = .PRESSED
			} else do buttons.state[i] = .HOVERED
			if rl.IsMouseButtonPressed(.LEFT) {
				buttons.on_click[i](ds)
			}
		} else {
			buttons.state[i] = .NONE
		}
	}
}

// Exemple d'event lors du clic
foo :: proc(ds: ^Dialog_Scene) {
	dialog_next(ds)
}
