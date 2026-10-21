extends Control

var world: WorldView
var game_layer: Control
var menu_layer: Control
var modal: Control
var modal_panel: PanelContainer
var right_panel: PanelContainer
var bindings: Array=[]
var chart: HistoryChart
var toast: PanelContainer
var toast_time: float=0
var audio: GameAudio
var wizard: MenuWizard
var business: BusinessScreens
var finances: FinanceScreens
var funding: InvestorScreens
var global_screens: WorldScreens
var top: PanelContainer
var left: PanelContainer
var bottom: PanelContainer
var camera_buttons: HBoxContainer
var floor_buttons: HBoxContainer
var news_line: Button
var analytics_button: Button

func _ready() -> void:
 theme=UI.theme()
 get_tree().quit_on_go_back=false
 audio=GameAudio.new();add_child(audio)
 wizard=MenuWizard.new(self);business=BusinessScreens.new(self);finances=FinanceScreens.new(self);funding=InvestorScreens.new(self);global_screens=WorldScreens.new(self)
 game_layer=Control.new();game_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(game_layer)
 world=WorldView.new();world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);game_layer.add_child(world)
 world.object_pressed.connect(city_object);world.cell_pressed.connect(office_cell)
 Game.updated.connect(refresh_values);Game.message.connect(show_toast)
 resized.connect(relayout)
 wizard.show_menu()
 if "--capture" in OS.get_cmdline_user_args():call_deferred("capture_designs")

func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_GO_BACK_REQUEST:go_back()

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):go_back();get_viewport().set_input_as_handled()

func go_back() -> void:
 if is_instance_valid(modal):close_panel()
 elif is_instance_valid(menu_layer):wizard.show_menu()
 elif not world.tool.is_empty():world.tool="";show_toast("Режим строительства закрыт","info")
 else:global_screens.show_pause()

func enter_game() -> void:
 if is_instance_valid(menu_layer):menu_layer.queue_free();menu_layer=null
 close_panel();game_layer.show();build_hud();world.refresh();relayout()

