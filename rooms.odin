package main

import rl "vendor:raylib"

MAX_ROOMS :: 10

Room_Positions :: [MAX_ROOMS]v2
Room_Sizes :: [MAX_ROOMS]v2


room :: struct {
	current:        int,
	world_position: Room_Positions,
	size:           Room_Sizes,
	room_count:     int,
}

room_init :: proc() {

}
