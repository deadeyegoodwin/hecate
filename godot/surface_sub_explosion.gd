# Copyright 2024, David Goodwin. All rights reserved.
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

# Required because this class is used in some @tool scripts.
# See https://github.com/godotengine/godot/issues/81250
#@tool

# A part of an explosion on a flat surface (e.g. wall).
class_name HecateSurfaceSubExplosion extends Node3D

# The kinds of sub-explosions available.
enum Kind { BOLT_SINGLE, BOLT_MULTI }

## 1D texture that determines visibility for some kinds over the firing duration.
## Controlled by 'visibility_speed' and 'visibility_offset' the texture is sampled
## based on firing duration and an 'r' channel value > 'visibility_threshold'
## indicates that the sub-explosion is visible.
static var _visibility_noise : NoiseTexture2D

## The kind of sub-explosion.
@export var kind : Kind = Kind.BOLT_SINGLE :
	set(v):
		kind = v
		match kind:
			Kind.BOLT_SINGLE:
				_sub = $BoltSingle
			Kind.BOLT_MULTI:
				_sub = $BoltMulti

## Size of mesh containing the sub-explosion.
@export var mesh_size := Vector2(1.0, 1.0) :
	set(v):
		mesh_size = v
		if _sub != null:
			_sub.mesh.size = mesh_size

## Color of the sub-explosion.
@export var color := Color.WHITE_SMOKE :
	set(v):
		color = v
		if (_sub != null) and (_sub.mesh != null) and (_sub.mesh.material != null):
			_sub.mesh.material.set_shader_parameter("hue", color.h)
			_sub.mesh.material.set_shader_parameter("saturation", color.s)
			_sub.mesh.material.set_shader_parameter("value", color.v)

## Rate at which 'visibility_noise' is sampled. A value of 1.0 indicates that
## the entire 'visibility_noise' texture will be used over the duration of the
## sub-explisions's firing, a value of 0.75 indicates that 75% of
## 'visibility_noise' will be used, etc.
@export_range(0.0, 1.0) var visibility_speed : float = 1.0

## Offset into 'visibility_noise' texture.
@export_range(0.0, 1.0) var visibility_offset : float = 0.0

## Threshold value of 'visibility_noise' texture 'r' channel. A value greater
## than 'visibility_threshold' indicates sub-explosion is visible.
@export_range(0.0, 1.0) var visibility_threshold : float = 0.5

## Amount of variation in path of sub-explosion over duration of firing.
@export_range(0.0, 1.0) var jitter : float = 0.0

# The mesh representing the particular sub-explosion kind.
var _sub : MeshInstance3D = null

# Image derived from visiblity_noise.
static var _visibility_noise_image : Image
static var _visibility_noise_width : int = 0

# 'jitter' converted to radians.
var _jitter_angle : float = 0.0

# Starting speed for the sub-explosion, in meters / sec. The sub-explosion
# travels in the local positive Y direction.
var _speed : float

# Duration, in seconds, for the sub-explosion. '_duration' == 0 indicates that
# the sub-explosion is not active.
var _duration : float = 0.0

# The total time that has elapsed since the start of the sub-explosion firing.
var _total_elapsed : float

# The elapsed time since the sub-explosion transform was last updated.
var _last_update_elapsed : float

# "Fire" the sub-explosion at a given speed and duration, in seconds.
func fire(speed : float, duration : float, delay : float = 0.0,
			flip : bool = false, rot : bool = false) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	_speed = speed
	_duration = duration
	_total_elapsed = 0.0
	_last_update_elapsed = 0.0
	if flip:
		_sub.transform = _sub.transform.rotated_local(Vector3.UP, PI)
	if rot:
		_sub.transform = _sub.transform.rotated_local(Vector3.RIGHT, PI)

static func _static_init() -> void:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.seed = 661
	noise.frequency = 0.095
	noise.cellular_jitter = 3.0

	_visibility_noise = NoiseTexture2D.new()
	_visibility_noise.width = 256
	_visibility_noise.height = 1
	_visibility_noise.generate_mipmaps = false
	_visibility_noise.seamless = true
	_visibility_noise.noise = noise
	await _visibility_noise.changed
	_visibility_noise_image = _visibility_noise.get_image()
	assert(_visibility_noise_image != null)
	_visibility_noise_width = _visibility_noise_image.get_width()

func _ready() -> void:
	_sub.mesh.material.set_shader_parameter("hue", color.h)
	_sub.mesh.material.set_shader_parameter("saturation", color.s)
	_sub.mesh.material.set_shader_parameter("value", color.v)
	_sub.mesh.size = mesh_size

	_jitter_angle = PI * jitter

	# '_visibility_noise_image' is set in static initializer, but perhaps
	# it could still be awaiting noise completion, so we double check here...
	assert(_visibility_noise_image != null)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	if _sub == null: return
	if _duration == 0.0:
		_sub.visible = false
	elif _total_elapsed >= _duration:
		_duration = 0.0
		_sub.visible = false
		queue_free()
	else:
		var progress : float = min(1.0, _total_elapsed / _duration)
		var vidx : int = int(
			float(_visibility_noise_width) * (visibility_offset + (progress * visibility_speed)))
		var vpixel := _visibility_noise_image.get_pixel(vidx % _visibility_noise_width, 0)
		var new_visibility : bool = (vpixel.r >= visibility_threshold)
		if _sub.visible != new_visibility:
			if not _sub.visible:
				transform = transform.rotated_local(Vector3.BACK, randf_range(-_jitter_angle, _jitter_angle))
				transform = transform.translated_local(
					Vector3(0.0, _speed * (_total_elapsed - _last_update_elapsed), 0.0))
				_last_update_elapsed = _total_elapsed
			_sub.visible = new_visibility
	_total_elapsed += delta
