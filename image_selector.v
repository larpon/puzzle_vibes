// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

// import shy.mth
import shy.lib as shy
import shy.mth

struct ImageSelectorEntry {
	removable bool
	name      string
	source    shy.AssetSource
}

@[heap]
struct ImageSelector {
	shy.Rect
mut:
	app           &App
	label         string
	scale         f32 = 1.0
	click_started bool
	is_hovered    bool
	on_clicked    fn () bool = unsafe { nil } // TODO V BUG: using ?fn () bool doesn't work with closures
	on_hovered    fn () bool = unsafe { nil } // TODO V BUG: using ?fn () bool doesn't work with closures
	on_leave      fn () bool = unsafe { nil } // TODO V BUG: using ?fn () bool doesn't work with closures
	on_pressed    fn () bool = unsafe { nil } // TODO V BUG: using ?fn () bool doesn't work with closures
	images        []ImageSelectorEntry
	selected      int
}

fn (ims ImageSelector) window_rect() shy.Rect {
	f := ims.app.canvas().factor
	sf := f32(1) / f * f
	return ims.Rect.mul_scalar(sf)
}

fn (ims ImageSelector) get_selected_image() ?ImageSelectorEntry {
	return ims.images[ims.selected]
}

fn (mut ims ImageSelector) remove_selected_image() {
	ims.images.delete(ims.selected)
	ims.selected--
	ims.next_image()
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

fn (ims &ImageSelector) window_de_origin_rect() shy.Rect {
	ims_rect := ims.window_rect()
	return shy.Rect{
		x: ims_rect.x - shy.half * ims_rect.width
		y: ims_rect.y - shy.half * ims_rect.height
		width: ims_rect.width
		height: ims_rect.height
	}
}

//[live]
fn (ims ImageSelector) draw() {
	a := ims.app

	mut text := ims.label
	area_center := ims.Rect
	// top_left := shy.vec2(area_center.x - shy.half * area_center.width,area_center.y - shy.half * area_center.height)
	draw_canvas := a.canvas()
	draw_scale := a.canvas().factor
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
		origin: shy.Anchor.center
		color: bgcolor
		fills: .body
		/*
		stroke: shy.Stroke{
			width: 3
			color: border_color
		}*/
		scale: ims.scale
	)

	mut design_factor := f32(1440) / draw_canvas.width
	if design_factor == 0 {
		design_factor = 1
	}
	font_size_factor := 1 / design_factor * draw_scale * ims.scale

	if ims.images.len > 0 {
		image := ims.images[ims.selected]
		text = image.name
		scale := f32(0.95)
		a.quick.image(
			x: area_center.x
			y: area_center.y
			width: area_center.width
			height: area_center.height
			source: image.source
			origin: .center
			scale: scale
			fill_mode: .aspect_crop //.aspect_fit
		)

		if image.removable {
			margin := area_center.height * 0.1
			radius := mth.min(area_center.width, area_center.height) * 0.05

			close_center_x := (area_center.x + (shy.half * area_center.width * scale) - margin) // * scale
			close_center_y := (area_center.y - (shy.half * area_center.height * scale) + margin) //* scale
			a.quick.circle(
				x: int(close_center_x)
				y: int(close_center_y)
				radius: int(radius)
				color: colors.red
				// origin: shy.Anchor.center
				// fills: .body
			)
			a.quick.rect(
				x: int(close_center_x)
				y: int(close_center_y)
				width: int(radius)
				height: int(radius * 0.2)
				color: colors.white
				origin: shy.Anchor.center
				rotation: 45 * shy.deg2rad
				fills: .body
			)
			a.quick.rect(
				x: int(close_center_x)
				y: int(close_center_y)
				width: int(radius)
				height: int(radius * 0.2)
				color: colors.white
				origin: shy.Anchor.center
				rotation: -45 * shy.deg2rad
				fills: .body
			)
		}
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

	text_as_runes := text.runes()
	if text_as_runes.len > 28 {
		text = text_as_runes[..25].string() + '...'
	}

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
