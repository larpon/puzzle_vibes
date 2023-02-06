// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy

//[live]
pub fn (mut a App) render_options_frame(dt f64) {
	canvas_size := a.canvas

	a.quick.image(
		source: a.asset('images/seamless_wooden_texture.jpg')
		width: canvas_size.width
		height: canvas_size.height
		fill_mode: .tile
	)

	a.dim_selector.draw()
}

// [live]
pub fn (mut a App) on_options_event_update(e UIEvent) {
	if a.mode != .options {
		return
	}
	match e {
		shy.KeyEvent {
			if e.state == .up {
				return
			}
			key := e.key_code
			match key {
				.backspace {
					a.puzzle_dim = a.dim_selector.dim
					a.mode = .menu
				}
				else {}
			}
		}
		else {}
	}
}
