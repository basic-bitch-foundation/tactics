extends Node2D

const GRID_SIZE = 6
const DOT_SPACING = 80
const GRID_OFFSET = Vector2(150, 150)

const DOT_BLACK = preload("res://tactic-assets/black_dot.png")
const DOT_PINK = preload("res://tactic-assets/pink_dot.png")
const DOT_BLUE = preload("res://tactic-assets/blue_dot.png")
const LINE_PINK = preload("res://tactic-assets/pink_line.png")
const LINE_BLUE = preload("res://tactic-assets/blue_line.png")
const BOX_PINK = preload("res://tactic-assets/pink_faded.png")
const BOX_BLUE = preload("res://tactic-assets/blue_faded.png")
const TURN_PINK = preload("res://tactic-assets/pink_turn.png")
const TURN_BLUE = preload("res://tactic-assets/blue_turn.png")

var h_lines = []
var v_lines = []
var boxes = []
var player = 0
var score = [0, 0]

var ai_on = true
var ai_side = 1
var ai_busy = false

const KEYS = [
	"sk-hc-v1-cfdae923f5bc41dbb09411ad00e6ee7c5541e576e4154a5e85bb6130fae09b70",
	"sk-hc-v1-d8422eb693734ad6b73db52baaef668c83119711ba144af5a4e7e38eeaebead8",
	"sk-hc-v1-bdf4897265f34d36938723d32432a45e150ddafdbe46473bb42ebe1662a88d09"
]

const MODELS = [
	"deepseek/deepseek-v3.2",
	"google/gemini-2.5-flash",
	"qwen/qwen3-32b"
]

const TIMEOUTS = [5.0, 3.0, 3.0]

var response = [null, null, null]
var timer = [0.0, 0.0, 0.0]
var sent = [false, false, false]
var idx = 0
var waiting = false

var dots = []
var h_sprites = []
var v_sprites = []
var box_sprites = []
var turn_img: Sprite2D


func _ready():
	setup_arrays()
	make_sprites()
	
	turn_img = get_node("turn indicator/Sprite2D")
	update_turn()
	
	get_node("HTTPRequest1").request_completed.connect(on_response.bind(0))
	get_node("HTTPRequest2").request_completed.connect(on_response.bind(1))
	get_node("HTTPRequest3").request_completed.connect(on_response.bind(2))
	
	print("Dots and Boxes - Blue starts")
	
	if ai_on and player == ai_side:
		call_deferred("ai_move")


func update_turn():
	if not turn_img:
		return
	turn_img.texture = TURN_BLUE if player == 0 else TURN_PINK


func setup_arrays():
	for row in range(GRID_SIZE):
		dots.append([])
		for col in range(GRID_SIZE):
			dots[row].append(null)
	
	for row in range(GRID_SIZE):
		h_lines.append([])
		h_sprites.append([])
		for col in range(GRID_SIZE - 1):
			h_lines[row].append(-1)
			h_sprites[row].append(null)
	
	for row in range(GRID_SIZE - 1):
		v_lines.append([])
		v_sprites.append([])
		for col in range(GRID_SIZE):
			v_lines[row].append(-1)
			v_sprites[row].append(null)
	
	for row in range(GRID_SIZE - 1):
		boxes.append([])
		box_sprites.append([])
		for col in range(GRID_SIZE - 1):
			boxes[row].append(-1)
			box_sprites[row].append(null)


func make_sprites():
	for row in range(GRID_SIZE - 1):
		for col in range(GRID_SIZE - 1):
			var b = Sprite2D.new()
			b.position = GRID_OFFSET + Vector2((col + 0.5) * DOT_SPACING, (row + 0.5) * DOT_SPACING)
			b.visible = false
			add_child(b)
			box_sprites[row][col] = b
	
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE - 1):
			var l = Sprite2D.new()
			l.position = GRID_OFFSET + Vector2((col + 0.5) * DOT_SPACING, row * DOT_SPACING)
			l.visible = false
			l.set_meta("type", "h")
			l.set_meta("row", row)
			l.set_meta("col", col)
			add_child(l)
			h_sprites[row][col] = l
	
	for row in range(GRID_SIZE - 1):
		for col in range(GRID_SIZE):
			var l = Sprite2D.new()
			l.position = GRID_OFFSET + Vector2(col * DOT_SPACING, (row + 0.5) * DOT_SPACING)
			l.rotation_degrees = 90
			l.visible = false
			l.set_meta("type", "v")
			l.set_meta("row", row)
			l.set_meta("col", col)
			add_child(l)
			v_sprites[row][col] = l
	
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var d = Sprite2D.new()
			d.texture = DOT_BLACK
			d.position = GRID_OFFSET + Vector2(col * DOT_SPACING, row * DOT_SPACING)
			add_child(d)
			dots[row][col] = d


