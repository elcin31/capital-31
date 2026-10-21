class_name BusinessScreens
extends RefCounted

var ui: Control
var rotated: bool=false
var product_name: String="Nexa AI"
var product_price: String="49"
var product_quality: int=75
var product_audience: int=1
var product_budget: int=1
var product_kind: int=0
var build_page: int=0

func _init(host: Control) -> void:ui=host

func show_property() -> void:
 var c=Game.company();var city=Catalog.CITIES[int(c.city)]
 var col=ui.open_panel("Riverside · Пространство для вашей компании",840)
 UI.label(col,city.name+" · Деловой квартал",24,UI.BLUE,true)
 UI.text(col,"Светлый офис с панорамными окнами. До 4 этажей, 16×12 клеток на этаж. Планировку, комнаты и оборудование вы создаёте сами.",18,UI.TEXT)
 UI.pair(col,"Аренда / месяц / этаж",Catalog.money(city.rent))
 UI.pair(col,"Возвратный депозит: 2 месяца",Catalog.money(city.rent*2))
 UI.pair(col,"Выкуп здания",Catalog.money(city.rent*90))
 UI.text(col,"Зарплаты и аренда начисляются каждый день и оплачиваются раз в 30 дней. Депозит — актив, а не расход.",15)
 var r=UI.row(col)
 if not c.office.rented:UI.button(r,"Арендовать офис",func():ui.perform(Game.rent_office,func():ui.navigate("office"),"build"),true)
 else:UI.button(r,"Войти в офис",func():ui.navigate("office"),true)
 UI.button(r,"Купить недвижимость",func():ui.perform(func():return Game.finance_action("property"),show_property,"build"))
 if c.office.rented:UI.button(col,"Арендовать дополнительный этаж",func():ui.perform(Game.add_floor,show_property,"build"))

func show_build() -> void:
 if not Game.company().office.rented:show_property();return
 ui.navigate("office")
 var col=ui.open_panel("Обустройство офиса · этаж %d"%(ui.world.floor_id+1),1000)
 var tabs=UI.row(col)
 UI.button(tabs,"Помещения",func():build_page=0;show_build(),build_page==0)
 UI.button(tabs,"Мебель и оборудование",func():build_page=1;show_build(),build_page==1)
 UI.button(tabs,"Стены / двери / покрытие",func():build_page=2;show_build(),build_page==2)
 UI.text(col,"Выберите объект, затем нажмите на сетку офиса. Комната занимает 4×4 клетки. Оставьте проход слева от двери. Начать удобно с клетки (1, 1).",15)
 var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);col.add_child(grid)
 if build_page==0:
  for i in range(Catalog.ROOM_DEFS.size()):
   var d=Catalog.ROOM_DEFS[i]
   if d.industry>=0 and int(d.industry)!=int(Game.company().industry):continue
   var box=UI.card(grid,Color(d.color).lightened(0.6));box.custom_minimum_size.x=272
   UI.label(box,d.name,16,UI.TEXT,true)
   UI.button(box,Catalog.money(d.cost)+" · Разместить",func():choose_tool("room",i,d.name))
 elif build_page==1:
  for i in range(Catalog.FURNITURE.size()):
   var d=Catalog.FURNITURE[i];var box=UI.card(grid)
   box.custom_minimum_size.x=272;UI.label(box,d.name,16,UI.TEXT,true)
   UI.label(box,"Размер %d×%d"%[d.w,d.h],12,UI.MUTED)
   UI.button(box,Catalog.money(d.cost)+" · Купить",func():choose_tool("furniture",i,d.name))
  UI.button(col,"Ориентация: "+("повёрнута" if rotated else "обычная"),func():rotated=not rotated;show_build())
 else:
  for item in [["wall","Внутренняя стена"],["door","Перенести дверь"],["cover","Сменить пол · €150"],["remove","Продать предмет / убрать стену"]]:
   UI.button(col,item[1],func():choose_tool(item[0],0,item[1]))
 UI.button(col,"Добавить этаж · ещё один депозит",func():ui.perform(Game.add_floor,show_build,"build"))

func choose_tool(tool: String, type: int, title: String) -> void:
 ui.close_panel();ui.world.tool=tool;ui.world.tool_type=type
 ui.show_toast(title+" · Нажмите на нужную клетку. Back — завершить.","info")

