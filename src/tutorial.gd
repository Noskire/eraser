extends Control

@onready var tuto_1 = $TextureRect1
@onready var tuto_2 = $TextureRect2
@onready var tuto_3 = $TextureRect3

@onready var timer = $Timer

var can_pass = false
var idx = 0

func _input(event):
	if not can_pass:
		return
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true and event.double_click == false:
			show_next()

func show_tuto():
	mouse_filter = MOUSE_FILTER_STOP
	can_pass = false
	idx = 1
	tuto_1.show()
	timer.start()

func show_next():
	can_pass = false
	if idx == 1:
		idx = 2
		tuto_2.show()
		tuto_1.hide()
		timer.start()
	elif idx == 2:
		idx = 3
		tuto_3.show()
		tuto_2.hide()
		timer.start()
	else:
		idx = 0
		tuto_1.hide()
		tuto_2.hide()
		tuto_3.hide()
		mouse_filter = MOUSE_FILTER_IGNORE

func _on_timer_timeout():
	can_pass = true
