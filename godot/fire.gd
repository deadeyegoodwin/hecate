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

## Noise texture used for light flickering
@export var flicker_noise : NoiseTexture2D

## Magnitude of noise flicker. A value of 1.0 indicates that the light can flicker
## from completely off to completely on. A value of 0.0 indicates no flicker. A value
## of 0.25 indicates that light can flicker from 75% to 100% intensity.
@export_range(0.0, 1.0) var flicker_noise_intensity : float = .75

## Emit sound for this fire.
@export var enable_sound : bool = false

# The light simulating the fire's light, and some of its properties
# initial values.
@onready var _light := $OmniLight3D
var _initial_energy : float
var _initial_indirect_energy : float

# The flame sound effect.
@onready var _sound := $FlameSound

var _flicker_noise_image : Image
var _flicker_offset : int

func _ready() -> void:
	_initial_energy = _light.light_energy
	_initial_indirect_energy = _light.light_indirect_energy
	_flicker_noise_image = flicker_noise.get_image()
	if _flicker_noise_image == null:
		await flicker_noise.changed
		_flicker_noise_image = flicker_noise.get_image()
		assert(_flicker_noise_image != null)
	_flicker_offset = randi_range(0, _flicker_noise_image.get_width() - 1)

	# Start sound if enabled...
	if enable_sound and not _sound.is_playing():
		_sound.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	if _flicker_noise_image != null:
		var d := _flicker_noise_image.get_pixel(_flicker_offset, 0)
		var intensity : float = (1 - d.r * flicker_noise_intensity)
		_light.light_energy = _initial_energy * intensity
		_light.light_indirect_energy = _initial_indirect_energy * intensity
		_flicker_offset = (_flicker_offset + 1) % _flicker_noise_image.get_width()
