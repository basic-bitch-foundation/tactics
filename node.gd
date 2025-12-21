extends Node2D


var xtex = preload("res://tactic-assets/x-board.png")

var otex = preload("res://tactic-assets/o-board.png")



var xhov = preload("res://tactic-assets/x-hover.png")

var ohov = preload("res://tactic-assets/o-hover.png")

var xturn = preload("res://tactic-assets/xturn.png")

var oturn = preload("res://tactic-assets/oturn.png")


var nums = []

var turn = true

var xscore = 0

var oscore = 0

var timer = 30

var board = []

var useai = true  

var aiside = true

var aiturn = false

var req: HTTPRequest


















func _ready():
	for i in range(10):
		nums.append(load("res://tactic-assets/" + str(i) + ".png"))
	
	board.append($Node2D/TextureButton)
	
	board.append($Node2D/TextureButton2)
	
	board.append($Node2D/TextureButton3)
	
	board.append($Node2D/TextureButton4)
	
	board.append($Node2D/TextureButton5)
	
	board.append($Node2D/TextureButton6)
	
	board.append($Node2D/TextureButton7)
	
	board.append($Node2D/TextureButton8)
	
	board.append($Node2D/TextureButton9)
	
	
	for cell in board:
		cell.pressed.connect(click.bind(cell))
	
	$timer/CountdownTimer.timeout.connect(tick)
	
	
	
	
	
	req = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(gotresponse)
	
	refresh()
	drawtimer()
	drawscore()
	
	if useai and not aiside:
		call_deferred("aimove")






















func click(cell):
	if cell.disabled or aiturn:
		return
	
	
	
	
	
	
	
	
	
	var mark = xtex if turn else otex
	cell.texture_normal = mark
	cell.texture_hover = mark
	cell.disabled = true
	
	
	
	
	
	
	
	
	if checkwin():
		if turn:
			xscore += 1
		else:
			oscore += 1
		drawscore()
		resetgame()
		return
	
	if boardfull():
		resetgame()
		return
	
	turn = not turn
	timer = 30
	refresh()
	
	if useai and ((aiside and not turn) or (not aiside and turn)):
		call_deferred("aimove")























func aimove():
	if aiturn:
		return
	
	aiturn = true
	
	
	var state = getstate()
	
	var avail = getmoves()
	
	
	var aisym = "O" if aiside else "X"
	
	
	var playsym = "X" if aiside else "O"
	
	
	
	
	var msg = "Tic Tac Toe Game - You are '%s', opponent is '%s'\n" % [aisym, playsym]
	msg += "Board: %s\n" % state
	msg += "Available: %s\n" % avail
	msg += "Layout:\n1|2|3\n4|5|6\n7|8|9\n"
	msg += "Strategy: Win > Block > Center(5) > Corner\n"
	msg += "Reply with ONLY the position number (1-9). Nothing else."
	
	
	
	
	
	
	var data = {
		"model": "google/gemini-2.5-flash",
		"messages": [{"role": "user", "content": msg}],
		"temperature": 0.3,
		"max_tokens": 10
	}
	
	
	var body = JSON.stringify(data)
	
	
	
	
	
	
	
	
	
	
	var headers = [
		"Authorization: Bearer sk-hc-v1-fb0ff6e1952e4b3d815de0df186865010081332da1ee4bcd9060de60b620bcb5",
		"Content-Type: application/json"
	]
	
	
	
	
	
	var err = req.request(
		"https://ai.hackclub.com/proxy/v1/chat/completions",
		headers,
		HTTPClient.METHOD_POST,
		body
	)
	
	if err != OK:
		aiturn = false
		fallback()