func show_employees() -> void:
 var col=ui.open_panel("Команда · Люди, которые создают компанию",1120)
 var c=Game.company()
 var metrics=UI.row(col)
 UI.metric(metrics,"В КОМАНДЕ",str(c.employees.size()))
 UI.metric(metrics,"ДОСТУПНЫЕ РАБОЧИЕ МЕСТА",str(OfficeSim.stations(c).size()),UI.BLUE)
 var wages: int=0
 for e in c.employees:wages+=int(e.wage)*30
 UI.metric(metrics,"ФОНД ОПЛАТЫ / 30 ДНЕЙ",Catalog.money(wages))
 UI.text(col,"Автоназначение распределяет труд между активными проектами. Работники приходят в 08:00, делают перерыв в 12:00 и уходят в 18:00.",14)
 UI.label(col,"ВАША КОМАНДА",14,UI.BLUE,true)
 if c.employees.is_empty():UI.text(col,"Команда ещё не собрана. Пригласите первого специалиста ниже.",17,UI.TEXT)
 for i in range(c.employees.size()):
  var e=c.employees[i];var box=UI.card(col);var row=UI.row(box)
  UI.portrait(row,e.appearance,Vector2(75,90))
  var info=UI.column(row)
  UI.label(info,e.name+" · "+Catalog.ROLES[int(e.role)],18,UI.TEXT,true)
  var status=UI.label(info,"",14,UI.MUTED)
  ui.bind_text(status,func():return "%s · Навык %.0f · Усталость %.0f%% · Настроение %.0f%% · Мотивация %.0f%% · Эфф. %.0f%%"%[e.status,e.skill,e.fatigue,e.satisfaction,float(e.get("motivation",80)),e.efficiency*100])
  UI.label(info,Catalog.money(e.wage*30)+" / месяц",14,UI.BLUE,true)
  var actions=UI.row(info)
  UI.button(actions,"Обучить · €500",func():ui.perform(func():return Game.employee_action(i,"train"),show_employees))
  UI.button(actions,"Зарплата +10%",func():ui.perform(func():return Game.employee_action(i,"raise"),show_employees))
  UI.button(actions,"Повысить",func():ui.perform(func():return Game.employee_action(i,"promote"),show_employees))
  UI.button(actions,"Уволить",func():ui.global_screens.confirm("Уволить "+e.name+"? Выходное пособие: "+Catalog.money(e.wage*7),func():ui.perform(func():return Game.employee_action(i,"fire"),show_employees)))
  var assignments=UI.row(box)
  var task_names: Array=["Автоназначение"]
  var selected: int=0
  for p in c.products:
   task_names.append(p.name)
   if int(e.task)==int(p.id):selected=task_names.size()-1
  UI.option(UI.column(assignments),"Задача",task_names,selected,func(n):ui.perform(func():return Game.employee_action(i,"task",-1 if n==0 else int(c.products[n-1].id))))
  UI.option(UI.column(assignments),"Должность",Catalog.ROLES,int(e.role),func(n):ui.perform(func():return Game.employee_action(i,"role",n)))
 UI.label(col,"КАНДИДАТЫ · зарплатные ожидания зависят от города и рынка",14,UI.BLUE,true)
 for candidate in Game.candidates():
  var box=UI.card(col);var row=UI.row(box)
  UI.portrait(row,candidate.appearance,Vector2(68,78))
  var info=UI.column(row)
  UI.label(info,candidate.name+" · "+Catalog.ROLES[int(candidate.role)],17,UI.TEXT,true)
  UI.label(info,"Навык %.0f · %s / месяц"%[candidate.skill,Catalog.money(candidate.wage*30)],14,UI.MUTED)
  UI.button(row,"Пригласить в команду",func():ui.perform(func():return Game.hire(candidate),show_employees,"level"),true)

