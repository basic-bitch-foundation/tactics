extends Node2D



var x_tex = preload("res://tactic-assets/x-board.png")


var o_tex = preload("res://tactic-assets/o-board.png")


var x_hover = preload("res://tactic-assets/x-hover.png")


var o_hover = preload("res://tactic-assets/o-hover.png")


var x_turn = preload("res://tactic-assets/xturn.png")


var o_turn = preload("res://tactic-assets/oturn.png")


var nums = []


var is_x = true


var x_score = 0


var o_score = 0


var time = 30


var cells = []













func _ready():
	for i in range(10):
		nums.append(load("res://tactic-assets/" + str(i) + ".png"))
	
	cells.append($Node2D/TextureButton)
	cells.append($Node2D/TextureButton2)
	cells.append($Node2D/TextureButton3)
	cells.append($Node2D/TextureButton4)
	cells.append($Node2D/TextureButton5)
	cells.append($Node2D/TextureButton6)
	cells.append($Node2D/TextureButton7)
	cells.append($Node2D/TextureButton8)
	cells.append($Node2D/TextureButton9)
	
	for cell in cells:
		cell.pressed.connect(on_cell_press.bind(cell))
	
	$timer/CountdownTimer.timeout.connect(on_timer)
	
	update_turn()
	update_hovers()
	update_timer()
	update_scores()










func on_cell_press(cell):
	if cell.disabled:
		return
	
	var mark = x_tex if is_x else o_tex
	cell.texture_normal = mark
	cell.texture_hover = mark
	cell.disabled = true
	
	if check_win():
		if is_x:
			x_score += 1
		else:
			o_score += 1
		update_scores()
		reset_board()
		return
	
	is_x = !is_x
	time = 30
	update_turn()
	update_hovers()










func update_hovers():
	var hover = x_hover if is_x else o_hover
	for cell in cells:
		if not cell.disabled:
			cell.texture_hover = hover




func update_turn():
	$turn_indi/Sprite2D.texture = x_turn if is_x else o_turn

















func on_timer():
	time -= 1
	if time <= 0:
		is_x = !is_x
		time = 33
		update_turn()
		update_hovers()
	update_timer()








func update_timer():
	var min = time / 60
	var sec = time % 60
	
	
	
	
	
	$timer/dig1.texture = nums[min / 10]
	
	
	
	
	$timer/dig2.texture = nums[min % 10]
	
	$timer/dig3.texture = nums[sec / 10]
	
	
	
	
	
	$timer/dig4.texture = nums[sec % 10]







func update_scores():
	
	
	$scoreboard/playerx/scoredigit1.texture = nums[x_score / 10]
	
	
	$scoreboard/playerx/scoredigit2.texture = nums[x_score % 10]
	
	
	$scoreboard/playero/scoredigit1.texture = nums[o_score / 10]
	
	
	$scoreboard/playero/scoredigit2.texture = nums[o_score % 10]




































func check_win():
	return false



























func reset_board():
	for cell in cells:
		cell.disabled = false
	
	update_hovers()
	time = 30
