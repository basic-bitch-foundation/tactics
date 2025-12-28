extends Node2D


@onready var i_btn = $i_btn
@onready var minimize_btn = $minimize
@onready var instruction_panel = $Panel  


func _ready():
	
	instruction_panel.visible = false
	minimize_btn.visible = false
	
	
	i_btn.pressed.connect(_on_i_btn_pressed)
	minimize_btn.pressed.connect(_on_minimize_pressed)

func _on_i_btn_pressed():
	
	instruction_panel.visible = true
	minimize_btn.visible = true
	
	i_btn.visible = false
	

func _on_minimize_pressed():
	
	instruction_panel.visible = false
	minimize_btn.visible = false
	
	i_btn.visible = true
	
