class_name Art
extends RefCounted

const NAVY = Color("102c50")
const BLUE = Color("168bff")
const CYAN = Color("00cff3")
const GREEN = Color("19c78b")
const SKINS = [Color("f5ccaa"),Color("e4ad84"),Color("bd825c"),Color("8d573d"),Color("623e30"),Color("f4d6bd")]
const HAIRS = [Color("302929"),Color("694434"),Color("c8924e"),Color("e8cf93"),Color("848899")]
const SUITS = [Color("173f68"),Color("168bff"),Color("376c5a"),Color("8d4a76"),Color("d97743"),Color("536487")]

static func poly(c: CanvasItem, points: Array, color: Color) -> void:
 c.draw_colored_polygon(PackedVector2Array(points),color)

static func iso(x: float, y: float) -> Vector2:
 return Vector2((x-y)*32.0,(x+y)*16.0)

static func tile(c: CanvasItem, x: float, y: float, color: Color, w: float = 1, h: float = 1, z: float = 0) -> void:
 var p=iso(x,y)-Vector2(0,z)
 poly(c,[p,p+iso(w,0),p+iso(w,h),p+iso(0,h)],color)

static func box(c: CanvasItem, x: float, y: float, w: float, h: float, z: float, color: Color, elevation: float = 0) -> void:
 var p=iso(x,y)-Vector2(0,elevation)
 var a=p-Vector2(0,z)
 var b=p+iso(w,0)-Vector2(0,z)
 var d=p+iso(0,h)-Vector2(0,z)
 var cc=p+iso(w,h)-Vector2(0,z)
 poly(c,[b,cc,cc+Vector2(0,z),b+Vector2(0,z)],color.darkened(0.22))
 poly(c,[d,cc,cc+Vector2(0,z),d+Vector2(0,z)],color.darkened(0.08))
 poly(c,[a,b,cc,d],color.lightened(0.16))

static func tree(c: CanvasItem, p: Vector2, scale_value: float = 1.0, palm: bool = false) -> void:
 c.draw_set_transform(p,0,Vector2.ONE*scale_value)
 c.draw_circle(Vector2(9,3),12,Color(0.05,0.26,0.20,0.15))
 c.draw_line(Vector2.ZERO,Vector2(0,-30),Color("916546"),4,true)
 if palm:
  for a in range(7):
   var direction=Vector2.from_angle(a*TAU/7)
   poly(c,[Vector2(0,-30),Vector2(0,-30)+direction*26+Vector2(0,6),Vector2(0,-30)+direction*12+direction.orthogonal()*5],Color("32b575"))
 else:
  c.draw_circle(Vector2(0,-34),17,Color("259f65"))
  c.draw_circle(Vector2(-9,-27),12,Color("37ba73"))
  c.draw_circle(Vector2(7,-31),13,Color("69ce76"))
  c.draw_circle(Vector2(-3,-40),10,Color("83dc83"))
 c.draw_set_transform(Vector2.ZERO)

static func person(c: CanvasItem, p: Vector2, scale_value: float, a: Dictionary, phase: float = 0.0, seated: bool = false) -> void:
 var skin=SKINS[int(a.get("skin",0))%SKINS.size()]
 var hair=HAIRS[int(a.get("hair_color",0))%HAIRS.size()]
 var suit=SUITS[int(a.get("outfit",0))%SUITS.size()]
 c.draw_set_transform(p,0,Vector2.ONE*scale_value)
 c.draw_circle(Vector2(0,1),6,Color(0.04,0.13,0.22,0.2))
 var stride=sin(phase)*3.0
 c.draw_line(Vector2(-2,-8),Vector2(-3+stride,0),NAVY,3,true)
 c.draw_line(Vector2(2,-8),Vector2(3-stride,0),NAVY,3,true)
 c.draw_line(Vector2(-3,-16),Vector2(3,-10),suit,7,true)
 c.draw_line(Vector2(-4,-15),Vector2(-5-stride*0.4,-8 if not seated else -13),skin,2,true)
 c.draw_line(Vector2(4,-15),Vector2(5+stride*0.4,-8 if not seated else -14),skin,2,true)
 c.draw_circle(Vector2(0,-23),5,skin)
 c.draw_arc(Vector2(0,-24),5,PI,TAU,12,hair,3,true)
 if int(a.get("hair",0))%3==2: c.draw_line(Vector2(4,-24),Vector2(5,-16),hair,3,true)
 c.draw_set_transform(Vector2.ZERO)

