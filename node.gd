extends Node2D

var xtexture = preload("res://tactic-assets/x-board.png")
var otexture = preload("res://tactic-assets/o-board.png")
var xhovertex = preload("res://tactic-assets/x-hover.png")
var ohovertex = preload("res://tactic-assets/o-hover.png")
var xturntex = preload("res://tactic-assets/xturn.png")
var oturntex = preload("res://tactic-assets/oturn.png")

var numtextures = []
var xturn = true
var xscore = 0
var oscore = 0
var timeleft = 30
var boardcells = []
var aiactive = true
var aiplayso = true
var aithinking = false
var req: HTTPRequest

var webversion = false
var jscallback = null
var jswindow = null

var allowfallback = true
var lastwasfallback = false

@onready var backbtn = $back_btn
@onready var playersnd = $PlayerMoveSound
@onready var aisnd = $AIMoveSound
@onready var gameoversnd = $GameOverSound
@onready var fallbacksnd = $FallbackSound if has_node("fallbacksound") else null


func _ready():
	webversion = OS.has_feature("web")
	
	if webversion:
		setupweb()
	
	backbtn.pressed.connect(gobacktomenu)
	var githubbutton = $i_button
	githubbutton.pressed.connect(opengithub)

	for i in range(10):
		numtextures.append(load("res://tactic-assets/" + str(i) + ".png"))
	
	boardcells.append($Node2D/TextureButton)
	boardcells.append($Node2D/TextureButton2)
	boardcells.append($Node2D/TextureButton3)
	boardcells.append($Node2D/TextureButton4)
	boardcells.append($Node2D/TextureButton5)
	boardcells.append($Node2D/TextureButton6)
	boardcells.append($Node2D/TextureButton7)
	boardcells.append($Node2D/TextureButton8)
	boardcells.append($Node2D/TextureButton9)
	
	for cell in boardcells:
		cell.pressed.connect(cellclick.bind(cell))
	
	$timer/CountdownTimer.timeout.connect(timertick)
	
	req = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(airesponse)
	
	refreshboard()
	updatetimer()
	updatescore()
	
	if aiactive and not aiplayso:
		call_deferred("aimakemove")


func setupweb():
	jscallback = JavaScriptBridge.create_callback(webmessage)
	jswindow = JavaScriptBridge.get_interface("window")
	jswindow.addEventListener("message", jscallback)
	print("Web callback  compl")


func webmessage(args):
	if args.size() == 0:
		return
	
	var event = args[0]
	if event == null:
		return
	
	var data = event.data
	if data == null:
		return
	
	if not data.type:
		return
	
	var msgtype = str(data.type)
	
	if msgtype == "AI_RESPONSE":
		handlewebai(data)


func handlewebai(data):
	aithinking = false
	
	var content = ""
	if data.content:
		content = str(data.content)
	
	if content == "":
		print("AI: empty response")
		if allowfallback:
			print("fallback on")
			dorandomfallback()
		else:
			print("ai fail no fallback")
		return
	
	print(">>> AI RESPONSE: ", content)
	
	var pos = -1
	var regex = RegEx.new()
	regex.compile("\\b([1-9])\\b")
	var match = regex.search(content)
	
	if match:
		pos = int(match.get_string())
	else:
		for i in range(len(content)):
			var c = content[i]
			if c >= "1" and c <= "9":
				pos = int(c)
				break
	
	if pos >= 1 and pos <= 9:
		var idx = pos - 1
		if not boardcells[idx].disabled:
			lastwasfallback = false
			print(" AI PLAYS: %d " % pos)
			makemove(idx)
			return
	
	print("AI: invalid move")
	if allowfallback:
		print("fallback")
		dorandomfallback()
	else:
		print(" ai fails")


func cellclick(cell):
	if cell.disabled or aithinking:
		return
	
	var mark = xtexture if xturn else otexture
	cell.texture_normal = mark
	cell.texture_hover = mark
	cell.disabled = true
	
	if playersnd:
		playersnd.play()
	
	if checkforwin():
		if xturn:
			xscore += 1
		else:
			oscore += 1
		updatescore()
		
		if gameoversnd:
			gameoversnd.play()
		
		resetgame()
		return
	
	if boardfull():
		if gameoversnd:
			gameoversnd.play()
		
		resetgame()
		return
	
	xturn = not xturn
	timeleft = 30
	refreshboard()
	
	if aiactive and ((aiplayso and not xturn) or (not aiplayso and xturn)):
		call_deferred("aimakemove")


func aimakemove():
	if aithinking:
		return
	
	aithinking = true
	lastwasfallback = false
	
	var state = getboardstate()
	var avail = getavailmoves()
	var aisym = "O" if aiplayso else "X"
	var playsym = "X" if aiplayso else "O"
	
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
	
	if webversion:
		var body = JSON.stringify(data)
		var reqdata = JavaScriptBridge.create_object("Object")
		reqdata.type = "AI_REQUEST"
		reqdata.url = "https://ai.hackclub.com/proxy/v1/chat/completions"
		reqdata.method = "POST"
		reqdata.body = body
		reqdata.apiKey = "sk-hc-v1-fb0ff6e1952e4b3d815de0df186865010081332da1ee4bcd9060de60b620bcb5"
		
		jswindow.parent.postMessage(reqdata, "*")
		print("ai web req sent")
	else:
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
			aithinking = false
			print("ai web req fail")
			if allowfallback:
				print("falback")
				dorandomfallback()


