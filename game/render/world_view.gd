class_name WorldView
extends Control

signal object_pressed(object: Dictionary)
signal cell_pressed(x: int, y: int)
var camera_root: Node2D
var city: CityCanvas
var office: OfficeCanvas
var actors: Node2D
var mode: String="city"
var floor_id: int=0
var zoom_value: float=1.0
var pan: Vector2=Vector2.ZERO
var last_city: int=-1
var dragging: bool=false
var moved: bool=false
var press_at: Vector2
var touches: Dictionary={}
var clock: float=0.0
var person_positions: Dictionary={}
var ghost: Vector2i=Vector2i(-100,-100)
var tool: String=""
var tool_type: int=0
var font: Font=preload("res://assets/fonts/DejaVuSans-Bold.ttf")

class ActorCanvas extends Node2D:
 var view: WorldView
 func _draw() -> void: view.draw_actors(self)

func _ready() -> void:
 clip_contents=true
 mouse_filter=MOUSE_FILTER_STOP
 camera_root=Node2D.new(); add_child(camera_root)
 city=CityCanvas.new(); camera_root.add_child(city)
 office=OfficeCanvas.new(); camera_root.add_child(office)
 actors=ActorCanvas.new(); actors.view=self; camera_root.add_child(actors)
 resized.connect(center_camera)
 Game.office_changed.connect(refresh)
 center_camera()

func refresh() -> void:
 if Game.state.is_empty(): return
 var c=Game.company()
 if last_city!=int(c.city): last_city=int(c.city); city.setup(last_city)
 office.setup(c,floor_id)
 city.visible=mode=="city"
 office.visible=mode=="office"
 actors.queue_redraw()

func set_mode(value: String) -> void:
 mode=value; tool=""; person_positions.clear(); center_camera(); refresh()

func center_camera() -> void:
 zoom_value=1.0 if mode=="office" else 0.9
 pan=Vector2(size.x*0.45,size.y*0.26) if mode=="office" else Vector2(size.x*0.50,-90)
 apply_camera()

func apply_camera() -> void:
 if camera_root==null:return
 camera_root.position=pan; camera_root.scale=Vector2.ONE*zoom_value

func change_zoom(factor: float, anchor: Vector2 = Vector2(-1,-1)) -> void:
 if anchor.x<0: anchor=size*0.5
 var old=zoom_value
 zoom_value=clampf(zoom_value*factor,0.42,1.85)
 pan=anchor-(anchor-pan)*(zoom_value/old)
 apply_camera()

func _process(delta: float) -> void:
 if not visible:return
 if Game.settings.quality>0: clock+=delta
 if actors!=null: actors.queue_redraw()

func _gui_input(event: InputEvent) -> void:
 if event is InputEventScreenTouch:
  if event.pressed:
   touches[event.index]=event.position
   if touches.size()==1: press_at=event.position; moved=false
  else:
   touches.erase(event.index)
   if touches.is_empty() and not moved: click(event.position)
  accept_event()
 elif event is InputEventScreenDrag:
  var old=touches.get(event.index,event.position-event.relative)
  touches[event.index]=event.position
  if touches.size()==1:
   if press_at.distance_to(event.position)>9:moved=true
   if moved:pan+=event.position-old;apply_camera()
  elif touches.size()==2:
   var keys=touches.keys()
   var other=touches[keys[0] if keys[1]==event.index else keys[1]]
   change_zoom(event.position.distance_to(other)/maxf(1,old.distance_to(other)),(event.position+other)*0.5)
   moved=true
  accept_event()
 elif event is InputEventMagnifyGesture:
  change_zoom(event.factor,event.position);accept_event()
 elif event is InputEventMouseButton and not DisplayServer.is_touchscreen_available():
  if event.button_index==MOUSE_BUTTON_WHEEL_UP: change_zoom(1.12,event.position)
  elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:change_zoom(0.89,event.position)
  elif event.button_index==MOUSE_BUTTON_LEFT:
   if event.pressed: dragging=true; moved=false; press_at=event.position
   else:
    if dragging and not moved: click(event.position)
    dragging=false
  accept_event()
 elif event is InputEventMouseMotion and not DisplayServer.is_touchscreen_available():
  if dragging:
   if press_at.distance_to(event.position)>7:moved=true
   if moved:pan+=event.relative;apply_camera()
  var p=(event.position-pan)/zoom_value
  ghost=Vector2i(floori(p.x/64.0+p.y/32.0),floori(p.y/32.0-p.x/64.0))

