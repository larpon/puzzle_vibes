// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import os
import toml
import shy.lib as shy
import shy.mth

pub struct UserSettings {
mut:
	music_volume f32 = 1.0
	sfx_volume   f32 = 1.0
	images       []string
	dimensions   shy.Size = shy.size(3, 3)
}

fn (mut us UserSettings) defaults() {
	us.music_volume = 1.0
	us.sfx_volume = 1.0
	us.images.clear()
	us.dimensions = shy.size(3, 3)
}

fn (a &App) ensure_settings_path() !string {
	save_path := os.join_path(os.config_dir()!, 'Black Grain', 'blackgrain.dk', 'puzzle_vibes')
	if !os.exists(save_path) {
		os.mkdir_all(save_path) or {
			return error('could not make directory "${save_path}": ${err}')
		}
	}
	return save_path
}

fn (a &App) settings_file() !string {
	save_path := a.ensure_settings_path()!
	return os.join_path(save_path, 'settings.toml')
}

fn (mut a App) save_settings_when_time_permits() {
	a.save_settings_next = true
}

fn (mut a App) load_settings() ! {
	save_file := a.settings_file()!
	if os.is_file(save_file) {
		// eprintln(os.read_file(save_file)!)
		// eprintln('---')

		toml_doc := toml.parse_file(save_file)!

		if val := toml_doc.value_opt('music.volume') {
			a.settings.music_volume = val.f32()
		}

		if val := toml_doc.value_opt('sfx.volume') {
			a.settings.sfx_volume = val.f32()
		}

		if dim_width := toml_doc.value_opt('puzzle.dimensions.width') {
			max := a.dim_selector.max.x
			w := dim_width.f32()
			a.settings.dimensions.width = mth.max(mth.min(w, max), 1)
		}

		if dim_height := toml_doc.value_opt('puzzle.dimensions.height') {
			max := a.dim_selector.max.y
			h := dim_height.f32()
			a.settings.dimensions.height = mth.max(mth.min(h, max), 1)
		}
		a.dim_selector.dim = a.settings.dimensions

		mut images := []string{}
		if toml_images := toml_doc.value_opt('app.images') {
			toml_any_arr := toml_images.array()
			images << toml_any_arr.as_strings()
		}
		// println(images)
		// eprintln(toml_doc)
		for image in images {
			a.add_user_image(image)!
		}
		// println(a.settings.images)
	}
}

fn (mut a App) save_settings() ! {
	save_file := a.settings_file()!

	mut toml_txt := '# Puzzle Vibes settings file
format_version = "1.0.0"

[music]
	volume = ${a.settings.music_volume:.3f}

[sfx]
	volume = ${a.settings.sfx_volume:.3f}

[puzzle]
	dimensions.width  = ${a.settings.dimensions.width}
	dimensions.height = ${a.settings.dimensions.height}

[app]
'
	mut images_txt := '\timages = [\n'
	for image in a.settings.images {
		images_txt += "\t\t'${image}',\n"
	}
	images_txt = images_txt.trim_right(',\n')
	images_txt += '\n\t]\n'
	toml_txt += images_txt
	os.write_file(save_file, toml_txt)!
	// eprintln('${@FN}')
	// 	a.show_toast(Toast{
	// 		text: 'Settings saved (TODO)'
	// 		duration: 2.5
	// 	})
}

fn (mut a App) reset_settings() ! {
	save_file := a.settings_file()!
	if os.is_file(save_file) {
		os.rm(save_file)!

		for i, mut image in a.image_selector.images {
			if image.removable {
				a.image_selector.images.delete(i)
				a.remove_user_image(image.source.str())
			}
		}
		a.image_selector.selected = 0
		a.settings.defaults()
	}
}
