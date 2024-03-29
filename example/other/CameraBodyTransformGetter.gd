extends Node3D

@export var camera : Node3D

func _physics_process(_delta):
	position.x = camera.position.x
	position.z = camera.position.z
	rotation.y = camera.rotation.y
