// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import os
import rand
import shy.lib as shy
// import shy.vec
// import shy.matrix
import shy.embed
import shy.particle
import shy.easy

enum Mode {
	menu
	game
}

[heap]
pub struct App {
	embed.ExampleApp
mut:
	mode           Mode //= .game
	puzzle         &Puzzle        = shy.null
	image_selector &ImageSelector = shy.null
	start_button   &MenuButton    = shy.null
	back_button    &BackButton    = shy.null
	is_starting    bool
	ps             &easy.ParticleSystem = shy.null
	//
	sfx   map[string]SFXInfo
	music map[string]Music
}

fn (a App) play_sfx_with_random_pitch(entry string) {
	a.quick.play(
		source: a.asset('sfx/' + a.sfx[entry].file)
		pitch: rand.f32_in_range(1, 3) or { 0.0 }
	)
}

fn (a App) play_sfx(entry string) {
	a.quick.play(
		source: a.asset('sfx/' + a.sfx[entry].file)
	)
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!
	// win_size = win_size.mul_scalar(0.5)
	// win_size.width *= 0.5
	// win_size.height *= 0.5

	a.ps = a.easy.new_particle_system(
		width: a.canvas.width
		height: a.canvas.height
		pool: 2500
	)

	design_factor := f32(1440) / a.canvas.width
	scale := f32(2.0) * 1 / design_factor
	a.ps.add(&particle.Emitter{
		enabled: false // true
		rate: 50
		position: shy.vec2[f32](shy.half * a.canvas.width, shy.half * a.canvas.height)
		velocity: particle.AngleDirection{
			angle: 0
			angle_variation: 360
			magnitude: 15
			magnitude_variation: 1
		}
		acceleration: particle.AngleDirection{
			angle: 0
			angle_variation: 360
			magnitude: -20
			magnitude_variation: 2
		}
		start_size: shy.vec2[f32](30.0 * scale, 35 * scale)
		size_variation: shy.vec2[f32](10.0 * scale, 10 * scale)
		life_time: 500 //* (1 / design_factor)
		life_time_variation: 500 //* (1 / design_factor)
		movement_velocity: 20 * (1 / design_factor)
	})

	a.ps.replace_default_painter(a.easy.image_particle_painter(
		color: shy.rgba(255, 255, 255, 100)
	))

	a.quick.load(shy.ImageOptions{
		source: a.asset(default_image)
	})!

	mut puzzle_images := []ImageSelectorEntry{}
	puzzle_images << ImageSelectorEntry{
		name: 'Pixel Art Ruins'
		source: a.asset(default_image)
	}
	for e in image_db {
		image := a.asset(os.join_path('images', e.file))
		entry := ImageSelectorEntry{
			name: e.name
			source: image
		}
		if entry !in puzzle_images {
			a.quick.load(shy.ImageOptions{
				source: image
			})!
			puzzle_images << entry
		}
	}

	a.quick.load(shy.ImageOptions{
		source: a.asset('images/puzzle_vibes_logo.png')
	})!

	a.quick.load(shy.ImageOptions{
		source: a.asset('images/seamless_wooden_texture.jpg')
		wrap_u: .repeat
		wrap_v: .repeat
	})!

	// 	mut asset := a.easy.load(source: a.asset('music/River Meditation.mp3'))!
	// 	a.music['River Meditation'] = asset.to[shy.Sound](shy.SoundOptions{})!

	for e in music_db {
		music := a.asset(os.join_path('music', e.file))
		mut asset := a.easy.load(source: music)!
		mut sound := asset.to[shy.Sound](shy.SoundOptions{})!
		sound.on_end = fn (sound shy.Sound) {
			// println('sound id: ${sound.id} ended')
			app := sound.asset.shy.app[App]()
			// println('Restarting River Meditation')
			if app.music.len > 0 {
				keys := app.music.keys()
				next := rand.int_in_range(0, keys.len) or { 0 }
				app.music[keys[next]].sound.play()
			}
		}
		a.music[e.name] = Music{
			info: e
			sound: sound
		}
	}
	a.music['River Meditation'].sound.play()

	// 	a.music['River Meditation'].on_start = fn (sound shy.Sound) {
	// 		println('River Meditation started sound id: ${sound.id}')
	// 	}
	// 	a.music['River Meditation'].on_pause = fn (sound shy.Sound, paused bool) {
	// 		println('River Meditation paused:${paused} sound id: ${sound.id}')
	// 	}
	// 	a.music['River Meditation'].on_end = fn (sound shy.Sound) {
	// 		println('River Meditation ended sound id: ${sound.id}')
	// 		app := sound.asset.shy.app[App]()
	// 		println('Restarting River Meditation')
	// 		app.music['River Meditation'].play()
	// 	}
	// 	a.music['River Meditation'].play()

	img := a.assets.get[shy.Image](a.asset(default_image))!

	for e in sfx_db {
		sfx := a.asset(os.join_path('sfx', e.file))
		a.sfx[e.name] = e
		a.quick.load(shy.SoundOptions{
			source: sfx
			max_repeats: 3
		})!
	}

	viewport := a.canvas.to_rect()

	a.puzzle = new_puzzle(
		app: a
		viewport: viewport
		image: img
	)!

	a.bind_button_handlers()!

	// Menu
	a.start_button = &MenuButton{
		a: a
		label: 'START'
		on_clicked: fn [mut a] () bool {
			mut button := a.start_button
			a.start_game() or { panic(err) }
			a.shy.once(fn [mut a, mut button] () {
				// println('${a.mode} -> .game')
				button.scale = 1
				a.mode = .game
			}, 150)
			return true
		}
		on_pressed: fn [mut a] () bool {
			mut button := a.start_button
			button.scale = 0.98
			a.play_sfx('Squish')
			return false
		}
		on_leave: fn [mut a] () bool {
			mut button := a.start_button
			button.scale = 1
			return false
		}
	}

	// Game
	a.back_button = &BackButton{
		a: a
		label: 'QUIT'
		on_clicked: fn [mut a] () bool {
			if a.mode == .menu {
				mut events := a.shy.events()
				events.send(shy.QuitEvent{
					timestamp: a.shy.ticks()
					window: a.window
					request: true
				}) or {}
			} else {
				mut button := a.back_button
				a.shy.once(fn [mut a, mut button] () {
					// println('${a.mode} -> .game')
					button.scale = 1
					a.mode = .menu
				}, 150)
			}
			return true
		}
		on_pressed: fn [mut a] () bool {
			a.play_sfx('Squish')
			mut button := a.back_button
			button.scale = 0.98
			return false
		}
		on_leave: fn [mut a] () bool {
			mut button := a.back_button
			button.scale = 1
			return false
		}
	}

	a.image_selector = &ImageSelector{
		a: a
		label: 'Select a puzzle'
		images: puzzle_images
		on_clicked: fn [mut a] () bool {
			if a.mode == .menu {
				ims_rect := a.image_selector.de_origin_rect()
				left_side := shy.Rect{
					x: ims_rect.x
					y: ims_rect.y
					width: shy.half * ims_rect.width
					height: ims_rect.height
				}
				// 				right_side := shy.Rect{
				// 					x: ims_rect.x + shy.half * ims_rect.width
				// 					y: ims_rect.y
				// 					width:shy.half * ims_rect.width
				// 					height: ims_rect.height
				// 				}
				if left_side.contains(a.mouse.x, a.mouse.y) {
					a.select_prev_image()
				} else {
					a.select_next_image()
				}
				return true
			}
			return false
		}
		/*
		on_pressed: fn [mut a] () bool {
			mut button := a.back_button
			button.scale = 0.98
			return false
		}
		on_leave: fn [mut a] () bool {
			mut button := a.back_button
			button.scale = 1
			return false
		}*/
	}
}

