extends Node2D

const POS = ["配信やめろww", "ば・く・れ・つ", "kksk", "88888", "覇権", "沼", "やばい！", "いけ！", "てぇてぇ"]
const NEG = ["下手", "きつい", "ブス", "不細工", "チビ", "キモいw", "引退しろ"]
var CHAT_FONT = preload("res://assets/fonts/chat_cjk.otf")
const INTRO_LINES = ["It's time to go live again!", "I'm so excited!"]
const TUTORIAL_LINES = ["For a healthy livestream, we need to interact with the green bullets! Collect 100 green bullets and today's stream will end successfully!", "Avoid the red bullets! These will severely damage my mental state.", "If mental energy reaches zero, the stream ends. Five green bullets are needed to offset the damage from one red bullet. So, let's make this stream a success!"]
var tutorial_step = 0

const MAX_MENTAL_ENERGY = 7
const GREENS_PER_HEART = 5
const LANES = [108.0, 155.0, 202.0, 249.0]
const PHASES = ["CASUAL VIEWERS", "TROLLS", "HATE RAID"]
const MOODS = ["NORMAL", "SMILE", "HAPPY", "SWEAT", "NERVOUS", "PANIC"]
const INK = Color("17152c")
const MINT = Color("67f0d3")
const RED = Color("ff779c")
const GOLD = Color("ffcf70")
const WHITE = Color("f6eeff")
const LILAC = Color("b39aff")
const PORTRAITS = {"normal":preload("res://assets/sprites/portrait_zoom/idle.png")}
const HAPPY_FRAMES = [preload("res://assets/sprites/portrait_zoom/happy_0.png"), preload("res://assets/sprites/portrait_zoom/happy_1.png"), preload("res://assets/sprites/portrait_zoom/happy_2.png"), preload("res://assets/sprites/portrait_zoom/happy_3.png"), preload("res://assets/sprites/portrait_zoom/happy_4.png")]
const SAD_FRAMES = [preload("res://assets/sprites/portrait_zoom/sad_0.png"), preload("res://assets/sprites/portrait_zoom/sad_1.png"), preload("res://assets/sprites/portrait_zoom/sad_2.png"), preload("res://assets/sprites/portrait_zoom/sad_3.png"), preload("res://assets/sprites/portrait_zoom/sad_4.png")]
const REACTIONS = {"heal":HAPPY_FRAMES, "damage":SAD_FRAMES, "panic":SAD_FRAMES}
const ATLAS = preload("res://assets/sprites/prototype_atlas.png")
const FONT = preload("res://assets/fonts/pixel.ttf")
const SFX = {"voice":preload("res://audio/voice_blip.wav"),"ding":preload("res://audio/ding.wav"), "hurt":preload("res://audio/hurt.wav"), "boss":preload("res://audio/boss.wav"), "victory":preload("res://audio/victory.wav"), "defeat":preload("res://audio/defeat.wav")}
const MUSIC = preload("res://audio/music.wav")
var rng = RandomNumberGenerator.new()
var state = "title"
var intro_line = 0
var intro_chars = 0.0
var intro_practice = false
var paused = false
var muted = false
var practice = false
var mental_energy = MAX_MENTAL_ENERGY
var recovery_progress = 0
var viewers = 0
var score = 0
var chain = 0
var mood = 0
var expression = 0
var portrait_kind = "normal"
var portrait_timer = 0.0
var damage_chain = 0
var reaction_age = 0.0
var phase = 0
var track = 2
var player_y = 202.0
var previous_y = 202.0
var switch_timer = 0.0
var switch_direction = 0
var dodge_anim = 0.0
var play_layer: Control
var overlay_layer: Control
var elapsed = 0.0
var anim_time = 0.0
var spawn_timer = 0.0
var mood_timer = 0.0
var hurt_timer = 0.0
var phase_flash = 0.0
var result_time = 0.0
var bullet_id = 0
var events: Array = []
var bullets: Array = []
var pops: Array = []
var stars: Array = []
var end_reason = ""
var soundcheck_index = 0
var sfx_count = {"voice":0,"ding":0,"hurt":0,"boss":0,"victory":0,"defeat":0}
var telemetry_timer = 0.0
var music_player: AudioStreamPlayer
var sound_players: Array[AudioStreamPlayer] = []

