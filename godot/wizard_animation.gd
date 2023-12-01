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

# Class to manage a wizard's animation tree and transitions. This class
# must be kept in sync with the wizard's AnimationTree as it depends on
# knowing the travel paths encoded in that tree.
class_name HecateWizardAnimation extends Node

# The animation states that the wizard can be in.
enum State { IDLE_LEFT, IDLE_RIGHT,
			 GLYPH_LEFT, GLYPH_RIGHT,
			 INVOKE_LEFT, INVOKE_RIGHT,
			 CAST_LEFT, CAST_RIGHT }

# Current animation state, and the target animation state that has been
# requested. Animation state will remain current until the animation(s) that
# transition to the target are complete. When current and target state are the
# same then there is no pending state transition.
var _current_state : State
var _target_state : State

# The playback object for the state machine that manages wizard animation.
var _playback : AnimationNodeStateMachinePlayback

# Initialize for an AnimationTree. Animtation does not start until start()
# is called.
func initialize(animation_tree : AnimationTree) -> void:
	_playback = animation_tree["parameters/playback"]

# Start animation in the specified state.
func start(state : State = State.IDLE_LEFT) -> void:
	_current_state = state
	_target_state = state
	_teleport(state, true)

# Return true if current state is a left-hand state.
func is_left_current_state() -> bool:
	match _current_state:
		State.IDLE_LEFT, State.GLYPH_LEFT, State.INVOKE_LEFT, State.CAST_LEFT:
			return true
	return false

# Return true if current state is a right-hand state.
func is_right_current_state() -> bool:
	match _current_state:
		State.IDLE_RIGHT, State.GLYPH_RIGHT, State.INVOKE_RIGHT, State.CAST_RIGHT:
			return true
	return false

# Return true if there is a pending target state that has not yet been reached.
func is_pending_target_state() -> bool:
	return _current_state != _target_state

# Return the current animation state.
func current_state() -> State:
	return _current_state

# Return the target animation state. Will be equal to current_state() if no
# target state has been requested / pending (but use is_pending_target_state() to
# determine if there is a pending target state).
func target_state() -> State:
	return _target_state

# Return true if the animation for the current state is at the end. For a looping
# animation this will return true only if called exactly when the animation
# is at the end.
func is_current_at_end() -> bool:
	return(_playback.is_playing() and (_playback.get_current_node() == _state_to_name(_current_state)) and
			(is_equal_approx(_playback.get_current_length(), _playback.get_current_play_position()) or
			 (_playback.get_current_play_position() > _playback.get_current_length())))

# Return true if the animation for the current state is at or beyond 'timestamp'.
func is_current_beyond_timestamp(timestamp : float) -> bool:
	return(_playback.is_playing() and (_playback.get_current_node() == _state_to_name(_current_state)) and
			(timestamp < _playback.get_current_play_position()))

# Set the target state. Returns false if there is already a target state
# pending.
func set_target(target : State) -> bool:
	if is_pending_target_state():
		return false
	if target != _current_state:
		_target_state = target
		_travel(target)
	return true

# Set the target state if the current state is 'current_state'. Returns false
# if there is already a target state or if the current state is not
# 'current_state'.
func set_target_if_current(target : State, current : State) -> bool:
	if _current_state != current:
		return false
	return set_target(target)

# Return the AnimationTree node name for a State.
func _state_to_name(s : State) -> String:
	match s:
		State.IDLE_LEFT:
			return "idle_left"
		State.IDLE_RIGHT:
			return "idle_right"
		State.GLYPH_LEFT, State.INVOKE_LEFT:
			return "glyph_left"
		State.GLYPH_RIGHT, State.INVOKE_RIGHT:
			return "glyph_right"
		State.CAST_LEFT:
			return "cast_left"
		State.CAST_RIGHT:
			return "cast_right"
		_:
			assert(false)
			return ""

# Teleport in the AnimationTree to 'state'. If 'reset' is true start the
# animation from the beginning.
func _teleport(state : State, reset : bool = false) -> void:
	_playback.start(_state_to_name(state), reset)

# Travel in the AnimationTree to 'state'.
func _travel(state : State) -> void:
	_playback.travel(_state_to_name(state))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	# If there is a pending target and the travel path is empty, then
	# the target has been reached.
	if is_pending_target_state():
		var tp = _playback.get_travel_path()
		if tp.is_empty():
			_current_state = _target_state
