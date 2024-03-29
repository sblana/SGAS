extends MeshInstance3D


@export var active_length := 1.0

var timer : Timer
var material : Material
var _active := false

@onready var gn : SGASGestureNode = $GNMakeRed



func _ready():
	timer = Timer.new()
	timer.autostart = false
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(reset)
	
	material = get_active_material(0)
	
	gn.gesture_activated.connect(activate)


func activate():
	if _active:
		return
	_active = true
	material.albedo_color = Color.RED
	timer.start(active_length)


func reset():
	_active = false
	material.albedo_color = Color.WHITE
