# Copyright (c) 2023, David Goodwin. All rights reserved.

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
	await _noise.changed
	_noise_image = _noise.get_image()
	_offset = randi_range(0, _noise_image.get_width() - 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	var d := _noise_image.get_pixel(_offset, 0)
	_light.light_energy = _initial_energy * d.r
	_light.light_indirect_energy = _initial_indirect_energy * d.r
	_offset = (_offset + 1) % _noise_image.get_width()