func build_hud() -> void:
 for node in [top,left,bottom,right_panel,camera_buttons,floor_buttons,news_line,analytics_button]:
  if is_instance_valid(node):node.queue_free()
 top=PanelContainer.new();top.add_theme_stylebox_override("panel",UI.style(Color("103650"),0));game_layer.add_child(top)
 var row=UI.row(top)
 var brand=UI.button(row,"▥  CAPITAL",global_screens.show_pause)
 brand.add_theme_font_override("font",UI.BOLD);brand.add_theme_font_size_override("font_size",24);brand.custom_minimum_size.x=205
 var vals=UI.row(row,true)
 var cap=UI.metric(vals,"ДЕНЬГИ КОМПАНИИ","",Color.WHITE)
 var rev=UI.metric(vals,"ВЫРУЧКА / 30 ДН.","",Color.WHITE)
 var profit=UI.metric(vals,"ПРИБЫЛЬ / 30 ДН.","",Color("44e8b1"))
 var team=UI.metric(vals,"СОТРУДНИКИ","",Color.WHITE)
 var date=UI.metric(vals,"ИГРОВОЕ ВРЕМЯ","",Color.WHITE)
 for v in vals.get_children():
  v.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  v.get_child(0).add_theme_color_override("font_color",Color("9ac2d5"))
 bind_text(cap,func():return Catalog.money(Game.ledger().accounts.cash,true))
 bind_text(rev,func():return Catalog.money(Game.ledger().report(maxi(0,Game.day()-29)).revenue,true))
 bind_text(profit,func():return Catalog.money(Game.ledger().report(maxi(0,Game.day()-29)).net,true))
 bind_text(team,func():return str(Game.company().employees.size()))
 bind_text(date,func():return "День %d · %02d:00"%[Game.day()+1,int(Game.state.hour)%24])
 UI.button(row,"☰",global_screens.show_pause)
 left=PanelContainer.new();left.add_theme_stylebox_override("panel",UI.style(Color("133e59"),14));game_layer.add_child(left)
 var lc=UI.column(left)
 UI.label(lc,Catalog.CITIES[int(Game.company().city)].name,25,Color.WHITE,true)
 UI.label(lc,Catalog.CITIES[int(Game.company().city)].country,15,Color("9fdbee"))
 UI.label(lc,"ГОРОД ВОЗМОЖНОСТЕЙ",11,Color("86c5db"),true);UI.separator(lc)
 for item in [["▦  Доступные офисы",business.show_property],["◈  Конкуренты",global_screens.show_competitors],["◆  Инвесторы",funding.show_investors],["↗  События рынка",global_screens.show_economy],["♟  Кадровый рынок",business.show_employees]]:
  var b=UI.button(lc,item[0],item[1]);b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.add_theme_stylebox_override("normal",UI.style(Color("20536d"),8));b.add_theme_color_override("font_color",Color.WHITE)
 var city=Catalog.CITIES[int(Game.company().city)]
 UI.label(lc,"Налог %.0f%% · Кредит %.1f%%"%[city.tax*100,city.rate*100],12,Color("abd2df"))
 var mm=MiniMap.new();mm.world=world;lc.add_child(mm);UI.label(lc,"Два пальца — масштаб",11,Color("86b9cf"))
 bottom=PanelContainer.new();bottom.add_theme_stylebox_override("panel",UI.style(Color("103650"),20));game_layer.add_child(bottom)
 var br=UI.row(bottom)
 var nav=[["▦","Офис",func():navigate("office")],["◈","Город",func():navigate("city")],["▣","Продукты",business.show_products],["€","Финансы",finances.show_finance],["♟","Команда",business.show_employees],["◆","Инвесторы",funding.show_investors],["◎","Мир",global_screens.show_world]]
 for item in nav:
  var b=UI.button(br,item[0]+"  "+item[1],item[2]);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_stylebox_override("normal",UI.style(Color("16475f"),9));b.add_theme_color_override("font_color",Color.WHITE)
 camera_buttons=UI.row(game_layer)
 for item in [["−",func():world.change_zoom(0.8)],["+",func():world.change_zoom(1.25)],["⌖",func():world.center_camera()]]:
  UI.button(camera_buttons,item[0],item[1]).custom_minimum_size.x=46
 var pause=UI.button(camera_buttons,"Ⅱ",func():Game.speed=0;refresh_values())
 pause.toggle_mode=true
 bind_value(pause,func():return Game.speed==0,"button_pressed")
 for rate in [1,2,5,10]:
  var time_button=UI.button(camera_buttons,"×%d"%rate,func():Game.speed=rate;refresh_values())
  time_button.custom_minimum_size.x=48;time_button.toggle_mode=true
  bind_value(time_button,func():return Game.speed==rate,"button_pressed")
 floor_buttons=UI.row(game_layer)
 UI.button(floor_buttons,"⚒  Строить",business.show_build)
 UI.button(floor_buttons,"Этаж −",func():world.floor_id=maxi(0,world.floor_id-1);world.refresh())
 UI.button(floor_buttons,"Этаж +",func():world.floor_id=mini(int(Game.company().office.floors)-1,world.floor_id+1);world.refresh())
 floor_buttons.visible=world.mode=="office"
 news_line=UI.button(game_layer,"",global_screens.show_news);news_line.add_theme_font_size_override("font_size",13)
 bind_text(news_line,func():return "● "+(Game.state.news[0].title if not Game.state.news.is_empty() else "Город ждёт ваших решений")+"   ›")
 analytics_button=UI.button(game_layer,"▥  Компания",func():right_panel.visible=not right_panel.visible)
 build_sidebar()