func airesponse(_result, code, _headers, body):
	aithinking = false
	
	if code != 200:
		print("ai http error %d " % code)
		if allowfallback:
			print("falback")
			dorandomfallback()
		return
	
	var text = body.get_string_from_utf8()
	var json = JSON.new()
	var err = json.parse(text)
	
	if err != OK:
		print("ai parse error")
		if allowfallback:
			print("fallback")
			dorandomfallback()
		return
	
	var resp = json.data
	
	if not resp.has("choices") or resp.choices.size() == 0:
		print("ai no choice")
		if allowfallback:
			print("falback")
			dorandomfallback()
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
		print(" ai no content ")
		if allowfallback:
			print("falback")
			dorandomfallback()
		return
	
	aimsg = aimsg.strip_edges()
	print(">ai reespone: ", aimsg)
	
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
		if not boardcells[idx].disabled:
			lastwasfallback = false
			print(">>> AI PLAYS: %d <<<" % pos)
			makemove(idx)
			return
	
	print("ai invalid move")
	if allowfallback:
		print("falback")
		dorandomfallback()


func makemove(idx):
	var cell = boardcells[idx]
	var mark = xtexture if xturn else otexture
	cell.texture_normal = mark
	cell.texture_hover = mark
	cell.disabled = true
	
	if lastwasfallback:
		if fallbacksnd:
			fallbacksnd.play()
		elif aisnd:
			aisnd.play()
		print("fallback made move")
	else:
		if aisnd:
			aisnd.play()
		print("move by ai")
	
	if checkforwin():
		if xturn:
			xscore += 1
		else:
			oscore += 1
		updatescore()
		
		if gameoversnd:
			gameoversnd.play()
		
		resetgame()
		return
	
	if boardfull():
		if gameoversnd:
			gameoversnd.play()
		
		resetgame()
		return
	
	xturn = not xturn
	timeleft = 30
	refreshboard()


func dorandomfallback():
	if not allowfallback:
		print("falback disable")
		aithinking = false
		return
	
	lastwasfallback = true
	
	var open = []
	for i in range(boardcells.size()):
		if not boardcells[i].disabled:
			open.append(i)
	
	if open.size() > 0:
		var pick = open[randi() % open.size()]
		print("fall back picked: %d <<<" % (pick + 1))
		makemove(pick)


func getboardstate() -> String:
	var state = ""
	for i in range(boardcells.size()):
		var cell = boardcells[i]
		var p = i + 1
		if cell.disabled:
			if cell.texture_normal == xtexture:
				state += "%d: X " % p
			else:
				state += "%d:O " % p
		else:
			state += "%d: _ " % p
	return state.strip_edges()


func getavailmoves() -> String:
	var avail = []
	for i in range(boardcells.size()):
		if not boardcells[i].disabled:
			avail.append(str(i + 1))
	return ",".join(avail)


func boardfull() -> bool:
	for cell in boardcells:
		if not cell.disabled:
			return false
	return true


func refreshboard():
	if aithinking:
		return
	var hov = xhovertex if xturn else ohovertex
	for cell in boardcells:
		if not cell.disabled:
			cell.texture_hover = hov
	$turn_indi/Sprite2D.texture = xturntex if xturn else oturntex


func timertick():
	timeleft -= 1
	if timeleft <= 0:
		xturn = not xturn
		timeleft = 33
		refreshboard()
	updatetimer()


func updatetimer():
	var m = timeleft / 60
	var s = timeleft % 60
	$timer/dig1.texture = numtextures[m / 10]
	$timer/dig2.texture = numtextures[m % 10]
	$timer/dig3.texture = numtextures[s / 10]
	$timer/dig4.texture = numtextures[s % 10]


func updatescore():
	$scoreboard/playerx/scoredigit1.texture = numtextures[xscore / 10]
	$scoreboard/playerx/scoredigit2.texture = numtextures[xscore % 10]
	$scoreboard/playero/scoredigit1.texture = numtextures[oscore / 10]
	$scoreboard/playero/scoredigit2.texture = numtextures[oscore % 10]


func checkforwin():
	var lines = [
		[0, 1, 2], [3, 4, 5], [6, 7, 8],
		[0, 3, 6], [1, 4, 7], [2, 5, 8],
		[0, 4, 8], [2, 4, 6]
	]
	
	for line in lines:
		var a = boardcells[line[0]]
		var b = boardcells[line[1]]
		var c = boardcells[line[2]]
		
		if a.disabled and b.disabled and c.disabled:
			if a.texture_normal == b.texture_normal and b.texture_normal == c.texture_normal:
				return true
	
	return false


func resetgame():
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://main.tscn")


func opengithub():
	if webversion and jswindow:
		var msg = JavaScriptBridge.create_object("Object")
		msg.type = "OPEN_URL"
		msg.url = "https://github.com/basic-bitch-foundation/tactics/"
		jswindow.parent.postMessage(msg, "*")
	else:
		OS.shell_open("https://github.com/basic-bitch-foundation/tactics/")


func gobacktomenu():
	get_tree().change_scene_to_file("res://main.tscn")
'''
'''
