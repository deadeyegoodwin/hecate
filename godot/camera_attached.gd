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

# A Camera3D that is associated with an "attachment" point. This camera
# will mimic the position and orientation changes of the attachment, while
# looking at a focus point.
class_name HecateAttachedCamera extends HecateCamera

# The "attachment" point for the camera.
var _attachment : Node3D = null

# The transform of the attachment when the camera was last updated. At the next
# camera update any difference between this and the current attachment
# transform must be applied to the camera.
var _attachment_last_transform : Transform3D

# The focus point of the camera.
var _focus : Vector3 = Vector3.ZERO

# Set the attachment for the camera, and capture the attachment's current
# transform so that camera can mimic and changes.
func set_attachment(a : Node3D) -> void:
	_attachment = a
	_attachment_last_transform = a.global_transform

# Set the focus for the camera.
func set_focus(pos : Vector3) -> void:
	_focus = pos
	look_at(_focus)

# Update the camera position relative to attachment and maintain orientation
# towards the focus.
func _update_camera() -> void:
	if _attachment != null:
		if _attachment.global_transform != _attachment_last_transform:
			global_transform = _attachment.global_transform * _attachment_last_transform.inverse() * global_transform
			_attachment_last_transform = _attachment.global_transform
			look_at(_focus)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	# Move the camera if it is currently active.
	if (not current) or (_attachment == null):
		return
	_update_camera()
