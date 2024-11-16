// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import os
import time
import toml
import shy.lib as shy
import shy.paths
import shy.mth

const config_dir = os.join_path(paths.root(.config), 'Black Grain', 'blackgrain.dk', 'puzzle_vibes')

pub struct Solve {
mut:
	image_id   string // "identifier" can be just "img.png" for builtin images, whole paths for user provided
	dimensions shy.Size = shy.size(0, 0)
	time       u64 // milliseconds
}

fn (s1 Solve) is_same(s2 Solve) bool {
	return s1.image_id == s2.image_id && int(s1.dimensions.width) == int(s2.dimensions.width)
		&& int(s1.dimensions.height) == int(s2.dimensions.height)
}

fn (s Solve) is_valid() bool {
	return s.image_id != '' && s.time > 0 && s.dimensions.width > 0 && s.dimensions.height > 0
}

// is_best returns `true` if `s` and `s1` is valid and `s` is best (has lowest `time`).
fn (s Solve) is_best(s1 Solve) bool {
	return (s.is_valid() && s1.is_valid()) && s == s.get_best(s1)
}

// get_best returns the best of the solves `s` and `s1`.
// If it can not be determined `s1` is returned
fn (s Solve) get_best(s1 Solve) Solve {
	if s.time == 0 || s1.time == 0 {
		return s1
	}
	if s.time < s1.time {
		return s
	}
	return s1
}

fn (s Solve) pretty_format() string {
	return time.Duration(i64(s.time) * 1000000).str()
}

pub struct UserSettings {
mut:
	music_volume f32 = 1.0
	sfx_volume   f32 = 1.0
	images       []string
	dimensions   shy.Size = shy.size(3, 3)
	game_mode    GameMode = .relaxed
	solves       []Solve
}

fn (mut us UserSettings) defaults() {
	us.music_volume = 1.0
	us.sfx_volume = 1.0
	us.images.clear()
	us.dimensions = shy.size(3, 3)
	us.game_mode = .relaxed
	us.solves.clear()
}

fn (a &App) ensure_settings_path() !string {
	save_path := config_dir
	paths.ensure(save_path)!
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
		toml_doc := toml.parse_file(save_file)!

		if val := toml_doc.value_opt('music.volume') {
			a.settings.music_volume = val.f32()
		}

		if val := toml_doc.value_opt('sfx.volume') {
			a.settings.sfx_volume = val.f32()
		}

		if dim_width := toml_doc.value_opt('puzzle.dimensions.width') {
			max := a.dim_selector.max.x
			w := f32(dim_width.int())
			a.settings.dimensions.width = mth.max(mth.min(w, max), 1)
		}

		if dim_height := toml_doc.value_opt('puzzle.dimensions.height') {
			max := a.dim_selector.max.y
			h := f32(dim_height.int())
			a.settings.dimensions.height = mth.max(mth.min(h, max), 1)
		}
		a.dim_selector.dim = a.settings.dimensions

		if game_mode := toml_doc.value_opt('app.game_mode') {
			a.settings.game_mode = game_mode_from_string(game_mode as string)
		}

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

		// Load "highscores"
		if toml_solves := toml_doc.value_opt('solves') {
			toml_any_arr := toml_solves.array()
			for toml_any in toml_any_arr {
				dim_width := f32(toml_any.value('dimensions.width').default_to(int(0)).int())
				dim_height := f32(toml_any.value('dimensions.height').default_to(int(0)).int())
				solve := Solve{
					image_id:   toml_any.value('image_id').default_to('').string()
					dimensions: shy.size(dim_width, dim_height)
					time:       toml_any.value('time').default_to(u64(0)).u64()
				}
				if solve.is_valid() {
					a.settings.solves << solve
				}
			}
		}
	}
}

fn (mut a App) save_settings() ! {
	save_file := a.settings_file()!

	mut toml_txt := '# Puzzle Vibes settings file
format_version = "1.0.0"
'
	// TODO BUG workaround for V gcc compilation error on Windows?!
	toml_txt += '
[music]
	volume = ${a.settings.music_volume:.3f}'

	toml_txt += '

[sfx]
	volume = ${a.settings.sfx_volume:.3f}'

	toml_txt += '

[puzzle]
	dimensions.width  = ${a.settings.dimensions.width:.1f}'

	toml_txt += '
	dimensions.height = ${a.settings.dimensions.height:.1f}'

	toml_txt += '

[app]
	game_mode = "${a.settings.game_mode}"
'

	mut images_txt := '\timages = [\n'
	for image in a.settings.images {
		images_txt += "\t\t'${image}',\n"
	}
	images_txt = images_txt.trim_right(',\n')
	images_txt += '\n\t]\n'
	toml_txt += images_txt

	// Save "highscores"
	for solve in a.settings.solves {
		if solve.is_valid() {
			toml_txt += '
[[solves]]
image_id = "${solve.image_id}"
dimensions.width  = ${solve.dimensions.width:.1f}
dimensions.height = ${solve.dimensions.height:.1f}
time = ${solve.time}
'
		}
	}

	os.write_file(save_file, toml_txt)!
	// $if wasm32_emscripten {
	//   shy.emscripten_sync_fs()!
	// }
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
