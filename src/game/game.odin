// This file is compiled as part of the `odin.dll` file. It contains the
// procs that `game.exe` will call, such as:
//
// game_init: Sets up the game state
// game_update: Run once per frame
// game_shutdown: Shuts down game and frees memory
// game_memory: Run just before a hot reload, so game.exe has a pointer to the
//		game's memory.
// game_hot_reloaded: Run after a hot reload so that the `g_mem` global variable
//		can be set to whatever pointer it was in the old DLL.

package game

import "core:fmt"
import rl "vendor:raylib"

PixelWindowHeight :: 180
FPS :: 144
FPS_TO_SPEED :: 0.41667
MAX :: 100000
SPEED_MULT :: FPS * FPS_TO_SPEED
WIDTH : i32 : 800
HEIGHT : i32 : 450

Bunny :: struct {
	pos: rl.Vector2,
	speed: rl.Vector2,
	color: rl.Color,
}

GameMemory :: struct {
	bunnies_count: int,
	bunnies: [MAX]Bunny,
	tex_bunny: rl.Texture2D,
}

g_mem: ^GameMemory

ui_camera :: proc() -> rl.Camera2D {
	return {
		zoom = f32(rl.GetScreenHeight())/PixelWindowHeight,
	}
}

update :: proc() {
	if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
		fmt.printfln("ADD BUNNIES. Total: {0}", g_mem.bunnies_count)

		for _ in 0..<200 {
			if g_mem.bunnies_count < MAX {
				new_bunny := &g_mem.bunnies[g_mem.bunnies_count]
				g_mem.bunnies_count += 1

				new_bunny.pos = rl.GetMousePosition()
				new_bunny.speed.x = f32(rl.GetRandomValue(-250, 250)) / SPEED_MULT
				new_bunny.speed.y = f32(rl.GetRandomValue(-250, 250)) / SPEED_MULT
				new_bunny.color = Color{
					cast(u8)rl.GetRandomValue(50, 240), 
					cast(u8)rl.GetRandomValue(80, 240), 
					cast(u8)rl.GetRandomValue(100, 240),
					255,
				}
			}
		}
	}

	for i in 0..<g_mem.bunnies_count {
		bunny := &g_mem.bunnies[i]

		bunny.pos.x += bunny.speed.x
		bunny.pos.y += bunny.speed.y

		if (((bunny.pos.x + f32(g_mem.tex_bunny.width/2)) > f32(rl.GetScreenWidth())) ||
			((bunny.pos.x + f32(g_mem.tex_bunny.width/2)) < 0)) {
			bunny.speed.x *= -1
		}

		if (((bunny.pos.y + f32(g_mem.tex_bunny.height/2)) > f32(rl.GetScreenHeight())) ||
			((bunny.pos.y + f32(g_mem.tex_bunny.height/2)) < 0)) {
			bunny.speed.y *= -1
		}
	}
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	
	for i in 0..<g_mem.bunnies_count {
		rl.DrawTexture(g_mem.tex_bunny, (i32)(g_mem.bunnies[i].pos.x), cast(i32)g_mem.bunnies[i].pos.y, g_mem.bunnies[i].color)
	}

	rl.DrawRectangle(0, 0, WIDTH, 40, rl.BLACK)
	rl.DrawFPS(10, 10)

	rl.EndDrawing()
}

@(export)
game_update :: proc() -> bool {
	update()
	draw()
	return !rl.WindowShouldClose()
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WIDTH, HEIGHT, "Odin + Raylib + Hot Reload template!")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(FPS)
}

@(export)
game_init :: proc() {
	g_mem = new(GameMemory)

	g_mem^ = GameMemory {
		bunnies_count = 0,
	}

	g_mem.tex_bunny = rl.LoadTexture("res/wabbit_alpha.png")

	game_hot_reloaded(g_mem)
}

@(export)
game_shutdown :: proc() {
	free(g_mem)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g_mem
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(GameMemory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g_mem = (^GameMemory)(mem)
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}