func _ready():
	CHAT_FONT.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	play_layer = Control.new()
	play_layer.set_script(preload("res://scripts/play_layer.gd"))
	play_layer.game = self
	play_layer.position = Vector2(56,140)
	play_layer.size = Vector2(619,303)
	play_layer.clip_contents = true
	play_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(play_layer)
	overlay_layer = Control.new()
	overlay_layer.set_script(preload("res://scripts/overlay.gd"))
	overlay_layer.game = self
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay_layer)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.seed = 672901
	for i in range(90):
		stars.append(Vector3(rng.randf_range(22, 462), rng.randf_range(82, 289), rng.randf_range(0.4, 1.4)))
	music_player = AudioStreamPlayer.new()
	music_player.stream = MUSIC
	music_player.volume_db = -9
	add_child(music_player)
	music_player.play() # Pixel Daydream, 200 BPM; embedded native looping soundtrack.
	for i in range(6):
		var p = AudioStreamPlayer.new()
		p.volume_db = -4
		add_child(p)
		sound_players.append(p)
	publish_state()

func sound(cue):
	sfx_count[cue] += 1
	for p in sound_players:
		if not p.playing:
			p.stream = SFX[cue]
			p.play()
			return

func record(kind, extra = {}):
	var e = {"kind":kind, "time":snapped(elapsed,0.01), "viewers":viewers, "mental_energy":mental_energy,"max_mental_energy":MAX_MENTAL_ENERGY,"recovery_progress":recovery_progress, "score":score, "track":track}
	e.merge(extra)
	events.append(e)
	if events.size()>80: events.pop_front()

func start_game(short_test=false):
	practice = short_test
	state = "playing"
	paused = false
	mental_energy = MAX_MENTAL_ENERGY
	recovery_progress = 0
	viewers = 0
	score = 0
	chain = 0
	damage_chain = 0
	reaction_age = 0
	mood = 0
	expression = 0
	portrait_kind = "normal"
	portrait_timer = 0
	phase = 0
	track = 2
	player_y = LANES[track]
	previous_y = player_y
	switch_timer = 0
	elapsed = 0
	spawn_timer = 0.4
	mood_timer = 0
	hurt_timer = 0
	phase_flash = 2.0
	result_time = 0
	end_reason = ""
	bullet_id = 0
	soundcheck_index = 0
	bullets.clear()
	pops.clear()
	events.clear()
	rng.seed = 672901
	music_player.volume_db = -9
	if not music_player.playing: music_player.play()
	record("start", {"mode":"soundcheck" if practice else "live"})
	publish_state()

func begin_intro(short_test=false):
	state="intro"
	intro_line=0
	intro_chars=0
	intro_practice=short_test
	paused=false
	music_player.volume_db = -13
	if not music_player.playing: music_player.play()
	publish_state()

func advance_intro():
	if intro_chars < INTRO_LINES[intro_line].length():
		intro_chars=INTRO_LINES[intro_line].length()
	elif intro_line < INTRO_LINES.size()-1:
		intro_line+=1
		intro_chars=0
	else:
		begin_tutorial()

func begin_tutorial():
	start_game(intro_practice)
	state="tutorial"
	tutorial_step=0
	music_player.volume_db = -13
	if not music_player.playing: music_player.play()
	publish_state()

func advance_tutorial():
	if tutorial_step<2:
		tutorial_step+=1
		sound("voice")
	else:
		start_game(intro_practice)
	publish_state()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var k = event.physical_keycode
		if k == KEY_M:
			muted = not muted
			AudioServer.set_bus_mute(0, muted)
		elif k == KEY_ESCAPE and state == "playing":
			paused = not paused
			music_player.stream_paused = paused
			record("pause" if paused else "resume")
		elif k == KEY_ENTER and state != "playing":
			if state=="intro": advance_intro()
			elif state=="tutorial": advance_tutorial()
			else: begin_intro(false)
		elif k == KEY_T and state == "title":
			begin_intro(true)
		elif state == "playing" and not paused:
			if k == KEY_UP or k == KEY_W: move_track(-1)
			if k == KEY_DOWN or k == KEY_S: move_track(1)
		publish_state()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p = get_global_mouse_position()
		if state=="tutorial":
			advance_tutorial()
		elif state=="intro":
			advance_intro()
		elif Rect2(426,378,356,44).has_point(p):
			if state != "playing": begin_intro(false)
			elif paused:
				paused = false
				music_player.stream_paused = false
				record("resume")

