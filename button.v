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
	a             &App
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
	a := b.a

	mut text := b.label
	area := b.Rect
	drawable_size := a.canvas
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

	mut design_factor := f32(1440) / drawable_size.width
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
	a := mb.a

	mut text := mb.label
	area := mb.Button.Rect
	drawable_size := a.canvas
	draw_scale := a.window.draw_factor()
	mut bgcolor := shy.colors.shy.red
	if mb.is_hovered {
		bgcolor = shy.colors.shy.blue
		if mb.click_started {
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
		scale: mb.scale
	)

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
		size: 48 * font_size_factor
		text: text
	)
}

fn (mut mb MenuButton) variable_update(dt f64) {
	drawable_size := mb.a.canvas
	area := shy.Rect{
		x: shy.half * drawable_size.width
		y: shy.half * drawable_size.height + (drawable_size.height * 0.15)
		width: 0.12 * drawable_size.width
		height: 0.05 * drawable_size.width
	}
	mb.Button.Rect = area
}

// BackButton
[heap]
struct BackButton {
	Button
}

fn (bb BackButton) draw() {
	// bb.Button.draw()
	a := bb.a

	mut text := bb.label
	area := bb.Button.Rect
	drawable_size := a.canvas
	draw_scale := a.window.draw_factor()
	mut color := shy.colors.shy.white
	if bb.is_hovered {
		color.a = 200 // shy.colors.shy.blue
		if bb.click_started {
			color.a = 127 // shy.colors.shy.green
		}
	}

	mut design_factor := f32(1440) / drawable_size.width
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

fn (mut bb BackButton) variable_update(dt f64) {
	drawable_size := bb.a.canvas
	area := shy.Rect{
		x: drawable_size.width - 10 - (0.07 * drawable_size.width) +
			((0.07 * drawable_size.width) * 0.5)
		y: 10 + ((0.08 * drawable_size.height) * 0.5)
		width: 0.07 * drawable_size.width
		height: 0.08 * drawable_size.height
	}
	// println('Area: ${area}')
	bb.Button.Rect = area
}