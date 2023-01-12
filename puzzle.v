// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import rand
import shy.lib as shy
import shy.mth
import shy.utils
import shy.vec { Vec2 }
// import shy.matrix

[heap]
struct Puzzle {
	shy.Rect // Holds the board top-left *scaled* x,y pos *inside* the viewport, width and height are the original image w/h before scaling
	app &App // TODO abstract drawing out into user-land?
mut:
	viewport   shy.Rect // Area defining the rendered output
	image      shy.Image
	dim        shy.Size // width: amount of horizontal pieces, height: amount of vertical pieces
	piece_size shy.Size // smallest, "most used" piece_size
	pieces     []&Piece
	pieces_map map[string]&Piece // yuk
	grabbed    u32 // id of the piece currently grabbed
	scale      f32
	margin     f32 = 0.75 // 0.1 - 0.9; percentage of minimum available screen space to fill
	solved     bool
}

[params]
struct PuzzleConfig {
	app        &App     // TODO abstract drawing out into user-land?
	viewport   shy.Rect // Area defining the rendered output
	image      shy.Image
	dimensions shy.Size // width: amount of horizontal pieces, height: amount of vertical pieces
}

[heap]
struct Piece {
	app    &App
	puzzle &Puzzle
mut:
	id         u32       // flat index row major
	xy         Vec2[u32] // x,y piece id top-left = 0,0 bottom-right = puzzle.dim.w-1/h-1
	pos        Vec2[f32] // x,y in *viewport*
	size       shy.Size  // size before scaling
	pos_solved Vec2[f32] // x,y in viewport when solved/untouched
	hovered    bool
	grabbed    bool
	laid       bool = true
}

pub fn new_puzzle(pc PuzzleConfig) !&Puzzle {
	a := pc.app
	viewport := pc.viewport
	img := pc.image
	dim := pc.dimensions

	piece_size := shy.Size{
		width: u32(img.width / dim.width)
		height: u32(img.height / dim.height)
	}

	rem_w := u32(img.width - (dim.width * piece_size.width))
	rem_h := u32(img.height - (dim.height * piece_size.height))

	// arw, arh := mth.reduce_fraction(u64(mth.max(piece_size.width, piece_size.height)), u64(mth.min(piece_size.width, piece_size.height)))
	// println('${arw}:${arh}')

	// dump(img)

	mut puzzle := &Puzzle{
		viewport: viewport
		width: img.width
		height: img.height
		app: a
		image: img
		piece_size: piece_size
		dim: dim
	}

	assert !isnil(puzzle.app)

	mut pid := u32(0)
	for x in 0 .. int(dim.width) {
		for y in 0 .. int(dim.height) {
			pid++
			mut size := piece_size
			if x == int(dim.width) - 1 {
				size.width += rem_w
			}
			if y == int(dim.height) - 1 {
				size.height += rem_h
			}

			pos_solved := shy.vec2[f32](x * (piece_size.width * 0.5), y * (piece_size.height * 0.5))
			pos := pos_solved
			piece := &Piece{
				app: a
				puzzle: puzzle
				id: pid
				xy: shy.vec2[u32](x, y)
				pos: pos
				pos_solved: pos_solved
				size: size
			}
			assert !isnil(piece.puzzle)
			assert !isnil(piece.app)
			puzzle.pieces << piece
			puzzle.pieces_map['${piece.xy.x}${piece.xy.y}'] = piece
		}
	}
	assert puzzle.pieces.len == dim.width * dim.height
	puzzle.set_viewport(viewport)

	puzzle.scramble()!

	println('${puzzle.pieces.len} pieces. Viewport: ${viewport.width}x${viewport.height} ${img.width}x${img.height} ${piece_size.width}x${piece_size.height} ${rem_w}x${rem_h} puzzle scale: ${puzzle.scale}')
	return puzzle
}

pub fn (mut p Puzzle) reset() {
	for mut piece in p.pieces {
		piece.reset()
	}
	p.solved = true
}

//[live]
pub fn (mut p Puzzle) fit_scale_ratio() f32 {
	img := p.image
	viewport := p.viewport
	return mth.min(f32(viewport.height) / (img.height), f32(viewport.width) / (img.width))
}

pub fn (mut p Puzzle) update_scale() {
	margin := mth.max(mth.min(p.margin, 0.99), 0.01)
	scale := p.fit_scale_ratio()
	p.scale = scale * margin
}

pub fn (mut p Puzzle) set_viewport(viewport shy.Rect) {
	p.viewport = viewport
	p.update_scale()
	p.x = p.center().x
	p.y = p.center().y
}

[params]
struct ScrambleOptions {
	do_not_scramble_laid bool
}

