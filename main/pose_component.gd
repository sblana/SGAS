@tool
class_name SGASPoseComponent
extends Node3D



signal pc_entered
signal pc_exited
signal pc_activated
signal pc_deactivated


@export var sgas_id_mask : Array[String] ## Only colliders with any of these as their sgas_id metadata are considered valid.
@export_group("Conditions")
@export var rotation_range := 0.0 ## Leave at 0.0 if you don't want to require a collider to have a specific rotation.
#@export_subgroup("Velocity conditions)
#@export var linear_velocity_min


var inside : bool ## Whether a valid collider is inside this node's ShapeCast.
var do_conditions_testing : bool 
var active : bool 
var _shapecast : ShapeCast3D 
var _colliders_previous : Array 
var _colliders_current : Array 



func _enter_tree():
	if Engine.is_editor_hint():
		return
	var parent = get_parent()
	if parent.has_method("components_updated"):
		parent.components_updated()


func _exit_tree():
	if Engine.is_editor_hint():
		return
	var parent = get_parent()
	if parent.has_method("components_updated"):
		tree_exited.connect(parent.components_updated, CONNECT_ONE_SHOT)


func _ready():
	if Engine.is_editor_hint():
		return
	for child in get_children():
		if child is ShapeCast3D:
			_shapecast = child
			break


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	
	var s := false
	for child in get_children():
		if child is ShapeCast3D:
			s = true
			break
	if not s:
		warnings.append("This node needs a ShapeCast3D to function.")
	
	if not get_parent() is SGASPoseNode:
		warnings.append("This node needs to be a child of a SGASPoseNode to function.")
	
	return warnings


# Collision is using a child ShapeCast3D. That ShapeCast3D does not need a script, as this node will call its methods and such.
func _physics_process(_delta):
	if Engine.is_editor_hint():
		return
	colliders_update()
	
	if inside and do_conditions_testing:
		var passed = conditions_test()
		if passed and not active:
			on_activated()
		if not passed and active:
			on_deactivated()


func colliders_update():
	_colliders_current.clear()
	
	if _shapecast.is_colliding():
		for i in _shapecast.get_collision_count():
			var collider = _shapecast.get_collider(i)
			# Check if the collider has a sgas_id that's in our mask
			if collider.has_meta("sgas_id") and collider.get_meta("sgas_id") in sgas_id_mask:
				# Check if entry velocity matches conditions
				_colliders_current.append(collider)
	
	if _colliders_current.size() and not _colliders_previous.size():
		on_entered()
	elif not _colliders_current.size() and _colliders_previous.size():
		on_exited()
	
	_colliders_previous.assign(_colliders_current)


func conditions_test() -> bool:
	var passed_conditions : Array[bool]
	for collider in _colliders_current:
		var passed := true
		if rotation_range:
			var coll_quat := Quaternion(collider.global_basis.orthonormalized())
			var self_quat := Quaternion(self.global_basis.orthonormalized())
			if coll_quat.angle_to(self_quat) >= deg_to_rad(rotation_range):
				passed = false
		# Check current velocity.
		passed_conditions.append(passed)
	# If any collider returned true:
	if true in passed_conditions:
		return true
	else: return false


func on_entered():
	inside = true
	emit_signal("pc_entered")


func on_exited():
	if active:
		on_deactivated()
	inside = false
	emit_signal("pc_exited")


func _on_pn_entered():
	do_conditions_testing = true


func _on_pn_exited():
	do_conditions_testing = false


func on_activated():
	active = true
	emit_signal("pc_activated")


func on_deactivated():
	active = false
	emit_signal("pc_deactivated")


func _on_enable():
	_shapecast.enabled = true

func _on_disable():
	_shapecast.enabled = false