func move_track(direction):
	var next_track = clampi(track + direction, 0, 3)
	if next_track == track: return
	previous_y = player_y
	track = next_track
	switch_direction = direction
	switch_timer = 0.12
	dodge_anim = 0.4
	record("switch")

func add_bullet(lane, positive, pattern="straight", speed_override=0.0, start_x=466.0):
	bullet_id += 1
	var words = POS if positive else NEG
	var word = words[rng.randi_range(0, words.size()-1)]
	var base_speed = [108.0,158.0,216.0][phase] * (1.0 + minf(0.35, elapsed*0.0015))
	var destination = clampi(lane + (1 if lane < 2 else -1), 0, 3)
	bullets.append({"id":bullet_id,"x":start_x,"y":LANES[lane],"base_y":LANES[lane],"lane":lane,"to":destination,"positive":positive,"word":word,"w":maxf(10,CHAT_FONT.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x*440.0/619.0),"age":0.0,"pattern":pattern,"speed":speed_override if speed_override>0 else base_speed,"dead":false})

func spawn_wave():
	if practice:
		# Short soundcheck fixture: same 100-viewer goal, green stream on track 2.
		add_bullet(1,true,"straight",200.0,400.0)
		soundcheck_index += 1
		return
	var lane = rng.randi_range(0,3)
	var ratio = [0.65,0.45,0.30][phase]
	var good = rng.randf() < ratio
	var pattern = "straight"
	if phase==1 and bullet_id%2==0: pattern="wave"
	if phase==2: pattern="cross" if bullet_id%2==0 else "zigzag"
	# Only one crossing stream spawns per interval; overlapping hazards need playtesting.
	add_bullet(lane,good,pattern)

func finish(won):
	state = "victory" if won else "defeat"
	end_reason = "100 VIEWERS" if won else "MENTAL ENERGY DEPLETED"
	result_time = 0
	expression = 2 if won else 5
	if won: portrait_kind = "heal"
	reaction_age = 0
	music_player.stop()
	sound("victory" if won else "defeat")
	record(state)

