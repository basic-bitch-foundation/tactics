extends Node2D

@onready var backbtn = $back_btn
@onready var playsnd = $PlayerMoveSound
@onready var aisnd = $AIMoveSound
@onready var oversnd = $GameOverSound
@onready var pinktens = $scoreboard/pink/Sprite2D2
@onready var pinkones = $scoreboard/pink/Sprite2D3
@onready var bluetens = $scoreboard/blue/Sprite2D2
@onready var blueones = $scoreboard/blue/Sprite2D3

const GRIDSIZE = 6
const DOTSPACE = 80
const GRIDOFF = Vector2(150, 150)

const DOTBLACK = preload("res://tactic-assets/black_dot.png")
const DOTPINK = preload("res://tactic-assets/pink_dot.png")
const DOTBLUE = preload("res://tactic-assets/blue_dot.png")
const LINEPINK = preload("res://tactic-assets/pink_line.png")
const LINEBLUE = preload("res://tactic-assets/blue_line.png")
const BOXPINK = preload("res://tactic-assets/pink_faded.png")
const BOXBLUE = preload("res://tactic-assets/blue_faded.png")
const TURNPINK = preload("res://tactic-assets/pink_turn.png")
const TURNBLUE = preload("res://tactic-assets/blue_turn.png")

var numtex = []

var hlines = []
var vlines = []
var boxdata = []
var curplayer = 0
var scores = [0, 0]

var aion = true
var aicolor = 1
var aibusy = false

const APIKEYS = [
	"sk-hc-v1-cfdae923f5bc41dbb09411ad00e6ee7c5541e576e4154a5e85bb6130fae09b70",
	"sk-hc-v1-d8422eb693734ad6b73db52baaef668c83119711ba144af5a4e7e38eeaebead8",
	"sk-hc-v1-bdf4897265f34d36938723d32432a45e150ddafdbe46473bb42ebe1662a88d09"
]

const AIMODELS = [
	"deepseek/deepseek-v3.2",
	"google/gemini-2.5-flash",
	"qwen/qwen3-32b"
]

const TIMEOUTVALS = [5.0, 3.0, 3.0]

var airesps = [null, null, null]
var aitimers = [0.0, 0.0, 0.0]
var aisent = [false, false, false]
var aiidx = 0
var iswait = false

var dotsprites = []
var hsprites = []
var vsprites = []
var boxsprites = []
var turnsprite: Sprite2D

var webmode = false
var jscb = null
var jswin = null
var webidx = 0


func _ready():
	webmode = OS.has_feature("web")
	
	if webmode:
		setupweb()
	
	backbtn.pressed.connect(goback)
	loadnums()
	makearrays()
	makesprites()
	drawscore()
	
	turnsprite = get_node("turn indicator/Sprite2D")
	drawturn()
	
	if not webmode:
		get_node("HTTPRequest1").request_completed.connect(gotresp.bind(0))
		get_node("HTTPRequest2").request_completed.connect(gotresp.bind(1))
		get_node("HTTPRequest3").request_completed.connect(gotresp.bind(2))
	
	print("Blue starts")
	
	if aion and curplayer == aicolor:
		call_deferred("aimove")


func cellclick(line: Sprite2D):
	var linetype = line.get_meta("type")
	var r = line.get_meta("row")
	var c = line.get_meta("col")
	
	if linetype == "h":
		hlines[r][c] = curplayer
	else:
		vlines[r][c] = curplayer
	
	line.visible = true
	line.texture = LINEBLUE if curplayer == 0 else LINEPINK
	if playsnd:
		playsnd.play()
	
	var gotbox = false
	if linetype == "h":
		if r > 0 and checkbox(r - 1, c):
			gotbox = true
		if r < GRIDSIZE - 1 and checkbox(r, c):
			gotbox = true
	else:
		if c > 0 and checkbox(r, c - 1):
			gotbox = true
		if c < GRIDSIZE - 1 and checkbox(r, c):
			gotbox = true
	
	var totboxes = (GRIDSIZE - 1) * (GRIDSIZE - 1)
	if scores[0] + scores[1] >= totboxes:
		return
	
	if not gotbox:
		curplayer = 1 - curplayer
		drawturn()
		print("Player %d turn (Blue=%d, Pink=%d)" % [curplayer + 1, scores[0], scores[1]])
		
		if aion and curplayer == aicolor:
			call_deferred("aimove")
	else:
		print("Player %d again! (Blue=%d, Pink=%d)" % [curplayer + 1, scores[0], scores[1]])
		
		if aion and curplayer == aicolor:
			call_deferred("aimove")


