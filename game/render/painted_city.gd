class_name PaintedCity
extends RefCounted

const RECT=Rect2(-1000,-150,2000,1125)
const FILES=["capital-city","san-francisco","dubai","bengaluru","moscow"]
const POINTS=[
 [Vector2(0.65,0.36),Vector2(0.37,0.40),Vector2(0.36,0.60),Vector2(0.73,0.65)],
 [Vector2(0.65,0.37),Vector2(0.37,0.40),Vector2(0.36,0.60),Vector2(0.78,0.62)],
 [Vector2(0.66,0.36),Vector2(0.37,0.39),Vector2(0.36,0.60),Vector2(0.78,0.62)],
 [Vector2(0.64,0.37),Vector2(0.37,0.39),Vector2(0.36,0.60),Vector2(0.78,0.62)],
 [Vector2(0.65,0.35),Vector2(0.37,0.39),Vector2(0.36,0.60),Vector2(0.78,0.62)]]

static func point(p: Vector2) -> Vector2:return RECT.position+p*RECT.size

static func objects(city: int) -> Array:
 var points=POINTS[city];var result: Array=[]
 for i in range(4):
  var p=point(points[i])
  result.append({"kind":["office","rival","investor","property"][i],"name":["Штаб-квартира","Kaiser Analytics","Vertex Capital","Riverside · Офисы"][i],"anchor":p,"hit_rect":Rect2(p-Vector2(100,10),Vector2(240,280))})
 return result

static func background(c: CanvasItem, texture: Texture2D) -> void:
 c.draw_texture_rect(texture,RECT,false)

static func actors(c: CanvasItem, view: WorldView) -> void:
 for b in view.city.buildings:
  var pos:Vector2=b.anchor
  var label=Game.company().name if b.kind=="office" else b.name
  var color=Art.CYAN if b.kind=="office" else (Color("ad80f3") if b.kind=="investor" else (Color("ef6577") if b.kind=="rival" else Art.BLUE))
  c.draw_set_transform(pos,0,Vector2.ONE/view.zoom_value)
  var style=UI.style(Color("133e59"),9,color)
  style.set_border_width_all(2)
  var width=minf(270,label.length()*9+28)
  c.draw_style_box(style,Rect2(-10,-23,width,42))
  c.draw_circle(Vector2(4,-2),5,color)
  c.draw_string(view.font,Vector2(16,4),label,HORIZONTAL_ALIGNMENT_LEFT,width-25,14,Color.WHITE)
  c.draw_line(Vector2(10,19),Vector2(10,34),color,2,true)
  c.draw_set_transform(Vector2.ZERO)
 if view.city.city_id==0 and Game.settings.quality>0:
  var t=fmod(view.clock*0.014,1.0)
  var p=point(Vector2(0.16,0.61).lerp(Vector2(0.27,0.96),t))
  c.draw_line(p+Vector2(10,-4),p+Vector2(27,-15),Color(0.8,1,1,0.5),2,true)
  c.draw_set_transform(p,-0.65,Vector2.ONE)
  c.draw_colored_polygon(PackedVector2Array([Vector2(-9,0),Vector2(0,-5),Vector2(12,0),Vector2(0,5)]),Color("f6fcff"))
  c.draw_rect(Rect2(-4,-3,8,5),Color("318bbc"))
  c.draw_set_transform(Vector2.ZERO)

 if view.city.city_id>0 and Game.settings.quality>0:
  var starts=[Vector2.ZERO,Vector2(0.13,0.54),Vector2(0.30,0.52),Vector2(0.30,0.55),Vector2(0.25,0.50)]
  var ends=[Vector2.ZERO,Vector2(0.64,0.98),Vector2(0.65,0.95),Vector2(0.66,0.90),Vector2(0.65,0.97)]
  for i in range(4):
   var t=fmod(view.clock*0.022+i*0.23,1.0)
   var p=point(starts[view.city.city_id].lerp(ends[view.city.city_id],t))
   c.draw_set_transform(p,0,Vector2.ONE*0.55)
   Art.box(c,0,0,0.45,0.23,6,[Color("f5fcff"),Art.BLUE,Color("ffaa32"),Color("ef6577")][i])
   Art.tile(c,0.1,0.03,Color("8ad4e5"),0.24,0.17,7)
   c.draw_set_transform(Vector2.ZERO)
