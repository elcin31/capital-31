extends SceneTree
var ui: Control
var game: Node
var failures: Array=[]
var checks: int=0

func _initialize() -> void:call_deferred("run")
func check(ok: bool, title: String) -> void:
 checks+=1
 print("PASS: " if ok else "FAIL: ",title)
 if not ok:failures.append(title)

func find_text(node: Node, text: String) -> Control:
 if node is Button and node.text==text and node.is_visible_in_tree() and not node.is_queued_for_deletion():return node
 for child in node.get_children():
  var result=find_text(child,text)
  if result!=null:return result
 return null

func click_at(point: Vector2) -> void:
 var event=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
 root.push_input(event);await process_frame
 event=event.duplicate();event.pressed=false;root.push_input(event)
 for i in range(3):await process_frame

func click(text: String) -> void:
 var node=find_text(ui,text)
 check(node!=null,"Кнопка: "+text)
 if node==null:return
 var parent=node.get_parent()
 while parent!=null:
  if parent is ScrollContainer:parent.ensure_control_visible(node)
  parent=parent.get_parent()
 for i in range(3):await process_frame
 await click_at(node.get_global_rect().get_center())

func snap(name: String) -> void:
 for i in range(3):await process_frame
 var path=ProjectSettings.globalize_path("res://../docs/qa/desktop")
 DirAccess.make_dir_recursive_absolute(path)
 root.get_texture().get_image().save_png(path+"/"+name+".png")

func run() -> void:
 game=root.get_node("Game")
 SaveStore.base_path="user://qa_gui_saves"
 ui=load("res://main.tscn").instantiate();root.add_child(ui)
 for i in range(4):await process_frame
 await click("Начать новую историю  →")
 check(is_instance_valid(ui.modal),"Открылся редактор основателя")
 ui.wizard.founder.appearance.skin=3;ui.wizard.founder.appearance.hair=2
 await click("Далее: страна и город  →")
 await click("Берлин")
 await click("Далее: регистрация компании  →")
 await click("Зарегистрировать компанию  →")
 check(game.company().name=="NOVA Technologies" and game.state.founder.appearance.skin==3,"Основатель и компания созданы через UI")
 await click("▦  Доступные офисы")
 await click("Арендовать офис")
 check(ui.world.mode=="office" and game.company().office.rented,"Аренда и переход в интерьер")
 await click("⚒  Строить")
 await click("€2 000 · Разместить")
 await click_at(ui.world.pan+Art.iso(1.4,1.4)*ui.world.zoom_value)
 check(game.company().office.rooms.size()==1,"Комната построена касанием сетки")
 await click("⚒  Строить")
 await click("Мебель и оборудование")
 await click("€900 · Купить")
 await click_at(ui.world.pan+Art.iso(2.4,2.4)*ui.world.zoom_value)
 check(game.company().office.furniture.size()==1,"Рабочее место куплено касанием")
 ui.world.tool=""
 await click("♟  Команда")
 await click("Пригласить в команду")
 check(game.company().employees.size()==1,"Найм через кадровый экран")
 ui.go_back()
 await click("▣  Продукты")
 await click("+  Новый продукт / направление")
 await click("Начать разработку")
 check(game.company().products.size()==1,"Настоящий проект создан через форму")
 ui.go_back();await click("×10")
 game.advance_time(205)
 while game.accumulator>=1:game.advance_time(0)
 check(game.company().products[0].stage=="Готов к выпуску","Разработка завершена ускоренным игровым временем")
 await click("▣  Продукты");await click("Выпустить")
 game.speed=10;game.advance_time(144)
 while game.accumulator>=1:game.advance_time(0)
 game.speed=0;game.updated.emit()
 check(game.company().products[0].revenue>0 and game.company().products[0].customers>0,"Появились клиенты и выручка")
 await snap("01-product")
 ui.go_back();await click("€  Финансы");await click("P&L")
 check(game.ledger().report().revenue>0,"P&L отражает реальные продажи")
 await snap("02-pnl");await click("Cash Flow");await snap("03-cashflow")
 ui.go_back();await click("◆  Инвесторы");await click("Предложить встречу")
 var cash=game.ledger().accounts.cash
 await click("Представить стратегию");await click("Принять предложение")
 check(game.company().negotiation.accepted and game.ledger().accounts.cash==cash+10000000,"Переговоры и поступление €100 000")
 check(game.company().cap_table.size()==2 and game.company().cap_table[0].share<1,"Доли обновлены через экран сделки")
 await snap("04-deal")
 ui.go_back();ui.global_screens.show_saves()
 var expected=game.state.duplicate(true)
 check(game.save_slot(2).is_empty(),"Ручное сохранение UI-сценария")
 game.state={};check(game.load_slot(2).is_empty(),"Загрузка UI-сценария")
 check(JSON.stringify(expected,"",true,true)==JSON.stringify(game.state,"",true,true),"Побитовое восстановление чисел и состояния")
 ui.enter_game();ui.navigate("office")
 var old_pan=ui.world.pan
 var touch=InputEventScreenTouch.new();touch.index=0;touch.position=Vector2(700,450);touch.pressed=true;ui.world._gui_input(touch)
 var drag=InputEventScreenDrag.new();drag.index=0;drag.position=Vector2(740,480);drag.relative=Vector2(40,30);ui.world._gui_input(drag)
 check(ui.world.pan!=old_pan,"Панорамирование пальцем")
 touch=InputEventScreenTouch.new();touch.index=1;touch.position=Vector2(900,450);touch.pressed=true;ui.world._gui_input(touch)
 var old_zoom=ui.world.zoom_value
 drag=InputEventScreenDrag.new();drag.index=1;drag.position=Vector2(1050,450);drag.relative=Vector2(150,0);ui.world._gui_input(drag)
 check(ui.world.zoom_value>old_zoom,"Масштабирование двумя пальцами")
 ui.world.touches.clear();ui.world.center_camera()
 ui.business.show_products();ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
 check(not is_instance_valid(ui.modal),"Android Back закрывает окно")
 for dimensions in [Vector2i(1440,810),Vector2i(1800,810),Vector2i(1620,810),Vector2i(1755,810)]:
  root.size=dimensions
  for i in range(4):await process_frame
  var inside=true
  for b in ui.bottom.get_child(0).get_children():
   if b.get_global_rect().end.x>ui.size.x:inside=false
  check(inside,"Навигация видна при размере "+str(dimensions))
 await snap("05-office")
 var result={"checks":checks,"failed":failures.size(),"failures":failures,"platform":"Godot desktop, Xvfb, software OpenGL; pointer clicks + touch gesture events","apk_test":false}
 var f=FileAccess.open("res://../docs/QA-GUI.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
 print("GUI RESULT: ",checks," checks, ",failures.size()," failed")
 quit(0 if failures.is_empty() else 1)
