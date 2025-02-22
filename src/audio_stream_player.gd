extends AudioStreamPlayer

@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

const start_game_sfx = preload("res://sounds/決定ボタンを押す3.mp3")
const click_sfx = preload("res://sounds/カーソル移動5.mp3")
const alert_sfx = preload("res://sounds/警告音1.mp3")
const erase_sfx = preload("res://sounds/つるはしで壁を破壊2.mp3")
const win_sfx = preload("res://sounds/レベルアップ.mp3")

func _ready():
	await get_tree().create_timer(1.0).timeout
	play()

func play_sfx(sfx):
	if sfx_player.is_playing():
		sfx_player.stop()
	
	match sfx:
		"start":
			sfx_player.stream = start_game_sfx
		"click":
			sfx_player.stream = click_sfx
		"alert":
			sfx_player.stream = alert_sfx
		"erase":
			sfx_player.stream = erase_sfx
		"win":
			sfx_player.stream = win_sfx
	sfx_player.play()
