class_name WorldScreens
extends RefCounted

var ui: Control
var branch_city: int=1
var previous_speed: int=0

func _init(host: Control) -> void:ui=host

func show_pause() -> void:
 previous_speed=Game.speed;Game.speed=0
 var col=ui.open_panel("CAPITAL · Меню игры",650)
 UI.button(col,"Продолжить",func():Game.speed=previous_speed;ui.close_panel(),true)
 UI.button(col,"Сохранить / загрузить",show_saves)
 UI.button(col,"Настройки",show_settings)
 UI.button(col,"Как играть",show_help)
 UI.button(col,"Карьера основателя",show_career)
 UI.button(col,"Главное меню",func():
  Game.save_slot(0);ui.wizard.show_menu())

func show_help() -> void:
 var col=ui.open_panel("Ваш путь от идеи до империи",900)
 for item in [
 "1. Город → Доступные офисы → Арендовать. Депозит не становится расходом.",
 "2. Офис → Строить → помещение. Нажмите на сетку: первый блок удобно поставить в (1, 1). Дверь находится слева, оставьте проход.",
 "3. Купите рабочее место внутри комнаты. Для IT подойдёт «Разработка»; для торговли нужны касса и стеллаж; для производства — цех, линия и сырьевой склад.",
 "4. Наймите профильного сотрудника в «Команде». Автоназначение уже включено.",
 "5. Создайте продукт. Запустите время ×5 или ×10. Готовый продукт нужно выпустить отдельной кнопкой.",
 "6. Рознице и производству нужны запасы. Купите сырьё / товары и включите автозакупку.",
 "7. Смотрите P&L, баланс и Cash Flow. Зарплаты и аренда оплачиваются каждые 30 дней, покупатели закрывают счета через 7 дней.",
 "8. Инвесторы → запрос → встреча. Аргументы учитывают реальные результаты. Принятие сделки меняет деньги и доли.",
 "9. «Мир» позволяет открыть филиал и переключиться на него. Основатель сохраняет навыки даже после потери бизнеса.",
 "Управление: палец — камера, касание — объект, два пальца — масштаб. Кнопка Ⅱ — пауза. Back закрывает окно или режим строительства."]:
  UI.text(UI.card(col),item,17,UI.TEXT)

func show_settings() -> void:
 var col=ui.open_panel("Настройки · Комфортная игра",680)
 UI.option(col,"Звук",["Включён","Выключен"],0 if Game.settings.sound else 1,func(n):Game.set_option("sound",n==0))
 UI.option(col,"Анимации и плотность движения",["Экономный режим","Полная детализация"],int(Game.settings.quality),func(n):Game.set_option("quality",n))
 UI.option(col,"Частота кадров",["30 FPS","60 FPS"],0 if Game.settings.fps==30 else 1,func(n):Game.set_option("fps",30 if n==0 else 60))
 UI.text(col,"Изменения сохраняются на устройстве. Скорость экономики не зависит от частоты кадров. Игра работает без сети.",16)
 UI.label(col,"CAPITAL 1.0 · Godot 4.6.3 · Android",14,UI.BLUE,true)

func show_saves() -> void:
 var col=ui.open_panel("Локальные сохранения",950)
 UI.text(col,"Автосохранение — каждые 5 игровых дней и при сворачивании. Каждый слот имеет проверку целостности и резервную копию.",15)
 for slot_data in SaveStore.slots():
  var slot=int(slot_data.slot);var box=UI.card(col);var row=UI.row(box)
  var info=UI.column(row)
  UI.label(info,"Автосохранение" if slot==0 else "Слот %d"%slot,18,UI.BLUE,true)
  UI.label(info,slot_data.company+" · День %d"%(int(slot_data.day)+1) if slot_data.valid else "Пустой слот",15,UI.TEXT)
  var save=UI.button(row,"Записать",func():
   if slot_data.valid:confirm("Перезаписать этот слот?",func():ui.perform(func():return Game.save_slot(slot),show_saves))
   else:ui.perform(func():return Game.save_slot(slot),show_saves))
  save.disabled=Game.state.is_empty()
  var load_button=UI.button(row,"Загрузить",func():ui.perform(func():return Game.load_slot(slot),ui.enter_game),true);load_button.disabled=not slot_data.valid
  UI.button(row,"Удалить",func():confirm("Удалить сохранение и резервную копию?",func():SaveStore.delete_slot(slot);show_saves()))

