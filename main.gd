extends Control

func _ready():
	$TTT.pressed.connect(_on_tictactoe_pressed)
	$DB.pressed.connect(_on_dots_pressed)
	$MUTE.pressed.connect(_on_mute_pressed)

func _on_tictactoe_pressed():
	get_tree().change_scene_to_file("res://node.tscn")

func _on_dots_pressed():
	get_tree().change_scene_to_file("res://dot_and_boxes.tscn")

func _on_mute_pressed():
	var muted = AudioManager.toggle_mute()
	
 

'''


'''
