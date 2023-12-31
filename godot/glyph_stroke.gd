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

# Required because this class is used in some @tool scripts.
# See https://github.com/godotengine/godot/issues/81250
#@tool

# A stroke in a HecateGlyph.
class_name HecateGlyphStroke extends Node3D

## Number of sides in the extruded polygon representing the glyph stroke.
@export var mesh_sides : int = 16

## Radius of the extruded polygon representing the glyph stroke.
@export var mesh_radius : float = 0.015 :
	set(v):
		mesh_radius = v
		if _polygon != null:
			_init_polygon()

## Base color of the stroke mesh and particles.
@export var base_color : Color = Color.WHITE_SMOKE :
	set(v):
		base_color = v
		if (_polygon != null) and (_polygon.material != null):
			_polygon.material.set_shader_parameter("smoke_color", base_color)
		if (_particles != null) and (_particles.process_material != null):
			_particles.process_material.color = base_color

## Texture density on the stoke mesh.
@export_range(0.01, 1.0) var mesh_density : float = 1.0 :
	set(v):
		mesh_density = v
		if (_polygon != null) and (_polygon.material != null):
			_polygon.material.set_shader_parameter("density", mesh_density)

## Speed of length-wise motion of the texture on the stroke mesh.
@export_range(0.0, 10.0) var mesh_length_speed : float = 0.2 :
	set(v):
		mesh_length_speed = v
		if (_polygon != null) and (_polygon.material != null):
			_polygon.material.set_shader_parameter("length_speed", mesh_length_speed)

## Speed of rotation of the texture on the stroke mesh.
@export_range(0.0, 10.0) var mesh_rotate_speed : float = 0.5 :
	set(v):
		mesh_rotate_speed = v
		if (_polygon != null) and (_polygon.material != null):
			_polygon.material.set_shader_parameter("rotate_speed", mesh_rotate_speed)

## Rate of hue change in the stoke mesh, based on density.
@export_range(0.0, 1.0) var mesh_hue_gradient : float = 1.0 :
	set(v):
		mesh_hue_gradient = v
		if (_polygon != null) and (_polygon.material != null):
			_polygon.material.set_shader_parameter("hue_gradient", mesh_hue_gradient)

## Rate of saturation change in the stoke mesh, based on density.
@export_range(0.0, 1.0) var mesh_saturation_gradient : float = 1.0 :
	set(v):
		mesh_saturation_gradient = v
		if (_polygon != null) and (_polygon.material != null):
			_polygon.material.set_shader_parameter("saturation_gradient", mesh_saturation_gradient)

## Rate of color value change in the stoke mesh, based on density.
@export_range(0.0, 1.0) var mesh_value_gradient : float = 1.0 :
	set(v):
		mesh_value_gradient = v
		if (_polygon != null) and (_polygon.material != null):
			_polygon.material.set_shader_parameter("value_gradient", mesh_value_gradient)

## Speed of length-wise motion of the surface on the stroke mesh.
@export_range(0.0, 10.0) var mesh_surface_length_speed : float = 0.05 :
	set(v):
		mesh_surface_length_speed = v
		if (_polygon != null) and (_polygon.material != null):
			_polygon.material.set_shader_parameter("surface_length_speed", mesh_surface_length_speed)

## Speed of rotation of the surface on the stroke mesh.
@export_range(0.0, 10.0) var mesh_surface_rotate_speed : float = 0.01 :
	set(v):
		mesh_surface_rotate_speed = v
		if (_polygon != null) and (_polygon.material != null):
			_polygon.material.set_shader_parameter("surface_rotate_speed", mesh_surface_rotate_speed)

## Magnitude to surface variation along each axis, as a ratio of the normal vector.
@export var mesh_surface_gradient : Vector3 = Vector3.ZERO :
	set(v):
		mesh_surface_gradient = v
		if (_polygon != null) and (_polygon.material != null):
			_polygon.material.set_shader_parameter("surface_gradient", mesh_surface_gradient)

@onready var _particles := $GPUParticles3D
@onready var _polygon := $CSGPolygon3D
@onready var _polygon_path := $CSGPolygon3D/Path3D

# The HecateBezierCurve that makes a smooth curve for the stroke.
var _curve_bake_interval : float = 0.005
var _curve := HecateBezierCurve.new()

# Particle emission and CSGPolygon don't like have two adjacent Curve3D points
# being close together. Define an epsilon that can be used to make sure two adjacent
# points are not too close together.
const _curve_point_epsilon : float = 0.005

# Pending new points to the stroke.
var _pending_adds : Array[Vector3]

# Pending update to the last point in the stroke.
var _is_pending_update := false
var _pending_update := Vector3.ZERO

# The points that compose a stroke curve must be represented in an Image
# that is then used as the "emission points" for the particles composing
# the visual representation of the stroke. Create the underlying image
# once and update it as necessary as the stoke changes.
var _emission_image := Image.create(2048, 1, false, Image.FORMAT_RGBF)

