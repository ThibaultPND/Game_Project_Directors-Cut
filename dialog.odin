package main

import "base:runtime"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

MAX_DIALOGS :: 200

Dialog_Sprite :: [MAX_DIALOGS]string
Dialog_Text :: [MAX_DIALOGS]string
Dialog_Pos :: [MAX_DIALOGS]i32

Dialog_Scene :: struct {
	active:     bool,
	font:       rl.Font,
	sprite:     Dialog_Sprite,
	sprite_pos: Dialog_Pos,
	line_text:  Dialog_Text,
	count:      i32,
	current:    i32,
	// ? current_letter: i32
}
Dialog_Line :: struct {
	text:   string,
	sprite: string,
	pos:    i32,
}

load_dialog :: proc(filename: string) -> ^Dialog_Scene {
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
	system := new(Dialog_Scene)
	latin_1 := make([]rune, 223)
	for i in 0 ..< len(latin_1) {
		latin_1[i] = rune(32 + i)
	}
	system.font = rl.LoadFontEx("assets/arialbd.ttf", 32, &latin_1[0], 223)
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
delete_dialog :: proc(ds: ^Dialog_Scene) {
	// ! : Verifier si il faut pas free le 
	// ! sprite ou d'autres trucs comme ça.
	free(ds)
}

dialog_update :: proc(ds: ^Dialog_Scene) {
	if ds.active {
		if rl.IsKeyPressed(.SPACE) do ds.current += 1

		if ds.line_text[ds.current] == "" {
			ds.active = false
		}
	}
}

dialog_next :: proc(ds: ^Dialog_Scene) {
	ds.active = true
	ds.current += 1
}

dialog_draw :: proc(ds: ^Dialog_Scene) {
	if ds.active {
		dialog_height: i32 = WINDOW_HEIGHT / 5
		dialog_width: i32 = WINDOW_WIDTH

		rl.DrawRectangle(0, WINDOW_HEIGHT - dialog_height, dialog_width, dialog_height, rl.GRAY)
		line_texts := parse_current_line(ds)
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

parse_current_line :: proc(ds: ^Dialog_Scene) -> [dynamic]string {
	lines: [dynamic]string
	text := ds.line_text[ds.current]

	row_len := 35

	for len(text) > 1 {
		text = strings.trim(text," ")
		len_to_cut := row_len
		if len(text) < row_len {
			len_to_cut = len(text)
		}
		// Si on coupe un mot :
		if len_to_cut < len(text) - 1 && text[len_to_cut-1] != ' ' && text[len_to_cut] != ' ' {
			start_len := len_to_cut
			for len_to_cut > 0 && text[len_to_cut] != ' ' {
				len_to_cut -= 1
			}
			if len_to_cut == 0 {
				len_to_cut = start_len
			}
		}

		append(&lines, (strings.cut(text, 0, len_to_cut)))
		if len(text) < row_len {
			break
		}
		text = strings.cut(text, len_to_cut) // coupe le reste → plus de pos
	}

	return lines
}
