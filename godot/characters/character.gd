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

# Base for characters. Defines exports that character must provide as they
# are expected by HecateWizard and other classes.
class_name HecateCharacter extends Node3D

## The position / orientation of the character's eyes. Does not need to be
## the exact eye position but should be chosen to ensure good interaction
## with animations. In particular the glyph hand should be visible when
## glyphing / targeting.
@export var eye_marker : Marker3D

## The position / orientation of the left-hand cast.
@export var left_cast_marker : Marker3D
## The position / orientation of the right-hand cast.
@export var right_cast_marker : Marker3D

## The animation timestamp to release the cast for left-hand cast.
@export var left_cast_animation_timestamp : float
## The animation timestamp to release the cast for right-hand cast.
@export var right_cast_animation_timestamp : float

## The node that is notified when an object collides with one of this
## character's hitboxes, by calling collision_handler.handle_character_collision().
@export var collision_handler : Node

# The kinds of owners for a character.
enum OwnerKind { NONE, PLAYER, OPPONENT }
var _owner : OwnerKind = OwnerKind.NONE

# Set the owner for this character, and adjust hitbox layer/mask to be appropriate
# for the owner.
func set_owner_kind(owner_kind : OwnerKind) -> void:
	_owner = owner_kind
	# Set the layer and mask of every contained hitbox based on the owner.
	_set_hitbox_layer_mask(self, _owner)

func _set_hitbox_layer_mask(n : Node, owner_kind : OwnerKind) -> void:
	if n is HecateHitbox:
		n.set_collision_layer(0)
		n.set_collision_mask(0)
		n.set_collision_mask_value(1, true)  # "wall"
		if owner_kind == HecateCharacter.OwnerKind.PLAYER:
			n.set_collision_layer_value(9, true)  # layer "player"
			n.set_collision_mask_value(18, true)   # layer "opponent projectile"
		elif owner_kind == HecateCharacter.OwnerKind.OPPONENT:
			n.set_collision_layer_value(17, true)  # layer "opponent"
			n.set_collision_mask_value(10, true)    # layer "player projectile"
	for c in n.get_children():
		_set_hitbox_layer_mask(c, owner_kind)

# Handle a collision with this character's 'hitbox_kind' hitbox by 'collider'.
func handle_hitbox_collision(hitbox_kind : HecateHitbox.Kind, collider : Node) -> void:
	if collision_handler != null:
		collision_handler.handle_character_collision(hitbox_kind, collider)
	else:
		print_debug(name, " unhandled hitbox collision on hitbox ",
					HecateHitbox.Kind.keys()[hitbox_kind], " by ", collider.name)