pub fn (mut a App) bind_button_handlers() ! {
	a.mouse.on_button_down(fn [mut a] (mbe shy.MouseButtonEvent) bool {
		if mbe.button != .left {
			return false
		}
		mouse := a.mouse

		mut handled := false
		mut bb := a.back_button
		mut area := bb.Button.Rect
		mut mouse_area := area.displaced_from(.center)
		if mouse_area.contains(mouse.x, mouse.y) {
			// println(mbe.clicks)
			bb.click_started = true
			if bb.on_pressed != unsafe { nil } {
				return bb.on_pressed()
			}
		}

		if a.mode == .menu {
			mut mb := a.start_button
			area = mb.Button.Rect
			mouse_area = area.displaced_from(.center)
			if mouse_area.contains(mouse.x, mouse.y) {
				// println(mbe.clicks)
				mb.click_started = true
				if mb.on_pressed != unsafe { nil } {
					return mb.on_pressed()
				}
			}

			mut ims := a.image_selector
			area = ims.Rect
			mouse_area = area.displaced_from(.center)
			if mouse_area.contains(mouse.x, mouse.y) {
				// println(imse.clicks)
				ims.click_started = true
				if ims.on_pressed != unsafe { nil } {
					return ims.on_pressed()
				}
			}
		}

		return handled
	})

	a.mouse.on_motion(fn [mut a] (mme shy.MouseMotionEvent) bool {
		mouse := a.mouse

		mut handled := false
		mut bb := a.back_button
		mut area := bb.Button.Rect
		mut mouse_area := area.displaced_from(.center)
		if mouse_area.contains(mouse.x, mouse.y) {
			bb.is_hovered = true
			if bb.on_hovered != unsafe { nil } {
				handled = bb.on_hovered()
			}
		} else {
			bb.is_hovered = false
			if bb.on_leave != unsafe { nil } {
				handled = bb.on_leave()
			}
		}
		if handled {
			return handled
		}

		if a.mode == .menu {
			mut mb := a.start_button
			area = mb.Button.Rect
			mouse_area = area.displaced_from(.center)
			if mouse_area.contains(mouse.x, mouse.y) {
				mb.is_hovered = true
				if mb.on_hovered != unsafe { nil } {
					handled = mb.on_hovered()
				}
			} else {
				mb.is_hovered = false
				if mb.on_leave != unsafe { nil } {
					handled = mb.on_leave()
				}
			}

			mut ims := a.image_selector
			area = ims.Rect
			mouse_area = area.displaced_from(.center)
			if mouse_area.contains(mouse.x, mouse.y) {
				ims.is_hovered = true
				if ims.on_hovered != unsafe { nil } {
					handled = ims.on_hovered()
				}
			} else {
				ims.is_hovered = false
				if ims.on_leave != unsafe { nil } {
					handled = ims.on_leave()
				}
			}
		}

		return handled
	})

	a.mouse.on_button_click(fn [mut a] (mbe shy.MouseButtonEvent) bool {
		if mbe.button != .left {
			return false
		}
		mouse := a.mouse
		mut handled := false

		mut bb := a.back_button
		mut was_started := bb.click_started
		bb.click_started = false
		mut area := bb.Button.Rect
		mut mouse_area := area.displaced_from(.center)
		if was_started && mouse_area.contains(mouse.x, mouse.y) {
			// println(mbe.clicks)
			if bb.on_clicked != unsafe { nil } {
				handled = bb.on_clicked()
			}
		} else {
			bb.is_hovered = false
			if bb.on_leave != unsafe { nil } {
				handled = bb.on_leave()
			}
		}
		if handled {
			return handled
		}

		mut mb_mouse_area := shy.Rect{}
		mut ims_mouse_area := shy.Rect{}
		if a.mode == .menu {
			mut mb := a.start_button
			was_started = mb.click_started
			mb.click_started = false
			area = mb.Button.Rect
			mb_mouse_area = area.displaced_from(.center)
			if was_started && mb_mouse_area.contains(mouse.x, mouse.y) {
				// println(mbe.clicks)
				if mb.on_clicked != unsafe { nil } {
					handled = mb.on_clicked()
				}
			}

			mut ims := a.image_selector
			was_started = ims.click_started
			ims.click_started = false
			area = ims.Rect
			ims_mouse_area = area.displaced_from(.center)
			if was_started && ims_mouse_area.contains(mouse.x, mouse.y) {
				// println(imse.clicks)
				if ims.on_clicked != unsafe { nil } {
					handled = ims.on_clicked()
				}
			}
		}
		if !(was_started && mb_mouse_area.contains(mouse.x, mouse.y)) {
			mut mb := a.start_button
			mb.is_hovered = false
			if mb.on_leave != unsafe { nil } {
				handled = mb.on_leave()
			}
		}
		if !(was_started && ims_mouse_area.contains(mouse.x, mouse.y)) {
			mut ims := a.image_selector
			ims.is_hovered = false
			if ims.on_leave != unsafe { nil } {
				handled = ims.on_leave()
			}
		}

		return handled
	})

	// A click anywhere when the puzzle is solved goes back to menu
	a.mouse.on_button_click(fn [mut a] (mbe shy.MouseButtonEvent) bool {
		if a.mode != .game {
			return false
		}
		if mbe.button != .left {
			return false
		}
		if a.puzzle.solved {
			// println('${a.mode} -> .game')
			a.mode = .menu
			return true
		}
		return false
	})
}

