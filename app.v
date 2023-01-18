// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import os
import shy.lib as shy
// import shy.vec
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
	mode         Mode //= .game
	puzzle       &Puzzle     = shy.null
	start_button &MenuButton = shy.null
	is_starting  bool
}

[heap]
struct MenuButton {
	shy.Rect
mut:
	a             &App
	label         string
	scale         f32 = 1.0
	click_started bool
	is_hovered    bool
	on_clicked    fn (mut button MenuButton) bool
	on_hovered    fn (mut button MenuButton) bool
	on_leave      fn (mut button MenuButton) bool
	on_pressed    fn (mut button MenuButton) bool
}

fn (mb MenuButton) draw() {
	a := mb.a

	mut text := mb.label
	area := mb.Rect
	drawable_size := a.canvas
	draw_scale := a.window.draw_factor()
	mouse_area := area.displaced_from(.center)
	mut color := shy.colors.shy.red
	if mouse_area.contains(a.mouse.x, a.mouse.y) {
		color = shy.colors.shy.blue
		if mb.click_started {
			color = shy.colors.shy.green
		}
	}

	a.quick.rect(
		Rect: area
		origin: .center
		color: color
		stroke: shy.Stroke{
			width: 3
		}
		scale: mb.scale
	)

	/*
	a.quick.rect(
		Rect: mouse_area
		color: shy.rgba(127,127,127,180)
	)*/

	mut design_factor := f32(1440) / drawable_size.width
	if design_factor == 0 {
		design_factor = 1
	}
	font_size_factor := 1 / design_factor * draw_scale * mb.scale

	a.quick.text(
		x: area.x
		y: area.y
		align: .center
		origin: .center
		size: 50 * font_size_factor
		text: text
	)
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!
	// win_size = win_size.mul_scalar(0.5)
	// win_size.width *= 0.5
	// win_size.height *= 0.5

	a.quick.load(shy.ImageOptions{
		uri: a.asset(default_image)
	})!

	a.quick.load(shy.ImageOptions{
		uri: a.asset('images/seamless_wooden_texture.jpg')
		wrap_u: .repeat
		wrap_v: .repeat
	})!

	img := a.assets.get[shy.Image](a.asset(default_image))!

	dim := shy.Size{
		width: 3
		height: 3
	}

	viewport := a.canvas.to_rect()

	a.puzzle = new_puzzle(
		app: a
		viewport: viewport
		image: img
		dimensions: dim
	)!

	a.mouse.on_button_down(fn [mut a] (mce shy.MouseButtonEvent) bool {
		if a.mode != .menu {
			return false
		}
		if mce.button != .left {
			return false
		}
		mouse := a.mouse
		mut mb := a.start_button
		area := mb.Rect
		mouse_area := area.displaced_from(.center)
		if mouse_area.contains(mouse.x, mouse.y) {
			// println(mce.clicks)
			mb.click_started = true
			if mb.on_pressed != unsafe { nil } {
				return mb.on_pressed(mut mb)
			}
		}
		return false
	})

	a.mouse.on_motion(fn [mut a] (mce shy.MouseMotionEvent) bool {
		if a.mode != .menu {
			return false
		}
		mouse := a.mouse
		mut mb := a.start_button
		area := mb.Rect
		mouse_area := area.displaced_from(.center)
		if mouse_area.contains(mouse.x, mouse.y) {
			mb.is_hovered = true
			if mb.on_hovered != unsafe { nil } {
				return mb.on_hovered(mut mb)
			}
		} else {
			if mb.on_leave != unsafe { nil } {
				return mb.on_leave(mut mb)
			}
			mb.is_hovered = false
		}
		return false
	})

	a.mouse.on_button_click(fn [mut a] (mce shy.MouseButtonEvent) bool {
		if a.mode != .menu {
			return false
		}
		if mce.button != .left {
			return false
		}
		mouse := a.mouse
		mut mb := a.start_button
		was_started := mb.click_started
		mb.click_started = false
		area := mb.Rect
		mouse_area := area.displaced_from(.center)
		if was_started && mouse_area.contains(mouse.x, mouse.y) {
			// println(mce.clicks)
			if mb.on_clicked != unsafe { nil } {
				return mb.on_clicked(mut mb)
			}
		}
		return false
	})

	a.mouse.on_button_click(fn [mut a] (mce shy.MouseButtonEvent) bool {
		if a.mode != .game {
			return false
		}
		if mce.button != .left {
			return false
		}
		if a.puzzle.solved {
			// println('${a.mode} -> .game')
			a.mode = .menu
			return true
		}
		return false
	})

	// Menu
	a.start_button = &MenuButton{
		a: a
		label: 'START'
		on_clicked: fn (mut button MenuButton) bool {
			mut a := button.a
			a.puzzle.scramble() or { panic(err) }
			a.shy.once(fn [mut a, mut button] () {
				// println('${a.mode} -> .game')
				button.scale = 1
				a.mode = .game
			}, 150)
			return true
		}
		on_pressed: fn (mut button MenuButton) bool {
			button.scale = 0.98
			return false
		}
		on_leave: fn (mut button MenuButton) bool {
			button.scale = 1
			return false
		}
	}
}

