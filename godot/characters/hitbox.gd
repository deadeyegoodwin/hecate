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

# Hitbox on a character.
class_name HecateHitbox extends CharacterBody3D

# The kind of hitboxes.
enum Kind { UNKNOWN, HEAD, BODY,
			LEFT_UPPER_ARM, LEFT_LOWER_ARM,
			RIGHT_UPPER_ARM, RIGHT_LOWER_ARM,
			LEFT_UPPER_LEG, LEFT_LOWER_LEG,
			RIGHT_UPPER_LEG, RIGHT_LOWER_LEG }

## The HecateCharacter node that is notified when an object collides with this
## hitbox, by calling HecateCharacter.handle_hitbox_collision().
@export var collision_handler : HecateCharacter

## The hitbox kind.
@export var kind : Kind = Kind.UNKNOWN

# Called when another object collides with this hitbox.
func handle_collision(collider : Node) -> void:
	if collision_handler != null:
		collision_handler.handle_hitbox_collision(kind, collider)
