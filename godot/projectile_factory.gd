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

# Factory to create HecateProjectile objects.
class_name HecateProjectileFactory extends RefCounted

const _projectile_scene = preload("res://projectile.tscn")

# Kinds of projectiles that can be created by this factory. Use the appropriate
# configure function below to configure the factory parameters for each kind
# of projectile.
enum Kind { BALL }

# Dictionary from Kind -> Dictionary of configured parameters.
var _configs : Dictionary

# Configure parameters for a BALL projectile. Return false if unable to configure.
func configure_ball_projectile(
	radius : float, base_color : Color, density : float = 1.0,
	surface_texture_speed0 : float = 0.0, surface_texture_speed1 : float = 0.0,
	hue_gradient : float = 0.0, saturation_gradient : float = 0.0, value_gradient : float = 0.0,
	surface_contour_speed0 : float = 0.0, surface_contour_speed1 : float = 0.0,
	surface_contour_gradient := Vector3.ZERO) -> bool:
	var config = { 'radius' : radius,
				   'base_color' : base_color,
				   'density' : density,
				   'surface_texture_speed0' : surface_texture_speed0,
				   'surface_texture_speed1' : surface_texture_speed1,
				   'hue_gradient' : hue_gradient,
				   'saturation_gradient' : saturation_gradient,
				   'value_gradient' : value_gradient,
				   'surface_contour_speed0' : surface_contour_speed0,
				   'surface_contour_speed1' : surface_contour_speed1,
				   'surface_contour_gradient' : surface_contour_gradient }
	_configs[Kind.BALL] = config
	return true

# Create and return a HecateProjectile of the given kind.
func create_projectile(kind : Kind) -> HecateProjectile:
	var projectile := _projectile_scene.instantiate()
	if kind in _configs:
		var cdict : Dictionary = _configs[kind]
		projectile.base_color = cdict['base_color']
		projectile.mesh_radius = cdict['radius']
		projectile.mesh_density = cdict['density']
		projectile.mesh_length_speed = cdict['surface_texture_speed0']
		projectile.mesh_rotate_speed = cdict['surface_texture_speed1']
		projectile.mesh_hue_gradient = cdict['hue_gradient']
		projectile.mesh_saturation_gradient = cdict['saturation_gradient']
		projectile.mesh_value_gradient = cdict['value_gradient']
		projectile.mesh_surface_length_speed = cdict['surface_contour_speed0']
		projectile.mesh_surface_rotate_speed = cdict['surface_contour_speed1']
		projectile.mesh_surface_gradient = cdict['surface_contour_gradient']

	return projectile