func build_sidebar() -> void:
 right_panel=PanelContainer.new();game_layer.add_child(right_panel)
 var col=UI.scroll(right_panel);col.add_theme_constant_override("separation",8)
 var heading=UI.row(col)
 UI.portrait(heading,Game.state.founder.appearance,Vector2(55,65))
 var title=UI.column(heading)
 var name_label=UI.label(title,Game.company().name,17,UI.TEXT,true)
 name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 name_label.custom_minimum_size.x=125
 UI.text(title,"От идеи к большой компании",10,UI.MUTED)
 UI.button(heading,"×",func():right_panel.hide());UI.separator(col)
 UI.label(col,"Динамика компании",16,UI.TEXT,true);UI.label(col,"● Выручка    ● Прибыль",11,UI.BLUE)
 chart=HistoryChart.new();chart.custom_minimum_size.y=115;chart.history=Game.company().history;col.add_child(chart)
 bind_text(UI.pair(col,"На счетах",""),func():return Catalog.money(Game.ledger().accounts.cash,true))
 bind_text(UI.pair(col,"Доля основателя",""),func():
  for owner in Game.company().cap_table:
   if owner.id=="founder":return "%.1f%%"%(owner.share*100)
  return "Филиал группы")
 bind_text(UI.pair(col,"Команда / места",""),func():return "%d / %d"%[Game.company().employees.size(),OfficeSim.stations(Game.company()).size()])
 UI.separator(col);UI.label(col,"СЛЕДУЮЩИЙ ШАГ",12,UI.BLUE,true)
 bind_text(UI.text(col,"",15,UI.TEXT),func():
  var c=Game.company()
  if not c.office.rented:return "Арендуйте первый офис. Депозит вернётся при ликвидации."
  if c.office.rooms.is_empty():return "Войдите в офис и постройте рабочую комнату."
  if OfficeSim.stations(c).is_empty():return "Купите рабочее место в режиме строительства."
  if c.employees.is_empty():return "Наймите сотрудника на кадровом рынке."
  if c.products.is_empty():return "Запустите разработку первого продукта."
  for p in c.products:
   if p.stage=="Готов к выпуску":return "Продукт готов! Запустите продажи."
  return "Развивайте продажи, ищите инвестиции и новые рынки.")
 UI.button(col,"Войти в офис  →",func():navigate("office"),true)
 UI.button(col,"Финансовый терминал",finances.show_finance)
 UI.button(col,"Профиль и карьера",global_screens.show_career)

func navigate(mode: String) -> void:
 close_panel()
 if mode=="office" and not Game.company().office.rented:business.show_property();return
 world.set_mode(mode);floor_buttons.visible=mode=="office"
 left.visible=mode=="city";right_panel.visible=mode=="city"

func relayout() -> void:
 var safe=Rect2(Vector2(12,10),size-Vector2(24,20))
 if OS.get_name()=="Android":
  var physical=DisplayServer.screen_get_size();var area=DisplayServer.get_display_safe_area()
  if physical.x>0 and area.size.x>0:
   var factor=size/Vector2(physical);safe=Rect2(Vector2(area.position)*factor+Vector2(10,8),Vector2(area.size)*factor-Vector2(20,16))
 if not is_instance_valid(top):return
 place(top,Rect2(safe.position,Vector2(safe.size.x,72)))
 place(left,Rect2(safe.position+Vector2(0,86),Vector2(222,570)))
 place(right_panel,Rect2(safe.position+Vector2(safe.size.x-334,86),Vector2(334,minf(598,safe.size.y-170))))
 place(bottom,Rect2(Vector2(safe.position.x+112,safe.end.y-68),Vector2(safe.size.x-224,68)))
 place(camera_buttons,Rect2(Vector2(safe.position.x+242,safe.end.y-124),Vector2(520,46)))
 place(floor_buttons,Rect2(safe.position+Vector2(245,86),Vector2(450,46)))
 place(news_line,Rect2(Vector2(safe.end.x-322,safe.end.y-121),Vector2(322,44)))
 place(analytics_button,Rect2(Vector2(safe.end.x-145,safe.position.y+90),Vector2(145,44)))
 if is_instance_valid(modal_panel):layout_modal()

