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

# The position / orientation of the character's eyes. Does not need to be
# the exact eye position but should be chosen to ensure good interaction
# with animations. In particular the glyph hand should be visible when
# glyphing / targeting.
@export var eye_marker : Marker3D

# The position / orientation of the left-hand cast.
@export var left_cast_marker : Marker3D

# The position / orientation of the left-hand cast.
@export var right_cast_marker : Marker3D
