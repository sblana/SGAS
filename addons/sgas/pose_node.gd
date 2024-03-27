class_name GBASPoseNode
extends Node3D



signal pn_entered
signal pn_exited
signal pn_activated
signal pn_deactivated
signal enable_pc
signal disable_pc


@export var id : StringName
@export var activation_time := 0.0 ## When >0, requires this pose to be active for the set length, before it sends the pn_activated signal.
@export var grace_time := 0.0 ## When a child PoseComponent has been deactivated, a timer for the set length is started. The pn_deactivated signal will only be emitted if this PoseNode is still deactivated when the timer runs out.
@export var synchronised_components := true ## Synchronisation waits for all child PoseComponents to have been entered before in state [cb]inside[/cb].[br]If false, this node will instead be in state [cb]inside[/cb] when at least 1 child PoseComponent is entered.
@export_group("Debug settings")


var activation_timer : Timer
var grace_timer : Timer
var _all_active : bool
var _inside : bool
var _active : bool
var _children_pc : Array[GBASPoseComponent]
var _actions : Array[StringName] # actions that want this pose enabled
var _enable_next : bool


func _ready():
	add_to_group("gbas_posenodes")


func _physics_process(_delta):
	if _enable_next:
		emit_signal("enable_pc")
	else:
		emit_signal("disable_pc")


func components_updated():
	var c = get_children()
	_children_pc.clear()
	for child in c:
		if child is GBASPoseComponent:
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
	# To be called _on_pc_activated (if _all_active), starting a timer, after which: if _all_active on_activated(), else don't do anything.


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
	# To be called _on_pc_deactivated, starting a timer, after which: if _all_active don't do anything, else on_deactivated().


func kill_act_timer():
	if is_instance_valid(activation_timer):
		activation_timer.queue_free()


func kill_grace_timer():
	if is_instance_valid(grace_timer):
		grace_timer.queue_free()


func on_activated():
	_active = true
	emit_signal("pn_activated")
	get_tree().call_group("gbas_actioncontrols", "on_pose_activated", id)
	print("pn called on_pose_activated")
	# Send the activated signal and such.


func on_deactivated():
	_active = false
	emit_signal("pn_deactivated")
	get_tree().call_group("gbas_actioncontrols", "on_pose_deactivated", id)
	# Send the deactivated signal and such.


func _on_request_enable_pose(actionid:StringName, poseid:StringName):
	if not id == poseid:
		return
	else:
		if actionid not in _actions:
			_actions.append(actionid)
		_enable_next = true


func _on_request_disable_pose(actionid:StringName, poseid:StringName):
	if not id == poseid:
		return
	else:
		_actions.erase(actionid)
		if not _actions.size():
			_enable_next = false
		else:
			_enable_next = true
