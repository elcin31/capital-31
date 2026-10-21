class_name CityCanvas
extends Node2D

var city_id: int = 0
var texture: Texture2D
var illustrated: bool=false
var buildings: Array = []
var font: Font = preload("res://assets/fonts/DejaVuSans-Bold.ttf")

func setup(id: int) -> void:
 city_id=id
 var asset="res://assets/"+PaintedCity.FILES[id]+".png"
 illustrated=ResourceLoader.exists(asset)
 if illustrated:
  texture=load(asset)
  buildings=PaintedCity.objects(id)
  queue_redraw()
  return
 buildings=[]
 var rng=RandomNumberGenerator.new()
 rng.seed=310031+id*13571
 for row in range(5):
  for col in range(5):
   var x=1+col*7
   var y=1+row*7
   var park=(row+col*2+id)%7==1
   var height=rng.randf_range(65,210)
   if city_id==2: height*=1.3
   if city_id==3: height*=0.7
   var own=col==2 and row==2
   if own: height=165
   var kind="office" if own else ("investor" if col==1 and row==3 else ("rival" if (col+row)%4==0 else ("property" if (col+row)%3==0 else "building")))
   buildings.append({"x":x,"y":y,"w":4.6 if own else rng.randf_range(3.4,5.0),"h":4.3 if own else rng.randf_range(3.0,5.0),"height":height,"park":park and not own,"glass":own or rng.randf()>0.38,"variant":rng.randi_range(0,5),"kind":kind,"name":"Штаб-квартира" if own else ("Vertex Capital" if kind=="investor" else ("Kaiser Analytics" if kind=="rival" else "Riverside · Офисы"))})
 buildings.sort_custom(func(a,b):return a.x+a.y<b.x+b.y)
 queue_redraw()

func _draw() -> void:
 if illustrated:
  PaintedCity.background(self,texture)
  return
 var sand=city_id==2
 Art.tile(self,-8,-8,Color("e8e5cf") if sand else Color("c2e5d1"),52,52)
 Art.box(self,-0.5,-0.5,36.5,36.5,12,Color("a3c8c8"),-12)
 for x in range(36):
  for y in range(36):
   var road=x%7==0 or y%7==0
   var water=(y>=27 and y<=28) and x%7!=0
   var color=Color("758fa3") if road else (Color("57c4dc") if water else (Color("e9e6d8") if sand else Color("d8e8db")))
   Art.tile(self,x,y,color)
   if road:
    if x%7==0 and y%7>0:
     draw_line(Art.iso(x+0.5,y+0.2),Art.iso(x+0.5,y+0.8),Color("e6edf0"),1.2,true)
    if y%7==0 and x%7>0:
     draw_line(Art.iso(x+0.2,y+0.5),Art.iso(x+0.8,y+0.5),Color("e6edf0"),1.2,true)
    if x%7==0 and y%7==1:
     for stripe in range(4): Art.tile(self,x+0.1+stripe*0.2,y,Color("d9eaf1"),0.08,0.7)
   if water and (x+y)%3==0: draw_line(Art.iso(x+0.1,y+0.3),Art.iso(x+0.8,y+0.3),Color("94e0e7"),2,true)
 for b in buildings:
  if b.park:
   Art.box(self,b.x,b.y,5,5,3,Color("9ed7aa"))
   Art.tile(self,b.x+2,b.y,Color("eee8cc"),0.5,5,3)
   Art.tile(self,b.x,b.y+2,Color("eee8cc"),5,0.5,3)
   Art.box(self,b.x+1.8,b.y+1.8,0.9,0.9,7,Color("80d4ed"),3)
   for xx in range(3):
    for yy in range(3):
     if xx!=1 or yy!=1: Art.tree(self,Art.iso(b.x+xx*1.7+0.6,b.y+yy*1.7+0.6),0.85,sand)
   continue
  building(b)
 for i in range(26):
  var x=float((i*11)%35)+0.4
  var y=float((i*7)%35)+0.9
  if x>0 and int(x)%7==0: Art.tree(self,Art.iso(x+0.7,y),0.65,sand)
 if city_id==0:
  var p=Art.iso(26,6)
  draw_line(p,p-Vector2(0,280),Color("b0c9d9"),6,true)
  draw_circle(p-Vector2(0,225),13,Color("c5e8f0"))
  draw_arc(p-Vector2(0,225),13,0,TAU,24,Color("6f9aaf"),2,true)
  draw_line(p-Vector2(0,280),p-Vector2(0,310),Color("ffaa32"),2,true)
 if city_id==1:
  var p=Art.iso(7,27)
  for i in [0,6]:
   var a=p+Art.iso(i,0)
   draw_line(a,a-Vector2(0,120),Color("e37651"),7,true)
   draw_line(a-Vector2(12,90),a+Vector2(12,-78),Color("e37651"),4,true)
  var start=p-Vector2(0,110)
  var end=p+Art.iso(6,0)-Vector2(0,110)
  draw_line(start,end,Color("e37651"),3,true)
  for i in range(1,6): draw_line(start.lerp(end,i/6.0),p+Art.iso(i,0),Color("e37651"),1,true)

