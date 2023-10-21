class_name Arena extends MeshInstance3D

# Wizards
const wizard_scene = preload("res://wizard.tscn")
var wiz : Wizard = null
var opp : Wizard = null

var initial_arena_size : Vector3

func initialize(n : String, sz : Vector3) -> void:
	name = n
	initial_arena_size = sz

func _ready() -> void:
	mesh.size = Vector2(initial_arena_size.x, initial_arena_size.z)

	wiz = wizard_scene.instantiate()
	wiz.initialize("wiz", Vector3(0, 0, initial_arena_size.z / 2.0 - 0.5), Vector3(0, 180.0, 0))
	add_child(wiz)
	opp = wizard_scene.instantiate()
	opp.initialize("opp", Vector3(0, 0, 0.5 - initial_arena_size.z / 2))
	add_child(opp)

func _process(delta : float) -> void:
	# Fireball!
	if Input.is_action_just_pressed("wizard_fireball"):
		var fireball = wiz.create_fireball()
		add_child(fireball)

