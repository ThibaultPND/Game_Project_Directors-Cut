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

Dialog_Scene :: struct {
	active:     bool,
	sprite:     Dialog_Sprite,
	sprite_pos: Dialog_Pos,
	line_text:  Dialog_Text,
	count:      i32,
	current:    i32,
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
		dialog_height: i32 = WINDOW_HEIGHT / 6
		dialog_width: i32 = WINDOW_WIDTH

		rl.DrawRectangle(0, WINDOW_HEIGHT - dialog_height, dialog_width, dialog_height, rl.GRAY)
		rl.DrawText(
			strings.clone_to_cstring(ds.line_text[ds.current]),
			30,
			(WINDOW_HEIGHT - dialog_height) + 20,
			24,
			rl.BLACK,
		)
	}
}
