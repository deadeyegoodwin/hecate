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

const _sub_explosion_scene = preload("res://surface_sub_explosion.tscn")

## The size of the sub-explosion bolts produced by the explosion.
@export var bolt_size := Vector2(1.0, 1.0)

## The size of the core sub-explosions produced by the explosion.
@export var core_size := Vector2(0.5, 0.5)

## The color of the explosion.
@export var color := Color.WHITE_SMOKE

# Explosion and sub-explosion sounds
@onready var _explosion_sound := $ExplosionSound
@onready var _sub_explosion_sound := $SubExplosionSound

# New sub-explosions that have just been trigger by call to "fire()".
# The explosion can be triggered every frame, do not need to wait for
# sub-explosions to complete.
class _SubExplosionInfo :
	var _sub : HecateSurfaceSubExplosion
	var _delay : float
	var _duration : float
	var _offset : Vector3
	var _speed : float
var _firing_sub_explosions : Array[_SubExplosionInfo]

# "Fire" the explosion with indicated number of core iterations and core duration, and the number
# of bolts and bolt bursts over the duration of the explosion.
func fire(duration : float, core_iterations : int, core_duration : float,
			num_bolt_bursts : int, num_bolts_per_burst : int, max_bolt_duration : float) -> void:
	assert(_firing_sub_explosions.is_empty())
	if _firing_sub_explosions.is_empty():
		# Core...
		var core_fire_fn = func(num_iters : int, total_duration : float) -> void:
			var core_kinds : Array[HecateSurfaceSubExplosion.Kind] = [
				HecateSurfaceSubExplosion.Kind.CORE0, HecateSurfaceSubExplosion.Kind.CORE1,
				HecateSurfaceSubExplosion.Kind.CORE2, HecateSurfaceSubExplosion.Kind.CORE3 ]
			var one_duration : float = total_duration / (num_iters * core_kinds.size())
			var ccnt : int = 0
			for iter in num_iters:
				for ckind in core_kinds:
					var core := _sub_explosion_scene.instantiate()
					core.visibility_speed = 1.0
					core.visibility_threshold = randf_range(0.0, 0.2)
					core.jitter = 0.0
					core.kind = ckind
					core.mesh_size = core_size
					core.color = color
					self.add_child(core)
					var info := _SubExplosionInfo.new()
					info._sub = core
					info._delay = one_duration * ccnt
					info._duration = one_duration
					info._offset = Vector3.ZERO
					info._speed = 0.0
					_firing_sub_explosions.append(info)
					ccnt += 1
		core_fire_fn.call_deferred(core_iterations, core_duration)

		# Bolts...
		var bolt_fire_fn = func(num_bolts : int, delay : float) -> void:
			for bidx in num_bolts:
				var bolt := _sub_explosion_scene.instantiate()
				bolt.visibility_offset = randf()
				bolt.visibility_speed = randf_range(0.75, 1.0)
				bolt.visibility_threshold = randf_range(0.2, 0.3)
				bolt.jitter = randf_range(0.0, 0.1)
				bolt.kind = HecateSurfaceSubExplosion.Kind.BOLT_SINGLE
				bolt.mesh_size = bolt_size
				bolt.color = color
				self.add_child(bolt)
				var info := _SubExplosionInfo.new()
				info._sub = bolt
				info._delay = delay
				info._duration = randf_range(0.5, 1.0) * max_bolt_duration
				info._offset = Vector3(0.0, core_size.y * 0.35, 0.0)
				info._speed = randf_range(bolt_size.x, bolt_size.x * 2.0)
				_firing_sub_explosions.append(info)
		# Time the start of the bursts evenly, so that the last burst completes
		# at 'duration'.
		var delay_delta : float = max(0.0,
			(duration - max_bolt_duration) / max(1, num_bolt_bursts - 1))
		var burst_delay : float = 0.0
		for burst in num_bolt_bursts:
			bolt_fire_fn.call_deferred(num_bolts_per_burst, burst_delay)
			burst_delay += delay_delta

# Free this explosion after the specified delay.
func delayed_free(delay : float) -> void:
	await get_tree().create_timer(delay).timeout
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	# Sub-explosion sound plays only when there are active sub-explosions.
	var active_sub_explosion : bool = false
	for c in get_children():
		if c is HecateSurfaceSubExplosion:
			active_sub_explosion = true
			break
	if active_sub_explosion != _sub_explosion_sound.is_playing():
		if active_sub_explosion:
			_sub_explosion_sound.play(randf_range(0.0, _sub_explosion_sound.stream.get_length()))
		else:
			_sub_explosion_sound.stop()

	if not _firing_sub_explosions.is_empty():
		# Explosion sound starts playing when fire() is invoked, unless it is
		# already playing...
		if not _explosion_sound.is_playing():
			_explosion_sound.play()

		for info in _firing_sub_explosions:
			var sub := info._sub
			var delay := info._delay
			var duration := info._duration
			var speed := info._speed
			var angle : float = randf_range(0, 2 * PI)
			sub.transform = Transform3D.IDENTITY.rotated_local(Vector3.BACK, angle)
			if info._offset != Vector3.ZERO:
				# Want the edge of the PlaneMesh holding the bolt to be at the center,
				# to translate the bolt half its width.
				sub.transform = sub.transform.translated_local(info._offset)
			sub.fire(speed, duration, delay,
						true if (randi() % 2) == 0 else false, # flip
						true if (randi() % 2) == 0 else false) # rot
		_firing_sub_explosions.clear()