func place(node: Control, rect: Rect2) -> void:
 node.position=rect.position;node.size=rect.size

func open_panel(title: String, width: float = 1000) -> VBoxContainer:
 close_panel()
 modal=Control.new();modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(modal)
 var dim=ColorRect.new();dim.color=Color(0.02,0.10,0.20,0.40);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);modal.add_child(dim)
 modal_panel=PanelContainer.new();modal_panel.set_meta("width",width);modal.add_child(modal_panel)
 var column=UI.column(modal_panel);var row=UI.row(column)
 var h=UI.label(row,title,24,UI.TEXT,true);h.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 UI.button(row,"×  Закрыть",close_panel);UI.separator(column)
 var content=UI.scroll(column);layout_modal();return content

func layout_modal() -> void:
 var width=minf(float(modal_panel.get_meta("width",1000)),size.x-70)
 place(modal_panel,Rect2(Vector2((size.x-width)/2.0,82),Vector2(width,maxf(350,size.y-176))))

func close_panel() -> void:
 if is_instance_valid(modal):remove_child(modal);modal.queue_free()
 modal=null;modal_panel=null

func bind_text(node: Control, fn: Callable) -> void:
 bindings.append({"node":weakref(node),"fn":fn,"property":"text"});node.set("text",fn.call())

func bind_value(node: Control, fn: Callable, property: String = "value") -> void:
 bindings.append({"node":weakref(node),"fn":fn,"property":property});node.set(property,fn.call())

func refresh_values() -> void:
 if Game.state.is_empty():return
 var valid: Array=[]
 for b in bindings:
  var node=b.node.get_ref()
  if is_instance_valid(node) and not node.is_queued_for_deletion():node.set(b.property,b.fn.call());valid.append(b)
 bindings=valid
 if is_instance_valid(chart):chart.queue_redraw()

func perform(fn: Callable, after: Callable = Callable(), cue: String = "click") -> void:
 var result=fn.call()
 if result is String and not result.is_empty():show_toast(result,"warning");audio.play_cue("warning");return
 audio.play_cue(cue);refresh_values()
 if after.is_valid():after.call_deferred()

func show_toast(text: String, kind: String = "info") -> void:
 if is_instance_valid(toast):toast.queue_free()
 toast=PanelContainer.new();toast.add_theme_stylebox_override("panel",UI.style(Color("133e59") if kind!="warning" else Color("b47422"),12));add_child(toast)
 var l=UI.label(toast,text,16,Color.WHITE);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 place(toast,Rect2(Vector2(size.x*0.5-280,size.y-190),Vector2(560,56)));toast_time=4

func _process(delta: float) -> void:
 if toast_time>0:
  toast_time-=delta
  if toast_time<=0 and is_instance_valid(toast):toast.queue_free()

func city_object(object: Dictionary) -> void:
 if object.kind=="investor":funding.show_investors()
 elif object.kind=="rival":global_screens.show_competitors()
 elif object.kind=="office" and Game.company().office.rented:navigate("office")
 else:business.show_property()

func office_cell(x: int, y: int) -> void:
 if world.tool=="room":perform(func():return Game.build_room(world.tool_type,x,y,world.floor_id),Callable(),"build")
 elif world.tool=="furniture":perform(func():return Game.buy_furniture(world.tool_type,x,y,world.floor_id,business.rotated),Callable(),"build")
 elif world.tool in ["wall","door","cover","remove"]:perform(func():return Game.alter_building(world.tool,x,y,world.floor_id),Callable(),"build")
 else:
  var r=OfficeSim.room_at(Game.company(),x,y,world.floor_id)
  if not r.is_empty():show_toast(Catalog.ROOM_DEFS[int(r.type)].name+" · «Строить» для обустройства","info")

func capture_designs() -> void:
 await get_tree().process_frame
 await wizard.capture_all()