func randommove():
	print("random move")
	var havail = []
	var vavail = []
	
	for r in range(GRIDSIZE):
		for c in range(GRIDSIZE - 1):
			if hlines[r][c] == -1:
				havail.append([r, c])
	
	for r in range(GRIDSIZE - 1):
		for c in range(GRIDSIZE):
			if vlines[r][c] == -1:
				vavail.append([r, c])
	
	var allmoves = havail + vavail
	if allmoves.size() > 0:
		var pick = allmoves[randi() % allmoves.size()]
		if pick in havail:
			print("Fallback: H%d,%d" % [pick[0], pick[1]])
			cellclick(hsprites[pick[0]][pick[1]])
		else:
			print("Fallback: V%d,%d" % [pick[0], pick[1]])
			cellclick(vsprites[pick[0]][pick[1]])


func setupweb():
	jscb = JavaScriptBridge.create_callback(webmsg)
	jswin = JavaScriptBridge.get_interface("window")
	jswin.addEventListener("message", jscb)
	print("web callback compl")


func makeprompt() -> String:
	var txt = "DOTS AND BOXES - 6x6 Grid\n\n"
	
	var you = "Player2" if aicolor == 1 else "Player1"
	var opp = "Player1" if aicolor == 1 else "Player2"
	txt += "YOU: %s, OPP: %s\n" % [you, opp]
	txt += "Score: P1=%d, P2=%d\n\n" % [scores[0], scores[1]]
	
	txt += "GRID: 6x6 dots (rows 0-5, cols 0-5)\n"
	txt += "H-lines: horizontal (row,col)\n"
	txt += "V-lines: vertical (row,col)\n\n"
	
	txt += "CLAIMED:\n"
	var p1moves = []
	var p2moves = []
	
	for r in range(GRIDSIZE):
		for c in range(GRIDSIZE - 1):
			if hlines[r][c] == 0:
				p1moves.append("H%d,%d" % [r, c])
			elif hlines[r][c] == 1:
				p2moves.append("H%d,%d" % [r, c])
	
	for r in range(GRIDSIZE - 1):
		for c in range(GRIDSIZE):
			if vlines[r][c] == 0:
				p1moves.append("V%d,%d" % [r, c])
			elif vlines[r][c] == 1:
				p2moves.append("V%d,%d" % [r, c])
	
	txt += "P1: %s\n" % (", ".join(p1moves) if p1moves.size() > 0 else "none")
	txt += "P2: %s\n\n" % (", ".join(p2moves) if p2moves.size() > 0 else "none")
	
	txt += "3-SIDED BOXES:\n"
	var critboxes = []
	for r in range(GRIDSIZE - 1):
		for c in range(GRIDSIZE - 1):
			if boxdata[r][c] == -1:
				var sidecount = 0
				if hlines[r][c] != -1: sidecount += 1
				if hlines[r + 1][c] != -1: sidecount += 1
				if vlines[r][c] != -1: sidecount += 1
				if vlines[r][c + 1] != -1: sidecount += 1
				
				if sidecount == 3:
					var missing = ""
					if hlines[r][c] == -1: missing = "H%d,%d" % [r, c]
					elif hlines[r + 1][c] == -1: missing = "H%d,%d" % [r + 1, c]
					elif vlines[r][c] == -1: missing = "V%d,%d" % [r, c]
					elif vlines[r][c + 1] == -1: missing = "V%d,%d" % [r, c + 1]
					critboxes.append("Box(%d,%d)=%s" % [r, c, missing])
	
	if critboxes.size() > 0:
		txt += ", ".join(critboxes) + "\n\n"
	else:
		txt += "None\n\n"
	
	txt += "AVAILABLE:\n"
	var openmoves = []
	for r in range(GRIDSIZE):
		for c in range(GRIDSIZE - 1):
			if hlines[r][c] == -1:
				openmoves.append("H%d,%d" % [r, c])
	
	for r in range(GRIDSIZE - 1):
		for c in range(GRIDSIZE):
			if vlines[r][c] == -1:
				openmoves.append("V%d,%d" % [r, c])
	
	txt += ", ".join(openmoves) + "\n\n"
	
	txt += "STRATEGY:\n"
	txt += "1. Complete 3-sided boxes first\n"
	txt += "2. Block opponent boxes\n"
	txt += "3. Chain captures\n"
	txt += "4. Avoid making 3-sided boxes\n"
	txt += "5. Control endgame\n\n"
	
	txt += "Reply with move: H<row>,<col> or V<row>,<col>\n"
	txt += "Example: H2,3 or V1,4\n"
	txt += "Your move:"
	
	return txt


