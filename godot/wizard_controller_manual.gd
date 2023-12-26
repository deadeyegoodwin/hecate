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

# Base class for wizard controller.
class_name HecateWizardControllerManual extends HecateWizardController

# Perform a control step based on input.
func step(animation : HecateWizardAnimation, left_cast : HecateCast, right_cast : HecateCast) -> void:
	# If left cast action...
	if Input.is_action_just_pressed("cast_left_action"):
		get_viewport().set_input_as_handled()
		# If current animation state is a right hand state, then attempt to transition
		# from that right state to the left glyph state. If unable to do so, then
		# just ignore this action.
		if animation.is_right_current_state():
			if right_cast.idle():
				var r := animation.set_target(HecateWizardAnimation.State.GLYPH_LEFT); assert(r)
		# Otherwise, if animation state is does not already have a pending target,
		# then advance to the animation state associated with the next cast state.
		elif not animation.is_pending_target_state():
			match animation.current_state():
				HecateWizardAnimation.State.IDLE_LEFT:
					var r := animation.set_target(HecateWizardAnimation.State.GLYPH_LEFT); assert(r)
				HecateWizardAnimation.State.GLYPH_LEFT:
					if left_cast.is_glyph_complete():
						var r := animation.set_target(HecateWizardAnimation.State.INVOKE_LEFT); assert(r)
				HecateWizardAnimation.State.INVOKE_LEFT:
					if left_cast.is_invoke_complete():
						left_cast.invoke_finalize()
						var r := animation.set_target(HecateWizardAnimation.State.LAUNCH_LEFT); assert(r)
	# If right cast action...
	elif Input.is_action_just_pressed("cast_right_action"):
		get_viewport().set_input_as_handled()
		# If current animation state is a left hand state, then attempt to transition
		# from that left state to the right glyph state. If unable to do so, then
		# just ignore this action.
		if animation.is_left_current_state():
			if left_cast.idle():
				var r := animation.set_target(HecateWizardAnimation.State.GLYPH_RIGHT); assert(r)
		# Otherwise, if animation state is does not already have a pending target,
		# then advance to the animation state associated with the next cast state.
		elif not animation.is_pending_target_state():
			match animation.current_state():
				HecateWizardAnimation.State.IDLE_RIGHT:
					var r := animation.set_target(HecateWizardAnimation.State.GLYPH_RIGHT); assert(r)
				HecateWizardAnimation.State.GLYPH_RIGHT:
					if right_cast.is_glyph_complete():
						var r := animation.set_target(HecateWizardAnimation.State.INVOKE_RIGHT); assert(r)
				HecateWizardAnimation.State.INVOKE_RIGHT:
					var r := animation.set_target(HecateWizardAnimation.State.LAUNCH_RIGHT); assert(r)