func _process(delta):
	anim_time += delta
	if state=="intro":
		var previous_chars = int(intro_chars)
		intro_chars=minf(INTRO_LINES[intro_line].length(),intro_chars+delta*24)
		if int(intro_chars)>previous_chars:
			var character = INTRO_LINES[intro_line][int(intro_chars)-1]
			if not character in [" ","\n","!",",",".","?","'","！","，","。","？"]: sound("voice")
	if not paused: reaction_age += delta
	if not paused:
		dodge_anim = maxf(0,dodge_anim-delta)
		for p in pops: p.ttl-=delta; p.y-=delta*13
		pops = pops.filter(func(p):return p.ttl>0)
		if state=="playing":
			elapsed += delta
			portrait_timer = maxf(0,portrait_timer-delta)
			if portrait_timer==0: portrait_kind="normal"
			hurt_timer = maxf(0,hurt_timer-delta)
			phase_flash = maxf(0,phase_flash-delta)
			mood_timer += delta
			if mood_timer>=3:
				mood_timer=0
				mood -= signi(mood)
			if switch_timer>0:
				switch_timer = maxf(0,switch_timer-delta)
				player_y = lerpf(previous_y, LANES[track], 1.0-pow(switch_timer/0.12,2))
			else: player_y=LANES[track]
			var next_phase = int(elapsed/20.0)%3
			if not practice and next_phase != phase:
				phase=next_phase
				phase_flash=2.2
				spawn_timer=maxf(spawn_timer,0.8)
				sound("boss")
				record("phase",{"phase":PHASES[phase]})
			spawn_timer-=delta
			if spawn_timer<=0:
				spawn_wave()
				spawn_timer = 0.15 if practice else [0.7,0.5,0.38][phase]/(1.0+minf(0.3,elapsed*0.001))
			for b in bullets:
				b.age+=delta
				b.x-=b.speed*delta
				match b.pattern:
					"wave": b.y=b.base_y+sin(b.age*TAU/2.4)*18.0
					"cross": b.y=lerpf(b.base_y,LANES[b.to],clampf((466-b.x)/280.0,0,1))
					"zigzag":
						var zig = absf(fmod(b.age*0.55,2.0)-1.0)
						b.y=lerpf(b.base_y,LANES[b.to],1.0-zig)
				if b.x < 108 and b.x+b.w > 100 and absf(b.y-player_y)<11 and state=="playing":
					if b.positive:
						viewers=mini(100,viewers+1)
						recovery_progress+=1
						var recovered = false
						if recovery_progress>=GREENS_PER_HEART:
							recovery_progress=0
							recovered=mental_energy<MAX_MENTAL_ENERGY
							mental_energy=mini(MAX_MENTAL_ENERGY,mental_energy+1)
						damage_chain=0
						reaction_age=0
						chain+=1
						score+=100+mini(chain-1,6)*25
						mood=mini(4,mood+1)
						portrait_kind="heal"
						portrait_timer=2.0
						sound("ding")
						pops.append({"x":94.0,"y":player_y-20,"text":"+1 VIEWER / +1 HEART" if recovered else "+1 VIEWER","ttl":0.8,"good":true})
						record("positive",{"word":b.word})
					else:
						mental_energy=maxi(0,mental_energy-1)
						chain=0
						mood=maxi(-4,mood-2)
						hurt_timer=0.65
						damage_chain+=1
						reaction_age=0
						portrait_kind="panic" if damage_chain>=2 else "damage"
						portrait_timer=2.0
						sound("hurt")
						pops.append({"x":94.0,"y":player_y-20,"text":"-1 HEART","ttl":0.8,"good":false})
						record("negative",{"word":b.word})
					b.dead=true
					if viewers>=100: finish(true)
					elif mental_energy<=0: finish(false)
			bullets=bullets.filter(func(b):return not b.dead and b.x+b.w>22)
			if state=="playing":
				expression=0
				if mood>0: expression=2 if mood>=3 else 1
				if mood<0: expression=5 if mood<=-4 else (4 if mood<=-2 else 3)
				if mental_energy<=4: expression=maxi(expression,3)
				if mental_energy<=2: expression=maxi(expression,4)
				if mental_energy<=1: expression=5
		elif state in ["victory","defeat"]:
			result_time+=delta
	telemetry_timer+=delta
	if telemetry_timer>=0.15:
		telemetry_timer=0
		publish_state()
	queue_redraw()
	play_layer.queue_redraw()
	overlay_layer.queue_redraw()

func publish_state():
	if OS.has_feature("web"):
		var upcoming=[]
		for b in bullets:
			upcoming.append({"id":b.id,"x":snapped(b.x,0.1),"y":snapped(b.y,0.1),"positive":b.positive,"word":b.word,"pattern":b.pattern})
		var data={"tutorial_step":tutorial_step,"tutorial_box":str(overlay_layer.tutorial_rect()),"intro_line":intro_line,"intro_chars":int(intro_chars),"portrait":portrait_kind,"damage_chain":damage_chain,"reaction_frame":mini(4,int(reaction_age*8)),"result_frame":overlay_layer.frame_index(),"sprite_row": (1 if switch_direction<0 else 2) if dodge_anim>0 else 0,"sprite_frame": mini(3,int((0.4-dodge_anim)*10)) if dodge_anim>0 else int(anim_time*8)%4,"state":state,"paused":paused,"muted":muted,"mode":"soundcheck" if practice else "live","mental_energy":mental_energy,"max_mental_energy":MAX_MENTAL_ENERGY,"recovery_progress":recovery_progress,"viewers":viewers,"score":score,"chain":chain,"track":track,"player_x":104,"player_y":snapped(player_y,0.1),"elapsed":snapped(elapsed,0.01),"phase":PHASES[phase],"expression":MOODS[expression],"bullets":upcoming,"events":events,"sfx":sfx_count,"music_title":"Pixel Daydream","music_bpm":200,"music_length":MUSIC.get_length(),"music_position":music_player.get_playback_position(),"music_loop":MUSIC.loop_mode,"music_paused":music_player.stream_paused,"music_playing":music_player.playing,"end_reason":end_reason}
		JavaScriptBridge.eval("window.chatOrbit = "+JSON.stringify(data)+";", true)