[markused]
pub fn (mut a App) frame(dt f64) {
	// a.draw.push_matrix()
	// a.draw.scale(0.5,0.5,1)
	// a.draw.translate(0,1280,0)
	// println('mode: ${a.mode}')
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
	drawable_size := a.canvas
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
	a.start_button.Rect = area

	a.start_button.draw()
}

pub fn (mut a App) render_game_frame(dt f64) {
	mut design_factor := f32(1440) / a.window.width()
	if design_factor == 0 {
		design_factor = 1
	}

	// Background
	a.quick.image(
		x: 0
		y: 0
		uri: a.asset('images/seamless_wooden_texture.jpg')
		width: a.canvas.width
		height: a.canvas.height
		fill_mode: .tile
	)
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
			if !a.puzzle.solved {
				mut color := shy.colors.shy.white
				color.a = 127
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
		}

		// println(mouse_area)
	}

	if grabbed_piece != shy.null {
		grabbed_piece.draw()
	}

	if a.puzzle.solved {
		cover := a.canvas
		mut color := shy.colors.shy.green
		color.a = 200
		a.quick.rect(
			Rect: cover.to_rect()
			color: color
			fills: .body
		)

		font_size_factor := 1 / design_factor * a.window.draw_factor()

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

// asset returns a `string` with the full path to the asset.
// asset unifies locating project assets.
pub fn (a App) asset(relative_path_to_app string) string {
	$if wasm32_emscripten {
		return relative_path_to_app
	}
	return os.resource_abs_path(os.join_path('assets', relative_path_to_app))
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
					if a.mode == .game {
						a.puzzle.scramble(do_not_scramble_laid: true) or { panic(err) }
					}
					if a.mode == .menu {
						a.mode = .game
					}
				}
				.a {
					a.puzzle.auto_solve()
				}
				else {}
			}
		}
		shy.MouseMotionEvent {
			a.on_game_event_update(e)
		}
		shy.MouseButtonEvent {
			a.on_game_event_update(e)
		}
		shy.WindowResizeEvent {
			mut viewport := a.canvas.to_rect()
			a.puzzle.set_viewport(viewport)
		}
		else {}
	}
}

type GameEvent = shy.MouseButtonEvent | shy.MouseMotionEvent

type UIEvent = shy.MouseButtonEvent | shy.MouseMotionEvent

// [live]
pub fn (mut a App) on_menu_event_update(event_type UIEvent) {
	if a.mode != .menu {
		return
	}

	// is_button_event := event_type is shy.MouseButtonEvent
}

pub fn (mut a App) on_game_event_update(event_type GameEvent) {
	if a.mode != .game {
		return
	}

	if a.puzzle.solved {
		return
	}

	is_button_event := event_type is shy.MouseButtonEvent

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
						pos := shy.vec2(svpr.x, svpr.y)
						piece.pos = piece.viewport_to_local(pos) // - piece.pos
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
