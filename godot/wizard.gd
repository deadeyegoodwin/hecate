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

# An opponent wizard.
class_name HecateWizard extends CharacterBody3D

# Statistics for the wizard.
var _statistics : HecateStatistics = null

# The arena that contains this wizard, will also act as the container
# for other nodes created by the wizard.
var _arena : HecateArena = null

# Initialize the wizard.
func initialize(a : HecateArena, n : String, stats : Dictionary,
				tform : Transform3D = Transform3D.IDENTITY) -> void:
	_arena = a
	name = n
	transform = tform
	_statistics = HecateStatistics.new(stats)

# Handle a 'collider' colliding with this wizard.
func handle_collision(collider : Node) -> void:
	print(name, " handle_collision with ", collider.name)
	var health = _statistics.get_stat(HecateStatistics.Kind.HEALTH)
	health -= 40.0
	_statistics.set_stat(HecateStatistics.Kind.HEALTH, health)
	if health <= 0.0:
		queue_free()
