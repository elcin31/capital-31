class_name WorldMap
extends Control
signal city_selected(id: int)
var font: Font=preload("res://assets/fonts/DejaVuSans-Bold.ttf")

func _ready() -> void:custom_minimum_size.y=245;mouse_filter=MOUSE_FILTER_STOP
func point(lon: float, lat: float) -> Vector2:return Vector2((lon+180)/360*size.x,(82-lat)/145*size.y)

func _draw() -> void:
 draw_style_box(UI.style(Color("133e59"),12),Rect2(Vector2.ZERO,size))
 for lon in range(-150,181,30):draw_line(point(lon,-60),point(lon,80),Color(0.4,0.8,0.9,0.1),1)
 for lat in range(-60,81,20):draw_line(point(-180,lat),point(180,lat),Color(0.4,0.8,0.9,0.1),1)
 var continents=[
 [[-168,70],[-130,74],[-100,60],[-60,53],[-52,20],[-82,9],[-110,27],[-126,50]],
 [[-81,10],[-48,-2],[-35,-12],[-54,-52],[-70,-38],[-78,-8]],
 [[-16,34],[12,38],[35,30],[48,9],[34,-20],[18,-35],[-1,-10]],
 [[-11,36],[-9,61],[20,72],[42,70],[55,52],[30,40]],
 [[32,72],[110,74],[170,61],[146,38],[119,21],[103,1],[77,7],[65,27],[43,41]],
 [[113,-12],[143,-10],[154,-27],[134,-40],[113,-30]]]
 for shape in continents:
  var points: Array=[]
  for p in shape:points.append(point(p[0],p[1]))
  Art.poly(self,points,Color("357b80"))
 if not Game.state.is_empty():
  var home=Catalog.CITIES[int(Game.company().city)]
  for c in Game.state.companies:
   if c.status=="Ликвидирована":continue
   var city=Catalog.CITIES[int(c.city)]
   draw_line(point(home.lon,home.lat),point(city.lon,city.lat),Color("50b7d1"),2,true)
 for i in range(5):
  var city=Catalog.CITIES[i];var p=point(city.lon,city.lat)
  draw_circle(p,7,Art.CYAN);draw_circle(p,3,Color.WHITE)
  draw_string(font,p+Vector2(10,-8 if i%2==0 else 22),city.name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.pressed:
  for i in range(5):
   var city=Catalog.CITIES[i]
   if event.position.distance_to(point(city.lon,city.lat))<36:city_selected.emit(i);accept_event();return