func click(at: Vector2) -> void:
 var p=(at-pan)/zoom_value
 if mode=="office":
  var tile=Vector2i(floori(p.x/64.0+p.y/32.0),floori(p.y/32.0-p.x/64.0))
  ghost=tile
  cell_pressed.emit(tile.x,tile.y)
 else:
  for b in city.buildings:
   if b.park:continue
   var center=Art.iso(b.x+b.w/2.0,b.y+b.h/2.0)-Vector2(0,b.height*0.5)
   if absf(p.x-center.x)<(b.w+b.h)*18 and absf(p.y-center.y)<b.height*0.55+40:
    object_pressed.emit(b); return

func draw_actors(c: CanvasItem) -> void:
 if Game.state.is_empty():return
 if mode=="city":
  var count=14 if Game.settings.quality==0 else 32
  for i in range(count):
   var t=fmod(clock*(0.7 if i%2==0 else -0.6)+i*3.71+1000,34.0)
   var x=t if i%2==0 else float((i*7)%35)+0.2
   var y=float((i*7)%35)+0.2 if i%2==0 else t
   var p=Art.iso(x,y)
   var screen=p*zoom_value+pan
   if screen.x<-80 or screen.x>size.x+80 or screen.y<0 or screen.y>size.y+80:continue
   if i%3==0:
    Art.box(c,x,y,0.85 if i%2==0 else 0.35,0.35 if i%2==0 else 0.85,8,[Color("ffaa32"),Color("f7fafb"),Color("168bff"),Color("eb6770")][i%4])
    Art.tile(c,x+0.1,y+0.05,Color("b5e9f8"),0.45,0.2,9)
   else: Art.person(c,p,0.48,Catalog.appearance(i),clock*6+i)
  var mark_count=0
  for b in city.buildings:
   if b.kind not in ["office","investor","rival","property"] or b.park:continue
   if b.kind=="rival" and mark_count>2:continue
   var pos=Art.iso(b.x+b.w*0.3,b.y+b.h*0.5)-Vector2(0,b.height+40)
   var label=Game.company().name if b.kind=="office" else b.name
   var color=Art.CYAN if b.kind=="office" else (Color("9f78e8") if b.kind=="investor" else (Color("ef6577") if b.kind=="rival" else Art.BLUE))
   if b.kind=="office":
    var corners=[Art.iso(b.x-0.3,b.y-0.3),Art.iso(b.x+b.w+0.3,b.y-0.3),Art.iso(b.x+b.w+0.3,b.y+b.h+0.3),Art.iso(b.x-0.3,b.y+b.h+0.3),Art.iso(b.x-0.3,b.y-0.3)]
    c.draw_polyline(PackedVector2Array(corners),color,3,true)
   var style=StyleBoxFlat.new()
   style.bg_color=Color("133e59");style.set_corner_radius_all(9);style.border_color=color;style.set_border_width_all(2)
   c.draw_style_box(style,Rect2(pos-Vector2(12,22),Vector2(mini(270,label.length()*10+35),42)))
   c.draw_circle(pos+Vector2(4,-1),5,color)
   c.draw_string(font,pos+Vector2(17,5),label,HORIZONTAL_ALIGNMENT_LEFT,235,15,Color.WHITE)
   c.draw_line(pos+Vector2(12,21),pos+Vector2(12,33),color,2,true)
   mark_count+=1
 else:
  var company=Game.company()
  for e in company.employees:
   if int(e.floor)!=floor_id or e.status=="Вне офиса":continue
   var target=Art.iso(float(e.x)+0.45,float(e.y)+0.45)
   var key=str(e.id)
   if not person_positions.has(key):person_positions[key]=Art.iso(0.4,6.4)
   if Game.speed>0:
    person_positions[key]=person_positions[key].lerp(target,0.12)
   var pos:Vector2=person_positions[key]
   var walking=pos.distance_to(target)>3
   Art.person(c,pos,1.15,e.appearance,clock*8 if walking else 0,not walking)
   if not walking and Game.settings.quality>0:
    c.draw_circle(pos-Vector2(0,39),3,Art.GREEN if e.efficiency>0 else Color("ffaa32"))
  if not tool.is_empty() and ghost.x>=0 and ghost.x<16 and ghost.y>=0 and ghost.y<12:
   Art.tile(c,ghost.x,ghost.y,Color(0.05,0.8,0.9,0.40),4 if tool=="room" else 1,4 if tool=="room" else 1,2)
