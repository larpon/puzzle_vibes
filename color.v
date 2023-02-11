// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy

const colors = Colors{}

struct Colors {
	white shy.Color = shy.colors.shy.white
	red   shy.Color = shy.colors.shy.red
	blue  shy.Color = shy.rgb(24, 143, 216)
	grey  shy.Color = shy.rgb(127, 127, 127)
}