func _input(event):
	if ai_busy:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if ai_on and player == ai_side:
			return
		
		var pos = get_global_mouse_position()
		var line = null
		var dist = 40.0
		
		for row in range(GRID_SIZE):
			for col in range(GRID_SIZE - 1):
				if h_lines[row][col] == -1:
					var l = h_sprites[row][col]
					var d = pos.distance_to(l.global_position)
					if d < dist:
						dist = d
						line = l
		
		for row in range(GRID_SIZE - 1):
			for col in range(GRID_SIZE):
				if v_lines[row][col] == -1:
					var l = v_sprites[row][col]
					var d = pos.distance_to(l.global_position)
					if d < dist:
						dist = d
						line = l
		
		if line:
			take_line(line)


func take_line(line: Sprite2D):
	var type = line.get_meta("type")
	var row = line.get_meta("row")
	var col = line.get_meta("col")
	
	if type == "h":
		h_lines[row][col] = player
	else:
		v_lines[row][col] = player
	
	line.visible = true
	line.texture = LINE_BLUE if player == 0 else LINE_PINK
	
	var got = false
	if type == "h":
		if row > 0 and got_box(row - 1, col):
			got = true
		if row < GRID_SIZE - 1 and got_box(row, col):
			got = true
	else:
		if col > 0 and got_box(row, col - 1):
			got = true
		if col < GRID_SIZE - 1 and got_box(row, col):
			got = true
	
	var total = (GRID_SIZE - 1) * (GRID_SIZE - 1)
	if score[0] + score[1] >= total:
		return
	
	if not got:
		player = 1 - player
		update_turn()
		print("Player %d turn (Blue=%d, Pink=%d)" % [player + 1, score[0], score[1]])
		
		if ai_on and player == ai_side:
			call_deferred("ai_move")
	else:
		print("Player %d again! (Blue=%d, Pink=%d)" % [player + 1, score[0], score[1]])
		
		if ai_on and player == ai_side:
			call_deferred("ai_move")


func got_box(row: int, col: int) -> bool:
	if boxes[row][col] != -1:
		return false
	
	var top = h_lines[row][col] != -1
	var bot = h_lines[row + 1][col] != -1
	var left = v_lines[row][col] != -1
	var right = v_lines[row][col + 1] != -1
	
	if top and bot and left and right:
		boxes[row][col] = player
		score[player] += 1
		
		var b = box_sprites[row][col]
		b.visible = true
		b.texture = BOX_BLUE if player == 0 else BOX_PINK
		
		var corners = [
			[row, col], [row, col + 1],
			[row + 1, col], [row + 1, col + 1]
		]
		for c in corners:
			dots[c[0]][c[1]].texture = DOT_BLUE if player == 0 else DOT_PINK
		
		print("Player %d scored! (Blue=%d, Pink=%d)" % [player + 1, score[0], score[1]])
		
		var total = (GRID_SIZE - 1) * (GRID_SIZE - 1)
		if score[0] + score[1] >= total:
			end_game()
		
		return true
	
	return false


func end_game():
	if score[0] > score[1]:
		print("GAME OVER - BLUE WINS! (%d-%d)" % [score[0], score[1]])
	elif score[1] > score[0]:
		print("GAME OVER - PINK WINS! (%d-%d)" % [score[0], score[1]])
	else:
		print("GAME OVER - TIE! (%d-%d)" % [score[0], score[1]])


