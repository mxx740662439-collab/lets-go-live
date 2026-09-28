extends Control
var game
const FONT=preload("res://assets/fonts/pixel.ttf")
const WIN=preload("res://assets/sprites/victory_result.png")
const LOSE=preload("res://assets/sprites/defeat_result.png")
const MINI=preload("res://assets/sprites/player_reference.png")
const DIALOGUE=preload("res://assets/sprites/dialogue_reference.png")
const PINK=Color("ff43c8")
const CYAN=Color("32eaff")
const DARK=Color("160923")
func text(x,y,value,col=Color.WHITE,size=12):
	draw_string(FONT,Vector2(x,y),value,0,-1,size,col)
func box(x,y,w,h,col):draw_rect(Rect2(x,y,w,h),col)
func bevel(x,y,w,h,col,cut=10):
	draw_colored_polygon(PackedVector2Array([Vector2(x+cut,y),Vector2(x+w-cut,y),Vector2(x+w,y+cut),Vector2(x+w,y+h-cut),Vector2(x+w-cut,y+h),Vector2(x+cut,y+h),Vector2(x,y+h-cut),Vector2(x,y+cut)]),col)
func frame_index():
	if game.state=="victory":
		var seq=[0,1,2,2,3,4,4,4,4,4,3,0]
		return seq[int(maxf(0,game.result_time-1.1)*5)%seq.size()]
	if game.state=="defeat":return mini(4,int(maxf(0,game.result_time-1.1)*3.5))
	return int(game.anim_time*8)%4
func _draw():
	var g=game
	if g.state=="tutorial":
		draw_tutorial()
		return
	if g.state=="intro":
		draw_intro()
		return
	if g.state=="playing" and not g.paused:return
	if g.state in ["victory","defeat"] and g.result_time<1.1:return
	var won=g.state=="victory"
	var lost=g.state=="defeat"
	var accent=g.GOLD if won else (g.RED if lost else CYAN)
	draw_rect(Rect2(0,0,960,540),Color(0.025,0.01,0.06,0.82))
	# Same cut corners and nested neon rails as the main monitor.
	bevel(141,88,678,380,Color("27036b"),17)
	bevel(145,92,670,372,PINK,15)
	bevel(148,95,664,366,Color("fff8ff"),13)
	bevel(150,97,660,362,CYAN,12)
	bevel(153,100,654,356,DARK,10)
	box(169,139,621,2,PINK)
	text(173,124,"Let's go live!",CYAN,12)
	text(568,124,"STREAM "+("REPORT" if won or lost else "CONTROL"),g.LILAC,10)
	for i in range(13):
		box(178+i*8,451,5,3,PINK if i%2 else CYAN)
		box(676+i*8,99,5,3,CYAN if i%2 else PINK)
	# Character stage stays inside the window and uses real reference frames.
	bevel(173,159,227,244,Color("29133f"),9)
	bevel(175,161,223,240,Color("0c081c"),8)
	box(190,353,193,2,accent)
	for i in range(12):box(191+i*16,357,8,2,Color("473160"))
	text(192,182,"SAYO / "+("ENCORE" if won else "OFFLINE" if lost else "READY"),accent,8)
	if won or lost:
		draw_texture_rect_region(WIN if won else LOSE,Rect2(220,181,128,180),Rect2(frame_index()*128,0,128,180))
	else:
		draw_texture_rect(MINI,Rect2(238,230+round(sin(g.anim_time*4)*3),96,84.52),false)
	text(197,383,"THANK YOU, CHAT!" if won else "TAKE A BREATHER" if lost else "YOUR ORBIT AWAITS",g.LILAC,10)
	var title="Let's go live!"
	var subtitle="WORDS CAN WARM HEARTS"
	var button="START GAME"
	if won:title="A GREAT STREAM!";subtitle="100 VIEWERS. YOU DID IT.";button="PLAY AGAIN"
	elif lost:title="I'LL DELETE MY ACCOUNT...";subtitle=g.end_reason;button="TRY AGAIN"
	elif g.paused:title="BE RIGHT BACK";subtitle="STREAM PAUSED. BREATHE.";button="RESUME STREAM"
	text(426,205,title,g.WHITE,14 if lost else 22)
	text(428,230,subtitle,accent,10)
	if g.state=="title": text(428,246,"OR CUT THEM DEEP.",accent,10)
	if won or lost:
		bevel(426,251,356,95,Color("2b1645"),6)
		text(441,272,"FINAL SCORE",g.LILAC,8);text(441,300,"%06d" % g.score,g.GOLD,20)
		text(632,272,"VIEWERS",g.LILAC,8);text(632,300,"%03d" % int(g.viewers),accent,20)
		text(441,332,"TIME %02d:%02d    KINDNESS x%d" % [int(g.elapsed)/60,int(g.elapsed)%60,g.chain],g.LILAC,8)
	else:
		text(429,294,"UP/DOWN OR W/S: MOVE",g.WHITE,10)
		text(429,321,"SAYO WILL SHOW YOU HOW TO PLAY.",g.LILAC,8)
	text(429,365,"BE KIND TO YOURSELF. GO AGAIN." if lost else "THE CHAT IS CHEERING FOR YOU." if won else "KEEP FLYING. KEEP STREAMING.",g.LILAC,9)
	var hover=Rect2(426,378,356,44).has_point(get_global_mouse_position())
	bevel(426,378,356,44,accent,7)
	bevel(428,380,352,40,Color("492264") if hover else Color("321446"),6)
	text(445,405,">",accent,14)
	var width=FONT.get_string_size(button,0,-1,14).x
	text(610-width/2,405,button,g.WHITE,14)
	text(426,443,"ESC: RESUME" if g.paused else "ENTER / CLICK TO CONTINUE",CYAN,8)
	text(175,434,"M: SOUND",g.LILAC,8)
	if g.state=="title":text(175,445,"T: SOUNDCHECK",g.LILAC,8)

