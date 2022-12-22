// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import os
import shy.lib as shy
//import shy.vec
// import shy.matrix
import shy.embed

enum Mode {
	menu
	game
}

[heap]
struct App {
	embed.ExampleApp
mut:
	mode   Mode    //= .game
	puzzle &Puzzle = shy.null
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	mut win_size := a.window.drawable_size()
	// win_size = win_size.mul_scalar(0.5)
	// win_size.width *= 0.5
	// win_size.height *= 0.5

	a.quick.load(
		uri: a.asset(default_image)
	)!

	img := a.assets.get[shy.Image](a.asset(default_image))!

	dim := shy.Size{
		width: 2
		height: 2
	}

	viewport := win_size.to_rect()

	a.puzzle = new_puzzle(
		app: a
		viewport: viewport
		image: img
		dimensions: dim
	)!
}

[markused]
pub fn (mut a App) frame(dt f64) {
	// a.draw.push_matrix()
	// a.draw.scale(0.5,0.5,1)
	// a.draw.translate(0,1280,0)
	match a.mode {
		.game {
			a.render_game_frame(dt)
		}
		.menu {
			a.render_menu_frame(dt)
		}
	}
	// a.draw.pop_matrix()
}

// [live]
pub fn (mut a App) render_menu_frame(dt f64) {
	drawable_size := a.window.drawable_size()
	draw_scale := a.window.draw_factor()
	// println(drawable_size)

	a.quick.rect(
		x: shy.half * drawable_size.width
		y: shy.half * drawable_size.height
		width: drawable_size.width
		height: drawable_size.height
		origin: .center
		stroke: shy.Stroke{
			width: 1
		}
	)

	area := shy.Rect{
		x: shy.half * drawable_size.width
		y: shy.half * drawable_size.height
		width: 0.2 * drawable_size.width
		height: 0.1 * drawable_size.width
	}

	mouse_area := area.displaced_from(.center)
	mut color := shy.colors.shy.red
	if mouse_area.contains(a.mouse.x, a.mouse.y) {
		color = shy.colors.shy.blue
		if a.mouse.is_button_down(.left) {
			color = shy.colors.shy.green
			a.puzzle.scramble() or { panic(err) }
			a.shy.once(fn [mut a] () {
				a.mode = .game
			}, 100)
		}
	}

	a.quick.rect(
		Rect: area
		origin: .center
		color: color
		stroke: shy.Stroke{
			width: 3
		}
	)

	/*
	a.quick.rect(
		Rect: mouse_area
		color: shy.rgba(127,127,127,180)
	)*/

	mut design_factor := f32(1440)/a.window.width()
	if design_factor == 0 {
		design_factor = 1
	}
	font_size_factor := 1/design_factor * draw_scale

	a.quick.text(
		x: area.x
		y: area.y
		align: .center
		origin: .center
		size: 50 * font_size_factor
		text: 'START'
	)
}

pub fn (mut a App) render_game_frame(dt f64) {
	a.puzzle.draw()

	mut grabbed_piece := &Piece(0)
	for piece in a.puzzle.pieces {
		if !piece.grabbed {
			piece.draw()
		} else {
			grabbed_piece = piece
		}

		mouse_area := piece.viewport_rect()
		if piece.hovered {
			color := shy.colors.shy.white
			a.quick.rect(
				// Rect: mouse_area // need int() to round off
				x: int(mouse_area.x)
				y: int(mouse_area.y)
				width: int(mouse_area.width)
				height: int(mouse_area.height)
				color: color
				fills: .outline
				stroke: shy.Stroke{
					color: color
				}
			)
		}

		// println(mouse_area)
	}

	if grabbed_piece != shy.null {
		grabbed_piece.draw()
	}

	if a.puzzle.solved {
		cover := a.window.drawable_size()
		mut color := shy.colors.shy.green
		color.a = 200
		a.quick.rect(
			Rect: cover.to_rect()
			color: color
			fills: .body
		)

		mut design_factor := f32(1440)/a.window.width()
		if design_factor == 0 {
			design_factor = 1
		}
		font_size_factor := 1/design_factor * a.window.draw_factor()

		font_size := f32(142) * font_size_factor
		a.quick.text(
			x: cover.width * shy.half
			y: cover.height * shy.half
			align: .center
			origin: .center
			size: font_size
			text: 'EXCELLENT'
		)
	}
}

