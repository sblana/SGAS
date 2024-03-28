@tool
class_name SGASPoseNode
extends Node3D



signal pn_entered
signal pn_exited
signal pn_activated
signal pn_deactivated
signal enable_pc
signal disable_pc


@export var id : StringName ## Unique ID.
@export var activation_time := 0.0 ## When >0, [code]_active[/code] has to be true for the set length before emitting the [code]pn_activated[/code] signal.
@export var grace_time := 0.0 ## When >0, [code]_active[/code] has to be false for the set length before emitting the [code]pn_deactivated[/code] signal.
@export var synchronised_components := true ## Synchronisation waits for all child PoseComponents to be in the state [code]inside[/code] before entering the state [code]inside[/code].[br]If false, this node will instead enter the state [code]inside[/code] when at least 1 child PoseComponent is entered.
#@export_group("Debug settings")


var activation_timer : Timer
var grace_timer : Timer
var _all_active : bool ## Whether all child PoseComponents are active.
var _inside : bool
var _active : bool
var _children_pc : Array[SGASPoseComponent]
var _gesturenodes : Array[StringName] ## Array of GestureNodes that want this pose enabled.
var _enable_next_frame : bool


func _ready():
	if Engine.is_editor_hint():
		return
	add_to_group("sgas_posenodes")


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	
	var pc := false
	for child in get_children():
		if child is SGASPoseComponent:
			pc = true
			break
	if not pc:
		warnings.append("This node needs at least one child SGASPoseComponent to function.")
		
	return warnings


func _physics_process(_delta):
	if Engine.is_editor_hint():
		return
	if _enable_next_frame:
		emit_signal("enable_pc")
	else:
		emit_signal("disable_pc")


func components_updated():
	var c = get_children()
	_children_pc.clear()
	for child in c:
		if child is SGASPoseComponent:
			_children_pc.append(child)
			
			if not pn_entered.is_connected(child._on_pn_entered):
				pn_entered.connect(child._on_pn_entered)
				pn_exited.connect(child._on_pn_exited)
				enable_pc.connect(child._on_enable)
				disable_pc.connect(child._on_disable)
			if not child.pc_entered.is_connected(_on_pc_entered):
				child.pc_entered.connect(_on_pc_entered)
				child.pc_exited.connect(_on_pc_exited)
				child.pc_activated.connect(_on_pc_activated)
				child.pc_deactivated.connect(_on_pc_deactivated)


func _on_pc_entered():
	if synchronised_components:
		for child in _children_pc:
			if !child.inside:
				return
		_inside = true
		emit_signal("pn_entered")
	else:
		if not _inside:
			_inside = true
			emit_signal("pn_entered")


func _on_pc_exited():
	if synchronised_components:
		if _inside:
			_inside = false
			emit_signal("pn_exited")
	else:
		for child in _children_pc:
			if child.inside:
				return
		_inside = false
		emit_signal("pn_exited")


func _on_pc_activated():
	for child in _children_pc:
		if !child.inside:
			return
	_all_active = true
	kill_grace_timer()
	if not _active:
		start_activation_timer()


func _on_pc_deactivated():
	if _all_active:
		_all_active = false
		kill_act_timer()
		if _active:
			start_grace_timer()


func start_activation_timer():
	if activation_time:
		activation_timer = Timer.new()
		activation_timer.one_shot = true
		activation_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
		add_child(activation_timer)
		activation_timer.timeout.connect(on_activated)
		activation_timer.start(activation_time)
	else:
		on_activated()


func start_grace_timer():
	if grace_time:
		grace_timer = Timer.new()
		grace_timer.one_shot = true
		grace_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
		add_child(grace_timer)
		grace_timer.timeout.connect(on_deactivated)
		grace_timer.start(grace_time)
	else:
		on_deactivated()


func kill_act_timer():
	if is_instance_valid(activation_timer):
		activation_timer.queue_free()


func kill_grace_timer():
	if is_instance_valid(grace_timer):
		grace_timer.queue_free()


func on_activated():
	_active = true
	emit_signal("pn_activated")
	get_tree().call_group("sgas_gesturenodes", "on_pose_activated", id)


func on_deactivated():
	_active = false
	emit_signal("pn_deactivated")
	get_tree().call_group("sgas_gesturenodes", "on_pose_deactivated", id)


func _on_request_enable_pose(gestureid:StringName, poseid:StringName):
	if not id == poseid:
		return
	else:
		if gestureid not in _gesturenodes:
			_gesturenodes.append(gestureid)
		_enable_next_frame = true


func _on_request_disable_pose(gestureid:StringName, poseid:StringName):
	if not id == poseid:
		return
	else:
		_gesturenodes.erase(gestureid)
		if not _gesturenodes.size():
			_enable_next_frame = false
		else:
			_enable_next_frame = true
