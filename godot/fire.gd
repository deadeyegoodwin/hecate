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

# Noise texture and underlying image used for light flickering
@export var _noise : NoiseTexture2D
var _noise_image : Image
var _offset : int

func _ready() -> void:
	_initial_energy = _light.light_energy
	_initial_indirect_energy = _light.light_indirect_energy
	_noise_image = _noise.get_image()
	if _noise_image == null:
		await _noise.changed
		_noise_image = _noise.get_image()
		assert(_noise_image != null)
	_offset = randi_range(0, _noise_image.get_width() - 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	if _noise_image != null:
		var d := _noise_image.get_pixel(_offset, 0)
		_light.light_energy = _initial_energy * d.r
		_light.light_indirect_energy = _initial_indirect_energy * d.r
		_offset = (_offset + 1) % _noise_image.get_width()
