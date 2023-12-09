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

class_name HecateCreditsScreen extends Control

@onready var _credits_label := $ScrollContainer/CreditsText

func _ready() -> void:
	_credits_label.text = """
Copyright 2023, David Goodwin. All rights reserved.\n
Strife of Hecate (also referred to as Hecate) is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n
Hecate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.\n
"""
	_credits_label.text += (
		"Hecate uses the Godot Engine version " +
		str(Engine.get_version_info()["major"]) + "." +
		str(Engine.get_version_info()["minor"]) + ". " +
		"Copyrights and licenses for Godot and components included in Godot are listed below.\n")

	for d in Engine.get_copyright_info():
		_credits_label.text += '\n' + d["name"] + '\n'
		for pd in d["parts"]:
			for cr in pd["copyright"]:
				_credits_label.text += cr + '\n'
			_credits_label.text += "License " + pd["license"] + '\n'

	var linfo := Engine.get_license_info()
	for l in linfo:
		_credits_label.text += "\nLicense " + l + '\n'
		_credits_label.text += linfo[l] + '\n'

# OK button pressed. Close credits screen and return to title screen.
func _on_ok_button_pressed():
	get_tree().change_scene_to_file("res://title_screen.tscn")
