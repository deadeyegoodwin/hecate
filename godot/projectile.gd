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

# A projectile.
class_name HecateProjectile extends CharacterBody3D

## Radius of the sphere representing the polygon.
@export var mesh_radius : float = 0.015 :
	set(v):
		mesh_radius = v
		if (_mesh != null) and (_mesh.mesh != null):
			_mesh.mesh.radius = mesh_radius
			_mesh.mesh.height = mesh_radius * 2

## Base color of the projectile mesh and particles.
@export var base_color : Color = Color.WHITE_SMOKE :
	set(v):
		base_color = v
		if (_mesh != null) and (_mesh.mesh.material != null):
			_mesh.mesh.material.set_shader_parameter("smoke_color", base_color)

## Texture density on the projectile mesh.
@export_range(0.01, 1.0) var mesh_density : float = 1.0 :
	set(v):
		mesh_density = v
		if (_mesh != null) and (_mesh.mesh.material != null):
			_mesh.mesh.material.set_shader_parameter("density", mesh_density)

## Speed of length-wise motion of the texture on the projectile mesh.
@export_range(0.0, 10.0) var mesh_length_speed : float = 0.4 :
	set(v):
		mesh_length_speed = v
		if (_mesh != null) and (_mesh.mesh.material != null):
			_mesh.mesh.material.set_shader_parameter("length_speed", mesh_length_speed)

## Speed of rotation of the texture on the projectile mesh.
@export_range(0.0, 10.0) var mesh_rotate_speed : float = 0.5 :
	set(v):
		mesh_rotate_speed = v
		if (_mesh != null) and (_mesh.mesh.material != null):
			_mesh.mesh.material.set_shader_parameter("rotate_speed", mesh_rotate_speed)

## Rate of hue change in the projectile mesh, based on density.
@export_range(0.0, 1.0) var mesh_hue_gradient : float = 1.0 :
	set(v):
		mesh_hue_gradient = v
		if (_mesh != null) and (_mesh.mesh.material != null):
			_mesh.mesh.material.set_shader_parameter("hue_gradient", mesh_hue_gradient)

## Rate of saturation change in the projectile mesh, based on density.
@export_range(0.0, 1.0) var mesh_saturation_gradient : float = 1.0 :
	set(v):
		mesh_saturation_gradient = v
		if (_mesh != null) and (_mesh.mesh.material != null):
			_mesh.mesh.material.set_shader_parameter("saturation_gradient", mesh_saturation_gradient)

## Rate of color value change in the stoke mesh, based on density.
@export_range(0.0, 1.0) var mesh_value_gradient : float = 1.0 :
	set(v):
		mesh_value_gradient = v
		if (_mesh != null) and (_mesh.mesh.material != null):
			_mesh.mesh.material.set_shader_parameter("value_gradient", mesh_value_gradient)

## Speed of length-wise motion of the surface on the projectile mesh.
@export_range(0.0, 10.0) var mesh_surface_length_speed : float = 0.1 :
	set(v):
		mesh_surface_length_speed = v
		if (_mesh != null) and (_mesh.mesh.material != null):
			_mesh.mesh.material.set_shader_parameter("surface_length_speed", mesh_surface_length_speed)

## Speed of rotation of the surface on the projectile mesh.
@export_range(0.0, 10.0) var mesh_surface_rotate_speed : float = 0.2 :
	set(v):
		mesh_surface_rotate_speed = v
		if (_mesh != null) and (_mesh.mesh.material != null):
			_mesh.mesh.material.set_shader_parameter("surface_rotate_speed", mesh_surface_rotate_speed)

## Magnitude to surface variation along each axis, as a ratio of the normal vector.
@export var mesh_surface_gradient : Vector3 = Vector3.ZERO :
	set(v):
		mesh_surface_gradient = v
		if (_mesh != null) and (_mesh.mesh.material != null):
			_mesh.mesh.material.set_shader_parameter("surface_gradient", mesh_surface_gradient)

## The time, in seconds, that the launch sound should start before the actual launch.
@export var prelaunch_sound_delta : float = 0.0

## The amount of damage done by the projectile.
@export var damage : float = 10.0

@onready var _mesh := $Mesh
@onready var _path := $Path3D
@onready var _pathfollow := $Path3D/PathFollow3D
@onready var _launch_sound := $LaunchSound

# What entity owns/launched this projectile.
var _owner : HecateCharacter.OwnerKind = HecateCharacter.OwnerKind.NONE

# Velocity, acceleration and surge of the projectile.
var _velocity : float = 0.0
var _acceleration : float = 0.0
var _surge : float = 0.0  # surge is rate of acceleration change

# Has the projectile been launched. If true then projectile moves along _curve.
var _launched : bool = false

