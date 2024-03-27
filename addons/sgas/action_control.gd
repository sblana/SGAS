class_name GBASActionControl
extends Node

signal action_reset
signal action_activated

@export var id : StringName
@export var events : Array[GBASGestureEvent]

var event_timer : Timer
enum EVENT_STATE{CURRENT, PASSED}
var _past_events_state : Array[EVENT_STATE]
var _next_event : int

func _ready():
	event_timer = Timer.new()
	event_timer.autostart = false
	event_timer.one_shot = true
	event_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(event_timer)
	# dont start timer or timeout.connect() now: timer is used first for minimum_time and then maximum_time
	add_to_group("gbas_actioncontrols")
	prepare_next_event()


func reset():
	emit_signal("action_reset")
	_past_events_state.clear()
	_next_event = 0
	for event in events:
		if event.event_type == 0:
			get_tree().call_group("gbas_posenodes", "_on_request_disable_pose", self.id, event.pose_id)
	prepare_next_event()


func prepare_next_event():
	if events.size() - 1 < _next_event:
		activate()
		reset()
	elif events[_next_event].event_type == 0: # if next event is a pose
		get_tree().call_group("gbas_posenodes", "_on_request_enable_pose", self.id, events[_next_event].pose_id)
	elif events[_next_event].event_type == 1: # if next event is a timer
		start_min_timer(_next_event)
	# call after pose_deactivated(), min_timeout(), or after reset


func activate():
	emit_signal("action_activated")


func unexpected_pose():
	reset()


func on_pose_activated(poseid:StringName):
	print("ac on_pose_activated")
	if not events[_next_event].event_type == 0: # enum POSE
		unexpected_pose()
		return
	else:
		if not events[_next_event].pose_id == poseid:
			if not events[0].pose_id == poseid:
				unexpected_pose()
				return
			else: # received the first pose, reset and run this function again
				reset()
				on_pose_activated(poseid)
		if _next_event:
			if not _past_events_state[_next_event - 1] == EVENT_STATE.PASSED:
				unexpected_pose()
				return
		if event_timer.timeout.is_connected(max_timeout):
			event_timer.timeout.disconnect(max_timeout)
		_past_events_state.append(EVENT_STATE.CURRENT)
		_next_event += 1
		if not events[_next_event - 1].holdable:
			get_tree().call_group("gbas_posenodes", "_on_request_disable_pose", self.id, events[_next_event - 1].pose_id)
		return


func on_pose_deactivated(poseid:StringName):
	if not _next_event:
		return # _next_event is at 0; we ignore
	else:
		if events[_next_event - 1].pose_id == poseid: #if last event is the same as the pose that was deactivated
			if _past_events_state[_next_event - 1] == EVENT_STATE.CURRENT: #if last event is marked as active ('current')
				_past_events_state[_next_event - 1] = EVENT_STATE.PASSED #mark last event as not active ('passed')
				get_tree().call_group("gbas_posenodes", "_on_request_disable_pose", self.id, poseid)
				prepare_next_event()
				return
			# else: unexpected result
		# else: unexpected result


func start_min_timer(event_index:int): # similar to pose_activated
	_past_events_state.append(EVENT_STATE.CURRENT)
	_next_event += 1
	if events[event_index].minimum_time:
		event_timer.timeout.connect(min_timeout, CONNECT_ONE_SHOT)
		event_timer.start(events[event_index].minimum_time)
	else: min_timeout()
	# starts timer; grabs properties from events:Array with the given index. call only when _past_events_state[_next_event - 1] is PASSED.


func min_timeout(): # similar to pose_deactivated
	_past_events_state[_next_event - 1] = EVENT_STATE.PASSED
	prepare_next_event()
	start_max_timer(_next_event - 1)


func start_max_timer(event_index:int):
	if events[event_index].maximum_time:
		event_timer.timeout.connect(max_timeout, CONNECT_ONE_SHOT)
		event_timer.start(events[event_index].maximum_time)
	# starts timer; grabs properties from events:Array with the given index. call only when _past_events_state[_next_event - 1] is PASSED.


func max_timeout():
	reset()
