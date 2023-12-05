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
		# If current animation state is right, then attempt to idle the right cast and
		# transition to left glyph. If unable to idle the right cast, then ignore
		# the command.
		if animation.is_right_current_state():
			if right_cast.idle():
				var r := animation.set_target(HecateWizardAnimation.State.GLYPH_LEFT); assert(r)
		# Otherwise, if cast is up-to-date with the animation, then advance to the animation
		# state associated with the next cast state. If cast is not up-to-date,
		# then ignore command.
		else:
			match animation.current_state():
				HecateWizardAnimation.State.IDLE_LEFT:
					var r := animation.set_target(HecateWizardAnimation.State.GLYPH_LEFT); assert(r)
				HecateWizardAnimation.State.GLYPH_LEFT:
					if left_cast.is_glyph_complete():
						var r := animation.set_target(HecateWizardAnimation.State.INVOKE_LEFT); assert(r)
				HecateWizardAnimation.State.INVOKE_LEFT:
					if left_cast.is_invoke_complete():
						left_cast.invoke_finalize()
						var r := animation.set_target(HecateWizardAnimation.State.CAST_LEFT); assert(r)
	# If right cast action...
	elif Input.is_action_just_pressed("cast_right_action"):
		get_viewport().set_input_as_handled()
		# If current animation state is left, then attempt to idle the left cast and
		# transition to right glyph. If unable to idle the left cast, then ignore
		# the command.
		if animation.is_left_current_state():
			if left_cast.idle():
				var r := animation.set_target(HecateWizardAnimation.State.GLYPH_RIGHT); assert(r)
		# Otherwise, if cast is up-to-date with the animation, then advance to the animation
		# state associated with the next cast state. If cast is not up-to-date,
		# then ignore command.
		else:
			match animation.current_state():
				HecateWizardAnimation.State.IDLE_RIGHT:
					var r := animation.set_target(HecateWizardAnimation.State.GLYPH_RIGHT); assert(r)
				HecateWizardAnimation.State.GLYPH_RIGHT:
					if right_cast.is_glyph_complete():
						var r := animation.set_target(HecateWizardAnimation.State.INVOKE_RIGHT); assert(r)
				HecateWizardAnimation.State.INVOKE_RIGHT:
					var r := animation.set_target(HecateWizardAnimation.State.CAST_RIGHT); assert(r)
