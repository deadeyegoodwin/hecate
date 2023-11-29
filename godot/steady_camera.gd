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

# A Camera3D that can be steadied along different axes and/or follow a
# target object.
class_name HecateSteadyCamera extends Camera3D

# The initial camera transform.
var _initial_transform : Transform3D

# The position being followed by the camera. The camera will be adjusted
# continuously to look at the position.
var _is_following : bool = false
var _follow_position : Vector3

# Initialize the camera. The transform of the camera is captured so that it
# can be restored by reset().
func initialize() -> void:
	_initial_transform = transform

# Stop following a position and reset the camera transform to its
# initial tranform (as set in initialize()).
func reset() -> void:
	transform = _initial_transform

# Stop following a position and adjust the camera to look at a new position.
# The adjustment is made just once and after calling this function the camera
# is no longer following any positon.
func look(pos : Vector3) -> void:
	_is_following = false
	look_at(pos)

# Set the camera to continuously look at a given position.
func follow(pos : Vector3) -> void:
	_is_following = true
	_follow_position = pos

# Stop following a position. Camera will remain pointed in current direction.
func follow_stop() -> void:
	_is_following = false

# Called at a fixed interval (default 60Hz)
func _physics_process(_delta : float) -> void:
	# If following a position update the camera...
	if _is_following:
		look_at(_follow_position)
