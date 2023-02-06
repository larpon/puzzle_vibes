// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

// import shy.mth
import shy.lib as shy

[heap]
struct DimensionSelector {
	shy.Rect
mut:
	a             &App
	label         string
	dim           shy.Size
	scale         f32 = 1.0
	click_started bool
	is_hovered    bool
	on_clicked    fn () bool
	on_hovered    fn () bool
	on_leave      fn () bool
	on_pressed    fn () bool
}

fn (dims &DimensionSelector) de_origin_rect() shy.Rect {
	dims_rect := dims.Rect
	return shy.Rect{
		x: dims_rect.x - shy.half * dims_rect.width
		y: dims_rect.y - shy.half * dims_rect.height
		width: dims_rect.width
		height: dims_rect.height
	}
}

//[live]
fn (dims DimensionSelector) draw() {
	a := dims.a

	mut text := dims.label
	area_center := dims.Rect
	// top_left := shy.vec2(area_center.x - shy.half * area_center.width,area_center.y - shy.half * area_center.height)
	canvas_size := a.canvas
	draw_scale := a.window.draw_factor()
	mut bgcolor := shy.rgba(0, 0, 0, 57)
	if dims.is_hovered {
		bgcolor.a = 67
		/*
		if dims.click_started {
			bgcolor = shy.colors.shy.green
		}*/
	}

	/*
	dim := a.puzzle_dim
	for row in dim.width {
		for col in dim.height {
		}
	}*/

	// mut border_color := shy.rgba(255,255,255,57)
	a.quick.rect(
		Rect: area_center
		origin: .center
		color: bgcolor
		fills: .body
		/*
		stroke: shy.Stroke{
			width: 3
			color: border_color
		}*/
		scale: dims.scale
	)

	mut design_factor := f32(1440) / canvas_size.width
	if design_factor == 0 {
		design_factor = 1
	}
	font_size_factor := 1 / design_factor * draw_scale * dims.scale

	a.quick.text(
		x: area_center.x
		y: area_center.y
		align: .center
		origin: .center
		size: 20 * font_size_factor
		text: 'No images found'
	)

	a.quick.rect(
		x: area_center.x - shy.half * area_center.width
		y: area_center.y + (shy.half * area_center.height) - area_center.height * 0.2
		width: area_center.width
		height: area_center.height * 0.2
		color: shy.rgba(0, 0, 0, 80)
		fills: .body
	)

	a.quick.text(
		x: area_center.x
		y: area_center.y + (shy.half * area_center.height) - area_center.height * 0.1
		align: .center
		origin: .center
		size: 50 * font_size_factor
		color: shy.colors.shy.black
		blur: 5
		scale: 1.01
		text: text
	)

	a.quick.text(
		x: area_center.x
		y: area_center.y + (shy.half * area_center.height) - area_center.height * 0.1
		align: .center
		origin: .center
		size: 50 * font_size_factor
		text: text
	)

	if dims.is_hovered {
		button_wh := int(0.05 * area_center.width)
		// base_color := colors.blue
		// Left navigation button
		l_rect := shy.Rect{
			x: (shy.half * button_wh) + area_center.x - shy.half * area_center.width
			y: area_center.y
			width: button_wh
			height: button_wh
		}
		/*
		Visual guide
		a.quick.rect(
			Rect: l_rect
			origin: .center
			color: base_color
			// fills: .body
// 			stroke: shy.Stroke{
// 				width: 3
// 				color: border_color
// 			}
			scale: dims.scale
		)*/
		a.quick.triangle(
			a: shy.vec2(l_rect.x, l_rect.y + shy.half * l_rect.height)
			b: shy.vec2(l_rect.x + l_rect.width, l_rect.y)
			c: shy.vec2(l_rect.x + l_rect.width, l_rect.y + l_rect.height)
			// rotation: 90
			fills: .body
			color: shy.colors.shy.white
			origin: .center
			scale: 0.7
		)

		// Right navigation button
		r_rect := shy.Rect{
			x: area_center.x + shy.half * area_center.width - (shy.half * button_wh)
			y: area_center.y
			width: button_wh
			height: button_wh
		}
		/*
		Visual guide
		a.quick.rect(
			Rect: r_rect
			origin: .center
			color: base_color
			// fills: .body
// 			stroke: shy.Stroke{
// 				width: 3
// 				color: border_color
// 			}
			scale: dims.scale
		)*/
		a.quick.triangle(
			a: shy.vec2(r_rect.x, r_rect.y)
			b: shy.vec2(r_rect.x + r_rect.width, r_rect.y + shy.half * r_rect.height)
			c: shy.vec2(r_rect.x, r_rect.y + r_rect.height)
			// rotation: rotation
			fills: .body
			color: shy.colors.shy.white
			origin: .center
			scale: 0.7
		)
	}
}
