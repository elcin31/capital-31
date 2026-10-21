class_name HistoryChart
extends Control

var history: Array=[]
var key: String="revenue"
var second: String="profit"
var font: Font=preload("res://assets/fonts/DejaVuSans.ttf")

func _ready() -> void:
 mouse_filter=MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)

func _draw() -> void:
 var area=Rect2(60,12,maxf(20,size.x-75),maxf(20,size.y-40))
 var top: float=100
 var bottom: float=0
 var data=history.slice(maxi(0,history.size()-30))
 for d in data:
  top=maxf(top,maxf(d.get(key,0),d.get(second,0)))
  bottom=minf(bottom,minf(d.get(key,0),d.get(second,0)))
 for i in range(4):
  var y=area.position.y+area.size.y*i/3.0
  draw_line(Vector2(area.position.x,y),Vector2(area.end.x,y),Color("dfebf6"),1)
  draw_string(font,Vector2(0,y+4),Catalog.money(top-(top-bottom)*i/3.0,true),HORIZONTAL_ALIGNMENT_LEFT,58,10,Color("7893a9"))
 if data.size()<2:
  draw_string(font,area.position+Vector2(12,area.size.y/2),"История появится через 2 игровых дня",HORIZONTAL_ALIGNMENT_LEFT,area.size.x-20,12,Color("7d99ad"))
  return
 var points=PackedVector2Array()
 for i in range(data.size()):
  var x=area.position.x+area.size.x*(i+0.5)/data.size()
  var val=float(data[i].get(key,0))
  var zero=area.end.y-(0-bottom)/(top-bottom)*area.size.y
  var y=area.end.y-(val-bottom)/(top-bottom)*area.size.y
  draw_rect(Rect2(x-area.size.x/data.size()*0.3,minf(zero,y),maxf(2,area.size.x/data.size()*0.6),maxf(1,absf(y-zero))),Art.BLUE)
  points.append(Vector2(x,area.end.y-(float(data[i].get(second,0))-bottom)/(top-bottom)*area.size.y))
 draw_polyline(points,Art.GREEN,2.5,true)
 draw_string(font,Vector2(area.position.x,size.y-3),"День %d"%int(data[0].day),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("7893a9"))
 draw_string(font,Vector2(area.end.x-60,size.y-3),"День %d"%int(data.back().day),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("7893a9"))
