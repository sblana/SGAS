class_name SGASGestureEvent
extends Resource

@export_enum("POSE", "TIME") var event_type
@export_group("Pose")
@export var pose_id : StringName
@export var holdable := true
@export_group("Time")
@export var minimum_time := 0.0
@export var maximum_time := 0.0
