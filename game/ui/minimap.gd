class_name MiniMap
extends Control

var world: WorldView
var map_rect: Rect2
var previous_pan: Vector2=Vector2.INF

func _ready() -> void:
 custom_minimum_size=Vector2(178,130)
 mouse_filter=MOUSE_FILTER_STOP

func _draw() -> void:
 if world!=null and world.city!=null and world.city.illustrated:
  var h=size.x*9.0/16.0
  map_rect=Rect2(0,(size.y-h)/2,size.x,h)
  draw_texture_rect(world.city.texture,map_rect,false)
  var first=((-world.pan/world.zoom_value)-PaintedCity.RECT.position)/PaintedCity.RECT.size
  var last=((world.size-world.pan)/world.zoom_value-PaintedCity.RECT.position)/PaintedCity.RECT.size
  draw_rect(Rect2(map_rect.position+first*map_rect.size,(last-first)*map_rect.size),Color.WHITE,false,2)
  for b in world.city.buildings:
   var at=(b.anchor-PaintedCity.RECT.position)/PaintedCity.RECT.size
   draw_circle(map_rect.position+at*map_rect.size,4,Art.CYAN if b.kind=="office" else Color("ffd24a"))
  return
 var scale_value=minf(size.x/80,size.y/42)
 var origin=Vector2(size.x/2,2)
 Art.poly(self,[origin,origin+Vector2(36*scale_value,18*scale_value),origin+Vector2(0,36*scale_value),origin+Vector2(-36*scale_value,18*scale_value)],Color("90cbb4"))
 for i in range(0,36,7):
  var a=origin+Vector2(i,-0.0)*scale_value
  var p=Vector2(i,i*0.5)*scale_value
  draw_line(origin+p,origin+p+Vector2(-35,17.5)*scale_value,Color("e6f8f5"),2,true)
  p=Vector2(-i,i*0.5)*scale_value
  draw_line(origin+p,origin+p+Vector2(35,17.5)*scale_value,Color("e6f8f5"),2,true)
 draw_circle(origin+Vector2(0,17)*scale_value,8,Color.WHITE)
 draw_circle(origin+Vector2(0,17)*scale_value,5,Art.BLUE)
 for p in [Vector2(-17,19),Vector2(13,12),Vector2(9,27)]:draw_circle(origin+p*scale_value,4,Color("ffaa32"))

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.pressed and world!=null:
  if world.city.illustrated and map_rect.has_point(event.position):
   var target=PaintedCity.point((event.position-map_rect.position)/map_rect.size)
   world.pan=world.size*0.5-target*world.zoom_value
   world.apply_camera()
  else:world.center_camera()
  accept_event()

func _process(_delta: float) -> void:
 if world!=null and previous_pan!=world.pan:
  previous_pan=world.pan
  queue_redraw()