func _process(delta):
	if not waiting:
		return
	
	for i in range(3):
		if sent[i] and response[i] == null:
			timer[i] += delta
	
	if idx < 3:
		if timer[idx] >= TIMEOUTS[idx]:
			if response[idx] == null:
				print("AI %d timeout, next..." % (idx + 1))
				idx += 1
				
				if idx < 3:
					ask_ai(idx)
				else:
					print("All AIs timeout, random move")
					clear_ai()
					random_move()


func ai_move():
	if ai_busy:
		return
	
	ai_busy = true
	waiting = true
	idx = 0
	
	response = [null, null, null]
	timer = [0.0, 0.0, 0.0]
	sent = [false, false, false]
	
	print("AI thinking...")
	ask_ai(0)


func ask_ai(i: int):
	if i >= 3:
		return
	
	var req = get_node("HTTPRequest" + str(i + 1))
	var prompt = make_prompt()
	var model = MODELS[i]
	
	var data = {
		"model": model,
		"messages": [{"role": "user", "content": prompt}],
		"temperature": 0.7,
		"max_tokens": 100
	}
	
	var body = JSON.stringify(data)
	var headers = [
		"Authorization: Bearer " + KEYS[i],
		"Content-Type: application/json"
	]
	
	print("AI %d (%s) timeout: %.1fs" % [i + 1, model, TIMEOUTS[i]])
	
	var err = req.request(
		"https://ai.hackclub.com/proxy/v1/chat/completions",
		headers,
		HTTPClient.METHOD_POST,
		body
	)
	
	if err != OK:
		print("AI %d failed" % (i + 1))
		response[i] = "ERROR"
	else:
		sent[i] = true
		timer[i] = 0.0


func on_response(_result, code, _headers, body, i: int):
	if not waiting:
		return
	
	if code != 200:
		print("AI %d error %d" % [i + 1, code])
		response[i] = "ERROR"
		return
	
	var text = body.get_string_from_utf8()
	var json = JSON.new()
	var err = json.parse(text)
	
	if err != OK:
		print("AI %d parse error" % (i + 1))
		response[i] = "ERROR"
		return
	
	var resp = json.data
	if not resp.has("choices") or resp.choices.size() == 0:
		print("AI %d bad response" % (i + 1))
		response[i] = "ERROR"
		return
	
	var choice = resp.choices[0]
	var msg = ""
	
	if choice.message.has("content") and choice.message.content != null:
		msg = choice.message.content
	else:
		print("AI %d no content" % (i + 1))
		response[i] = "ERROR"
		return
	
	msg = msg.strip_edges()
	print("AI %d: %s" % [i + 1, msg])
	
	response[i] = msg
	
	if i == idx:
		parse_move(msg, i)


func parse_move(msg: String, i: int):
	var regex = RegEx.new()
	regex.compile("([HV])(\\d+),(\\d+)")
	var match = regex.search(msg)
	
	if match:
		var type = match.get_string(1)
		var row = int(match.get_string(2))
		var col = int(match.get_string(3))
		
		if type == "H" and row >= 0 and row < GRID_SIZE and col >= 0 and col < GRID_SIZE - 1:
			if h_lines[row][col] == -1:
				print("AI %d plays: H%d,%d (%.1fs)" % [i + 1, row, col, timer[i]])
				clear_ai()
				take_line(h_sprites[row][col])
				return
		elif type == "V" and row >= 0 and row < GRID_SIZE - 1 and col >= 0 and col < GRID_SIZE:
			if v_lines[row][col] == -1:
				print("AI %d plays: V%d,%d (%.1fs)" % [i + 1, row, col, timer[i]])
				clear_ai()
				take_line(v_sprites[row][col])
				return
	
	print("AI %d bad move" % (i + 1))
	
	idx += 1
	if idx < 3:
		if sent[idx] and response[idx] != null:
			parse_move(response[idx], idx)
		else:
			ask_ai(idx)
	else:
		clear_ai()
		random_move()


func clear_ai():
	ai_busy = false
	waiting = false
	response = [null, null, null]
	timer = [0.0, 0.0, 0.0]
	sent = [false, false, false]
	idx = 0