static func portrait(c: CanvasItem, rect: Rect2, a: Dictionary, negotiating: bool = false) -> void:
 var s=minf(rect.size.x/240.0,rect.size.y/280.0)
 var origin=rect.position+Vector2(rect.size.x/2.0,rect.size.y*0.51)
 c.draw_set_transform(origin,0,Vector2.ONE*s)
 var skin=SKINS[int(a.get("skin",0))%SKINS.size()]
 var hair=HAIRS[int(a.get("hair_color",0))%HAIRS.size()]
 var suit=SUITS[int(a.get("outfit",0))%SUITS.size()]
 var female=int(a.get("gender",0))==1
 var face=int(a.get("face",0))%4
 var long_hair=int(a.get("hair",0)) in [2,4,6]
 c.draw_circle(Vector2(0,-8),110,Color("e6f4ff"))
 c.draw_arc(Vector2(0,-8),108,0,TAU,72,CYAN.lightened(0.5),2,true)
 if long_hair:
  c.draw_circle(Vector2(0,-40),54,hair)
  poly(c,[Vector2(-51,-40),Vector2(-58,49),Vector2(60,49),Vector2(48,-44)],hair)
 poly(c,[Vector2(-104,126),Vector2(-93,59),Vector2(-40,28),Vector2(37,28),Vector2(94,60),Vector2(105,126)],suit)
 poly(c,[Vector2(-88,65),Vector2(-37,30),Vector2(-10,126),Vector2(-52,112)],suit.lightened(0.16))
 poly(c,[Vector2(88,65),Vector2(37,30),Vector2(10,126),Vector2(52,112)],suit.darkened(0.12))
 poly(c,[Vector2(-27,29),Vector2(27,29),Vector2(18,126),Vector2(-18,126)],Color("f5fcff"))
 c.draw_rect(Rect2(-17,7,34,40),skin.darkened(0.06))
 poly(c,[Vector2(-21,35),Vector2(0,51),Vector2(-13,66),Vector2(-34,38)],Color.WHITE)
 poly(c,[Vector2(21,35),Vector2(0,51),Vector2(13,66),Vector2(34,38)],Color("e1edfa"))
 if not female:
  poly(c,[Vector2(-5,51),Vector2(5,51),Vector2(10,108),Vector2(0,119),Vector2(-10,108)],CYAN if not negotiating else Color("ffd24a"))
 else: c.draw_arc(Vector2(0,36),23,0.1,PI-0.1,20,Color("ffd24a"),2,true)
 c.draw_circle(Vector2(-42,-35),10,skin.darkened(0.08))
 c.draw_circle(Vector2(42,-35),10,skin.darkened(0.08))
 var face_points: Array=[]
 for i in range(40):
  var angle=i*TAU/40
  var width=44.0+face*1.5
  face_points.append(Vector2(cos(angle)*width,sin(angle)*58-41))
 poly(c,face_points,skin)
 poly(c,[Vector2(27,-87),Vector2(42,-63),Vector2(38,-7),Vector2(20,12),Vector2(33,-29)],skin.darkened(0.05))
 var style=int(a.get("hair",0))
 if style!=5:
  c.draw_arc(Vector2(0,-54),45,PI*0.96,TAU*1.02,30,hair,17,true)
  poly(c,[Vector2(-43,-64),Vector2(-31,-102),Vector2(12,-106),Vector2(44,-77),Vector2(10,-78),Vector2(-21,-61),Vector2(-39,-40)],hair)
  if style%2==1: poly(c,[Vector2(-43,-65),Vector2(4,-107),Vector2(49,-85),Vector2(33,-61),Vector2(13,-71)],hair.lightened(0.12))
  if long_hair: c.draw_line(Vector2(-45,-54),Vector2(-47,11),hair,10,true)
 var eyes=[Color("537c91"),Color("73955d"),Color("77543b"),Color("4b4247")][int(a.get("eyes",0))%4]
 for side in [-1,1]:
  var ep=Vector2(side*18,-42)
  c.draw_line(ep+Vector2(-10,-10),ep+Vector2(8,-11),hair,3,true)
  c.draw_circle(ep,6,Color("fff9f0"))
  c.draw_circle(ep+Vector2(0,0),3.6,eyes)
  c.draw_circle(ep+Vector2(0,0),1.8,NAVY)
  c.draw_circle(ep+Vector2(1,-1),1,Color.WHITE)
 c.draw_polyline(PackedVector2Array([Vector2(0,-38),Vector2(-4,-19),Vector2(4,-18)]),skin.darkened(0.22),1.5,true)
 c.draw_arc(Vector2(0,-14),16,0.3,PI-0.3,18,Color("b66e63"),2.5,true)
 var accessory=int(a.get("accessory",0))
 if accessory in [1,3]:
  for side in [-1,1]:
   c.draw_arc(Vector2(side*19,-41),12,0,TAU,24,NAVY,2,true)
  c.draw_line(Vector2(-7,-43),Vector2(7,-43),NAVY,2,true)
 if accessory in [2,3]:
  c.draw_circle(Vector2(-44,-20),3,Color("ffd24a")); c.draw_circle(Vector2(44,-20),3,Color("ffd24a"))
 if int(a.get("style",0))==1: c.draw_arc(Vector2.ZERO,115,0,TAU,72,Color("ffd24a"),3,true)
 c.draw_set_transform(Vector2.ZERO)