func checkbox(r: int, c: int) -> bool:
	if boxdata[r][c] != -1:
		return false
	
	var top = hlines[r][c] != -1
	var bot = hlines[r + 1][c] != -1
	var left = vlines[r][c] != -1
	var right = vlines[r][c + 1] != -1
	
	if top and bot and left and right:
		boxdata[r][c] = curplayer
		scores[curplayer] += 1
		drawscore()
		
		var boxspr = boxsprites[r][c]
		boxspr.visible = true
		boxspr.texture = BOXBLUE if curplayer == 0 else BOXPINK
		
		var corners = [
			[r, c], [r, c + 1],
			[r + 1, c], [r + 1, c + 1]
		]
		for corner in corners:
			dotsprites[corner[0]][corner[1]].texture = DOTBLUE if curplayer == 0 else DOTPINK
		
		print("Player %d scored! (Blue=%d, Pink=%d)" % [curplayer + 1, scores[0], scores[1]])
		
		var totboxes = (GRIDSIZE - 1) * (GRIDSIZE - 1)
		if scores[0] + scores[1] >= totboxes:
			gameover()
		
		return true
	
	return false


func webmsg(args):
	if args.size() == 0:
		return
	
	var evt = args[0]
	if evt == null:
		return
	
	var data = evt.data
	if data == null:
		return
	
	if not data.type:
		return
	
	var mtype = str(data.type)
	
	if mtype == "AI_RESPONSE":
		handlewebresponse(data)


func _input(event):
	if aibusy:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if aion and curplayer == aicolor:
			return
		
		var mousepos = get_global_mouse_position()
		var bestline = null
		var bestdist = 40.0
		
		for r in range(GRIDSIZE):
			for c in range(GRIDSIZE - 1):
				if hlines[r][c] == -1:
					var ln = hsprites[r][c]
					var dst = mousepos.distance_to(ln.global_position)
					if dst < bestdist:
						bestdist = dst
						bestline = ln
		
		for r in range(GRIDSIZE - 1):
			for c in range(GRIDSIZE):
				if vlines[r][c] == -1:
					var ln = vsprites[r][c]
					var dst = mousepos.distance_to(ln.global_position)
					if dst < bestdist:
						bestdist = dst
						bestline = ln
		
		if bestline:
			cellclick(bestline)


func handlewebresponse(data):
	var msg = ""
	if data.content:
		msg = str(data.content)
	
	if msg == "":
		print("AI %d: empty response" % (webidx + 1))
		trynextai()
		return
	
	print("AI %d: %s" % [webidx + 1, msg])
	
	var regex = RegEx.new()
	regex.compile("([HV])(\\d+),(\\d+)")
	var match = regex.search(msg)
	
	if match:
		var ltype = match.get_string(1)
		var row = int(match.get_string(2))
		var col = int(match.get_string(3))
		
		if ltype == "H" and row >= 0 and row < GRIDSIZE and col >= 0 and col < GRIDSIZE - 1:
			if hlines[row][col] == -1:
				print("AI plays: H%d,%d" % [row, col])
				if aisnd:
					aisnd.play()
				aibusy = false
				cellclick(hsprites[row][col])
				return
		elif ltype == "V" and row >= 0 and row < GRIDSIZE - 1 and col >= 0 and col < GRIDSIZE:
			if vlines[row][col] == -1:
				print("AI plays: V%d,%d" % [row, col])
				if aisnd:
					aisnd.play()
				aibusy = false
				cellclick(vsprites[row][col])
				return
	
	print("AI %d: invalid move" % (webidx + 1))
	trynextai()


func loadnums():
	for i in range(10):
		numtex.append(load("res://tactic-assets/" + str(i) + ".png"))


func drawscore():
	var bt = scores[0] / 10
	var bo = scores[0] % 10
	var pt = scores[1] / 10
	var po = scores[1] % 10
	
	bluetens.texture = numtex[bt]
	blueones.texture = numtex[bo]
	pinktens.texture = numtex[pt]
	pinkones.texture = numtex[po]