func make_prompt() -> String:
	var p = "DOTS AND BOXES - 6x6 Grid\n\n"
	
	var you = "Player2" if ai_side == 1 else "Player1"
	var opp = "Player1" if ai_side == 1 else "Player2"
	p += "YOU: %s, OPP: %s\n" % [you, opp]
	p += "Score: P1=%d, P2=%d\n\n" % [score[0], score[1]]
	
	p += "GRID: 6x6 dots (rows 0-5, cols 0-5)\n"
	p += "H-lines: horizontal (row,col)\n"
	p += "V-lines: vertical (row,col)\n\n"
	
	p += "CLAIMED:\n"
	var p1 = []
	var p2 = []
	
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE - 1):
			if h_lines[row][col] == 0:
				p1.append("H%d,%d" % [row, col])
			elif h_lines[row][col] == 1:
				p2.append("H%d,%d" % [row, col])
	
	for row in range(GRID_SIZE - 1):
		for col in range(GRID_SIZE):
			if v_lines[row][col] == 0:
				p1.append("V%d,%d" % [row, col])
			elif v_lines[row][col] == 1:
				p2.append("V%d,%d" % [row, col])
	
	p += "P1: %s\n" % (", ".join(p1) if p1.size() > 0 else "none")
	p += "P2: %s\n\n" % (", ".join(p2) if p2.size() > 0 else "none")
	
	p += "3-SIDED BOXES:\n"
	var crit = []
	for row in range(GRID_SIZE - 1):
		for col in range(GRID_SIZE - 1):
			if boxes[row][col] == -1:
				var sides = 0
				if h_lines[row][col] != -1: sides += 1
				if h_lines[row + 1][col] != -1: sides += 1
				if v_lines[row][col] != -1: sides += 1
				if v_lines[row][col + 1] != -1: sides += 1
				
				if sides == 3:
					var miss = ""
					if h_lines[row][col] == -1: miss = "H%d,%d" % [row, col]
					elif h_lines[row + 1][col] == -1: miss = "H%d,%d" % [row + 1, col]
					elif v_lines[row][col] == -1: miss = "V%d,%d" % [row, col]
					elif v_lines[row][col + 1] == -1: miss = "V%d,%d" % [row, col + 1]
					crit.append("Box(%d,%d)=%s" % [row, col, miss])
	
	if crit.size() > 0:
		p += ", ".join(crit) + "\n\n"
	else:
		p += "None\n\n"
	
	p += "AVAILABLE:\n"
	var avail = []
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE - 1):
			if h_lines[row][col] == -1:
				avail.append("H%d,%d" % [row, col])
	
	for row in range(GRID_SIZE - 1):
		for col in range(GRID_SIZE):
			if v_lines[row][col] == -1:
				avail.append("V%d,%d" % [row, col])
	
	p += ", ".join(avail) + "\n\n"
	
	p += "STRATEGY:\n"
	p += "1. Complete 3-sided boxes first\n"
	p += "2. Block opponent boxes\n"
	p += "3. Chain captures\n"
	p += "4. Avoid making 3-sided boxes\n"
	p += "5. Control endgame\n\n"
	
	p += "Reply with move: H<row>,<col> or V<row>,<col>\n"
	p += "Example: H2,3 or V1,4\n"
	p += "Your move:"
	
	return p


func random_move():
	print("Random move")
	var h_avail = []
	var v_avail = []
	
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE - 1):
			if h_lines[row][col] == -1:
				h_avail.append([row, col])
	
	for row in range(GRID_SIZE - 1):
		for col in range(GRID_SIZE):
			if v_lines[row][col] == -1:
				v_avail.append([row, col])
	
	var all = h_avail + v_avail
	if all.size() > 0:
		var m = all[randi() % all.size()]
		if m in h_avail:
			print("Fallback: H%d,%d" % [m[0], m[1]])
			take_line(h_sprites[m[0]][m[1]])
		else:
			print("Fallback: V%d,%d" % [m[0], m[1]])
			take_line(v_sprites[m[0]][m[1]])

'''

'''
