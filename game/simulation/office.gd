class_name OfficeSim
extends RefCounted

const WIDTH: int = 16
const HEIGHT: int = 12

static func room_at(c: Dictionary, x: int, y: int, floor_id: int) -> Dictionary:
 for r in c.office.rooms:
  if int(r.floor) == floor_id and x >= r.x and y >= r.y and x < r.x+r.w and y < r.y+r.h: return r
 return {}

static func occupied(c: Dictionary, x: int, y: int, floor_id: int) -> bool:
 for f in c.office.furniture:
  if int(f.floor) != floor_id: continue
  var def = Catalog.FURNITURE[int(f.type)]
  var w = int(def.h if f.get("rotated",false) else def.w)
  var h = int(def.w if f.get("rotated",false) else def.h)
  if x >= f.x and y >= f.y and x < f.x+w and y < f.y+h: return true
 for wall in c.office.get("walls",[]):
  if int(wall.floor)==floor_id and int(wall.x)==x and int(wall.y)==y: return true
 return false

static func can_step(c: Dictionary, a: Vector2i, b: Vector2i, floor_id: int) -> bool:
 if b.x < 0 or b.y < 0 or b.x >= WIDTH or b.y >= HEIGHT or occupied(c,b.x,b.y,floor_id): return false
 var ra = room_at(c,a.x,a.y,floor_id)
 var rb = room_at(c,b.x,b.y,floor_id)
 if ra.get("id",-1)==rb.get("id",-1): return true
 for r in [ra,rb]:
  if r.is_empty(): continue
  var door = Vector2i(int(r.get("door_x",r.x)),int(r.get("door_y",r.y+1)))
  if a != door and b != door: return false
 return true

static func path(c: Dictionary, start: Vector2i, goal: Vector2i, floor_id: int) -> Array:
 if start==goal: return [start]
 var queue: Array[Vector2i] = [start]
 var visited = {start:start}
 var head: int = 0
 while head < queue.size():
  var v = queue[head]
  head += 1
  for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var next = v+d
   if visited.has(next) or not can_step(c,v,next,floor_id): continue
   visited[next]=v
   if next==goal:
    var result: Array = [next]
    while result.back()!=start: result.append(visited[result.back()])
    result.reverse()
    return result
   queue.append(next)
 return []

static func add_room(c: Dictionary, type: int, x: int, y: int, floor_id: int, w: int = 4, h: int = 4) -> String:
 if not c.office.rented: return "Сначала арендуйте офис"
 if type < 0 or type >= Catalog.ROOM_DEFS.size(): return "Неизвестное помещение"
 var def = Catalog.ROOM_DEFS[type]
 if def.industry >= 0 and int(def.industry)!=int(c.industry): return "Помещение другой отрасли"
 if x < 1 or y < 0 or x+w >= WIDTH or y+h >= HEIGHT: return "Оставьте проход вдоль края этажа"
 if floor_id < 0 or floor_id >= c.office.floors: return "Этаж недоступен"
 for xx in range(x,x+w):
  for yy in range(y,y+h):
   if not room_at(c,xx,yy,floor_id).is_empty(): return "Помещения пересекаются"
 var r = {"id":c.office.get("next_room",0),"type":type,"x":x,"y":y,"w":w,"h":h,"floor":floor_id,"door_x":x,"door_y":y+1,"cover":0}
 c.office.rooms.append(r)
 if path(c,Vector2i(0,6),Vector2i(x,y+1),floor_id).is_empty():
  c.office.rooms.erase(r)
  return "Дверь недоступна: нужен свободный проход слева"
 c.office.next_room = int(c.office.get("next_room",0))+1
 return ""

static func add_furniture(c: Dictionary, type: int, x: int, y: int, floor_id: int, rotated: bool = false) -> String:
 if type < 0 or type >= Catalog.FURNITURE.size(): return "Неизвестный предмет"
 var def = Catalog.FURNITURE[type]
 var r = room_at(c,x,y,floor_id)
 if r.is_empty(): return "Размещайте мебель внутри помещения"
 var kind = Catalog.ROOM_DEFS[int(r.type)].kind
 if not def.rooms.is_empty() and not kind in def.rooms: return "Этот предмет не подходит для комнаты"
 var w = int(def.h if rotated else def.w)
 var h = int(def.w if rotated else def.h)
 for xx in range(x,x+w):
  for yy in range(y,y+h):
   if xx >= r.x+r.w or yy >= r.y+r.h or occupied(c,xx,yy,floor_id): return "Нет свободного места"
   if xx==int(r.door_x) and yy==int(r.door_y): return "Не перекрывайте дверь"
 var f = {"id":int(c.office.get("next_furniture",0)),"type":type,"x":x,"y":y,"floor":floor_id,"rotated":rotated}
 c.office.furniture.append(f)
 if stations(c).size() < count_work_objects(c):
  c.office.furniture.erase(f)
  return "Предмет перекрывает доступ к рабочему месту"
 c.office.next_furniture = int(c.office.get("next_furniture",0))+1
 return ""