func _ready() -> void:
	# Update the curve particles and polygon...
	_refresh_curve()
	_init_polygon()

	_particles.process_material.color = base_color

	_polygon.material.set_shader_parameter("smoke_color", base_color)
	_polygon.material.set_shader_parameter("density", clampf(mesh_density, 0.01, 1.0))
	_polygon.material.set_shader_parameter("length_speed", clampf(mesh_length_speed, 0.0, 10.0))
	_polygon.material.set_shader_parameter("rotate_speed", clampf(mesh_rotate_speed, 0.0, 10.0))
	_polygon.material.set_shader_parameter("hue_gradient", clampf(mesh_hue_gradient, 0.0, 1.0))
	_polygon.material.set_shader_parameter("saturation_gradient", clampf(mesh_saturation_gradient, 0.0, 1.0))
	_polygon.material.set_shader_parameter("value_gradient", clampf(mesh_value_gradient, 0.0, 1.0))
	_polygon.material.set_shader_parameter("surface_length_speed", clampf(mesh_surface_length_speed, 0.0, 10.0))
	_polygon.material.set_shader_parameter("surface_rotate_speed", clampf(mesh_surface_rotate_speed, 0.0, 10.0))
	_polygon.material.set_shader_parameter("surface_gradient", mesh_surface_gradient)

# Set the CSGPolygon to a circular shape.
func _init_polygon() -> void:
	var angle_delta : float = (PI * 2) / mesh_sides
	var vector : Vector2 = Vector2(mesh_radius, 0)
	var varr : PackedVector2Array = []
	for sidx in mesh_sides:
		varr.append(vector)
		vector = vector.rotated(angle_delta)
	_polygon.polygon = varr

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	var need_refresh := false
	# If there are pending additions to the stroke, add them to the curve.
	if not _pending_adds.is_empty():
		# If a first, single point is being added to the stroke, then add it twice,
		# once as the starting point of the stroke, and the second as the "active"
		# point on the stoke that can be updated with 'update_last_point()'.
		if (_curve.point_count() == 0) and (_pending_adds.size() == 1):
			_pending_adds.append(_pending_adds[0])
		# As points are added to the curve, skip any that are within the epsilon of
		# the previous point.
		for pt : Vector3 in _pending_adds:
			if _curve.point_count() == 0:
				_curve.append_point(pt)
			elif _curve.point_count() == 1:
				if _curve.point_distance(_curve.point_count() - 1, pt) < _curve_point_epsilon:
					_curve.append_point(pt + Vector3(_curve_point_epsilon, _curve_point_epsilon, 0))
				else:
					_curve.append_point(pt)
			elif _curve.point_distance(_curve.point_count() - 2, pt) >= _curve_point_epsilon:
				_curve.append_point(pt)
		assert(_curve.point_count() >= 2, 'stroke requires at least 2 point, incorrect epsilon filtering?')
		_pending_adds.clear()
		need_refresh = true
	# Update last point position if the change to the last point position is
	# greater than epsilon and doesn't move the point to within epsilon of the
	# previous point.
	if _is_pending_update:
		_is_pending_update = false
		if ((_curve.point_count() >= 2) and # should always be true
			(_curve.point_distance(_curve.point_count() - 1, _pending_update) >= _curve_point_epsilon) and
			(_curve.point_distance(_curve.point_count() - 2, _pending_update) >= _curve_point_epsilon)):
			_curve.update_last_point(_pending_update)
			need_refresh = true
	if need_refresh:
		_refresh_curve()

# Based on '_curve' update the polygon path and generate a new set of emission
# points for the particles.
func _refresh_curve() -> void:
	var curve3d := _curve.curve()

	# Update polygon...
	_polygon_path.curve = curve3d

	# Update particle emission points...
	curve3d.bake_interval = _curve_bake_interval
	var pts := curve3d.get_baked_points()
	var cnt := pts.size()
	if cnt > 0:
		for idx in range(min(cnt, _emission_image.get_size().x)):
			var pt := pts[idx]
			_emission_image.set_pixel(idx, 0, Color(pt.x, pt.y, pt.z))
		var image_texture := ImageTexture.create_from_image(_emission_image)
		_particles.process_material.emission_point_texture = image_texture
	_particles.process_material.emission_point_count = cnt

# Return the Curve3D representation of this stroke.
func curve() -> Curve3D:
	return _curve.curve()

# Add a new point to the end of the stroke.
func add_point(pt : Vector3) -> void:
	# Just record the new point here... added to '_curve' in _process.
	_pending_adds.append(pt)

# Update the position of the last added point, if any.
func update_last_point(pt : Vector3) -> void:
	_pending_update = pt
	_is_pending_update = true

# Stop using this stroke as part of the parent glyph. If 'fade' is
# true then allow existing particles to complete their lifetime. If 'remove_from_scene'
# is true then the stroke is removed from the scene, otherwise it is just made
# invisible.
func release(fade : bool = true, remove_from_scene : bool = true):
	_pending_adds.clear()
	_is_pending_update = false

	if fade:
		# Use tween to fade the mesh and particles in parallel. Mesh fades quickly,
		# duration is only 1/4 of particle lifetime.
		var tween = create_tween()
		tween.tween_property(self, "mesh_density", 0.01, _particles.lifetime / 4.0)

		# Should be able to await on "_particles.finished" signal but that doesn't
		# seem to always work. Instead we simply sleep long enough for all the particles
		# to complete their lifetime.
		_particles.emitting = false
		await get_tree().create_timer(_particles.lifetime).timeout
	visible = false
	_particles.process_material.emission_point_count = 0
	_particles.process_material.emission_point_texture = null
	if remove_from_scene:
		queue_free()
