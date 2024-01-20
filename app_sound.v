// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import rand

fn (a App) play_sfx_with_volume(entry string, volume f32) {
	a.quick.play(
		source: a.asset('sfx/' + a.sfx[entry].file)
		volume: volume
	)
}

fn (a App) play_sfx(entry string) {
	a.quick.play(
		source: a.asset('sfx/' + a.sfx[entry].file)
	)
}

fn (a App) play_sfx_with_pitch(entry string, pitch f32) {
	a.quick.play(
		source: a.asset('sfx/' + a.sfx[entry].file)
		pitch: pitch
	)
}

fn (a App) play_sfx_with_random_pitch(entry string) {
	a.quick.play(
		source: a.asset('sfx/' + a.sfx[entry].file)
		pitch: rand.f32_in_range(0.8, 1.2) or { 0.0 }
	)
}

fn (a App) play_sfx_with_random_pitch_in_range(entry string, from f32, to f32) {
	a.quick.play(
		source: a.asset('sfx/' + a.sfx[entry].file)
		pitch: rand.f32_in_range(from, to) or { 0.0 }
	)
}

pub fn (a &App) stop_music() {
	for _, v in a.music {
		if v.sound.is_playing() {
			v.sound.stop()
		}
	}
}

pub fn (a &App) play_cheer() {
	a.play_sfx_with_volume('Cheering crowd', 0.435)
}

pub fn (mut a App) play_music(key string) {
	a.cur_music = key
	unsafe { a.music[a.cur_music].sound.play() }
	// entry := a.music[a.cur_music]
	// 	a.show_toast(Toast{
	// 		text: 'Now playing "${entry.info.name}"'
	// 		duration: 3.5
	// 	})
}

pub fn (mut a App) play_random_music() {
	if a.music.len > 0 {
		a.stop_music()
		keys := a.music.keys()
		mut next := rand.int_in_range(0, keys.len) or { 0 }
		mut song := keys[next]
		if a.music.len > 1 {
			retries := 10
			mut retry := 0
			for song == a.cur_music {
				retry++
				next = rand.int_in_range(0, keys.len) or { 0 }
				song = keys[next]
				if retry >= retries || song != a.cur_music {
					break
				}
			}
		}
		a.play_music(song)
	}
}
