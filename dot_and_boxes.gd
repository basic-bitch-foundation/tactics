extends Node2D

var dotsize = 8
var linewidth = 6
var cellsize = 70
var startx = 100
var starty = 100

var dots = []
var hlines = []
var vlines = []
var boxes = []

var turn = true
var bluescore = 0
var redscore = 0

func _ready():
	setupgrid()
	connectlines()

func setupgrid():
	var bg = $ColorRect
	bg.size = Vector2(1152, 648)
	bg.position = Vector2(0, 0)
	bg.color = Color.WHITE
	
	var dotparent = $Grid/Dots
	var dotnodes = dotparent.get_children()
	
	var idx = 0
	for row in range(6):
		var dotrow = []
		for col in range(6):
			if idx < dotnodes.size():
				var dot = dotnodes[idx]
				dot.size = Vector2(dotsize, dotsize)
				dot.position = Vector2(startx + col * cellsize, starty + row * cellsize)
				dot.color = Color.BLACK
				dotrow.append(dot)
				idx += 1
		dots.append(dotrow)
	
	var hparent = $Grid/Lines/H_lines
	var hnodes = hparent.get_children()
	
	idx = 0
	for row in range(6):
		var hrow = []
		for col in range(5):
			if idx < hnodes.size():
				var line = hnodes[idx]
				line.size = Vector2(cellsize - dotsize - 2, linewidth)
				line.position = Vector2(startx + col * cellsize + dotsize, starty + row * cellsize + 1)
				line.color = Color.WHITE
				hrow.append(line)
				idx += 1
		hlines.append(hrow)
	
	var vparent = $Grid/Lines/V_lines
	var vnodes = vparent.get_children()
	
	idx = 0
	for row in range(5):
		var vrow = []
		for col in range(6):
			if idx < vnodes.size():
				var line = vnodes[idx]
				line.size = Vector2(linewidth, cellsize - dotsize - 2)
				line.position = Vector2(startx + col * cellsize + 1, starty + row * cellsize + dotsize)
				line.color = Color.WHITE
				vrow.append(line)
				idx += 1
		vlines.append(vrow)
	
	var boxparent = $Grid/Boxes
	var boxnodes = boxparent.get_children()
	
	idx = 0
	for row in range(5):
		var boxrow = []
		for col in range(5):
			if idx < boxnodes.size():
				var box = boxnodes[idx]
				box.size = Vector2(cellsize - dotsize - 2, cellsize - dotsize - 2)
				box.position = Vector2(startx + col * cellsize + dotsize, starty + row * cellsize + dotsize)
				box.color = Color.WHITE
				box.modulate.a = 0
				boxrow.append(box)
				idx += 1
		boxes.append(boxrow)

func connectlines():
	for row in range(6):
		for col in range(5):
			if hlines[row][col]:
				hlines[row][col].gui_input.connect(clickhline.bind(row, col))
	
	for row in range(5):
		for col in range(6):
			if vlines[row][col]:
				vlines[row][col].gui_input.connect(clickvline.bind(row, col))

func clickhline(event, row, col):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hlines[row][col].color == Color.WHITE:
			var linecolor = Color.BLUE if turn else Color.RED
			hlines[row][col].color = linecolor
			
			var captured = checkboxes(row, col, true)
			if not captured:
				turn = not turn

func clickvline(event, row, col):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if vlines[row][col].color == Color.WHITE:
			var linecolor = Color.BLUE if turn else Color.RED
			vlines[row][col].color = linecolor
			
			var captured = checkboxes(row, col, false)
			if not captured:
				turn = not turn

func checkboxes(row, col, ishline) -> bool:
	var captured = false
	
	if ishline:
		if row > 0:
			if isboxcomplete(row - 1, col):
				capturebox(row - 1, col)
				captured = true
		if row < 5:
			if isboxcomplete(row, col):
				capturebox(row, col)
				captured = true
	else:
		if col > 0:
			if isboxcomplete(row, col - 1):
				capturebox(row, col - 1)
				captured = true
		if col < 5:
			if isboxcomplete(row, col):
				capturebox(row, col)
				captured = true
	
	return captured

func isboxcomplete(row, col) -> bool:
	if boxes[row][col].modulate.a > 0:
		return false
	
	var top = hlines[row][col].color != Color.WHITE
	var bottom = hlines[row + 1][col].color != Color.WHITE
	var left = vlines[row][col].color != Color.WHITE
	var right = vlines[row][col + 1].color != Color.WHITE
	
	return top and bottom and left and right

func capturebox(row, col):
	var boxcolor = Color.BLUE if turn else Color.RED
	boxes[row][col].modulate = Color(boxcolor.r, boxcolor.g, boxcolor.b, 0.3)
	
	if turn:
		bluescore += 1
	else:
		redscore += 1
	
	print("Blue: ", bluescore, " | Red: ", redscore)
