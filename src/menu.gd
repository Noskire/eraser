extends Control

@onready var n_players_spin_box = $Margin/VBox/HBox/HBox/NPlayersSpinBox
@onready var width_spin_box = $Margin/VBox/HBox/HBox2/WidthSpinBox
@onready var height_spin_box = $Margin/VBox/HBox/HBox2/HeightSpinBox

#@onready var panel1 = $Margin/VBox/Center/HBox/Panel1
@onready var player1_name = $Margin/VBox/Center/HBox/Panel1/Margin/VBox/PlayerName
@onready var player1_btn = $Margin/VBox/Center/HBox/Panel1/Margin/VBox/HBox/Player
@onready var ai1_btn = $Margin/VBox/Center/HBox/Panel1/Margin/VBox/HBox/AI

#@onready var panel2 = $Margin/VBox/Center/HBox/Panel2
@onready var player2_name = $Margin/VBox/Center/HBox/Panel2/Margin/VBox/PlayerName
@onready var player2_btn = $Margin/VBox/Center/HBox/Panel2/Margin/VBox/HBox/Player
@onready var ai2_btn = $Margin/VBox/Center/HBox/Panel2/Margin/VBox/HBox/AI

@onready var panel3 = $Margin/VBox/Center/HBox/Panel3
@onready var player3_name = $Margin/VBox/Center/HBox/Panel3/Margin/VBox/PlayerName
@onready var player3_btn = $Margin/VBox/Center/HBox/Panel3/Margin/VBox/HBox/Player
@onready var ai3_btn = $Margin/VBox/Center/HBox/Panel3/Margin/VBox/HBox/AI

@onready var panel4 = $Margin/VBox/Center/HBox/Panel4
@onready var player4_name = $Margin/VBox/Center/HBox/Panel4/Margin/VBox/PlayerName
@onready var player4_btn = $Margin/VBox/Center/HBox/Panel4/Margin/VBox/HBox/Player
@onready var ai4_btn = $Margin/VBox/Center/HBox/Panel4/Margin/VBox/HBox/AI

@onready var master_vol = $Margin/VBox/HBox2/HBox/MasterVol

@onready var tutorial = $Tutorial

func _ready():
	n_players_spin_box.value = Global.num_players
	width_spin_box.value = Global.grid_size.x
	height_spin_box.value = Global.grid_size.y
	
	player1_name.text = Global.players_names[0]
	player2_name.text = Global.players_names[1]
	player3_name.text = Global.players_names[2]
	player4_name.text = Global.players_names[3]
	
	master_vol.value = Global.master_vol

func _on_n_players_spin_box_value_changed(value):
	Global.num_players = value
	if value >= 3:
		panel3.show()
	else:
		panel3.hide()
	if value == 4:
		panel4.show()
	else:
		panel4.hide()

func _on_width_spin_box_value_changed(value):
	Global.grid_size.x = value

func _on_height_spin_box_value_changed(value):
	Global.grid_size.y = value

func _on_player1_name_text_changed(new_text):
	Global.players_names[0] = new_text

func _on_player2_name_text_changed(new_text):
	Global.players_names[1] = new_text

func _on_player3_name_text_changed(new_text):
	Global.players_names[2] = new_text

func _on_player4_name_text_changed(new_text):
	Global.players_names[3] = new_text

func _on_player1_toggled(toggled_on):
	AudioPlayer.play_sfx("click")
	if toggled_on:
		ai1_btn.set_pressed_no_signal(false)
		Global.players[0] = "player"
	else:
		ai1_btn.set_pressed_no_signal(true)
		Global.players[0] = "ai"

func _on_ai1_toggled(toggled_on):
	AudioPlayer.play_sfx("click")
	if toggled_on:
		player1_btn.set_pressed_no_signal(false)
		Global.players[0] = "ai"
	else:
		player1_btn.set_pressed_no_signal(true)
		Global.players[0] = "player"

func _on_player2_toggled(toggled_on):
	AudioPlayer.play_sfx("click")
	if toggled_on:
		ai2_btn.set_pressed_no_signal(false)
		Global.players[1] = "player"
	else:
		ai2_btn.set_pressed_no_signal(true)
		Global.players[1] = "ai"

func _on_ai2_toggled(toggled_on):
	AudioPlayer.play_sfx("click")
	if toggled_on:
		player2_btn.set_pressed_no_signal(false)
		Global.players[1] = "ai"
	else:
		player2_btn.set_pressed_no_signal(true)
		Global.players[1] = "player"

func _on_player3_toggled(toggled_on):
	AudioPlayer.play_sfx("click")
	if toggled_on:
		ai3_btn.set_pressed_no_signal(false)
		Global.players[2] = "player"
	else:
		ai3_btn.set_pressed_no_signal(true)
		Global.players[2] = "ai"

func _on_ai3_toggled(toggled_on):
	AudioPlayer.play_sfx("click")
	if toggled_on:
		player3_btn.set_pressed_no_signal(false)
		Global.players[2] = "ai"
	else:
		player3_btn.set_pressed_no_signal(true)
		Global.players[2] = "player"

func _on_player4_toggled(toggled_on):
	AudioPlayer.play_sfx("click")
	if toggled_on:
		ai4_btn.set_pressed_no_signal(false)
		Global.players[3] = "player"
	else:
		ai4_btn.set_pressed_no_signal(true)
		Global.players[3] = "ai"

func _on_ai4_toggled(toggled_on):
	AudioPlayer.play_sfx("click")
	if toggled_on:
		player4_btn.set_pressed_no_signal(false)
		Global.players[3] = "ai"
	else:
		player4_btn.set_pressed_no_signal(true)
		Global.players[3] = "player"

func _on_start_game_button_up():
	AudioPlayer.play_sfx("start")
	get_tree().change_scene_to_file("res://src/main.tscn")

func _on_master_vol_value_changed(value):
	Global.master_vol = value
	
	if value == 0:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_show_tutorial_button_up():
	tutorial.show_tuto()