func trynextai():
	webidx += 1
	if webidx < 3:
		webask(webidx)
	else:
		aibusy = false
		randommove()


func webask(i: int):
	if i >= 3:
		aibusy = false
		randommove()
		return
	
	webidx = i
	
	var prompt = makeprompt()
	var reqdata = {
		"model": AIMODELS[i],
		"messages": [{"role": "user", "content": prompt}],
		"temperature": 0.7,
		"max_tokens": 100
	}
	
	var body = JSON.stringify(reqdata)
	
	var msgobj = JavaScriptBridge.create_object("Object")
	msgobj.type = "AI_REQUEST"
	msgobj.url = "https://ai.hackclub.com/proxy/v1/chat/completions"
	msgobj.method = "POST"
	msgobj.body = body
	msgobj.apiKey = APIKEYS[i]
	
	print("AI %d (%s) - web request" % [i + 1, AIMODELS[i]])
	jswin.parent.postMessage(msgobj, "*")


func drawturn():
	if not turnsprite:
		return
	turnsprite.texture = TURNBLUE if curplayer == 0 else TURNPINK


func makearrays():
	for r in range(GRIDSIZE):
		dotsprites.append([])
		for c in range(GRIDSIZE):
			dotsprites[r].append(null)
	
	for r in range(GRIDSIZE):
		hlines.append([])
		hsprites.append([])
		for c in range(GRIDSIZE - 1):
			hlines[r].append(-1)
			hsprites[r].append(null)
	
	for r in range(GRIDSIZE - 1):
		vlines.append([])
		vsprites.append([])
		for c in range(GRIDSIZE):
			vlines[r].append(-1)
			vsprites[r].append(null)
	
	for r in range(GRIDSIZE - 1):
		boxdata.append([])
		boxsprites.append([])
		for c in range(GRIDSIZE - 1):
			boxdata[r].append(-1)
			boxsprites[r].append(null)


func gameover():
	if oversnd:
		oversnd.play()
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://main.tscn")
	if scores[0] > scores[1]:
		print("GAME OVER - BLUE WINS! (%d-%d)" % [scores[0], scores[1]])
	elif scores[1] > scores[0]:
		print("GAME OVER - PINK WINS! (%d-%d)" % [scores[0], scores[1]])
	else:
		print("GAME OVER - TIE! (%d-%d)" % [scores[0], scores[1]])


func makesprites():
	for r in range(GRIDSIZE - 1):
		for c in range(GRIDSIZE - 1):
			var boxspr = Sprite2D.new()
			boxspr.position = GRIDOFF + Vector2((c + 0.5) * DOTSPACE, (r + 0.5) * DOTSPACE)
			boxspr.visible = false
			add_child(boxspr)
			boxsprites[r][c] = boxspr
	
	for r in range(GRIDSIZE):
		for c in range(GRIDSIZE - 1):
			var linespr = Sprite2D.new()
			linespr.position = GRIDOFF + Vector2((c + 0.5) * DOTSPACE, r * DOTSPACE)
			linespr.visible = false
			linespr.set_meta("type", "h")
			linespr.set_meta("row", r)
			linespr.set_meta("col", c)
			add_child(linespr)
			hsprites[r][c] = linespr
	
	for r in range(GRIDSIZE - 1):
		for c in range(GRIDSIZE):
			var linespr = Sprite2D.new()
			linespr.position = GRIDOFF + Vector2(c * DOTSPACE, (r + 0.5) * DOTSPACE)
			linespr.rotation_degrees = 90
			linespr.visible = false
			linespr.set_meta("type", "v")
			linespr.set_meta("row", r)
			linespr.set_meta("col", c)
			add_child(linespr)
			vsprites[r][c] = linespr
	
	for r in range(GRIDSIZE):
		for c in range(GRIDSIZE):
			var dotspr = Sprite2D.new()
			dotspr.texture = DOTBLACK
			dotspr.position = GRIDOFF + Vector2(c * DOTSPACE, r * DOTSPACE)
			add_child(dotspr)
			dotsprites[r][c] = dotspr


