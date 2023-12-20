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

class_name HecateTitleScreen extends Control

@onready var _start_button := $ButtonBar/StartButton

func _ready() -> void:
	_start_button.grab_focus()

# Start button pressed...
func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

# Quit button pressed...
func _on_quit_buitton_pressed():
	get_tree().quit()

# Credits button pressed...
func _on_credits_button_pressed():
	get_tree().change_scene_to_file("res://credits_screen.tscn")