# The transform that maps from curve position to projectile position.
var _curve_transform : Transform3D
# The total time that the projectile has been progressing along the curve.
var _curve_delta : float = 0.0

# Initialize the projectile.
func initialize(powner : HecateCharacter.OwnerKind) -> void:
	_owner = powner

func _ready() -> void:
	# Set the layer and mask of the projectile based on the owner.
	set_collision_layer(0)
	set_collision_mask(0)
	set_collision_mask_value(1, true)  # "wall"
	if _owner == HecateCharacter.OwnerKind.PLAYER:
		set_collision_layer_value(10, true)  # layer "player projectile"
		set_collision_mask_value(17, true)   # layer "opponent"
	elif _owner == HecateCharacter.OwnerKind.OPPONENT:
		set_collision_layer_value(18, true)  # layer "opponent projectile"
		set_collision_mask_value(9, true)    # layer "player"

	_mesh.mesh.radius = mesh_radius
	_mesh.mesh.height = mesh_radius * 2
	_mesh.mesh.material.set_shader_parameter("smoke_color", base_color)
	_mesh.mesh.material.set_shader_parameter("density", clampf(mesh_density, 0.01, 1.0))
	_mesh.mesh.material.set_shader_parameter("length_speed", clampf(mesh_length_speed, 0.0, 10.0))
	_mesh.mesh.material.set_shader_parameter("rotate_speed", clampf(mesh_rotate_speed, 0.0, 10.0))
	_mesh.mesh.material.set_shader_parameter("hue_gradient", clampf(mesh_hue_gradient, 0.0, 1.0))
	_mesh.mesh.material.set_shader_parameter("saturation_gradient", clampf(mesh_saturation_gradient, 0.0, 1.0))
	_mesh.mesh.material.set_shader_parameter("value_gradient", clampf(mesh_value_gradient, 0.0, 1.0))
	_mesh.mesh.material.set_shader_parameter("surface_length_speed", clampf(mesh_surface_length_speed, 0.0, 10.0))
	_mesh.mesh.material.set_shader_parameter("surface_rotate_speed", clampf(mesh_surface_rotate_speed, 0.0, 10.0))
	_mesh.mesh.material.set_shader_parameter("surface_gradient", mesh_surface_gradient)

# Called to notify the projectile that the launch is going to occur in 'duration' seconds.
func prelaunch(duration : float) -> bool:
	# To coordinate with launch, sound must be started earlier...
	if (not _launch_sound.is_playing()) and (duration <= prelaunch_sound_delta):
		_launch_sound.play()
	return true

# Launch the projectile to follow the path of a specified curve.
func launch(curve : Curve3D, curve_transform : Transform3D = Transform3D.IDENTITY,
			vel : float = 1.0, acc : float = 0.0, surge : float = 0.0) -> void:
	assert(_launched == false)
	if not _launched:
		_launched = true
		_path.curve = curve
		_pathfollow.progress = 0
		_curve_transform = curve_transform
		_velocity = vel
		_acceleration = acc
		_surge = surge
		position = (_curve_transform * Transform3D(Basis.IDENTITY, curve.get_point_position(0))).origin

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	# If the projectile has been launched, calculate how far the projectile
	# is along the curve based on the total time delta that has elapsed.
	if _launched:
		_curve_delta += delta
		var progress : float = (
			(_velocity * _curve_delta) +
			(0.5 * _acceleration * pow(_curve_delta, 2)) +
			(0.166666667 * _surge * pow(_curve_delta, 3)))

		# Advance '_pathfollow' node along the curve and use the resulting
		# position to update the position of the projectile.
		assert(progress >= _pathfollow.progress)
		_pathfollow.progress = progress
		var new_position : Vector3 = (
			_curve_transform * Transform3D(Basis.IDENTITY, _pathfollow.position)).origin

		# FIXME Currently we are moving directly from last curve position to
		# new curve position, but with high velocity and/or parts of the curve
		# with high curvature, this movement does not necessarily follow the curve.
		# Instead should advance along the curve segments to reach the new position.
		var collision := move_and_collide(new_position - position)
		if collision != null:
			# If the object collided with has a collision handler function, then
			# invoke it.
			var collider = collision.get_collider()
			if collider.has_method("handle_collision"):
				collider.handle_collision(self)

			# Perform any collision actions required for this projectile itself.
			queue_free()

		# FIXME If the projectile reaches the end of the path without colliding
		# (as can happen if the original target is no longer there), we must explicitly
		# delete the projectile. What we should instead do is create the original
		# curve/trajectory to contain one additional point beyond the target that
		# will cause the projectile to continue "out of scene" (likely hitting a wall).
		if _pathfollow.progress_ratio >= 1.0:
			queue_free()
