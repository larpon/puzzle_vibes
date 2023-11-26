// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import os
import rand
import time
import shy.lib as shy
import shy.embed
import shy.particle
import shy.easy
import shy.mth

enum Mode {
	menu
	game
	options
}

enum GameMode {
	relaxed
	time
}

fn game_mode_from_string(s string) GameMode {
	return match s {
		'time' {
			.time
		}
		else {
			.relaxed
		}
	}
}

@[heap]
pub struct App {
	embed.ExampleApp
mut:
	settings       &UserSettings = &UserSettings{}
	mode           Mode //= .game // nice if you're debugging game play
	puzzle         &Puzzle            = shy.null
	image_selector &ImageSelector     = shy.null
	dim_selector   &DimensionSelector = shy.null
	start_button   &MenuButton        = shy.null
	back_button    &BackButton        = shy.null
	options_button &OptionsButton     = shy.null
	is_starting    bool
	ps             &easy.ParticleSystem = shy.null
	//
	sfx            map[string]SFXInfo
	music          map[string]Music
	cur_music      string
	hovered_pieces []Piece // To avoid re-allocating a new array every event
	toast_ids      u16
	toasts         []Toast
	//
	save_settings_next bool
	//
	game_start_time u64
	game_end_time   u64
	//
	version_full string = version_full()
}

pub fn (mut a App) shutdown() ! {
	a.save_settings() or { eprintln('Saving settings failed: ${err}') }
	a.ExampleApp.shutdown()!
}

fn (mut a App) set_mode(mode Mode) {
	from := a.mode
	to := mode

	if to == .menu {
		if from == .options {
			a.save_settings() or {
				eprintln('Saving settings failed: ${err}')
				a.show_toast(Toast{
					text: 'Saving settings failed'
					duration: 2.5
				})
			}
		}
		if from == .game {
			a.puzzle.grabbed = 0
		}
	}
	a.mode = to
}

pub fn (mut a App) update_canvas() {
	// For playing around with fake "high DPI"
	/*
	fake := f32(2)
	a.set_canvas(shy.Canvas{
    ...a.window.canvas()
    factor: fake
    factor_x: fake
    factor_y: fake
  })
	*/
}