func _process(delta):
	if webmode:
		return
	
	if not iswait:
		return
	
	for i in range(3):
		if aisent[i] and airesps[i] == null:
			aitimers[i] += delta
	
	if aiidx < 3:
		if aitimers[aiidx] >= TIMEOUTVALS[aiidx]:
			if airesps[aiidx] == null:
				print("AI %d timeout, next..." % (aiidx + 1))
				aiidx += 1
				
				if aiidx < 3:
					askai(aiidx)
				else:
					print("All AIs timeout, random move")
					clearai()
					randommove()


func aimove():
	if aibusy:
		return
	
	aibusy = true
	
	if webmode:
		webidx = 0
		webask(0)
	else:
		iswait = true
		aiidx = 0
		airesps = [null, null, null]
		aitimers = [0.0, 0.0, 0.0]
		aisent = [false, false, false]
		print("AI thinking...")
		askai(0)


func askai(i: int):
	if i >= 3:
		return
	
	var req = get_node("HTTPRequest" + str(i + 1))
	var prompt = makeprompt()
	var model = AIMODELS[i]
	
	var reqdata = {
		"model": model,
		"messages": [{"role": "user", "content": prompt}],
		"temperature": 0.7,
		"max_tokens": 100
	}
	
	var body = JSON.stringify(reqdata)
	var headers = [
		"Authorization: Bearer " + APIKEYS[i],
		"Content-Type: application/json"
	]
	
	print("AI %d (%s) timeout: %.1fs" % [i + 1, model, TIMEOUTVALS[i]])
	
	var err = req.request(
		"https://ai.hackclub.com/proxy/v1/chat/completions",
		headers,
		HTTPClient.METHOD_POST,
		body
	)
	
	if err != OK:
		print("AI %d failed" % (i + 1))
		airesps[i] = "ERROR"
	else:
		aisent[i] = true
		aitimers[i] = 0.0


func gotresp(_result, code, _headers, body, i: int):
	if not iswait:
		return
	
	if code != 200:
		print("AI %d error %d" % [i + 1, code])
		airesps[i] = "ERROR"
		return
	
	var txt = body.get_string_from_utf8()
	var json = JSON.new()
	var err = json.parse(txt)
	
	if err != OK:
		print("AI %d parse error" % (i + 1))
		airesps[i] = "ERROR"
		return
	
	var resp = json.data
	if not resp.has("choices") or resp.choices.size() == 0:
		print("AI %d bad response" % (i + 1))
		airesps[i] = "ERROR"
		return
	
	var choice = resp.choices[0]
	var msg = ""
	
	if choice.message.has("content") and choice.message.content != null:
		msg = choice.message.content
	else:
		print("AI %d no content" % (i + 1))
		airesps[i] = "ERROR"
		return
	
	msg = msg.strip_edges()
	print("AI %d: %s" % [i + 1, msg])
	
	airesps[i] = msg
	
	if i == aiidx:
		parsemove(msg, i)


func parsemove(msg: String, i: int):
	var regex = RegEx.new()
	regex.compile("([HV])(\\d+),(\\d+)")
	var match = regex.search(msg)
	
	if match:
		var ltype = match.get_string(1)
		var row = int(match.get_string(2))
		var col = int(match.get_string(3))
		
		if ltype == "H" and row >= 0 and row < GRIDSIZE and col >= 0 and col < GRIDSIZE - 1:
			if hlines[row][col] == -1:
				print("AI %d plays: H%d,%d (%.1fs)" % [i + 1, row, col, aitimers[i]])
				if aisnd:
					aisnd.play()
				clearai()
				cellclick(hsprites[row][col])
				return
		elif ltype == "V" and row >= 0 and row < GRIDSIZE - 1 and col >= 0 and col < GRIDSIZE:
			if vlines[row][col] == -1:
				print("AI %d plays: V%d,%d (%.1fs)" % [i + 1, row, col, aitimers[i]])
				if aisnd:
					aisnd.play()
				clearai()
				cellclick(vsprites[row][col])
				return
	
	print("AI %d bad move" % (i + 1))
	
	aiidx += 1
	if aiidx < 3:
		if aisent[aiidx] and airesps[aiidx] != null:
			parsemove(airesps[aiidx], aiidx)
		else:
			askai(aiidx)
	else:
		clearai()
		randommove()


func clearai():
	aibusy = false
	iswait = false
	airesps = [null, null, null]
	aitimers = [0.0, 0.0, 0.0]
	aisent = [false, false, false]
	aiidx = 0


func goback():
	get_tree().change_scene_to_file("res://main.tscn")
