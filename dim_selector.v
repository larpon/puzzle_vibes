// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.utils
import shy.lib as shy
import shy.vec { Vec2 }

[heap]
struct DimensionSelector {
	shy.Rect
mut:
	app   &App
	label string
	dim   shy.Size = shy.size(3, 3)
	// min Vec2[f32] = shy.vec2[f32](1,1)
	max           Vec2[f32] = shy.vec2[f32](20, 20)
	scale         f32       = 1.0
	click_started bool
	is_hovered    bool
	on_clicked    fn () bool = unsafe { nil } // TODO V BUG: using ?fn () bool doesn't work with closures
	on_hovered    fn () bool = unsafe { nil } // TODO V BUG: using ?fn () bool doesn't work with closures
	on_leave      fn () bool = unsafe { nil } // TODO V BUG: using ?fn () bool doesn't work with closures
	on_pressed    fn () bool = unsafe { nil } // TODO V BUG: using ?fn () bool doesn't work with closures
}

fn (dims DimensionSelector) window_rect() shy.Rect {
	f := dims.app.canvas.factor
	sf := f32(1) / f * f
	return dims.Rect.mul_scalar(sf)
}

fn (dims &DimensionSelector) window_de_origin_rect() shy.Rect {
	dims_rect := dims.window_rect()
	return shy.Rect{
		x: dims_rect.x - shy.half * dims_rect.width
		y: dims_rect.y - shy.half * dims_rect.height
		width: dims_rect.width
		height: dims_rect.height
	}
}

fn (dims &DimensionSelector) to_cell(xy Vec2[f32]) ?Vec2[int] {
	area_center := dims.Rect
	// min := dims.min
	max := dims.max
	// box_width := area_center.width / max.x
	// box_height := area_center.height / max.y
	top_left := shy.vec2(area_center.x - shy.half * area_center.width, area_center.y - shy.half * area_center.height)
	off := top_left //+ shy.vec2[f32](box_width*0.5,box_height*0.5)
	if xy.x >= off.x && xy.x <= off.x + area_center.x && xy.y >= off.y
		&& xy.y <= off.y + area_center.y {
		cell := shy.vec2(utils.remap(xy.x, off.x, off.x + area_center.width, 0, max.x),
			utils.remap(xy.y, off.y, off.y + area_center.height, 0, max.y))
		return Vec2[int]{
			x: int(cell.x) + 1
			y: int(cell.y) + 1
		}
	}

	return none
}

//[live]
fn (dims &DimensionSelector) draw() {
	a := dims.app

	// min := dims.min
	max := dims.max

	mut text := dims.label
	area_center := dims.Rect
	top_left := shy.vec2(area_center.x - shy.half * area_center.width, area_center.y - shy.half * area_center.height)
	draw_canvas := a.canvas
	draw_scale := a.canvas.factor
	mut bgcolor := shy.rgba(0, 0, 0, 57)
	if dims.is_hovered {
		bgcolor.a = 67
		/*
		if dims.click_started {
			bgcolor = shy.colors.shy.green
		}*/
	}

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

	mut design_factor := f32(1440) / draw_canvas.width
	if design_factor == 0 {
		design_factor = 1
	}
	font_size_factor := 1 / design_factor * draw_scale * dims.scale

	dim := dims.dim

	box_width := area_center.width / max.x
	box_height := area_center.height / max.y
	for ix in 0 .. int(max.x) {
		for iy in 0 .. int(max.y) {
			off := top_left + shy.vec2[f32](box_width * 0.5, box_height * 0.5)
			rect := shy.Rect{
				x: off.x + (ix * box_width)
				y: off.y + (iy * box_height)
				width: box_width - 1
				height: box_height - 1
			}
			mut color := shy.rgba(0, 0, 0, 27)
			// iix := ix+1
			// iiy := iy+1
			if ix <= max.x {
				if iy <= max.y {
					if ix < dim.width && iy < dim.height {
						color = shy.rgba(255, 255, 255, 200)
					}
				}
			}
			a.quick.rect(
				Rect: rect
				origin: .center
				color: color
				// color: shy.rgba(127,127,127,127) //bgcolor
				fills: .body
				/*
				stroke: shy.Stroke{
					width: 1
					color: color
				}*/
				scale: dims.scale
			)
		}
	}

	/*
	a.quick.text(
		x: area_center.x
		y: area_center.y
		align: .center
		origin: .center
		size: 20 * font_size_factor
		text: 'No images found'
	)*/

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
}
