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

# Camera manager
@onready var _camera_manager : HecateCameraManager = $CameraManager

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	# Exit to menu?
	if Input.is_action_just_pressed("exit_to_menu"):
		get_tree().change_scene_to_file("res://title_screen.tscn")

	# Cycle through the cameras...
	if Input.is_action_just_pressed("camera_manager_next"):
		_camera_manager.activate_camera_next()
	elif Input.is_action_just_pressed("camera_manager_prev"):
		_camera_manager.activate_camera_prev()
