class_name Arena extends MeshInstance3D

var arena_size : Vector3

func initialize(n : String, sz : Vector3) -> void:
	name = n
	arena_size = sz

func _ready():
	mesh.size = Vector2(arena_size.x, arena_size.z)
