package main

import rl "vendor:raylib"

MAX_DIALOGS :: 200

Dialog_Sprite :: [MAX_DIALOGS]string
Dialog_Text :: [MAX_DIALOGS][256]u8
Dialog_Pos :: [MAX_DIALOGS]i32

Dialog_Scene :: struct {
	active:     bool,
	sprite:     Dialog_Sprite,
	sprite_pos: Dialog_Pos,
	line_text:  Dialog_Text,
}

load_dialog :: proc(ds: ^Dialog_Scene, filename: cstring) {

}
dialog_update :: proc(ds: ^Dialog_Scene) {
	if !ds.active do return


}
