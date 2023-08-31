// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy

//[live]
pub fn (mut a App) render_options_frame(dt f64) {
	draw_canvas := a.canvas

	a.quick.image(
		source: a.asset('images/seamless_wooden_texture.jpg')
		width: draw_canvas.width
		height: draw_canvas.height
		fill_mode: .tile
	)

	draw_scale := a.canvas.factor

	mut design_factor := f32(1440) / draw_canvas.width
	if design_factor == 0 {
		design_factor = 1
	}
	size_factor := 1 / design_factor * draw_scale
	a.quick.text(
		x: shy.half * draw_canvas.width
		y: draw_canvas.height * 0.1
		align: .center
		origin: .center
		size: 30 * size_factor
		text: 'Drag and drop image files onto the Window
to use as custom puzzle images.
Use the grid below to control the puzzle dimensions'
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
					a.settings.dimensions = a.dim_selector.dim
					a.set_mode(.menu)
				}
				else {}
			}
		}
		else {}
	}
}
