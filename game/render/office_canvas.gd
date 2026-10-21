class_name OfficeCanvas
extends Node2D

var data: Dictionary={}
var floor_id: int=0
var font: Font=preload("res://assets/fonts/DejaVuSans-Bold.ttf")

func setup(c: Dictionary, level: int) -> void:
 data=c
 floor_id=level
 queue_redraw()

func _draw() -> void:
 if data.is_empty(): return
 Art.poly(self,[Art.iso(0,0)+Vector2(30,30),Art.iso(16,0)+Vector2(50,30),Art.iso(16,12)+Vector2(50,35),Art.iso(0,12)+Vector2(20,30)],Color(0.05,0.18,0.27,0.1))
 Art.box(self,0,0,16,12,13,Color("b4c8d4"),-13)
 for x in range(16):
  for y in range(12):
   var r=OfficeSim.room_at(data,x,y,floor_id)
   var color=Color("e4edf1") if r.is_empty() else Color(Catalog.ROOM_DEFS[int(r.type)].color)
   if not r.is_empty() and r.get("cover",0)==1: color=Color("e0bf94")
   if not r.is_empty() and r.get("cover",0)==2: color=Color("d9dff4")
   Art.tile(self,x+0.015,y+0.015,color.lightened(0.02 if (x+y)%2==0 else 0),0.97,0.97)
 Art.box(self,0,0,16,0.12,63,Color("e8f3fc"))
 Art.box(self,0,0,0.12,12,63,Color("e8f3fc"))
 for x in range(1,16):
  Art.box(self,x,0,0.8,0.14,43,Color("76cee9"),12)
 for y in range(1,12): Art.box(self,0,y,0.14,0.8,43,Color("6bc4e5"),12)
 for r in data.office.rooms:
  if int(r.floor)!=floor_id: continue
  var x=float(r.x)
  var y=float(r.y)
  var w=float(r.w)
  var h=float(r.h)
  for xx in range(int(x),int(x+w)):
   if xx!=int(r.door_x) or int(r.door_y)!=int(y): Art.box(self,xx,y,0.96,0.10,35,Color("f3f8ff"))
   if xx!=int(r.door_x) or int(r.door_y)!=int(y+h-1): Art.box(self,xx,y+h-0.10,0.96,0.1,10,Color("a9becb"))
  for yy in range(int(y),int(y+h)):
   if int(r.door_x)!=int(x) or yy!=int(r.door_y): Art.box(self,x,yy,0.1,0.96,35,Color("e5eff9"))
   if int(r.door_x)!=int(x+w-1) or yy!=int(r.door_y): Art.box(self,x+w-0.1,yy,0.1,0.96,10,Color("9fb9cb"))
  Art.tile(self,r.door_x,r.door_y,Art.GREEN,0.96,0.96,1)
  var def=Catalog.ROOM_DEFS[int(r.type)]
  draw_string(font,Art.iso(x+0.4,y+0.3)-Vector2(0,9),def.name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Art.NAVY)
 var items: Array=[]
 for f in data.office.furniture:
  if int(f.floor)==floor_id: items.append(f)
 items.sort_custom(func(a,b):return a.x+a.y<b.x+b.y)
 for f in items: furniture(f)
 for wall in data.office.walls:
  if int(wall.floor)==floor_id: Art.box(self,wall.x,wall.y,0.96,0.96,32,Color("c5d8e4"))
 if data.office.rooms.is_empty():
  draw_string(font,Vector2(-70,190),"ВАШЕ НОВОЕ ПРОСТРАНСТВО",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("638aa1"))

func furniture(f: Dictionary) -> void:
 var d=Catalog.FURNITURE[int(f.type)]
 var x=float(f.x)
 var y=float(f.y)
 var w=float(d.h if f.get("rotated",false) else d.w)
 var h=float(d.w if f.get("rotated",false) else d.h)
 match d.kind:
  "desk","computer":
   Art.box(self,x+0.1,y+0.1,0.78,0.68,18,Color("bf895d"))
   Art.box(self,x+0.08,y+0.08,0.82,0.72,4,Color("f3e2bb"),18)
   Art.box(self,x+0.27,y+0.18,0.5,0.09,13,Color("27527a"),23)
   Art.box(self,x+0.29,y+0.2,0.45,0.02,10,Art.CYAN if d.kind=="computer" else Color("59baf2"),24)
   Art.tile(self,x+0.28,y+0.47,Color("708797"),0.38,0.14,23)
   Art.box(self,x+0.35,y+0.91,0.35,0.28,13,Color("2474a8"))
  "table":
   Art.box(self,x+0.08,y+0.1,w-0.16,h-0.2,22,Color("d2a375"))
   Art.tile(self,x+0.15,y+0.17,Color("f4d9ab"),w-0.3,h-0.34,23)
   for i in range(int(w)*2): Art.box(self,x+i*0.45,y+0.94,0.30,0.23,12,Color("5579ab"))
  "sofa":
   Art.box(self,x+0.1,y+0.15,w-0.2,h-0.2,15,Color("25bfa8"))
   Art.box(self,x+0.1,y+0.15,w-0.2,0.2,26,Color("3ed6b9"))
   Art.box(self,x+0.1,y+0.15,0.17,h-0.2,21,Color("66e2cb"))
   Art.box(self,x+w-0.27,y+0.15,0.17,h-0.2,21,Color("24a98c"))
  "server":
   Art.box(self,x+0.1,y+0.1,0.76,0.76,52,Color("23466d"))
   for i in range(6):
    Art.box(self,x+0.12,y+0.87,0.65,0.02,3,Color("4383a7"),6+i*7)
    draw_circle(Art.iso(x+0.7,y+0.9)-Vector2(0,8+i*7),1.5,Art.GREEN)
  "shelf","cabinet":
   Art.box(self,x+0.08,y+0.08,0.84,0.80,42,Color("c4a175"))
   for i in range(3):
    Art.box(self,x+0.1,y+0.3,0.8,0.6,2,Color("edf3f2"),i*13+2)
    for j in range(2): Art.box(self,x+0.17+j*0.36,y+0.5,0.27,0.3,9,[Color("ffaa32"),Color("168bff"),Color("19c78b")][i],i*13+4)
  "checkout":
   Art.box(self,x+0.1,y+0.2,0.8,0.65,22,Color("f7f9f4"))
   Art.box(self,x+0.15,y+0.35,0.35,0.15,14,Color("345b85"),23)
   Art.tile(self,x+0.2,y+0.4,Art.CYAN,0.25,0.1,38)
  "machine":
   Art.box(self,x+0.05,y+0.1,w-0.1,h-0.2,24,Color("60869b"))
   Art.tile(self,x+0.1,y+0.18,Color("354a5d"),w-0.2,h-0.35,25)
   for i in range(7): Art.box(self,x+0.15+i*(w-0.3)/7,y+0.2,0.09,0.6,4,Color("b7cad3"),26)
   Art.box(self,x+0.45,y+0.2,0.7,0.6,20,Color("ffaa32"),27)
  "lab":
   Art.box(self,x+0.1,y+0.12,0.8,0.7,24,Color("eff5ff"))
   Art.box(self,x+0.35,y+0.3,0.4,0.3,16,Color("85dbec"),25)
  "coffee":
   Art.box(self,x+0.12,y+0.14,0.76,0.7,24,Color("d6ac7b"))
   Art.box(self,x+0.35,y+0.3,0.35,0.3,18,Color("334663"),25)
  "plant": Art.tree(self,Art.iso(x+0.5,y+0.5),0.65)
