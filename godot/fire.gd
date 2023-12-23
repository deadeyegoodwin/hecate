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

# Torch-like fire.
class_name HecateFire extends Node3D

# The light simulating the fire's light, and some of its properties
# initial values.
@onready var _light := $OmniLight3D
var _initial_energy : float
var _initial_indirect_energy : float

## Noise texture and underlying image used for light flickering
@export var noise : NoiseTexture2D

## Magnitude of noise flicker. A value of 1.0 indicates that the light can flicker
## from completely off to completely on. A value of 0.0 indicates no flicker. A value
## of 0.25 indicates that light can flicker from 75% to 100% intensity.
@export_range(0.0, 1.0) var noise_intensity : float = .75

var _noise_image : Image
var _offset : int

func _ready() -> void:
	_initial_energy = _light.light_energy
	_initial_indirect_energy = _light.light_indirect_energy
	_noise_image = noise.get_image()
	if _noise_image == null:
		await noise.changed
		_noise_image = noise.get_image()
		assert(_noise_image != null)
	_offset = randi_range(0, _noise_image.get_width() - 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	if _noise_image != null:
		var d := _noise_image.get_pixel(_offset, 0)
		var intensity : float = (1 - d.r * noise_intensity)
		_light.light_energy = _initial_energy * intensity
		_light.light_indirect_energy = _initial_indirect_energy * intensity
		_offset = (_offset + 1) % _noise_image.get_width()