func show_products() -> void:
 var col=ui.open_panel("Продукты · От идеи до первых клиентов",1100)
 UI.button(col,"+  Новый продукт / направление",show_product_form,true)
 var c=Game.company()
 if c.products.is_empty():UI.text(col,"Первый продукт станет началом вашей истории. Команда, рабочие места и бюджет определяют скорость разработки.",18,UI.TEXT)
 for i in range(c.products.size()):
  var p=c.products[i];var box=UI.card(col)
  UI.label(box,p.name,23,UI.TEXT,true)
  ui.bind_text(UI.label(box,"",15,UI.BLUE,true),func():return p.stage+" · %.0f%%"%(p.progress/maxf(1,p.required)*100))
  var progress=UI.progress(box,p.progress/maxf(1,p.required)*100)
  ui.bind_value(progress,func():return p.progress/maxf(1,p.required)*100)
  var row=UI.row(box)
  ui.bind_text(UI.metric(row,"КЛИЕНТЫ",""),func():return str(int(p.customers)))
  ui.bind_text(UI.metric(row,"ВЫРУЧКА / ДЕНЬ","",UI.GREEN),func():return Catalog.money(p.daily_revenue))
  ui.bind_text(UI.metric(row,"КАЧЕСТВО",""),func():return "%.0f / 100"%p.quality)
  UI.metric(row,"СООТВЕТСТВИЕ РЫНКУ","%.0f%%"%p.fit)
  ui.bind_text(UI.label(box,"",14,UI.MUTED),func():return "Известность %.0f%% · Удовлетворённость %.0f%% · Инновации %.0f%%"%[p.awareness,p.satisfaction,p.innovation])
  var actions=UI.row(box)
  var launch=UI.button(actions,"Выпустить",func():ui.perform(func():return Game.product_action(i,"launch"),show_products,"product"),true)
  ui.bind_value(launch,func():return p.stage!="Готов к выпуску","disabled")
  UI.button(actions,"Обновить · €1 500",func():ui.perform(func():return Game.product_action(i,"update"),show_products))
  UI.button(actions,"Реклама · €1 200",func():ui.perform(func():return Game.product_action(i,"campaign"),show_products))
  var price=LineEdit.new();price.text=str(int(p.price)/100);price.custom_minimum_size=Vector2(90,44);actions.add_child(price)
  UI.button(actions,"Цена €",func():
   if not price.text.is_valid_int():ui.show_toast("Введите целую цену в евро","warning");return
   ui.perform(func():return Game.product_action(i,"price",int(price.text)*100),show_products))
  if c.industry!=0:
   ui.bind_text(UI.label(box,"",16,UI.TEXT,true),func():return "На складе: %d · Сырьё: %d · Продано сегодня: %d"%[p.stock,p.materials,p.sales])
   var supplies=UI.row(box)
   UI.button(supplies,"Закупить 50 ед.",func():ui.perform(func():return Game.product_action(i,"supply"),show_products,"build"))
   UI.button(supplies,"Автозакупка: "+("ВКЛ" if p.auto_supply else "ВЫКЛ"),func():ui.perform(func():return Game.product_action(i,"auto"),show_products))
  UI.button(box,"Прекратить продажи",func():ui.global_screens.confirm("Снять "+p.name+" с продажи?",func():ui.perform(func():return Game.product_action(i,"stop"),show_products)))

func show_product_form() -> void:
 var col=ui.open_panel("Новый продукт · План разработки",860)
 UI.field(col,"Название",product_name,func(s):product_name=s)
 UI.option(col,"Направление",Catalog.MODELS[int(Game.company().industry)],product_kind,func(n):product_kind=n)
 UI.option(col,"Целевая аудитория",["Массовый рынок","Малый бизнес","Корпорации"],product_audience,func(n):product_audience=n)
 UI.field(col,"Цена в евро",product_price,func(s):product_price=s)
 UI.option(col,"Приоритет качества",["Быстрый запуск · 50","Сбалансированный · 75","Премиум · 95"],[50,75,95].find(product_quality),func(n):product_quality=[50,75,95][n])
 UI.option(col,"Исследовательский бюджет",["€1 000","€2 500","€5 000"],product_budget,func(n):product_budget=n)
 UI.text(col,"Объём работы: %d ч. при эффективности 1.0. Дополнительная команда ускоряет работу. Слабое оборудование и усталость замедляют её."%(100+product_quality),16,UI.TEXT)
 UI.button(col,"Начать разработку",func():
  if product_name.strip_edges().is_empty() or not product_price.is_valid_int():ui.show_toast("Введите название и целую цену","warning");return
  ui.perform(func():return Game.start_product(product_name,int(product_price)*100,product_quality,product_audience,[100000,250000,500000][product_budget],product_kind),show_products,"build"),true)
