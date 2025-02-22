extends Control

@onready var anim = $AnimationPlayer

var skip_time = 4.0

const main_path = "res://src/menu.tscn"

func _input(event:InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed == true and event.double_click == false:
			skip_splash()

func skip_splash():
	var curr_time = anim.get_current_animation_position()
	
	if curr_time < skip_time:
		anim.seek(skip_time, true)
	else:
		anim.stop()
		get_tree().change_scene_to_file(main_path)

func _on_animation_finished(_anim_name):
	get_tree().change_scene_to_file(main_path)