pub fn (mut p Puzzle) scramble(opt ScrambleOptions) ! {
	viewport := p.viewport
	for mut piece in p.pieces {
		if opt.do_not_scramble_laid && piece.laid {
			continue
		}
		vp_rect := piece.viewport_rect()
		piece_size := shy.Size{
			width: vp_rect.width
			height: vp_rect.height
		}
		mut x_range_min := piece_size.width * 0.5
		mut x_range_max := viewport.width - x_range_min
		mut y_range_min := piece_size.height * 0.5
		mut y_range_max := viewport.height - y_range_min

		if x_range_min > x_range_max {
			x_range_min, x_range_max = x_range_max, x_range_min
		}
		if y_range_min > y_range_max {
			y_range_min, y_range_max = y_range_max, y_range_min
		}

		// println('Win: ${win_size.width}x${win_size.height} aspect: ${aspect} Ranges x/y: ${x_range_min},${x_range_max}/${y_range_min},${y_range_max}')

		r_x := rand.f32_in_range(x_range_min, x_range_max) or { return error('${@FN}: ${err}') }
		r_y := rand.f32_in_range(y_range_min, y_range_max) or { return error('${@FN}: ${err}') }

		piece.pos = piece.viewport_to_local(shy.vec2(r_x, r_y))
		piece.laid = false
		// If *any* of the pieces gets scrambled, the puzzle is unsolved.
		p.solved = false
	}
}

pub fn (p &Piece) is_solved() bool {
	return p.laid && p.pos.eq_epsilon(p.pos_solved)
}

pub fn (p &Puzzle) center() Vec2[f32] {
	viewport := p.viewport
	scale := p.scale
	return Vec2[f32]{
		x: viewport.x + (viewport.width * shy.half) - (p.width * shy.half) * scale
		y: viewport.y + (viewport.height * shy.half) - (p.height * shy.half) * scale
	}
}

pub fn (p &Puzzle) get_solved_piece(viewport_pos Vec2[f32]) ?&Piece {
	vp := viewport_pos
	board := shy.Rect{
		x: p.x
		y: p.y
		width: p.width * p.scale
		height: p.height * p.scale
	}
	if board.contains(vp.x, vp.y) {
		for piece in p.pieces {
			if piece.solved_viewport_rect().contains(vp.x, vp.y) {
				return piece
			}
		}
	}
	return none
}

pub fn (p &Puzzle) get_quadrant(viewport_pos Vec2[f32]) ?shy.Rect {
	if piece := p.get_solved_piece(viewport_pos) {
		return piece.solved_viewport_rect()
	}
	return none
}

pub fn (mut p Puzzle) auto_solve() {
	for mut piece in p.pieces {
		piece.pos = piece.pos_solved
		piece.laid = true
	}
	p.solved = true
}

fn (mut p Puzzle) draw() {
	a := p.app
	// NOTE can be uncommented to live/debug scaling
	// p.update_scale()

	scale := p.scale

	pos := shy.vec2(p.x, p.y)

	a.quick.image(
		x: pos.x
		y: pos.y
		uri: p.image.uri()
		scale: scale
		color: shy.rgba(255, 255, 255, 5)
	)

	a.quick.rect(
		x: pos.x - 2
		y: pos.y - 2
		width: (p.width) * scale + 4
		height: (p.height) * scale + 4
		color: shy.rgba(255, 255, 255, 25)
		fills: .body
	)

	if p.grabbed != shy.null && a.mouse.is_button_down(.left) {
		m := shy.vec2(f32(a.mouse.x), a.mouse.y)
		if rect := p.get_quadrant(m) {
			a.quick.rect(
				x: rect.x
				y: rect.y
				width: (rect.width)
				height: (rect.height)
				color: shy.rgba(255, 155, 255, 25)
				fills: .body
			)
		}
	}
}

pub fn (p &Piece) viewport_rect() shy.Rect {
	area := p.viewport_rect_raw()
	return area.displaced_from(.center)
}

pub fn (p &Piece) viewport_rect_raw() shy.Rect {
	scale := p.puzzle.scale
	offset := p.viewport_offset()
	pos := p.local_to_viewport(p.pos)

	area := shy.Rect{
		x: pos.x + offset.x
		y: pos.y + offset.y
		width: p.size.width * scale
		height: p.size.height * scale
	}

	return area
}

pub fn (p &Piece) solved_viewport_rect() shy.Rect {
	area := p.solved_viewport_rect_raw()
	return area.displaced_from(.center)
}

pub fn (p &Piece) solved_viewport_rect_raw() shy.Rect {
	scale := p.puzzle.scale
	offset := p.viewport_offset()
	pos := p.local_to_viewport(p.pos_solved)

	area := shy.Rect{
		x: pos.x + offset.x
		y: pos.y + offset.y
		width: p.size.width * scale
		height: p.size.height * scale
	}

	return area
}

pub fn (mut p Piece) reset() {
	p.pos = p.pos_solved
	p.hovered = false
	p.grabbed = false
	p.laid = true
}

