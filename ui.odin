package main
import sa "core:container/small_array"
import "core:fmt"
import rl "vendor:raylib"

Buttons :: sa.Small_Array(50, Button)

Button_State :: enum {
	NONE,
	HOVERED,
	PRESSED,
	HIDED,
}
Button :: struct {
	rect:       rl.Rectangle,
	text:       cstring,
	color:      rl.Color,
	text_color: rl.Color,
	state:      Button_State,
	on_click:   proc(ds: ^Dialog_Scene),
}

button_init :: proc(
	pos: rl.Vector2,
	size: rl.Vector2,
	text: cstring,
	color: rl.Color,
	text_color: rl.Color,
	on_click: proc(ds: ^Dialog_Scene),
) -> Button {
	return Button {
		rl.Rectangle{pos.x, pos.y, size.x, size.y},
		text,
		color,
		text_color,
		.NONE,
		on_click,
	}
}

// TODO : Gérer la fonction avec des images
buttons_draw :: proc(buttons: ^Buttons) {
	for button in sa.slice(buttons) {
		button_color: rl.Color

		switch button.state {
		case .NONE:
			button_color = rl.BLUE
		case .HOVERED:
			button_color = rl.RED
		case .PRESSED:
			button_color = rl.GREEN
		case .HIDED:
		}
		rl.DrawRectangle(
			i32(button.rect.x),
			i32(button.rect.y),
			i32(button.rect.width),
			i32(button.rect.height),
			button_color,
		)
		rl.DrawText(button.text, i32(button.rect.x), i32(button.rect.y), 16, button.text_color)
	}
}
buttons_update :: proc(buttons: ^Buttons, ds: ^Dialog_Scene) {
	for &button in sa.slice(buttons) {
		if cord_over_rect(rl.GetMousePosition(), button.rect) {
			if rl.IsMouseButtonDown(.LEFT) {
				button.state = .PRESSED
			} else do button.state = .HOVERED
			if rl.IsMouseButtonPressed(.LEFT) {
				button.on_click(ds)
			}
		} else {
			button.state = .NONE
		}
	}
}

// Exemple d'event lors du clic
foo :: proc(ds: ^Dialog_Scene) {
	dialog_next(ds)
}
