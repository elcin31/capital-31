class_name MeetingBackdrop
extends Control
func _ready() -> void:
 mouse_filter=MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("e6f3fa"))
 var window=Rect2(size.x*0.30,10,size.x*0.40,size.y*0.48)
 draw_rect(window,Color("b6e6fa"))
 for i in range(13):
  var h=18+(i*37)%47
  draw_rect(Rect2(window.position+Vector2(i*window.size.x/13.0,window.size.y-h),Vector2(window.size.x/15.0,h)),Color("7cb5cd"))
 for i in range(4):
  var x=window.position.x+i*window.size.x/3.0
  draw_line(Vector2(x,10),Vector2(x,window.end.y),Color.WHITE,4,true)
 draw_line(Vector2(window.position.x,window.end.y),window.end,Color.WHITE,5,true)
 draw_rect(Rect2(0,size.y*0.68,size.x,size.y*0.32),Color("d8e9ed"))
 Art.poly(self,[Vector2(size.x*0.12,size.y*0.97),Vector2(size.x*0.26,size.y*0.77),Vector2(size.x*0.74,size.y*0.77),Vector2(size.x*0.88,size.y*0.97)],Color("d1af87"))
