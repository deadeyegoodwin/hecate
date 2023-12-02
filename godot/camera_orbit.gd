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

# A Camera3D that is associated with one or more focus points. The camera
# can switch between focus points and revolve around / zoom in-out the
# active focus point.
class_name HecateOrbitCamera extends HecateCamera

# The minimum and maximum distance from a focus for the camera.
const MIN_DISTANCE : float = 1.0
const MAX_DISTANCE : float = 30.0

## Meters per second that camera zooms in and out.
@export_range(0.1, 30.0) var zoom_speed : float = 10.0

## Radians per second that camera revolves around focus.
@export_range(0.01, PI) var revolve_speed : float = PI / 2

## Initial distance (meters) that camera sits relative to a focus.
@export_range(MIN_DISTANCE, MAX_DISTANCE) var initial_distance : float = 2.0

## Initial angle (radians) that camera sits relatve to a focus.
@export_range(0, TAU) var initial_angle : float = 0.0

# For now this camera keeps a fixed Y while revolving...
const FIXED_Y : float = 1.5

# The list of foci for the camera. The camera must have at least one focus
# to operate. For each focus keep the location of the focus, and the angle
# and distance of the camera from the focus.
class _Focus:
	var _position : Vector3
	var _distance : float
	var _angle : float  # radians
	func _init(p : Vector3, d : float, a : float):
		_position = p; _distance = d; _angle = a

var _foci : Array[_Focus]
var _foci_idx : int = 0

# Add a focus to the camera.
func append_focus(pos : Vector3, dist : float = initial_distance, ang : float = initial_angle) -> void:
	var focus := _Focus.new(pos, dist, ang)
	_foci.append(focus)
	if _foci.size() == 1:
		_update_camera(focus, 0.0, 0.0)

# Advance camera to next focus.
func next_focus() -> void:
	if not _foci.is_empty():
		_foci_idx = (_foci_idx + 1) % _foci.size()
		_update_camera(_foci[_foci_idx], 0.0, 0.0)

# Advance camera to previous focus.
func prev_focus() -> void:
	if not _foci.is_empty():
		if _foci_idx == 0:
			_foci_idx = _foci.size() - 1
		else:
			_foci_idx -= 1
		_update_camera(_foci[_foci_idx], 0.0, 0.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	# Move the camera if it is currently active.
	if (not current) or _foci.is_empty():
		return

	# Cycle through the foci...
	if Input.is_action_just_pressed("camera_next"):
		next_focus()
	elif Input.is_action_just_pressed("camera_prev"):
		prev_focus()
	else:
		# Move and update camera.
		var focus := _foci[_foci_idx]
		var zoom_delta : float = 0.0
		var revolve_delta : float = 0.0
		if Input.is_action_pressed("camera_move_left"):
			revolve_delta = 1.0
		elif Input.is_action_pressed("camera_move_right"):
			revolve_delta = -1.0
		elif Input.is_action_pressed("camera_move_forward"):
			zoom_delta = -1.0
		elif Input.is_action_pressed("camera_move_back"):
			zoom_delta = 1.0

		if (revolve_delta != 0.0) or (zoom_delta != 0.0):
			_update_camera(focus, revolve_delta * revolve_speed * delta, zoom_delta * zoom_speed * delta)

# Update the camera position and maintain orientation towards the current focus.
func _update_camera(focus : _Focus, angle_delta : float, distance_delta : float) -> void:
		focus._angle = fmod(focus._angle + angle_delta, TAU)
		focus._distance = clampf(focus._distance + distance_delta, MIN_DISTANCE, MAX_DISTANCE)
		position = focus._position + Vector3(sin(focus._angle) * focus._distance, FIXED_Y, cos(focus._angle) * focus._distance)
		look_at(focus._position)
