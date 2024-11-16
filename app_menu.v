// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy

// @[live]
pub fn (mut a App) render_menu_frame(dt f64) {
	draw_canvas := a.canvas()
	// println(draw_canvas)

	// Background
	a.quick.image(
		// x: 0
		// y: 0
		source:    a.asset('images/seamless_wooden_texture.jpg')
		width:     a.canvas().width
		height:    a.canvas().height
		fill_mode: .tile
	)

	/*
	a.quick.rect(
		x: shy.half * draw_canvas.width
		y: shy.half * draw_canvas.height
		width: draw_canvas.width
		height: draw_canvas.height
		origin: shy.Anchor.center
		color: bgcolor
		stroke: shy.Stroke{
			width: 1
		}
	)*/

	// Particles when puzzle images are switched
	a.ps.draw()

	// Logo
	a.quick.image(
		x:      shy.half * draw_canvas.width
		y:      shy.half * draw_canvas.height
		source: a.asset('images/puzzle_vibes_logo.png')
		origin: shy.Anchor.center
		offset: shy.vec2[f32](0, -(draw_canvas.height * 0.32))
		scale:  (a.canvas().width / 1920) * 0.45
	)

	a.options_button.draw()
	a.image_selector.draw()

	draw_scale := a.canvas().factor
	mut design_factor := f32(1440) / draw_canvas.width
	if design_factor == 0 {
		design_factor = 1
	}
	size_factor := 1 / design_factor * draw_scale

	best_solve := a.current_image_best_solve
	if best_solve.is_valid() {
		ims_rect := a.image_selector.Rect
		bgcolor := shy.rgba(0, 0, 0, 67)
		et := a.easy.text(
			x:      ims_rect.x
			y:      ims_rect.y + (shy.half * ims_rect.height) + (30 * size_factor)
			align:  .center
			origin: shy.Anchor.center
			size:   30 * size_factor
			text:   'Best solve time is ${best_solve.pretty_format()} for ${best_solve.dimensions.width:.0f}x${best_solve.dimensions.height:.0f}, ${int(a.settings.dimensions.area())} pieces'
		)
		bounds := et.bounds()
		a.quick.rect(
			x:      ims_rect.x
			y:      ims_rect.y + (shy.half * ims_rect.height) + (30 * size_factor)
			origin: shy.Anchor.center
			width:  ims_rect.width
			height: bounds.height + (18 * size_factor)
			fills:  .body
			color:  bgcolor
		)
		et.draw()
	}
	a.start_button.draw()

	sb_rect := a.start_button.Button.Rect
	a.quick.text(
		x:      sb_rect.x
		y:      sb_rect.y + shy.half * sb_rect.height + 20 * size_factor
		align:  .center
		origin: shy.Anchor.center
		size:   20 * size_factor
		text:   '${a.settings.dimensions.width:.0f}x${a.settings.dimensions.height:.0f} Puzzle, ${int(a.settings.dimensions.area())} pieces'
	)

	mut version_info := a.version_full
	a.quick.text(
		x:      10 * size_factor
		y:      draw_canvas.height - 10 * size_factor
		align:  .center
		origin: shy.Anchor.bottom_left
		size:   15 * size_factor
		text:   '${version_info}'
	)
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
				.space, .@return, .kp_enter {
					a.start_game() or { panic(err) }
					a.set_mode(.game)
				}
				.o {
					a.dim_selector.dim = a.settings.dimensions
					a.set_mode(.options)
				}
				.left {
					a.select_prev_image()
				}
				.right {
					a.select_next_image()
				}
				.up {
					a.stop_music() // play_random_music() <- don't do that here
				}
				.down {
					a.play_cheer()
				}
				.t {
					$if debug {
						a.show_toast(
							text:     'test'
							duration: 4
						)
					}
				}
				.r {
					$if debug {
						a.reset_settings() or {
							eprintln('Resetting settings failed: ${err}')
							a.show_toast(
								text:     'Resetting settings failed'
								duration: 4
							)
						}
					}
				}
				else {}
			}
		}
		else {}
	}
}