func rect(x,y,w,h,color): draw_rect(Rect2(round(x),round(y),w,h),color)
func outline(x,y,w,h,color): draw_rect(Rect2(x,y,w,h),color,false,1.0)
func text(x,y,value,color=WHITE,size=8): draw_string(FONT,Vector2(round(x),round(y)),str(value),HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func centered(y,value,color=WHITE,size=8,left=0,right=640):
	var width=FONT.get_string_size(str(value),HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	text((left+right-width)/2,y,value,color,size)
func sprite(source:Rect2,dest:Rect2,modulate_color=Color.WHITE):draw_texture_rect_region(ATLAS,dest,source,modulate_color)

func _draw():
	draw_texture_rect(preload("res://assets/sprites/neon_frame.png"),Rect2(0,0,960,540),false)
	text(80,52,"Let's go live!",WHITE,18)
	text(365,40,"SAYO'S NIGHT SHIFT",LILAC,12)
	text(365,60,"CATCH KINDNESS. DODGE HATE.",MINT,8)
	rect(717,25,184,32,Color("321044"));outline(717,25,184,32,RED)
	rect(729,37,6,6,RED if int(anim_time*2)%2==0 else LILAC)
	text(745,47,"LIVE %05d" % int(viewers),WHITE,12)
	text(36,124,"VIEWERS",MINT,12)
	rect(137,108,377,19,Color("24113f"));outline(137,108,377,19,LILAC)
	rect(140,111,int(371*viewers/100),13,MINT)
	for x in range(148,510,12):
		if x<140+371*viewers/100:rect(x,111,2,13,Color("207c92"))
	text(533,124,"%03d" % int(viewers),WHITE,12)
	text(598,123,"/100",LILAC,8)
	text(733,124,"SAYO / CAM 01",WHITE,12)
	draw_rect(Rect2(723,146,200,168),Color("160c29"))
	for cx in [726,920]:
		for cy in [149,311]:
			draw_line(Vector2(cx,cy),Vector2(cx+(13 if cx==726 else -13),cy),WHITE,2)
			draw_line(Vector2(cx,cy),Vector2(cx,cy+(13 if cy==149 else -13)),WHITE,2)
	var portrait: Texture2D = REACTIONS[portrait_kind][mini(4,int(reaction_age*8))] if REACTIONS.has(portrait_kind) else PORTRAITS[portrait_kind]
	draw_texture_rect_region(portrait,Rect2(723,146,200,168),Rect2(0,0,600,504))
	text(737,334,"LIVE SIGNAL  ||||",MINT,8)
	text(735,364,"MENTAL ENERGY",MINT,8)
	text(881,364,"%d/%d" % [mental_energy,MAX_MENTAL_ENERGY],LILAC,8)
	rect(752,386,165,21,Color("09051c"))
	var heart=["01100110","11111111","11111111","01111110","00111100","00011000"]
	for n in range(MAX_MENTAL_ENERGY):
		for y in range(6):
			for x in range(8):
				if heart[y][x]=="1":rect(756+n*23+x*2,390+y*2,2,2,RED if n<mental_energy else Color("38224f"))
	text(752,419,"RECOVERY %d/%d" % [recovery_progress,GREENS_PER_HEART],GOLD,8)
	text(735,438,"KINDNESS x%d" % chain,GOLD,12)
	text(34,496,"SCORE",LILAC,8);text(99,496,"%06d" % score,GOLD,18)
	text(278,489,"SOUNDCHECK" if practice else PHASES[phase],MINT if phase==0 else RED,8)
	text(278,503,"KEEP FLYING",LILAC,8)
	text(433,490,"UP/DOWN: DODGE",WHITE,8)
	text(433,503,"ESC: PAUSE  M: SOUND",LILAC,8)
	text(752,489,"%02d:%02d" % [int(elapsed)/60,int(elapsed)%60],WHITE,12)
	text(752,503,"MUTED" if muted else "ON AIR / MUSIC",LILAC,8)
