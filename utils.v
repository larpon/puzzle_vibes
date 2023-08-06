// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import os

[unsafe]
fn commit_hash() string {
	mut static hash := ''
	if hash == '' {
		git_exe := os.find_abs_path_of_executable('git') or { '' }
		if git_exe != '' {
			mut git_cmd := 'git -C "${exe_dir()}" rev-parse --short HEAD'
			$if windows {
				git_cmd = 'git.exe -C "${exe_dir()}" rev-parse --short HEAD'
			}
			res := os.execute(git_cmd)
			if res.exit_code == 0 {
				hash = res.output
			}
		}
	}
	return hash.trim_space()
}

fn version_full() string {
	mut v := version()
	ch := unsafe { commit_hash() }
	if ch != '' {
		v = '${v} ${ch}'
	}
	$if debug {
		v += ' (debug)'
	}
	$if prod {
		v = 'v${v}'
	}
	return v
}

fn version() string {
	mut v := '0.0.0'
	vmod := @VMOD_FILE
	if vmod.len > 0 {
		if vmod.contains('version:') {
			v = vmod.all_after('version:').all_before('\n').replace("'", '').replace('"',
				'').trim_space()
		}
	}
	return v
}

fn exe_dir() string {
	return os.dir(os.real_path(os.executable()))
}