func gotresponse(_result, code, _headers, body):
	aiturn = false
	
	if code != 200:
		fallback()
		return
	
	
	var text = body.get_string_from_utf8()
	
	var json = JSON.new()
	
	
	var err = json.parse(text)
	
	if err != OK:
		fallback()
		return
	
	
	
	var resp = json.data
	
	if not resp.has("choices") or resp.choices.size() == 0:
		fallback()
		return
	
	
	
	var choice = resp.choices[0]
	
	
	var aimsg = ""
	
	if choice.message.has("content") and choice.message.content != null and choice.message.content != "":
		aimsg = choice.message.content
	elif choice.message.has("reasoning") and choice.message.reasoning != null:
		aimsg = choice.message.reasoning
	elif choice.has("reasoning_details") and choice.reasoning_details.size() > 0:
		aimsg = choice.reasoning_details[0].text
	else:
		fallback()
		return
	
	aimsg = aimsg.strip_edges()
	print("AI: ", aimsg)
	
	
	
	var pos = -1
	
	
	var regex = RegEx.new()
	regex.compile("\\b([1-9])\\b")
	
	
	
	var match = regex.search(aimsg)
	
	if match:
		pos = int(match.get_string())
	else:
		for i in range(len(aimsg)):
			var c = aimsg[i]
			if c >= "1" and c <= "9":
				pos = int(c)
				break
	
	if pos >= 1 and pos <= 9:
		var idx = pos - 1
		if not board[idx].disabled:
			domove(idx)
			return
	
	fallback()





func domove(idx):
	var cell = board[idx]
	var mark = xtex if turn else otex
	cell.texture_normal = mark
	cell.texture_hover = mark
	cell.disabled = true
	
	if checkwin():
		if turn:
			xscore += 1
		else:
			oscore += 1
		drawscore()
		resetgame()
		return
	
	if boardfull():
		resetgame()
		return
	
	turn = not turn
	timer = 30
	refresh()






func fallback():
	var open = []
	for i in range(board.size()):
		if not board[i].disabled:
			open.append(i)
	
	if open.size() > 0:
		var pick = open[randi() % open.size()]
		domove(pick)






func getstate() -> String:
	var state = ""
	for i in range(board.size()):
		var cell = board[i]
		var p = i + 1
		if cell.disabled:
			if cell.texture_normal == xtex:
				state += "%d:X " % p
			else:
				state += "%d:O " % p
		else:
			state += "%d:_ " % p
	return state.strip_edges()















func getmoves() -> String:
	var avail = []
	for i in range(board.size()):
		if not board[i].disabled:
			avail.append(str(i + 1))
	return ",".join(avail)


















func boardfull() -> bool:
	for cell in board:
		if not cell.disabled:
			return false
	return true










func refresh():
	if aiturn:
		return
	var hov = xhov if turn else ohov
	for cell in board:
		if not cell.disabled:
			cell.texture_hover = hov
	$turn_indi/Sprite2D.texture = xturn if turn else oturn












func tick():
	timer -= 1
	if timer <= 0:
		turn = not turn
		timer = 33
		refresh()
	drawtimer()












func drawtimer():
	var m = timer / 60
	
	var s = timer % 60
	
	$timer/dig1.texture = nums[m / 10]
	
	$timer/dig2.texture = nums[m % 10]
	
	$timer/dig3.texture = nums[s / 10]
	
	$timer/dig4.texture = nums[s % 10]
	










func drawscore():
	$scoreboard/playerx/scoredigit1.texture = nums[xscore / 10]
	
	$scoreboard/playerx/scoredigit2.texture = nums[xscore % 10]
	
	$scoreboard/playero/scoredigit1.texture = nums[oscore / 10]
	
	
	$scoreboard/playero/scoredigit2.texture = nums[oscore % 10]


















func checkwin():
	var lines = [
		[0, 1, 2], [3, 4, 5], [6, 7, 8],
		[0, 3, 6], [1, 4, 7], [2, 5, 8],
		[0, 4, 8], [2, 4, 6]
	]
	
	for line in lines:
		var a = board[line[0]]
		var b = board[line[1]]
		var c = board[line[2]]
		
		if a.disabled and b.disabled and c.disabled:
			if a.texture_normal == b.texture_normal and b.texture_normal == c.texture_normal:
				return true
	
	return false















func resetgame():
	for cell in board:
		cell.disabled = false
		cell.texture_normal = null
	
	turn = true
	timer = 30
	refresh()
	
	if useai and not aiside:
		call_deferred("aimove")
