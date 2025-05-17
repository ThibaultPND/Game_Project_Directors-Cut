package main

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

MAX_DIALOGS :: 200

Dialog_Sprite :: [MAX_DIALOGS]string
Dialog_Text :: [MAX_DIALOGS]string
Dialog_Pos :: [MAX_DIALOGS]i32


@(private = "file")
frame_counter: int

Dialogs_System :: struct {
	active:         bool,
	font:           rl.Font,
	sprite:         Dialog_Sprite,
	sprite_pos:     Dialog_Pos,
	line_text:      Dialog_Text,
	count:          i32,
	current:        i32,
	text_speed:     i32,
	current_letter: int,
}
Dialog_Line :: struct {
	text:   string,
	sprite: string,
	pos:    i32,
}

new_dialog_system :: proc(filename: string) -> ^Dialogs_System {
	data, ok := os.read_entire_file_from_filename(filename)
	if !ok {
		fmt.eprintfln("Failed to load the lang : \"%s\" ", filename)
		return nil
	}
	defer delete(data)

	// Load dialogs
	lines: []Dialog_Line
	unmarshall_err := json.unmarshal(data, &lines)
	if unmarshall_err != nil {
		fmt.eprintfln("Failed to unmarshall the file : \"%s\"", filename)
		return nil
	}
	system := new(Dialogs_System)
	latin_1 := make([]rune, 223)
	for i in 0 ..< len(latin_1) {
		latin_1[i] = rune(32 + i)
	}
	system.font = rl.LoadFontEx("assets/fonts/arialbd.ttf", 32, &latin_1[0], 223)
	system.active = false
	system.count = i32(len(lines))
	for i in 0 ..< system.count {
		line := lines[i]
		system.line_text[i] = line.text
		system.sprite[i] = line.sprite
		system.sprite_pos[i] = line.pos
	}
	return system
}
delete_dialog :: proc(ds: ^Dialogs_System) {
	// ! : Verifier si il faut pas free le 
	// ! sprite ou d'autres trucs comme ça.
	free(ds)
}

dialog_update :: proc(ds: ^Dialogs_System) {
	if ds.active {
		if rl.IsKeyPressed(.SPACE) {
			if ds.current_letter != len(ds.line_text[ds.current]) {
				ds.current_letter = len(ds.line_text[ds.current])
			} else {
				dialog_next(ds)
			}
		}

		if ds.line_text[ds.current] == "" {
			ds.active = false
		} else {
			if int(ds.current_letter) != len(ds.line_text[ds.current]) {
				frame_counter += 1
				// TODO : Rendre modifiable dans les settings
				letter_flow := 2
				if frame_counter >= letter_flow {
					ds.current_letter += 1
					frame_counter = 0
				}
			}
		}
	}

}

dialog_next :: proc(ds: ^Dialogs_System) {
	ds.active = true
	ds.current += 1
	ds.current_letter = 1
}

dialog_draw :: proc(ds: ^Dialogs_System) {
	if ds.active {
		dialog_height: i32 = WINDOW_HEIGHT / 5
		dialog_width: i32 = WINDOW_WIDTH

		rl.DrawRectangle(0, WINDOW_HEIGHT - dialog_height, dialog_width, dialog_height, rl.GRAY)

		line := strings.cut(ds.line_text[ds.current], 0, ds.current_letter)
		line_texts := parse_current_line(line)
		defer delete(line_texts)
		for i in 0 ..< len(line_texts) {
			line_text := strings.clone_to_cstring(line_texts[i])
			defer delete(line_text)

			row_size := rl.MeasureTextEx(ds.font, line_text, 30, 2)
			rl.DrawTextEx(
				ds.font,
				line_text,
				v2 {
					(WINDOW_WIDTH - row_size.x) / 2,
					f32(WINDOW_HEIGHT - (dialog_height * 3) / 4) +
					f32(i) * (f32(row_size.y * 3) / 4),
				},
				30,
				2,
				rl.BLACK,
			)
		}
	}
}

parse_current_line :: proc(text: string) -> [dynamic]string {
	lines: [dynamic]string
	text := text

	// TODO : Rendre modifiable dans les settings
	row_len := 35

	for len(text) > 1 {
		text = strings.trim_left(text, " ")
		if len(text) <= row_len + 5 {
			append(&lines, text)
			break
		}

		len_to_cut := row_len
		if len_to_cut < len(text) && text[len_to_cut] != ' ' && text[len_to_cut - 1] != ' ' {
			i := len_to_cut
			for i > 0 && text[i] != ' ' {
				i -= 1
			}
			if i > 0 {
				len_to_cut = i
			}
		}

		append(&lines, strings.cut(text, 0, len_to_cut))
		if len_to_cut >= len(text) {
			text = ""
			break
		}
		text = strings.cut(text, len_to_cut) // coupe le reste → plus de pos
	}

	return lines
}