func building(b: Dictionary) -> void:
 var x=float(b.x)
 var y=float(b.y)
 var w=float(b.w)
 var h=float(b.h)
 var z=float(b.height)
 var own=b.kind=="office"
 var p=Art.iso(x,y)
 Art.poly(self,[p+Art.iso(w,0),p+Art.iso(w,h)+Vector2(75,12),p+Art.iso(0,h)+Vector2(50,12),p+Art.iso(0,h)],Color(0.04,0.17,0.23,0.16))
 Art.box(self,x-0.3,y-0.3,w+0.6,h+0.6,4,Color("f5f3e7"))
 var color=Color("308bb5") if b.glass else [Color("ebc99f"),Color("ede3d3"),Color("c0cad8"),Color("d5a887"),Color("c3dfcf"),Color("d2c6e6")][int(b.variant)]
 if city_id==2 and not b.glass: color=Color("eddbb8")
 if city_id==3 and not b.glass: color=Color("efc4a4")
 if own: Art.box(self,x-0.13,y-0.13,w+0.26,h+0.26,8,Art.CYAN)
 Art.box(self,x,y,w,h,z,color)
 var rows=int(z/18)
 var cols=7 if b.glass else 5
 var pa=p+Art.iso(0,h)
 var pb=p+Art.iso(w,h)
 var pc=p+Art.iso(w,0)
 for row in range(rows):
  var vertical=9+row*18
  for side in range(2):
   var aa=pa if side==0 else pc
   var bb=pb
   for col in range(cols):
    var a=aa.lerp(bb,(col+0.12)/cols)-Vector2(0,vertical)
    var d=aa.lerp(bb,(col+0.88)/cols)-Vector2(0,vertical)
    var reflected=(row+col+int(b.variant))%7
    var glass=[Color("7cdef5"),Color("c1eff3"),Color("2184ac"),Color("3fa6c5"),Color("aae9ee"),Color("ffe2a4"),Color("7bc8de")][reflected]
    Art.poly(self,[a,d,d-Vector2(0,12),a-Vector2(0,12)],glass.darkened(0.12) if side else glass)
   if b.glass: draw_line(aa-Vector2(0,vertical+14),bb-Vector2(0,vertical+14),Color("306583"),1.4,true)
 for side in range(2):
  var aa=pa if side==0 else pc
  for col in range(cols+1):
   var a=aa.lerp(pb,float(col)/cols)
   draw_line(a,a-Vector2(0,z),Color("d5eced") if b.glass else Color("f7eddb"),1.8,true)
 Art.box(self,x-0.06,y-0.06,w+0.12,h+0.12,5,Color("eff5ee"),z)
 Art.tile(self,x+0.2,y+0.2,Color("b2d1d4"),w-0.4,h-0.4,z+5)
 if own or b.variant%2==0:
  Art.box(self,x+0.7,y+0.6,w*0.5,h*0.5,22,Color("75bacb"),z+5)
  Art.tile(self,x+0.8,y+0.7,Color("69ceaa"),w*0.5-0.2,h*0.5-0.2,z+28)
  for i in range(4): Art.tree(self,Art.iso(x+0.5+i*0.8,y+h-0.4)-Vector2(0,z+5),0.42,city_id==2)
 else:
  for i in range(2): Art.box(self,x+0.5+i*1.2,y+0.6,0.8,0.8,12,Color("a5b7c2"),z+5)
 if city_id==2:
  draw_line(p+Art.iso(w/2,h/2)-Vector2(0,z),p+Art.iso(w/2,h/2)-Vector2(0,z+55),Color("daeff3"),3,true)
 if city_id==4 and b.variant==1:
  Art.box(self,x+w*0.35,y+h*0.35,w*0.3,h*0.3,45,Color("f1ddba"),z+5)
  var sp=Art.iso(x+w*0.5,y+h*0.5)-Vector2(0,z+50)
  draw_line(sp,sp-Vector2(0,45),Color("e9c474"),3,true)
 if own:
  var label_pos=p+Art.iso(0.2,h)-Vector2(0,z*0.45)
  draw_string(font,label_pos,"CAPITAL",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
 Art.box(self,x+w*0.45,y+h,0.9,0.14,25,Color("6fd1e0"))
 for i in range(3): Art.tree(self,Art.iso(x+0.5+i*1.5,y+h+0.4),0.6,city_id==2)