// asset unifies locating project assets
pub fn (a App) asset(path string) string {
	$if wasm32_emscripten {
		return path
	}
	return os.resource_abs_path(os.join_path('assets', path))
}

[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)
	match e {
		shy.KeyEvent {
			if e.state == .up {
				return
			}
			key := e.key_code
			// kb := a.kbd
			// alt_is_held := (kb.is_key_down(.lalt) || kb.is_key_down(.ralt))
			match key {
				.backspace {
					a.mode = .menu
				}
				.s {
					a.puzzle.scramble(do_not_scramble_laid: true) or { panic(err) }
				}
				.a {
					a.puzzle.auto_solve()
				}
				else {}
			}
		}
		shy.MouseMotionEvent {
			a.on_game_event_update(GameEvent(e))
		}
		shy.MouseButtonEvent {
			a.on_game_event_update(GameEvent(e))
		}
		shy.WindowResizeEvent {
			mut viewport := a.window.drawable_size().to_rect()
			a.puzzle.set_viewport(viewport)
		}
		else {}
	}
}

type GameEvent = shy.MouseMotionEvent | shy.MouseButtonEvent

// [live]
pub fn (mut a App) on_game_event_update(event_type GameEvent) {
	if a.mode != .game {
		return
	}

	is_button_event := event_type is shy.MouseButtonEvent

	if a.puzzle.solved {
		if a.mouse.is_button_down(.left) {
			a.mode = .menu
		}
		return
	}

	m := shy.vec2[f32](a.mouse.x, a.mouse.y)
	mut solved := true
	for mut piece in a.puzzle.pieces {
		piece.hovered = false
		// No need to check this in movement events
		if is_button_event && !a.mouse.is_button_down(.left) {
			if piece.id == a.puzzle.grabbed {
				piece.grabbed = false
				a.puzzle.grabbed = 0
				if p := a.puzzle.get_solved_piece(m) {
					if p.id == piece.id {
						// NOTE The following is important for being able to detect if the puzzle is solved
						// since we use an epsilon equality check to detect if the pieces are near their solved
						// position (start position, before the initial scramble).
						// The float math involved for getting points in and out of the viewports is admittedly very crue and homemade
						// so things can end up several pixels apart from their starting location, hence this litte "trick" to
						// get the values back where they came from. If it works, eh?!
						piece.pos = p.pos_solved
					} else {
						svpr := p.solved_viewport_rect_raw()
						pos := shy.vec2(svpr.x,svpr.y)
						piece.pos = piece.viewport_to_local(pos)// - piece.pos
					}
					piece.laid = true
				}
			}
		}

		mouse_area := piece.viewport_rect()

		if piece.id == a.puzzle.grabbed {
			piece.pos = piece.viewport_to_local(m)
		}

		if mouse_area.contains(a.mouse.x, a.mouse.y) {
			piece.hovered = true
			if is_button_event && a.mouse.is_button_down(.left) {
				if a.puzzle.grabbed == 0 {
					piece.grabbed = true
					a.puzzle.grabbed = piece.id
					piece.pos = piece.viewport_to_local(m)
					piece.laid = false
				}
			}
		}
		if !piece.is_solved() {
			// println('${piece.xy.x},${piece.xy.y} is not solved: ${piece.pos} vs ${piece.pos_solved}')
			solved = false
		}
	}
	if solved {
		a.puzzle.reset()
	}
}
