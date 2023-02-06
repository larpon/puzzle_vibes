// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

// import shy.mth
import shy.lib as shy

struct ImageSelectorEntry {
	name   string
	source shy.AssetSource
}

[heap]
struct ImageSelector {
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
	images        []ImageSelectorEntry
	selected      int
pub mut:
	todo_rm shy.ImageFillMode
}

fn (ims ImageSelector) get_selected_image() ?ImageSelectorEntry {
	return ims.images[ims.selected]
}

fn (mut ims ImageSelector) next_image() {
	ims.selected++
	if ims.selected >= ims.images.len {
		ims.selected = 0
	}
	if ims.selected < 0 {
		ims.selected = if ims.images.len > 0 { ims.images.len - 1 } else { 0 }
	}
}

fn (mut ims ImageSelector) prev_image() {
	ims.selected--
	if ims.selected >= ims.images.len {
		ims.selected = 0
	}
	if ims.selected < 0 {
		ims.selected = if ims.images.len > 0 { ims.images.len - 1 } else { 0 }
	}
}

fn (ims &ImageSelector) de_origin_rect() shy.Rect {
	ims_rect := ims.Rect
	return shy.Rect{
		x: ims_rect.x - shy.half * ims_rect.width
		y: ims_rect.y - shy.half * ims_rect.height
		width: ims_rect.width
		height: ims_rect.height
	}
}

//[live]
fn (ims ImageSelector) draw() {
	a := ims.a

	mut text := ims.label
	area_center := ims.Rect
	// top_left := shy.vec2(area_center.x - shy.half * area_center.width,area_center.y - shy.half * area_center.height)
	canvas_size := a.canvas
	draw_scale := a.window.draw_factor()
	mut bgcolor := shy.rgba(0, 0, 0, 57)
	if ims.is_hovered {
		bgcolor.a = 67
		/*
		if ims.click_started {
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
		scale: ims.scale
	)

	mut design_factor := f32(1440) / canvas_size.width
	if design_factor == 0 {
		design_factor = 1
	}
	font_size_factor := 1 / design_factor * draw_scale * ims.scale

	if ims.images.len > 0 {
		image := ims.images[ims.selected]
		text = image.name
		a.quick.image(
			x: area_center.x
			y: area_center.y
			width: area_center.width
			height: area_center.height
			source: image.source
			origin: .center
			scale: 0.95
			fill_mode: .aspect_crop //.aspect_fit
		)
	} else {
		a.quick.text(
			x: area_center.x
			y: area_center.y
			align: .center
			origin: .center
			size: 20 * font_size_factor
			text: 'No images found'
		)
	}

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

	if ims.is_hovered {
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
			scale: ims.scale
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
			scale: ims.scale
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
