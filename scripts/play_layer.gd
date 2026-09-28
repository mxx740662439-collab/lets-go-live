extends Control
var game
const MINI = preload("res://assets/sprites/player_reference.png")
const FONT = preload("res://assets/fonts/pixel.ttf")
func pt(x,y):return Vector2(round((x-22)*619/440),round(53+(y-108)*68/47))
func _draw():
	var g=game
	for b in g.bullets:
		var p=pt(b.x,b.y)-Vector2(0,12)
		var col=Color("00ff69") if b.positive else Color("ff1768")
		draw_string(g.CHAT_FONT,p+Vector2(0,17),b.word,0,-1,14,col)

	var pos=pt(104,g.player_y)-Vector2(16,16)
	pos.y+=round(sin(g.anim_time*4)*2)
	if g.state=="victory":pos.y-=absf(sin(g.result_time*4))*18
	if g.state=="defeat":pos.y=minf(266,pos.y+g.result_time*100)
	if g.hurt_timer<=0 or int(g.hurt_timer*20)%2==0:
		draw_texture_rect(MINI,Rect2(pos+Vector2(0,2),Vector2(32,28.17)),false)
	for pop in g.pops:
		draw_string(FONT,pt(pop.x,pop.y),pop.text,0,-1,10,g.MINT if pop.good else g.RED)
	if g.phase_flash>0 and g.state=="playing" and not g.practice:
		draw_rect(Rect2(170,8,385,22),Color("24113f"))
		draw_string(FONT,Vector2(183,23),g.PHASES[g.phase]+" INCOMING",0,-1,10,g.GOLD)
