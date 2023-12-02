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

# Manages a set of cameras, providing enable / disable control as well as
# smooth transitions between cameras.
class_name HecateCameraManager extends Node

# Map from camera name to corresponding HecateCamera object, and also an
# ordered list of the camera in the order registered.
var _cameras : Dictionary
var _cameras_ordered : Array[HecateCamera]

# Register a new named camera. Return false if unable to register the camera
# because a camera of the given 'camera_name' already exists in the manager.
func register_camera(camera_name : String, camera : HecateCamera) -> bool:
	if _cameras.has(camera_name):
		return false
	_cameras[camera_name] = camera
	_cameras_ordered.append(camera)
	return true

# Make the named camera the active camera and all other cameras inactive.
# Return false if unable to make the named camera active.
func activate_camera(camera_name : String) -> bool:
	if not _cameras.has(camera_name):
		return false
	for n in _cameras:
		_cameras[n].current = (n == camera_name)
	return true

# Active the "next" camera in the list of ordered cameras. If no camera
# is currently activated, activate the first camera. Return false if there
# are no cameras to activate.
func activate_camera_next() -> bool:
	if _cameras_ordered.is_empty():
		return false
	if _cameras_ordered.size() > 1:
		for idx in range(_cameras_ordered.size()):
			if _cameras_ordered[idx].current:
				_cameras_ordered[idx].current = false
				_cameras_ordered[(idx + 1) % _cameras_ordered.size()].current = true
				return true
		_cameras_ordered[0].current = true
	return true

# Active the "previous" camera in the list of ordered cameras. If no camera
# is currently activated, activate the last camera. Return false if there
# are no cameras to activate.
func activate_camera_prev() -> bool:
	if _cameras_ordered.is_empty():
		return false
	if _cameras_ordered.size() > 1:
		for idx in range(_cameras_ordered.size() - 1, -1, -1):
			if _cameras_ordered[idx].current:
				_cameras_ordered[idx].current = false
				if idx == 0:
					_cameras_ordered[_cameras_ordered.size() - 1].current = true
				else:
					_cameras_ordered[idx - 1].current = true
				return true
		_cameras_ordered[_cameras_ordered.size() - 1].current = true
	return true