// The region of the puzzle image this piece represents/depicts
fn (p &Piece) region() shy.Rect {
	return shy.Rect{
		x: p.xy.x * p.puzzle.piece_size.width
		y: p.xy.y * p.puzzle.piece_size.height
		width: p.size.width
		height: p.size.height
	}
}

pub fn (p &Piece) viewport_offset() Vec2[f32] {
	pz := p.puzzle
	scale := pz.scale

	ps_w := pz.piece_size.width * scale
	ps_h := pz.piece_size.height * scale

	compensate_origin := shy.vec2(int(0.5 * ps_w), int(0.5 * ps_h))

	piece_displace := shy.vec2((p.xy.x * ps_w * 0.5), (p.xy.y * ps_h * 0.5))

	offset := shy.vec2[f32](compensate_origin.x + piece_displace.x, compensate_origin.y +
		piece_displace.y)

	// NOTE kept for visual debugging purposes
	// margins := 0
	// if margins > 0 {
	// 	margin := shy.Size{
	// 		width: margins
	// 		height: margins
	// 	}
	// 	offset.x += (p.xy.x * margin.width)
	// 	offset.y += (p.xy.y * margin.height)
	// }

	return offset
}

pub fn (p &Puzzle) viewport_to_local(viewport_pos Vec2[f32]) Vec2[f32] {
	scale := p.scale
	mut p_pos := viewport_pos
	p_pos *= shy.vec2[f32]((1 / scale), (1 / scale))
	p_pos -= shy.vec2[f32](p.x * (1 / scale), p.y * (1 / scale))
	return p_pos
}

pub fn (p &Piece) local_to_viewport(pos Vec2[f32]) Vec2[f32] {
	pz := p.puzzle
	scale := pz.scale
	size_diff_w := (p.size.width - pz.piece_size.width) * scale
	size_diff_h := (p.size.height - pz.piece_size.height) * scale
	// println('${size_diff_w}x$size_diff_h')
	mut new_pos := shy.vec2[f32](0, 0)
	new_pos.x = (pos.x) * scale + size_diff_w / 2 + pz.x
	new_pos.y = (pos.y) * scale + size_diff_h / 2 + pz.y
	return new_pos
}

pub fn (mut p Piece) viewport_to_local(viewport_pos Vec2[f32]) Vec2[f32] {
	mut p_pos := p.puzzle.viewport_to_local(viewport_pos)
	p_pos -= shy.vec2[f32](p.size.width * 0.5, p.size.height * 0.5)
	p_pos -= p.pos_solved
	return p_pos
}

//[live]
pub fn (p &Piece) draw() {
	a := p.app
	pz := p.puzzle
	mut scale := pz.scale
	mut grab_scale := f32(1)
	offset := p.viewport_offset()
	pos := p.local_to_viewport(p.pos)

	if p.grabbed {
		// Draw shadow under grabbed piece
		grab_scale = 1.05
		scale *= grab_scale

		shadow_color := shy.rgba(0, 0, 0, 70)

		shadow_offset := utils.remap(f32(0.025), 0, 1, 0, pz.image.width) * scale

		a.quick.rect(
			Rect: p.viewport_rect()
			offset: shy.vec2[f32](shadow_offset, shadow_offset)
			color: shadow_color
			fills: .body
		)
	}

	// println('${pos_x} vs ${mth.round_to_even(pos_x)}')
	// if p.xy.x == 0 && p.xy.y == 0 {
	// println('Pos: ${pos_x}x${pos_y}\nRegion: ${region}\nOffset: ${offset}\n')
	//}

	a.quick.image(
		x: pos.x
		y: pos.y
		uri: p.puzzle.image.uri()
		origin: .center
		scale: scale
		offset: offset
		region: p.region()
	)

	/*
	TODO this is a slow mess, but only used when debugging...
	mut design_factor := mth.min(f32(1440) / a.window.width(), f32(720) / a.window.height())
	if design_factor == 0 {
		design_factor = 1
	}
	font_size_factor := 1/design_factor * a.window.draw_factor() * p.puzzle.scale
	font_size := f32(22) * font_size_factor
	a.quick.text(
		x: pos.x
		y: pos.y
		offset: offset
		align: .center
		origin: .center
		size: font_size
		text: '${p.xy.x:.0},${p.xy.y:.0}' + '\n${p.size.width:.0},${p.size.height:.0}' +
			'\n${p.pos.x:.0},${p.pos.y:.0}'
	)
	*/

	if p.puzzle.solved {
		return
	}

	if p.grabbed {
		mut color := shy.colors.shy.white
		color.a = 127
		a.quick.rect(
			Rect: p.viewport_rect_raw()
			fills: .outline
			origin: .center
			scale: grab_scale
			// offset: offset
			stroke: shy.Stroke{
				color: color
				width: 3
			}
		)
	}
}
