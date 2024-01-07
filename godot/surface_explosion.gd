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

# An explosion on a flat surface (e.g. wall).
class_name HecateSurfaceExplosion extends Node3D

const _bolt_scene = preload("res://surface_explosion_bolt.tscn")

## The size of the bolts produces by the explosion.
@export var bolt_size := Vector2(1.0, 1.0)

## The color of the explosion.
@export var color := Color.WHITE_SMOKE

# Explosion sound
@onready var _sound := $ExplosionSound

# New bolts that have just been trigger by call to "fire()", the delay for
# the bolt, and the max duration for the bolt. as [ bolt, delay, max-duration ].
# The explosion can be triggered every frame, do not need to wait for bolts to
# complete.
var _firing_bolts : Array

# "Fire" the explosion with indicated number of bolts and bolt bursts over the
# duration of the explosion.
func fire(duration : float, num_bursts : int, num_bolts_per_burst : int,
			 max_bolt_duration : float) -> void:
	assert(_firing_bolts.is_empty())
	if _firing_bolts.is_empty():
		var fire_fn = func(num_bolts : int, delay : float) -> void:
			for bidx in num_bolts:
				var bolt := _bolt_scene.instantiate()
				bolt.visibility_offset = randf()
				bolt.visibility_speed = randf_range(0.75, 1.0)
				bolt.visibility_threshold = randf_range(0.2, 0.4)
				bolt.jitter = randf_range(0.0, 0.2)
				bolt.kind = HecateSurfaceExplosionBolt.BoltKind.SINGLE
				bolt.mesh_size = bolt_size
				bolt.color = color
				self.add_child(bolt)
				_firing_bolts.append([bolt, delay, max_bolt_duration])
		# Time the start of the bursts evenly, so that the last burst completes
		# at 'duration'.
		var delay_delta : float = max(0.0,
			(duration - max_bolt_duration) / max(1, num_bursts - 1))
		var burst_delay : float = 0.0
		for burst in num_bursts:
			fire_fn.call_deferred(num_bolts_per_burst, burst_delay)
			burst_delay += delay_delta

# Free this explosion after the specified delay.
func delayed_free(delay : float) -> void:
	await get_tree().create_timer(delay).timeout
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	if not _firing_bolts.is_empty():
		# Explosion sound...
		if not _sound.is_playing():
			_sound.play()

		for arr in _firing_bolts:
			var bolt : HecateSurfaceExplosionBolt = arr[0]
			var delay : float = arr[1]
			var duration : float = randf_range(0.5, 1.0) * arr[2]  # seconds
			var speed : float = randf_range(bolt_size.x, bolt_size.x * 2.0)
			var angle : float = randf_range(0, 2 * PI)
			# Want the edge of the PlaneMesh holding the bolt to be at the center,
			# to translate the bolt half its width.
			bolt.transform = Transform3D.IDENTITY.rotated_local(Vector3.BACK, angle)
			bolt.transform = bolt.transform.translated_local(Vector3(0.0, bolt.mesh_size.y / 2.0, 0.0))
			bolt.fire(speed, duration, delay,
						true if (randi() % 2) == 0 else false, # flip
						true if (randi() % 2) == 0 else false) # rot
		_firing_bolts.clear()