func confirm(text: String, action: Callable) -> void:
 var col=ui.open_panel("Подтверждение",650)
 UI.text(col,text,20,UI.TEXT)
 UI.button(col,"Подтвердить",action,true);UI.button(col,"Отмена",ui.close_panel)

func show_world() -> void:
 var col=ui.open_panel("Мир · Международная группа",1120)
 var map=WorldMap.new();col.add_child(map);map.city_selected.connect(func(id):branch_city=id;show_world())
 var row=UI.row(col)
 UI.option(UI.column(row),"Новый рынок",Catalog.CITIES.map(func(c):return c.name),branch_city,func(n):branch_city=n)
 UI.button(row,"Открыть филиал · €40 000",func():ui.perform(func():return Game.open_branch(branch_city),show_world,"level"),true)
 var cash: int=0;var rev: int=0;var profit: int=0;var debt: int=0
 for c in Game.state.companies:
  var l=Ledger.new(c.ledger);var r=l.report(maxi(0,Game.day()-29))
  cash+=int(l.accounts.cash);rev+=int(r.revenue);profit+=int(r.net);debt+=int(l.accounts.debt)
  for entry in l.journal:
   if entry.memo=="Внутригрупповые дивиденды" and int(entry.day)>=maxi(0,Game.day()-29):rev-=int(entry.cash);profit-=int(entry.cash)
   if entry.memo=="Возврат капитала филиала" and int(entry.day)>=maxi(0,Game.day()-29):
    rev-=int(entry.pl.get("revenue",0))
    profit-=int(entry.pl.get("revenue",0))-int(entry.pl.get("maintenance",0))
 var summary=UI.row(col)
 UI.metric(summary,"ДЕНЬГИ ГРУППЫ",Catalog.money(cash),UI.BLUE)
 UI.metric(summary,"ВЫРУЧКА / 30 ДН.",Catalog.money(rev))
 UI.metric(summary,"ПРИБЫЛЬ / 30 ДН.",Catalog.money(profit),UI.GREEN)
 UI.metric(summary,"ВНЕШНИЙ ДОЛГ",Catalog.money(debt))
 UI.text(col,"Внутренний взнос в филиал переносит деньги внутри группы и не признаётся её выручкой или прибылью.",13)
 for i in range(Game.state.companies.size()):
  var c=Game.state.companies[i];var box=UI.card(col);var r=UI.row(box)
  var info=UI.column(r)
  UI.label(info,c.name,18,UI.TEXT,true);UI.label(info,Catalog.CITIES[int(c.city)].name+" · "+c.status,14,UI.MUTED)
  UI.button(r,"Управлять компанией",func():Game.state.current=i;ui.world.floor_id=0;ui.enter_game();ui.world.center_camera(),i==int(Game.state.current))

func show_competitors() -> void:
 var col=ui.open_panel("Рынок · Автономные компании",1120)
 UI.text(col,"Компании принимают решения каждые 7 дней, меняют цены и персонал, создают продукты и могут потерять платёжеспособность. Их привлекательность уменьшает доступный вам спрос.",15)
 for rival in Game.state.world.competitors:
  var box=UI.card(col);var row=UI.row(box);var info=UI.column(row)
  UI.label(info,rival.name+" · "+Catalog.CITIES[int(rival.city)].name,20,UI.TEXT,true)
  UI.label(info,Catalog.INDUSTRIES[int(rival.industry)]+" · "+rival.status,13,UI.BLUE)
  UI.text(info,"Команда %d · Продуктов %d · Цена %s · Качество %.0f\nВыручка / день %s · Прибыль %s · Денежные средства %s\nПоследнее решение: %s"%[rival.staff,rival.products,Catalog.money(rival.price),rival.quality,Catalog.money(rival.revenue),Catalog.money(rival.profit),Catalog.money(rival.cash),rival.decision],14,UI.TEXT)
  UI.label(row,"%.1f%%"%(rival.share*100),27,UI.BLUE,true)
  if rival.active:
   var price=maxi(3000000,int(rival.cash-rival.debt+rival.revenue*12))
   UI.button(box,"Приобрести · "+Catalog.money(price),func():confirm("Приобрести "+rival.name+" за "+Catalog.money(price)+"? Будет создана дочерняя компания.",func():ui.perform(func():return Game.acquire_rival(int(rival.id)),show_competitors,"deal")))