static func count_work_objects(c: Dictionary) -> int:
 var count: int = 0
 for f in c.office.furniture:
  if Catalog.FURNITURE[int(f.type)].kind in ["desk","computer","checkout","machine"]: count+=1
 return count

static func stations(c: Dictionary) -> Array:
 var out: Array = []
 for f in c.office.furniture:
  if not Catalog.FURNITURE[int(f.type)].kind in ["desk","computer","checkout","machine"]: continue
  for d in [Vector2i(0,1),Vector2i(1,0),Vector2i(0,-1),Vector2i(-1,0)]:
   var at = Vector2i(int(f.x),int(f.y))+d
   if not path(c,Vector2i(0,6),at,int(f.floor)).is_empty():
    out.append({"x":at.x,"y":at.y,"floor":f.floor,"bonus":Catalog.FURNITURE[int(f.type)].bonus,"kind":Catalog.FURNITURE[int(f.type)].kind})
    break
 return out

static func bonus(c: Dictionary, kinds: Array) -> float:
 var result: float = 0.0
 for f in c.office.furniture:
  if Catalog.FURNITURE[int(f.type)].kind in kinds: result+=1.0
 return result

static func has_room(c: Dictionary, kind: String) -> bool:
 for r in c.office.rooms:
  if Catalog.ROOM_DEFS[int(r.type)].kind==kind: return true
 return false

static func employee_hour(c: Dictionary, hour: int) -> float:
 var work: float = 0.0
 var seats = stations(c)
 for i in range(c.employees.size()):
  var e = c.employees[i]
  e.efficiency = 0.0
  var target = Vector2i(0,6)
  var floor_id: int = int(e.get("floor",0))
  var status = "Вне офиса"
  if hour >= int(e.get("start",8)) and hour < int(e.get("end",18)):
   if e.fatigue > 65 or hour==12:
    status="Отдыхает" if has_room(c,"break") else "Перерыв"
    e.fatigue = maxf(0,e.fatigue-(18 if has_room(c,"break") else 8))
    for r in c.office.rooms:
     if Catalog.ROOM_DEFS[int(r.type)].kind=="break":
      target=Vector2i(int(r.x),int(r.y)+1)
      floor_id=int(r.floor)
      break
   elif i < seats.size():
    var seat = seats[i]
    floor_id=int(seat.floor)
    target=Vector2i(int(seat.x),int(seat.y))
    status="Работает" if e.task >= 0 else "Автоназначение"
    var specialty = (c.industry==0 and int(e.role) in [0,8]) or (c.industry==1 and int(e.role) in [4,5]) or (c.industry==2 and int(e.role) in [6,7])
    e.efficiency = (0.35+float(e.skill)/100.0)*(1.0-e.fatigue/150.0)*(0.4+e.satisfaction/160.0)*minf(1.6,seat.bonus)*(1.0 if specialty else 0.65)
    if path(c,Vector2i(0,6),target,floor_id).is_empty():
     e.efficiency=0
     status="Нет прохода"
    e.fatigue=minf(100,e.fatigue+3.0)
    e.experience+=e.efficiency*0.02
    e.skill=minf(100,e.skill+e.efficiency*0.005)
   else:
    status="Нет рабочего места"
    e.satisfaction=maxf(0,e.satisfaction-0.05)
    e.fatigue=maxf(0,e.fatigue-1)
  else:
   e.fatigue=maxf(0,e.fatigue-3)
  e.status=status
  e.floor=floor_id
  var start=Vector2i(int(e.get("x",0)),int(e.get("y",6)))
  var route=path(c,start,target,floor_id)
  e.route=[]
  for cell in route: e.route.append([cell.x,cell.y])
  e.x=target.x
  e.y=target.y
  work+=float(e.efficiency)
 return work
