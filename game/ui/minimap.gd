class_name MiniMap
extends Control

var world: WorldView

func _ready() -> void:
 custom_minimum_size=Vector2(178,130)
 mouse_filter=MOUSE_FILTER_STOP

func _draw() -> void:
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
 if event is InputEventMouseButton and event.pressed and world!=null:world.center_camera();accept_event()
