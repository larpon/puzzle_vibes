// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy

const default_image = 'image/classical_ruin_tiles.png'

// const default_image = 'image/red.png'

// const default_image = 'image/colors.jpg'

// const default_image = 'image/0x0_25x22.png'

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}
