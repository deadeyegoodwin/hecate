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

# A bolt of an explosion on a flat surface (e.g. wall).
class_name HecateSurfaceExplosionBolt extends Node3D

# The kinds of bolts available.
enum BoltKind { SINGLE, MULTI }

## 1D texture that determines visibility of the bolt over the firing duration.
## Controlled by 'visibility_speed' and 'visibility_offset' the texture is sampled
## based on firing duration and an 'r' channel value > 'visibility_threshold'
## indicates that the bolt is visible.
static var _visibility_noise : NoiseTexture2D

## The kind of bolt.
@export var kind : BoltKind = BoltKind.SINGLE :
	set(v):
		kind = v
		match kind:
			BoltKind.SINGLE:
				_bolt = $BoltSingle
			BoltKind.MULTI:
				_bolt = $BoltMulti

## Rate at which 'visibility_noise' is sampled. A value of 1.0 indicates that
## the entire 'visibility_noise' texture will be used over the duration of the
## bolt's firing, a value of 0.75 indicates that 75% of 'visibility_noise' will
## be used, etc.
@export_range(0.0, 1.0) var visibility_speed : float = 1.0

## Offset into 'visibility_noise' texture.
@export_range(0.0, 1.0) var visibility_offset : float = 0.0

## Threshold value of 'visibility_noise' texture 'r' channel. A value greater
## than 'visibility_threshold' indicates that bolt is visible.
@export_range(0.0, 1.0) var visibility_threshold : float = 0.5

## Amount of variation in path of bolt over duration of firing.
@export_range(0.0, 1.0) var jitter : float = 0.0

# The mesh representing the particular bolt kind.
var _bolt : MeshInstance3D = null

# Image derived from visiblity_noise.
static var _visibility_noise_image : Image
static var _visibility_noise_width : int = 0

# 'jitter' converted to radians.
var _jitter_angle : float = 0.0

# Starting speed for the bolt, in meters / sec. The bolt travels in the local
# positive Y direction.
var _speed : float

# Duration, in seconds, for the bolt. '_duration' == 0 indicates that the
# bolt is not active.
var _duration : float = 0.0

# The total time that has elapsed since the start of the bolt firing.
var _total_elapsed : float

# The elapsed time when the bolt transform was last updated.
var _last_update_elapsed : float

# "Fire" the bolt at a given speed and duration, in seconds.
func fire(speed : float, duration : float, delay : float = 0.0,
			flip : bool = false, rot : bool = false) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	_speed = speed
	_duration = duration
	_total_elapsed = 0.0
	_last_update_elapsed = 0.0
	if flip:
		_bolt.transform = _bolt.transform.rotated_local(Vector3.UP, PI)
	if rot:
		_bolt.transform = _bolt.transform.rotated_local(Vector3.RIGHT, PI)

# Return the size of the bolt (or more specifically, the size of the mesh containing
# the bolt.
func size() -> Vector2:
	return _bolt.mesh.size

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

# Return a randomly chosen BoltKind.
static func random_kind() -> BoltKind:
	if (randi() % 2) == 0:
		return BoltKind.SINGLE
	return BoltKind.MULTI

func _ready() -> void:
	_jitter_angle = PI * jitter
	# '_visibility_noise_image' is set in static initializer, but perhaps
	# it could still be awaiting noise completion, so we double check here...
	assert(_visibility_noise_image != null)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	if _bolt == null: return
	if _duration == 0.0:
		_bolt.visible = false
	elif _total_elapsed >= _duration:
		_duration = 0.0
		_bolt.visible = false
		queue_free()
	else:
		var progress : float = min(1.0, _total_elapsed / _duration)
		var vidx : int = int(
			float(_visibility_noise_width) * (visibility_offset + (progress * visibility_speed)))
		var vpixel := _visibility_noise_image.get_pixel(vidx % _visibility_noise_width, 0)
		var new_visibility : bool = (vpixel.r >= visibility_threshold)
		if _bolt.visible != new_visibility:
			if not _bolt.visible:
				transform = transform.rotated_local(Vector3.BACK, randf_range(-_jitter_angle, _jitter_angle))
				transform = transform.translated_local(
					Vector3(0.0, _speed * (_total_elapsed - _last_update_elapsed), 0.0))
				_last_update_elapsed = _total_elapsed
			_bolt.visible = new_visibility
	_total_elapsed += delta
