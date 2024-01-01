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

# New bolts that have just been trigger by call to "fire()". The explosion can be
# triggered every frame, do not need to wait for bolts to complete.
var _firing_bolts : Array[HecateSurfaceExplosionBolt]

# "Fire" the explosion with indicated number of bolts.
func fire(num_bolts : int) -> void:
	assert(_firing_bolts.is_empty())
	if _firing_bolts.is_empty():
		var fire_fn = func():
			for bidx in num_bolts:
				var bolt := _bolt_scene.instantiate()
				bolt.visibility_offset = randf()
				bolt.visibility_speed = randf_range(0.25, .75)
				bolt.visibility_threshold = randf_range(0.6, 0.9)
				bolt.jitter = randf_range(0.01, 0.05)
				self.add_child(bolt)
				_firing_bolts.append(bolt)
		fire_fn.call_deferred()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	if not _firing_bolts.is_empty():
		for bolt in _firing_bolts:
			var duration : float = randf_range(0.1, 0.6)  # seconds
			var speed : float = randf_range(0.5, 3.0)
			var angle : float = randf_range(0, 2 * PI)
			# Want the edge of the PlaneMesh holding the bolt to be at the center,
			# to translate the bolt half its width.
			bolt.transform = Transform3D.IDENTITY.rotated_local(Vector3.BACK, angle)
			bolt.transform = bolt.transform.translated_local(Vector3(0.0, bolt.size().y / 2.0, 0.0))
			bolt.fire(speed, duration)
		_firing_bolts.clear()
