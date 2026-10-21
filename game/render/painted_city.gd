class_name PaintedCity
extends RefCounted

const RECT=Rect2(-1000,-150,2000,1125)
const FILES=["capital-city","san-francisco","dubai","bengaluru","moscow"]
const POINTS=[
 [Vector2(0.65,0.36),Vector2(0.37,0.55),Vector2(0.27,0.77),Vector2(0.86,0.57)],
 [Vector2(0.65,0.37),Vector2(0.33,0.58),Vector2(0.26,0.79),Vector2(0.84,0.60)],
 [Vector2(0.66,0.36),Vector2(0.36,0.60),Vector2(0.25,0.78),Vector2(0.83,0.58)],
 [Vector2(0.64,0.37),Vector2(0.35,0.60),Vector2(0.26,0.79),Vector2(0.83,0.58)],
 [Vector2(0.65,0.35),Vector2(0.34,0.59),Vector2(0.25,0.79),Vector2(0.83,0.57)]]

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
  Art.box(c,0,0,0.1,0.1,0,Color.TRANSPARENT)
  c.draw_set_transform(p,-0.65,Vector2.ONE)
  c.draw_colored_polygon(PackedVector2Array([Vector2(-9,0),Vector2(0,-5),Vector2(12,0),Vector2(0,5)]),Color("f6fcff"))
  c.draw_rect(Rect2(-4,-3,8,5),Color("318bbc"))
  c.draw_set_transform(Vector2.ZERO)
