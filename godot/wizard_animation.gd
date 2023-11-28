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

# Class to manage a wizard's animation tree and transitions.
class_name HecateWizardAnimation extends Node

enum State { IDLE, GLYPH, CAST }

# The playback object for the state machine that manages wizard animation.
var _playback : AnimationNodeStateMachinePlayback

func initialize(animation_tree : AnimationTree) -> void:
	_playback = animation_tree["parameters/playback"]

func start() -> void:
	_travel(State.IDLE)

func enqueue(state : State) -> void:
	# FIXME, for now just travel immediately
	_travel(state)

func _travel(state : State) -> void:
	var target : String
	match state:
		State.IDLE:
			target = "idle_left"
		State.GLYPH:
			target = "glyph_left"
		State.CAST:
			target = "cast_left"
		_:
			assert(false)
			return
	_playback.travel(target)

# Called at a fixed interval (default 60Hz)
func _physics_process(_delta : float) -> void:
	pass
