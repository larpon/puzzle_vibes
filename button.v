// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

// import shy.mth
import shy.lib as shy

[heap]
struct Button {
	shy.Rect
mut:
	app             &App = unsafe { nil }
	label         string
	scale         f32 = 1.0
	click_started bool
	is_hovered    bool
	on_clicked    fn () bool
	on_hovered    fn () bool
	on_leave      fn () bool
	on_pressed    fn () bool
}

fn (b Button) draw() {
	a := b.app

	mut text := b.label
	area := b.Rect
	canvas_size := a.canvas
	draw_scale := a.window.draw_factor()
	mut bgcolor := shy.colors.shy.red
	if b.is_hovered {
		bgcolor = shy.colors.shy.blue
		if b.click_started {
			bgcolor = shy.colors.shy.green
		}
	}

	a.quick.rect(
		Rect: area
		origin: .center
		color: bgcolor
		stroke: shy.Stroke{
			width: 3
		}
		scale: b.scale
	)

	/*
	a.quick.rect(
		Rect: mouse_area
		color: shy.rgba(127,127,127,180)
	)*/

	mut design_factor := f32(1440) / canvas_size.width
	if design_factor == 0 {
		design_factor = 1
	}
	font_size_factor := 1 / design_factor * draw_scale * b.scale

	a.quick.text(
		x: area.x
		y: area.y
		align: .center
		origin: .center
		size: 50 * font_size_factor
		text: text
	)
}

fn (mut b Button) variable_update(dt f64) {}

// MenuButton
[heap]
struct MenuButton {
	Button
}

fn (mb MenuButton) draw() {
	a := mb.app

	mut text := mb.label
	area := mb.Button.Rect
	canvas_size := a.canvas
	draw_scale := a.window.draw_factor()
	base_color := colors.blue
	mut bgcolor := base_color
	if mb.is_hovered {
		bgcolor = base_color.lighter()
		if mb.click_started {
			bgcolor = base_color.darker()
		}
	}

	a.quick.rect(
		Rect: area
		origin: .center
		color: bgcolor
		stroke: shy.Stroke{
			width: 3
		}
		scale: mb.scale
	)

	mut design_factor := f32(1440) / canvas_size.width
	if design_factor == 0 {
		design_factor = 1
	}
	font_size_factor := 1 / design_factor * draw_scale * mb.scale

	a.quick.text(
		x: area.x
		y: area.y
		align: .center
		origin: .center
		size: 48 * font_size_factor
		text: text
	)
}

// BackButton
[heap]
struct BackButton {
	Button
}

fn (bb BackButton) draw() {
	// bb.Button.draw()
	a := bb.app

	mut text := bb.label
	area := bb.Button.Rect
	canvas_size := a.canvas
	draw_scale := a.window.draw_factor()
	mut color := shy.colors.shy.white
	if bb.is_hovered {
		color.a = 200 // shy.colors.shy.blue
		if bb.click_started {
			color.a = 127 // shy.colors.shy.green
		}
	}

	mut design_factor := f32(1440) / canvas_size.width
	if design_factor == 0 {
		design_factor = 1
	}
	font_size_factor := 1 / design_factor * draw_scale * bb.scale

	a.quick.text(
		x: area.x
		y: area.y
		align: .center
		origin: .center
		color: color
		size: 42 * font_size_factor
		text: text
	)
}

fn (mut bb BackButton) on_resize() {
	canvas_size := bb.app.canvas
	area := shy.Rect{
		x: canvas_size.width - 10 - (0.07 * canvas_size.width) + ((0.07 * canvas_size.width) * 0.5)
		y: 10 + ((0.08 * canvas_size.height) * 0.5)
		width: 0.07 * canvas_size.width
		height: 0.08 * canvas_size.height
	}
	// println('Area: ${area}')
	bb.Button.Rect = area
}

// OptionsButton
[heap]
struct OptionsButton {
	Button
}

fn (ob OptionsButton) draw() {
	// bb.Button.draw()
	a := ob.app

	mut text := ob.label
	area := ob.Button.Rect
	canvas_size := a.canvas
	draw_scale := a.window.draw_factor()
	mut color := shy.colors.shy.white
	if ob.is_hovered {
		color.a = 200 // shy.colors.shy.blue
		if ob.click_started {
			color.a = 127 // shy.colors.shy.green
		}
	}

	mut design_factor := f32(1440) / canvas_size.width
	if design_factor == 0 {
		design_factor = 1
	}
	font_size_factor := 1 / design_factor * draw_scale * ob.scale

	a.quick.text(
		x: area.x
		y: area.y
		align: .center
		origin: .center
		color: color
		size: 42 * font_size_factor
		text: text
	)
}

fn (mut ob OptionsButton) on_resize() {
	canvas_size := ob.app.canvas
	area := shy.Rect{
		x: 10 + (0.04 * canvas_size.width) + ((0.04 * canvas_size.width) * 0.5)
		y: 10 + ((0.08 * canvas_size.height) * 0.5)
		width: 0.11 * canvas_size.width
		height: 0.08 * canvas_size.height
	}
	// println('Area: ${area}')
	ob.Button.Rect = area
}
