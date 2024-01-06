# Copyright 2024, David Goodwin. All rights reserved.
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

# To run thie test, uncomment the following line and make sure @tool is
# uncommented in surface_explosion.gd and surface_explosion_bolt.gd.
# Running the test will likely make changes to the scene files that should
# not be persisted in the repository.
#@tool

# Test for HecateSurfaceExplosion.
class_name HecateSurfaceExplosionTest extends Node3D

# Debounce key presses...
var _key_debounce := false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	# Space-bar starts a new explosion.
	if Input.is_key_pressed(KEY_SPACE):
		if not _key_debounce:
			$Explosion.fire(3.0, 5, 10, 0.6)
			_key_debounce = true
	else:
		_key_debounce = false
