class_name Arena extends Node3D

# The overall size of the arena. A const export would be useful here but
# not supported so use the size() function to get this value.
const arena_size := Vector3(5.0, 4.0, 10.0)

# Wizards
const wizard_scene = preload("res://wizard.tscn")
var wiz : Wizard = null
var opp : Wizard = null

# Get the size of the arena
func size() -> Vector3:
	return arena_size

func _ready() -> void:
	wiz = wizard_scene.instantiate()
	wiz.initialize("wiz", Vector3(0, 0, arena_size.z / 2.0 - 0.5), Vector3(0, 180.0, 0))
	wiz.add_camera()

	add_child(wiz)
	opp = wizard_scene.instantiate()
	opp.initialize("opp", Vector3(0, 0, 0.5 - arena_size.z / 2))
	add_child(opp)

func _process(delta : float) -> void:
	# Fireball!
	if Input.is_action_just_pressed("wizard_fireball"):
		var fireball = wiz.create_fireball()
		add_child(fireball)
