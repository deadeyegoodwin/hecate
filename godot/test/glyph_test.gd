# Copyright 2023, David Goodwin. All rights reserved.
#
# This file is part of Hecate. Hecate is free software: you can
# redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#
# Hecate is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with Hecate. If not, see <https://www.gnu.org/licenses/>.

# Make sure @tool is uncommented in glyph.gd and glyph_stroke.gd.
@tool

# Demonstates HecateGlyph and HecateGlyphStroke. To start a new glyph stroke or
# to add points to the current stroke, move the $Marker3D to the desired position
# and press <Spacebar>. To end the current stoke, press <End>.
class_name HecateGlyphTest extends Node

# The Marker3D used to specify a point to add to the glyph.
@onready var _marker := $Marker3D

# The glyph.
@onready var _glyph := $Glyph

# The pool of glyph strokes that are available for this test. Once these strokes
# are used the test must be restarted to get more strokes. This is unlike how
# glyphs work in Hecate because there strokes are created dynamically, but for
# testing it is better to have strokes be part of the scene tree.
@onready var _stroke_pool : Array[HecateGlyphStroke] = [
	$Stroke0, $Stroke1, $Stroke2, $Stroke3]

# Debounce key presses...
var _key_debounce := false

func _ready() -> void:
	_glyph.set_strokes_pool(_stroke_pool)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	# Space-bar starts a new stroke or adds a point to the current glyph stroke.
	# 'End' key ends the current stroke.
	if Input.is_key_pressed(KEY_SPACE):
		if not _key_debounce:
			if _glyph.is_active_stroke():
				_glyph.add_to_stroke(_marker.position)
			else:
				_glyph.start_stroke(_marker.position)
			_key_debounce = true
	elif Input.is_key_pressed(KEY_END):
		if not _key_debounce:
			_glyph.end_stroke()
			_key_debounce = true
	else:
		if not _key_debounce and _glyph.is_active_stroke():
			_glyph.update_stroke(_marker.position)
		_key_debounce = false
