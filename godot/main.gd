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

# Top-level node.
extends Node

# Camera
@onready var _camera := $CameraPivot
# Meters per second that the camera moves
var _camera_move_speed : int = 20

# The arena
@onready var _arena : HecateArena = $Arena

func _ready() -> void:
	$CameraPivot/Camera.current = false
	_camera.position = Vector3(
		4, 4, 0.95 * max(_arena.size().x, _arena.size().z))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	# Toggle between first-person and arena cameras.
	if Input.is_action_just_pressed("toggle_arena_camera"):
		if $CameraPivot/Camera.current:
			$CameraPivot/Camera.current = false
		else:
			$CameraPivot/Camera.make_current()

	# Move the camera...
	var input_dir := Input.get_vector(
		"arena_camera_move_left", "arena_camera_move_right", "arena_camera_move_forward", "arena_camera_move_back")
	var direction = (_camera.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var new_position : Vector3 = _camera.position + direction * _camera_move_speed * delta
	if new_position.length() > 2.0:
		_camera.position += direction * _camera_move_speed * delta
	_camera.look_at(_arena.position)