@[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!
	a.update_canvas()
	a.window.set_title('Puzzle Vibes')

	icon := $embed_file('assets/images/icon_128x128.png')
	a.window.set_icon(icon)!

	a.ps = a.easy.new_particle_system(
		width: a.canvas().width
		height: a.canvas().height
		pool: 2500
	)

	design_factor := f32(1440) / a.canvas().width
	scale := f32(2.0) * 1 / design_factor
	a.ps.add(&particle.Emitter{
		enabled: false // true
		rate: 50
		position: shy.vec2[f32](shy.half * a.canvas().width, shy.half * a.canvas().height)
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
		resize: a.canvas().factor
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
				resize: a.canvas().factor
				source: image
			})!
			puzzle_images << entry
		}
	}

	a.quick.load(shy.ImageOptions{
		resize: a.canvas().factor
		source: a.asset('images/puzzle_vibes_logo.png')
	})!

	a.quick.load(shy.ImageOptions{
		resize: a.canvas().factor
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
			mut app := sound.asset.shy.app[App]()
			// println('Restarting River Meditation')
			app.play_random_music()
		}
		/*
		sound.on_start = fn (sound shy.Sound) {
			app := sound.asset.shy.app[App]()
			// println('Restarting River Meditation')
			app.play_random_music()
		}*/
		a.music[e.name] = Music{
			info: e
			sound: sound
		}
	}
	a.play_music('River Meditation')

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

	viewport := a.canvas().rect()

	a.puzzle = new_puzzle(
		app: a
		viewport: viewport
		image: img
	)!

	a.bind_button_handlers()!

	// Menu
	a.start_button = &MenuButton{
		app: a
		label: 'START'
		on_clicked: fn [mut a] () bool {
			mut button := a.start_button
			a.start_game() or { panic(err) }
			a.shy.once(fn [mut a, mut button] () {
				// println('${a.mode} -> .game')
				button.scale = 1
				a.set_mode(.game)
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
		app: a
		label: 'QUIT'
		on_clicked: fn [mut a] () bool {
			if a.mode == .menu {
				mut events := a.shy.events()
				events.send(shy.QuitEvent{
					timestamp: a.shy.ticks()
					window_id: a.window.id
					request: true
				}) or {}
			} else {
				if a.mode == .options {
					a.settings.dimensions = a.dim_selector.dim
				}
				mut button := a.back_button

				a.shy.once(fn [mut a, mut button] () {
					// println('${a.mode} -> .game')
					button.scale = 1
					a.set_mode(.menu)
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

	a.options_button = &OptionsButton{
		app: a
		label: 'OPTIONS'
		on_clicked: fn [mut a] () bool {
			if a.mode == .menu {
				mut button := a.options_button
				a.shy.once(fn [mut a, mut button] () {
					// println('${a.mode} -> .options')
					button.scale = 1
					a.dim_selector.dim = a.settings.dimensions
					a.set_mode(.options)
				}, 150)
				return true
			}
			return false
		}
		on_pressed: fn [mut a] () bool {
			a.play_sfx('Squish')
			mut button := a.options_button
			button.scale = 0.98
			return false
		}
		on_leave: fn [mut a] () bool {
			mut button := a.options_button
			button.scale = 1
			return false
		}
	}

	a.image_selector = &ImageSelector{
		app: a
		label: 'Select a puzzle'
		images: puzzle_images
		on_clicked: fn [mut a] () bool {
			if a.mode == .menu {
				ims_rect := a.image_selector.window_de_origin_rect()
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

				// Close button click
				if image := a.image_selector.get_selected_image() {
					ims_rect_c := a.image_selector.window_rect()
					if image.removable {
						margin := ims_rect_c.height * 0.1
						radius := (mth.min(ims_rect_c.width, ims_rect_c.height) * 0.05) * 2
						scale := f32(0.95)
						close_center_x := (ims_rect_c.x + (shy.half * ims_rect_c.width * scale) - margin)
						close_center_y := (ims_rect_c.y - (shy.half * ims_rect_c.height * scale) +
							margin)
						remove_area := shy.Rect{
							x: close_center_x
							y: close_center_y
							width: radius
							height: radius
						}.displaced_from(.center)
						if remove_area.contains(a.mouse.x, a.mouse.y) {
							a.image_selector.remove_selected_image()
							a.remove_user_image(image.source.str())
							a.show_toast(Toast{
								text: 'Removed "${image.name}"'
								duration: 1.5
							})
							return true
						}
					}
				}

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

	a.dim_selector = &DimensionSelector{
		app: a
		dim: shy.size(3, 3)
		/*
		on_clicked: fn [mut a] () bool {
			if a.mode == .options {
				cell := a.dim_selector.to_cell()
			}
			return false
		}*/
		on_pressed: fn [mut a] () bool {
			if a.mode == .options {
				if cell := a.dim_selector.to_cell(shy.vec2[f32](a.mouse.x, a.mouse.y)) {
					a.dim_selector.dim = shy.Size{
						width: cell.x
						height: cell.y
					}
					a.dim_selector.label = '${a.dim_selector.dim.width:.0f}x${a.dim_selector.dim.height:.0f} Puzzle, ${int(a.dim_selector.dim.area())} pieces'
					a.play_sfx('Squish')
					// println(cell)
				}
			}
			return false
		}
		/*
		on_leave: fn [mut a] () bool {
			mut button := a.back_button
			button.scale = 1
			return false
		}*/
	}

	// We load the image here since we need valid references to image_selector and dim_selector
	a.load_settings()!

	a.dim_selector.label = '${a.settings.dimensions.width:.0f}x${a.settings.dimensions.height:.0f} Puzzle, ${int(a.settings.dimensions.area())} pieces'

	a.on_resize()
}

pub fn (mut a App) bind_button_handlers() ! {
	a.mouse.on_button_down(fn [mut a] (mbe shy.MouseButtonEvent) bool {
		if mbe.button != .left {
			return false
		}
		mouse := a.mouse

		mut handled := false
		mut bb := a.back_button
		mut area := bb.Button.window_rect()
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
			area = mb.Button.window_rect()
			mouse_area = area.displaced_from(.center)
			if mouse_area.contains(mouse.x, mouse.y) {
				// println(mbe.clicks)
				mb.click_started = true
				if mb.on_pressed != unsafe { nil } {
					return mb.on_pressed()
				}
			}

			mut ob := a.options_button
			area = ob.Button.window_rect()
			mouse_area = area.displaced_from(.center)
			if mouse_area.contains(mouse.x, mouse.y) {
				// println(mbe.clicks)
				ob.click_started = true
				if ob.on_pressed != unsafe { nil } {
					return ob.on_pressed()
				}
			}

			mut ims := a.image_selector
			area = ims.window_rect()
			mouse_area = area.displaced_from(.center)
			if mouse_area.contains(mouse.x, mouse.y) {
				// println(imse.clicks)
				ims.click_started = true
				if ims.on_pressed != unsafe { nil } {
					return ims.on_pressed()
				}
			}
		}

		if a.mode == .options {
			mut dims := a.dim_selector
			area = dims.window_rect()
			mouse_area = area.displaced_from(.center)
			if mouse_area.contains(mouse.x, mouse.y) {
				// println(imse.clicks)
				dims.click_started = true
				if dims.on_pressed != unsafe { nil } {
					return dims.on_pressed()
				}
			}
		}

		return handled
	})

	a.mouse.on_motion(fn [mut a] (mme shy.MouseMotionEvent) bool {
		mouse := a.mouse

		mut handled := false
		mut bb := a.back_button
		mut area := bb.Button.window_rect()
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
			area = mb.Button.window_rect()
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

			mut ob := a.options_button
			area = ob.Button.window_rect()
			mouse_area = area.displaced_from(.center)
			if mouse_area.contains(mouse.x, mouse.y) {
				ob.is_hovered = true
				if ob.on_hovered != unsafe { nil } {
					handled = ob.on_hovered()
				}
			} else {
				ob.is_hovered = false
				if ob.on_leave != unsafe { nil } {
					handled = ob.on_leave()
				}
			}

			mut ims := a.image_selector
			area = ims.window_rect()
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

		if a.mode == .options {
			mut dims := a.dim_selector
			area = dims.window_rect()
			mouse_area = area.displaced_from(.center)
			if mouse_area.contains(mouse.x, mouse.y) {
				dims.is_hovered = true
				if dims.on_hovered != unsafe { nil } {
					handled = dims.on_hovered()
				}
			} else {
				dims.is_hovered = false
				if dims.on_leave != unsafe { nil } {
					handled = dims.on_leave()
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
		mut area := bb.Button.window_rect()
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

		mut ob_mouse_area := shy.Rect{}
		mut mb_mouse_area := shy.Rect{}
		mut ims_mouse_area := shy.Rect{}
		mut dims_mouse_area := shy.Rect{}
		if a.mode == .menu {
			mut mb := a.start_button
			was_started = mb.click_started
			mb.click_started = false
			area = mb.Button.window_rect()
			mb_mouse_area = area.displaced_from(.center)
			if was_started && mb_mouse_area.contains(mouse.x, mouse.y) {
				// println(mbe.clicks)
				if mb.on_clicked != unsafe { nil } {
					handled = mb.on_clicked()
				}
			}

			mut ob := a.options_button
			was_started = ob.click_started
			ob.click_started = false
			area = ob.Button.window_rect()
			ob_mouse_area = area.displaced_from(.center)
			if was_started && ob_mouse_area.contains(mouse.x, mouse.y) {
				// println(mbe.clicks)
				if ob.on_clicked != unsafe { nil } {
					handled = ob.on_clicked()
				}
			}

			mut ims := a.image_selector
			was_started = ims.click_started
			ims.click_started = false
			area = ims.window_rect()
			ims_mouse_area = area.displaced_from(.center)
			if was_started && ims_mouse_area.contains(mouse.x, mouse.y) {
				// println(imse.clicks)
				if ims.on_clicked != unsafe { nil } {
					handled = ims.on_clicked()
				}
			}
		}
		if a.mode == .options {
			mut dims := a.dim_selector
			was_started = dims.click_started
			dims.click_started = false
			area = dims.window_rect()
			dims_mouse_area = area.displaced_from(.center)
			if was_started && dims_mouse_area.contains(mouse.x, mouse.y) {
				// println(imse.clicks)
				if dims.on_clicked != unsafe { nil } {
					handled = dims.on_clicked()
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
		if !(was_started && ob_mouse_area.contains(mouse.x, mouse.y)) {
			mut ob := a.options_button
			ob.is_hovered = false
			if ob.on_leave != unsafe { nil } {
				handled = ob.on_leave()
			}
		}
		if !(was_started && ims_mouse_area.contains(mouse.x, mouse.y)) {
			mut ims := a.image_selector
			ims.is_hovered = false
			if ims.on_leave != unsafe { nil } {
				handled = ims.on_leave()
			}
		}
		if !(was_started && dims_mouse_area.contains(mouse.x, mouse.y)) {
			mut dims := a.dim_selector
			dims.is_hovered = false
			if dims.on_leave != unsafe { nil } {
				handled = dims.on_leave()
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
			a.set_mode(.menu)
			return true
		}
		return false
	})
}

pub fn (mut a App) on_resize() {
	// Placement of Start button
	a.update_canvas()
	draw_canvas := a.canvas()
	a.start_button.Button.Rect = shy.Rect{
		x: shy.half * draw_canvas.width
		y: 0.85 * draw_canvas.height //+ (draw_canvas.height * 0.15)
		width: 0.12 * draw_canvas.width
		height: 0.05 * draw_canvas.width
	}

	a.image_selector.Rect = shy.Rect{
		x: shy.half * draw_canvas.width
		y: shy.half * draw_canvas.height + (draw_canvas.height * 0.05)
		width: 0.4 * draw_canvas.width
		height: 0.2 * draw_canvas.width
	}

	a.dim_selector.Rect = shy.Rect{
		x: shy.half * draw_canvas.width
		y: shy.half * draw_canvas.height - (draw_canvas.height * 0.05)
		width: 0.3 * draw_canvas.width
		height: 0.18 * draw_canvas.width
	}

	if a.image_selector.images.len > 0 {
		mut emitters := a.ps.emitters()
		design_factor := f32(1440) / a.canvas().width
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
	a.options_button.on_resize()
	a.back_button.on_resize()
}

@[markused]
pub fn (mut a App) variable_update(dt f64) {
	a.ExampleApp.variable_update(dt)

	if a.mode == .menu {
		a.back_button.label = 'QUIT'
	} else {
		a.back_button.label = 'BACK'
	}

	if a.save_settings_next {
		a.save_settings() or {
			eprintln('Saving settings failed: ${err}')
			a.show_toast(Toast{
				text: 'Saving settings failed'
				duration: 2.5
			})
		}
		a.save_settings_next = false
	}
}

@[markused]
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
		.options {
			a.render_options_frame(dt)
		}
	}
	// a.draw.pop_matrix()
	a.back_button.draw()
	a.draw_toasts(dt)
}

// asset returns a `string` with the full path to the asset.
// asset unifies locating project assets.
pub fn (a App) asset(relative_path string) string {
	path := relative_path // relative_path.replace('\\','/')
	$if wasm32_emscripten || android {
		return path
	}
	$if macos {
		exe_dir := os.resource_abs_path('').trim_right(os.path_separator)
		if exe_dir.ends_with('MacOS') {
			if os.real_path(os.join_path(exe_dir, '..')).ends_with('Contents') {
				if os.real_path(os.join_path(exe_dir, '..', '..')).ends_with('.app') {
					return os.real_path(os.join_path(exe_dir, '..', 'Resources', 'assets',
						path))
				}
			}
		}
	}
	return os.resource_abs_path(os.join_path('assets', path))
}

pub fn (mut a App) start_game() ! {
	a.settings.dimensions = a.dim_selector.dim
	imse := a.image_selector.get_selected_image() or {
		return error('Failed getting selected image')
	}
	img := a.assets.get[shy.Image](imse.source)!

	a.puzzle.on_piece_init = fn (mut piece Piece) {
		// mut p := unsafe { piece }
		piece.rotation = rand.f32_in_range(-4, 4) or { 0 }
	}

	a.puzzle.init(
		app: a
		viewport: a.canvas().rect()
		image: img
		dimensions: a.settings.dimensions
	)!

	a.puzzle.scramble()!
	a.game_start_time = a.shy.ticks()
}

pub fn (mut a App) end_game() {
	a.game_end_time = a.shy.ticks()
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

pub fn (mut a App) add_user_image(path string) ! {
	if os.is_file(path) {
		filename := os.file_name(path)
		entry := ImageSelectorEntry{
			removable: true
			name: filename.all_before_last('.')
			source: path
		}
		a.quick.load(shy.ImageOptions{
			resize: a.canvas().factor
			source: path
		})!
		a.image_selector.images << entry
		a.image_selector.selected = a.image_selector.images.len - 1
		if path !in a.settings.images {
			a.settings.images << path
			// println(a.settings.images)
		}
	}
}

pub fn (mut a App) remove_user_image(path string) {
	for i, image_path in a.settings.images {
		if path == image_path {
			a.settings.images.delete(i)
			break
		}
	}
	a.play_sfx_with_random_pitch_in_range('Disagree', 0.8, 1.2)
}

@[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)

	match e {
		shy.DropFileEvent {
			if a.mode in [.menu, .options] {
				image := e.path
				filename := os.file_name(image)
				a.add_user_image(image) or {
					a.show_toast(Toast{
						text: 'Failed adding "${filename}"'
						duration: 2.5
					})
					return
				}
				a.show_toast(Toast{
					text: 'Added ${filename}'
					duration: 2.5
				})
				a.play_sfx('Squish')
				a.save_settings_when_time_permits()
			}
		}
		shy.KeyEvent {
			a.on_menu_event_update(e)
			a.on_options_event_update(e)
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
			mut viewport := a.canvas().rect()
			a.puzzle.set_viewport(viewport)
			a.on_resize()
		}
		else {}
	}
}

pub fn (mut a App) render_game_frame(dt f64) {
	mut design_factor := f32(1440) / a.canvas().width
	if design_factor == 0 {
		design_factor = 1
	}

	// Background
	a.quick.image(
		// x: 0
		// y: 0
		source: a.asset('images/seamless_wooden_texture.jpg')
		width: a.canvas().width
		height: a.canvas().height
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

	mut grabbed_piece := &Piece(unsafe { nil })
	for piece in a.puzzle.pieces {
		if !piece.grabbed {
			piece.draw()
		} else {
			grabbed_piece = piece
		}

		if piece.hovered {
			if !a.puzzle.solved {
				mut color := shy.colors.shy.white
				color.a = 127
				mouse_area := piece.viewport_rect_raw()
				a.quick.rect(
					// Rect: mouse_area // need int() to round off
					x: int(mouse_area.x)
					y: int(mouse_area.y)
					width: int(mouse_area.width)
					height: int(mouse_area.height)
					rotation: piece.rotation * shy.deg2rad // piece rotation is stored as degrees
					color: color
					fills: .stroke
					origin: .center
					stroke: shy.Stroke{
						color: color
					}
				)
			}
		}
	}

	if grabbed_piece != shy.null {
		grabbed_piece.draw()
	}

	if a.puzzle.solved {
		mut bgcolor := shy.colors.shy.white
		bgcolor.a = 30
		a.quick.rect(
			Rect: a.canvas().rect()
			color: bgcolor
			fills: .body
		)

		font_size_factor := 1 / design_factor * a.canvas().factor

		font_size := f32(192) * font_size_factor
		excellent_text := a.easy.text(
			x: a.canvas().width * shy.half
			y: a.canvas().height * shy.half
			align: .center
			origin: .center
			size: font_size
			text: 'EXCELLENT'
		)
		et_bounds := excellent_text.bounds()

		// TODO
		show_play_time := true
		mut play_time_text := a.easy.text(size: 0)
		if show_play_time {
			play_time := time.Duration(i64(a.game_end_time - a.game_start_time) * 1000000)
			play_time_text = a.easy.text(
				x: (a.canvas().width * shy.half)
				y: (a.canvas().height * shy.half) + (shy.half * et_bounds.height) //* 1.1
				align: .center
				origin: .top_center
				size: f32(60) * font_size_factor
				text: 'Puzzle solved in ${play_time}'
				offset: shy.vec2[f32](0, 10 * font_size_factor)
			)
		}
		ptt_bounds := play_time_text.bounds()

		mut cover := a.canvas().rect()
		cover.y = (a.canvas().height * shy.half) - shy.half * et_bounds.height - (shy.half * et_bounds.height * 0.2)
		cover.height = et_bounds.height + 2 * (shy.half * et_bounds.height * 0.2)
		if show_play_time {
			cover.y -= shy.half * ptt_bounds.height
			cover.height += ptt_bounds.height * 2
		}
		mut color := shy.colors.shy.green
		color.a = 180
		a.quick.rect(
			Rect: cover
			color: color
			fills: .body
		)

		excellent_text.draw()
		play_time_text.draw()

		// println(et_bounds)
	}
}

type GameEvent = shy.KeyEvent | shy.MouseButtonEvent | shy.MouseMotionEvent

type UIEvent = shy.KeyEvent | shy.MouseButtonEvent | shy.MouseMotionEvent

pub fn (mut a App) on_game_event_update(e GameEvent) {
	if a.mode != .game {
		return
	}

	if a.puzzle.solved {
		if e is shy.KeyEvent {
			if e.state == .up {
				return
			}
			match e.key_code {
				.backspace {
					a.set_mode(.menu)
				}
				else {}
			}
		}
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
					a.set_mode(.menu)
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
		else {}
	}

	is_button_event := e is shy.MouseButtonEvent

	m := shy.vec2[f32](a.mouse.x, a.mouse.y)
	mut solved := true

	for piece_ in a.puzzle.pieces {
		mut piece := unsafe { piece_ }
		piece.hovered = false
		// No need to check this in movement events
		if is_button_event && !a.mouse.is_button_down(.left) {
			// Handle drop
			if piece.id == a.puzzle.grabbed {
				piece.grabbed = false
				piece.rotation = rand.f32_in_range(-4, 4) or { 0 }
				a.puzzle.grabbed = 0
				a.play_sfx_with_random_pitch('Lay')
				if p := a.puzzle.get_solved_piece(m) {
					piece.rotation = 0
					if a.puzzle.has_piece_at(m) {
						a.play_sfx_with_random_pitch_in_range('Disagree', 0.8, 1.2)
						// println('Piece already in this quadrant')
						piece.pos = piece.last_pos
					} else {
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
							piece.pos = piece.viewport_to_local(pos)
						}
						piece.laid = true
					}
				}
			}
		}

		mouse_area := piece.viewport_rect()

		if piece.id == a.puzzle.grabbed {
			piece.pos = piece.viewport_to_local(m)
		}

		if mouse_area.contains(a.mouse.x, a.mouse.y) {
			piece.hovered = true
			a.hovered_pieces << piece
		}
		if !piece.is_solved() {
			// println('${piece.xy.x},${piece.xy.y} is not solved: ${piece.pos} vs ${piece.pos_solved}')
			solved = false
		}
	}

	if a.hovered_pieces.len > 0 {
		// Makes sure we grab the top-most piece by
		// sorting the ones hovered and just grab the first
		a.hovered_pieces.sort(a.id > b.id)
		if is_button_event && a.mouse.is_button_down(.left) {
			// Grab piece
			if a.puzzle.grabbed == 0 {
				hovered_piece := a.hovered_pieces[0]
				for mut piece in a.puzzle.pieces {
					if piece.id == hovered_piece.id {
						piece.grabbed = true
						piece.laid = false
						piece.rotation = 0
						a.puzzle.grabbed = piece.id
						piece.last_pos = piece.pos
						piece.pos = piece.viewport_to_local(m)
						a.play_sfx_with_random_pitch('Take')
					}
				}
			}
		}
	}
	a.hovered_pieces.clear()

	if solved {
		// println('SOLVED!')
		a.end_game()
		a.play_cheer()
		a.puzzle.reset()
	}
}
