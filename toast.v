// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.ease
import shy.utils

pub struct Toast {
	id       u16
	text     string
	duration f32 // 1.5 = 1.5 seconds
mut:
	timer &shy.Timer = shy.null
	fader &shy.Animator[f32] = shy.null
}

pub fn (mut a App) show_toast(toast Toast) {
	a.toast_ids++
	tid := a.toast_ids

	mut timer := a.shy.new_timer(
		duration: u64(toast.duration * 1000 * (a.toasts.len + 1)) // NOTE * (a.toasts.len+1) is a poor man's queue system...
	)
	timer.callback = fn [tid, mut a] () {
		for mut toast in a.toasts {
			if toast.id == tid {
				ac := shy.AnimatorConfig{
					running: true
					duration: 500
					ease: ease.Ease{
						kind: .sine
						mode: .out
					}
					on_event_fn: fn [tid, mut a] (ud voidptr, ae shy.AnimEvent) {
						if ae == .end {
							for i, toast in a.toasts {
								if toast.id == tid {
									a.toasts.delete(i)
								}
							}
						}
					}
				}
				toast.fader = a.shy.new_animator[f32](ac)
				toast.fader.init(f32(1), 0, 500)
				toast.fader.run()
			}
		}
	}
	timer.run()

	t := Toast{
		...toast
		id: tid
		timer: timer
	}
	a.toasts << t
}

pub fn (a &App) draw_toasts(dt f64) {
	if toast := a.toasts[0] {
		x := shy.half * a.canvas.width
		y := a.canvas.height * 0.1
		mut color := colors.white
		mut frame_bg_color := colors.grey
		draw_scale := a.window.draw_factor()
		mut design_factor := f32(1440) / a.canvas.width
		if design_factor == 0 {
			design_factor = 1
		}
		size_factor := 1 / design_factor * draw_scale
		if !isnil(toast.timer) && toast.timer.running {
			et := a.easy.text(
				text: toast.text
				x: x
				y: y
				origin: .center
				size: 50 * size_factor
			)
			bounds := et.bounds()
			a.quick.rect(
				color: frame_bg_color
				x: x
				y: y
				width: bounds.width + 20 * size_factor
				height: bounds.height + 20 * size_factor
				origin: .center
			)
			et.draw()
		} else if !isnil(toast.fader) && toast.fader.running {
			color.a = utils.remap_f32_to_u8(toast.fader.value(), 0, 1, 0, 255)
			frame_bg_color.a = utils.remap_f32_to_u8(toast.fader.value(), 0, 1, 0, 255)
			et := a.easy.text(
				text: toast.text
				color: color
				x: x
				y: y
				origin: .center
				size: 50 * size_factor
			)
			bounds := et.bounds()
			a.quick.rect(
				color: frame_bg_color
				x: x
				y: y
				width: bounds.width + 20 * size_factor
				height: bounds.height + 20 * size_factor
				origin: .center
				stroke: shy.Stroke{
					color: color
				}
			)
			et.draw()
		}
	}
}
