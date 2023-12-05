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

# An arena containing player and opponents.
class_name HecateArena extends Node3D

# The camera manager and the camera used to view the entire arena.
@export var camera_manager : HecateCameraManager
@onready var _camera : HecateOrbitCamera = $OrbitCamera

# The player and opponent.
@onready var _player := $Player
@onready var _opponent := $Opponent

# The overall size of the arena. A const export would be useful here but
# not supported so use the size() function to get this value. Note that the
# size of the arena is determined by the size of the meshes that make up
# the arena and so this value must be changed whenever the arena meshes are
# changed.
const _arena_size := Vector3(6.0, 6.0, 10.0)

# Get the bounding-box size of the arena.
func size() -> Vector3:
	return _arena_size

func _ready() -> void:
	var r := camera_manager.register_camera(name, _camera); assert(r)
	camera_manager.activate_camera(name)

	if camera_manager != null:
		r = _player.set_camera_manager(camera_manager); assert(r)
		r = _opponent.set_camera_manager(camera_manager); assert(r)

	_camera.append_focus(Vector3(0, 2.0, 0), 5.0, PI / 2.0)
	_camera.append_focus(_player.transform.origin + Vector3(0, 1.0, 0), 3.0, PI / 4.0)
	_camera.append_focus(_opponent.transform.origin + Vector3(0, 1.0, 0), 3.0, PI * 0.75)