[markused]
pub fn (mut a App) variable_update(dt f64) {
	a.ExampleApp.variable_update(dt)
	// Placement of Start button
	canvas_size := a.canvas
	a.start_button.Button.Rect = shy.Rect{
		x: shy.half * canvas_size.width
		y: 0.85 * canvas_size.height //+ (canvas_size.height * 0.15)
		width: 0.12 * canvas_size.width
		height: 0.05 * canvas_size.width
	}

	a.image_selector.Rect = shy.Rect{
		x: shy.half * canvas_size.width
		y: shy.half * canvas_size.height + (canvas_size.height * 0.05)
		width: 0.40 * canvas_size.width
		height: 0.2 * canvas_size.width
	}

	if a.image_selector.images.len > 0 {
		mut emitters := a.ps.emitters()
		design_factor := f32(1440) / a.canvas.width
		scale := f32(2.0) * (1 / design_factor)
		for mut em in emitters {
			// TODO this is stupid
			// We're adjusting values so effects look a-like in different screen-widths...
			em.start_size = shy.vec2[f32](30.0 * scale, 35 * scale)
			em.size_variation = shy.vec2[f32](10.0 * scale, 10 * scale)
			// em.life_time = 1000 * (1 / design_factor)
			// em.life_time_variation = 500 * (1 / design_factor)
			em.movement_velocity = 20 * (1 / design_factor)
			em.velocity = particle.AngleDirection{
				angle: 0
				angle_variation: 360
				magnitude: 15 * (1 / design_factor)
				magnitude_variation: 1 * (1 / design_factor)
			}
			em.acceleration = particle.AngleDirection{
				angle: 0
				angle_variation: 360
				magnitude: -20 * (1 / design_factor)
				magnitude_variation: 2 * (1 / design_factor)
			}

			em.position.x = a.image_selector.x
			em.position.y = a.image_selector.y
		}
	}

	a.back_button.variable_update(dt)
	if a.mode == .menu {
		a.back_button.label = 'QUIT'
	} else {
		a.back_button.label = 'BACK'
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
	a.back_button.draw()
}

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

pub fn (mut a App) render_game_frame(dt f64) {
	mut design_factor := f32(1440) / a.canvas.width
	if design_factor == 0 {
		design_factor = 1
	}

	// Background
	a.quick.image(
		// x: 0
		// y: 0
		source: a.asset('images/seamless_wooden_texture.jpg')
		width: a.canvas.width
		height: a.canvas.height
		fill_mode: .tile
	)

	// Draw black boxes as puzzle area
	puz_scale := a.puzzle.scale
	puz_pos := shy.vec2(a.puzzle.x, a.puzzle.y)

	a.quick.rect(
		x: puz_pos.x - 3
		y: puz_pos.y - 3
		width: (a.puzzle.width) * puz_scale + 5
		height: (a.puzzle.height) * puz_scale + 5
		color: shy.rgba(0, 0, 0, 255 / 4)
		fills: .body
	)
	a.quick.rect(
		x: puz_pos.x + 2.5
		y: puz_pos.y + 2.5
		width: (a.puzzle.width) * puz_scale - 4.5
		height: (a.puzzle.height) * puz_scale - 4.5
		color: shy.rgba(0, 0, 0, 255 / 4)
		fills: .body
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
					fills: .stroke
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
		mut bgcolor := shy.colors.shy.white
		bgcolor.a = 30
		a.quick.rect(
			Rect: a.canvas.to_rect()
			color: bgcolor
			fills: .body
		)

		mut cover := a.canvas.to_rect()
		cover.y = cover.height * 0.3333
		cover.height *= 0.3333

		mut color := shy.colors.shy.green
		color.a = 180
		a.quick.rect(
			Rect: cover
			color: color
			fills: .body
		)

		font_size_factor := 1 / design_factor * a.window.draw_factor()

		font_size := f32(192) * font_size_factor
		a.quick.text(
			x: a.canvas.width * shy.half
			y: a.canvas.height * shy.half
			align: .center
			origin: .center
			size: font_size
			text: 'EXCELLENT'
		)
	}
}

// asset returns a `string` with the full path to the asset.
// asset unifies locating project assets.
pub fn (a App) asset(relative_path string) string {
	path := relative_path // relative_path.replace('\\','/')
	$if wasm32_emscripten {
		return path
	}
	return os.resource_abs_path(os.join_path('assets', path))
}

pub fn (mut a App) start_game() ! {
	dim := shy.Size{
		width: 3
		height: 3
	}
	imse := a.image_selector.get_selected_image() or {
		return error('Failed getting selected image')
	}
	img := a.assets.get[shy.Image](imse.source)!
	a.puzzle.init(
		app: a
		viewport: a.canvas.to_rect()
		image: img
		dimensions: dim
	)!

	a.puzzle.scramble()!
}

fn (mut a App) select_next_image() {
	if a.mode != .menu {
		return
	}
	mut emitters := a.ps.emitters()
	for i, mut em in emitters {
		if i == 0 {
			em.burst(400)
		}
	}
	a.image_selector.next_image()
	a.play_sfx_with_random_pitch('Whoosh')
}

fn (mut a App) select_prev_image() {
	if a.mode != .menu {
		return
	}
	// TODO reference bug
	// if mut emitter := a.ps.emitter_at_index(0) {
	//	emitter.burst(100)
	//}
	// TODO
	mut emitters := a.ps.emitters()
	for i, mut em in emitters {
		if i == 0 {
			em.burst(400)
		}
	}

	a.image_selector.prev_image()
	a.play_sfx_with_random_pitch('Whoosh')
}

[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)

	match e {
		shy.KeyEvent {
			a.on_menu_event_update(e)
			a.on_game_event_update(e)
			if e.state == .up {
				return
			}
			key := e.key_code
			// kb := a.kbd
			// alt_is_held := (kb.is_key_down(.lalt) || kb.is_key_down(.ralt))
			match key {
				.p {
					// 					mut s := a.music['River Meditation']
					// 					s.pause(!s.is_paused())
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

type GameEvent = shy.KeyEvent | shy.MouseButtonEvent | shy.MouseMotionEvent

type UIEvent = shy.KeyEvent | shy.MouseButtonEvent | shy.MouseMotionEvent

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

pub fn (mut a App) on_game_event_update(e GameEvent) {
	if a.mode != .game {
		return
	}

	if a.puzzle.solved {
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
					a.mode = .menu
				}
				.s {
					a.puzzle.scramble(do_not_scramble_laid: true) or { panic(err) }
				}
				.a {
					a.puzzle.auto_solve()
					a.play_sfx('Cheering crowd')
				}
				else {}
			}
		}
		else {}
	}

	is_button_event := e is shy.MouseButtonEvent

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
		// println('SOLVED!')
		a.play_sfx('Cheering crowd')
		a.puzzle.reset()
	}
}