func draw_intro():
	var g=game
	box(0,0,960,540,Color("10091e"))
	draw_texture_rect(DIALOGUE,Rect2(60,12,840,476),false)
	text(160,279,"SAYO",Color("4f00ff"),12)
	var line=g.INTRO_LINES[g.intro_line].substr(0,int(g.intro_chars))
	var lines=line.split("\n")
	for i in range(lines.size()):
		text(135,338+i*28,lines[i],Color("4f00ff"),14)
	text(135,429,"ENTER / CLICK TO CONTINUE",Color("4f00ff"),10)
	text(738,429,"%d / %d" % [g.intro_line+1,g.INTRO_LINES.size()],Color("4f00ff"),10)

func tutorial_target():
	return Rect2(133,104,509,26) if game.tutorial_step==0 else Rect2(747,383,179,20)

func tutorial_rect():
	# Select a safe position in viewport coordinates instead of covering a HUD target.
	var candidates=[Rect2(205,200,470,238),Rect2(205,150,470,238),Rect2(65,150,470,238),Rect2(225,195,470,238)]
	if game.tutorial_step>0:
		candidates=[candidates[1],candidates[0],candidates[3],candidates[2]]
	var player=game.play_layer.position+game.play_layer.pt(104,game.player_y)
	var protected=[tutorial_target().grow(12),Rect2(715,140,215,202),Rect2(player-Vector2(24,24),Vector2(48,48)),Rect2(130,101,515,32),Rect2(715,347,219,99)]
	var best:Rect2=candidates[0]
	var least=INF
	for candidate in candidates:
		var penalty=0.0
		for obstacle in protected:
			if candidate.intersects(obstacle):
				var overlap=candidate.intersection(obstacle)
				penalty+=overlap.size.x*overlap.size.y
		if penalty<least:
			least=penalty
			best=candidate
	return best

func draw_tutorial():
	var g=game
	var r=tutorial_rect()
	var target=tutorial_target()
	var accent=g.MINT if g.tutorial_step==0 else PINK
	# Draw a spotlight border without obscuring the bar or the heart icons.
	draw_rect(target.grow(5),accent,false,2)
	var tip=Vector2(target.get_center().x,target.end.y+8) if g.tutorial_step==0 else Vector2(target.position.x-8,target.get_center().y)
	var start=Vector2(r.get_center().x,r.position.y-4) if g.tutorial_step==0 else Vector2(r.end.x+4,r.end.y-20)
	var elbow=Vector2(start.x,tip.y)
	draw_line(start,elbow,accent,3)
	draw_line(elbow,tip,accent,3)
	if g.tutorial_step==0:
		draw_colored_polygon(PackedVector2Array([tip,tip+Vector2(-7,10),tip+Vector2(7,10)]),accent)
	else:
		draw_colored_polygon(PackedVector2Array([tip,tip+Vector2(-10,-7),tip+Vector2(-10,7)]),accent)
	bevel(r.position.x+5,r.position.y+5,r.size.x,r.size.y,Color("080419"),8)
	bevel(r.position.x,r.position.y,r.size.x,r.size.y,accent,8)
	bevel(r.position.x+2,r.position.y+2,r.size.x-4,r.size.y-4,DARK,7)
	var x=r.position.x
	var y=r.position.y
	draw_texture_rect_region(g.PORTRAITS.normal,Rect2(x+16,y+13,62,52),Rect2(0,0,600,504))
	text(x+91,y+31,"SAYO",PINK,12)
	text(x+91,y+52,"BEFORE WE GO LIVE",g.LILAC,8)
	text(x+405,y+31,"%d/3" % (g.tutorial_step+1),accent,10)
	box(x+16,y+71,r.size.x-32,1,accent)
	var lines=[]
	var line=""
	for word in g.TUTORIAL_LINES[g.tutorial_step].split(" "):
		var trial=word if line.is_empty() else line+" "+word
		if FONT.get_string_size(trial,0,-1,10).x>r.size.x-36 and not line.is_empty():
			lines.append(line)
			line=word
		else:line=trial
	if not line.is_empty():lines.append(line)
	for i in range(lines.size()):text(x+18,y+95+i*18,lines[i],g.WHITE,10)
	box(x+16,y+r.size.y-39,r.size.x-32,1,Color("50306d"))
	text(x+18,y+r.size.y-17,"ENTER / CLICK: "+("LET'S BEGIN!" if g.tutorial_step==2 else "NEXT"),accent,9)
