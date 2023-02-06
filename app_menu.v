// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy

//[live]
pub fn (mut a App) render_menu_frame(dt f64) {
	canvas_size := a.canvas
	// println(canvas_size)

	// Background
	a.quick.image(
		// x: 0
		// y: 0
		source: a.asset('images/seamless_wooden_texture.jpg')
		width: a.canvas.width
		height: a.canvas.height
		fill_mode: .tile
	)

	/*
	a.quick.rect(
		x: shy.half * canvas_size.width
		y: shy.half * canvas_size.height
		width: canvas_size.width
		height: canvas_size.height
		origin: .center
		color: bgcolor
		stroke: shy.Stroke{
			width: 1
		}
	)*/

	a.ps.draw()

	// Logo
	a.quick.image(
		x: shy.half * canvas_size.width
		y: shy.half * canvas_size.height
		source: a.asset('images/puzzle_vibes_logo.png')
		origin: .center
		offset: shy.vec2[f32](0, -(canvas_size.height * 0.32))
		scale: (a.canvas.width / 1920) * 0.45
	)

	a.image_selector.draw()

	a.start_button.draw()
}

// [live]
pub fn (mut a App) on_menu_event_update(e UIEvent) {
	if a.mode != .menu {
		return
	}
	match e {
		shy.KeyEvent {
			if e.state == .up {
				return
			}
			key := e.key_code
			match key {
				.s {
					a.start_game() or { panic(err) }
					a.mode = .game
				}
				.left {
					a.select_prev_image()
				}
				.right {
					a.select_next_image()
				}
				/*
				.up {
					a.image_selector.todo_rm = a.image_selector.todo_rm.next()
					dump(a.image_selector.todo_rm)
				}
				.down {
					a.image_selector.todo_rm = a.image_selector.todo_rm.prev()
					dump(a.image_selector.todo_rm)
				}*/
				else {}
			}
		}
		else {}
	}
}
