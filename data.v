// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy

const default_image = 'images/classical_ruin_tiles.png'

const image_db = parse_image_db($embed_file('assets/images/images.txt').to_string())

const music_db = parse_music_db($embed_file('assets/music/music.txt').to_string())

const sfx_db = parse_sfx_db($embed_file('assets/sfx/sfx.txt').to_string())

struct Music {
	info  MusicInfo
	sound shy.Sound
}

struct ImageInfo {
	name    string
	file    string
	url     string
	comment string
}

fn (i []ImageInfo) get_name(n string) ?ImageInfo {
	for e in i {
		if e.name == n {
			return e
		}
	}
	return none
}

struct MusicInfo {
	name    string
	file    string
	url     string
	comment string
}

fn (i []MusicInfo) get_name(n string) ?MusicInfo {
	for e in i {
		if e.name == n {
			return e
		}
	}
	return none
}

struct SFXInfo {
	name    string
	file    string
	url     string
	comment string
}

fn (i []SFXInfo) get_name(n string) ?SFXInfo {
	for e in i {
		if e.name == n {
			return e
		}
	}
	return none
}

fn parse_image_db(raw string) []ImageInfo {
	lines := parse_db(raw)
	mut db := []ImageInfo{}
	for line in lines {
		fields := line.split('|').map(it.trim_space())
		if fields.len < 4 {
			continue
		}
		// dump(fields)
		db << ImageInfo{
			name:    fields[0]
			file:    fields[1]
			url:     fields[2]
			comment: fields[2]
		}
	}
	return db
}

fn parse_music_db(raw string) []MusicInfo {
	lines := parse_db(raw)
	mut db := []MusicInfo{}
	for line in lines {
		fields := line.split('|').map(it.trim_space())
		if fields.len < 4 {
			continue
		}
		db << MusicInfo{
			name:    fields[0]
			file:    fields[1]
			url:     fields[2]
			comment: fields[2]
		}
	}
	return db
}

fn parse_sfx_db(raw string) []SFXInfo {
	lines := parse_db(raw)
	mut db := []SFXInfo{}
	for line in lines {
		fields := line.split('|').map(it.trim_space())
		if fields.len < 4 {
			continue
		}
		db << SFXInfo{
			name:    fields[0]
			file:    fields[1]
			url:     fields[2]
			comment: fields[2]
		}
	}
	return db
}

fn parse_db(raw string) []string {
	return raw.replace('\r', '').split('\n').filter(!it.trim_space().starts_with('#')).filter(it.trim_space() != '')
}