func show_economy() -> void:
 var col=ui.open_panel("Экономика · Возможности и риски",850)
 var w=Game.state.world;var ev=Catalog.EVENTS[int(w.event)]
 UI.label(col,ev.name,28,UI.BLUE,true);UI.text(col,ev.text,19,UI.TEXT)
 UI.pair(col,"Множитель спроса","%.2f×"%w.demand)
 UI.pair(col,"Ожидания зарплат","%.2f×"%w.wages)
 UI.pair(col,"Стоимость поставок","%.2f×"%w.supply)
 UI.pair(col,"Надбавка к плавающей ставке","+%.1f п.п."%(w.rate*100))
 UI.pair(col,"Следующий пересмотр","День %d"%(int(w.next_event)+1))
 UI.button(col,"Открыть ленту событий",show_news)

func show_news() -> void:
 var col=ui.open_panel("Новости · Живой экономический мир",950)
 UI.button(col,"Показатели текущего цикла",show_economy)
 for item in Game.state.news:
  var box=UI.card(col)
  UI.label(box,"День %d · %s"%[int(item.day)+1,item.title],19,UI.BLUE,true)
  UI.text(box,item.text,16,UI.TEXT)

func show_career() -> void:
 var col=ui.open_panel("Основатель · Карьера продолжается",1000)
 var f=Game.state.founder;var row=UI.row(col)
 UI.portrait(row,f.appearance,Vector2(215,240))
 var info=UI.column(row);UI.label(info,f.first+" "+f.last,28,UI.TEXT,true)
 UI.pair(info,"Личные деньги",Catalog.money(f.personal),UI.GREEN)
 UI.pair(info,"Основано компаний",str(f.career.size()))
 for i in range(Catalog.SKILLS.size()):
  UI.pair(info,Catalog.SKILLS[i],"%.1f / 100"%float(f.skills[i]))
 UI.label(col,"ДОСТИЖЕНИЯ",14,UI.BLUE,true)
 var titles=["Первый офис","Первая команда","От идеи к продукту","100 клиентов","Операционная прибыль","Первый инвестор","Новый филиал","Миллион в год","Через экономический цикл","Первая выручка"]
 for i in range(titles.size()):UI.label(col,("✓  " if str(i) in Game.state.achievements else "○  ")+titles[i],16,UI.GREEN if str(i) in Game.state.achievements else UI.MUTED)
 UI.label(col,"ИСТОРИЯ ПРЕДПРИНИМАТЕЛЯ",14,UI.BLUE,true)
 for item in f.career:UI.text(col,"День %d · %s"%[int(item.day)+1,item.text],15,UI.TEXT)
 UI.button(col,"Основать ещё одну компанию",func():ui.wizard.career_mode=true;ui.wizard.show_city(),true)
 UI.button(col,"Финансовые трудности / банкротство",show_bankruptcy)

func show_bankruptcy() -> void:
 var col=ui.open_panel("Ликвидность · Второй шанс",900)
 var c=Game.company();var a=Game.ledger().accounts
 UI.label(col,c.name+" · "+c.status,25,UI.BLUE,true)
 UI.pair(col,"Денежный остаток",Catalog.money(a.cash))
 UI.pair(col,"Долги и счета",Catalog.money(a.debt+a.ap+a.tax_payable))
 UI.pair(col,"Дней отрицательной ликвидности",str(int(c.insolvent_days))+" / 10")
 UI.text(col,"После 10 дней отрицательного остатка начинается банкротство. Можно вложить личный капитал, продать оборудование в офисе или договориться о списании 10% банковского долга ценой репутации и повышенной ставки.",17,UI.TEXT)
 UI.button(col,"Открыть финансовые операции",func():ui.finances.page=5;ui.finances.show_finance())
 UI.button(col,"Предложить реструктуризацию",func():ui.perform(func():return Game.finance_action("restructure"),show_bankruptcy,"deal"))
 UI.button(col,"Продать оборудование в офисе",func():ui.navigate("office");ui.business.choose_tool("remove",0,"Продажа оборудования"))
 UI.button(col,"Ликвидировать компанию",func():confirm("Активы будут проданы с дисконтом, кредиторы получат доступные средства. Остаток распределяется владельцам. Карьера основателя сохранится.",func():ui.perform(func():return Game.finance_action("liquidate"),show_career,"warning")))
 UI.button(col,"Начать новый бизнес тем же основателем",func():ui.wizard.career_mode=true;ui.wizard.show_city(),true)
