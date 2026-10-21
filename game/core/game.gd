extends Node

signal updated
signal message(text: String, kind: String)
signal office_changed

var state: Dictionary = {}
var speed: int = 0
var accumulator: float = 0.0
var settings: Dictionary = {"sound":true,"quality":1,"fps":30}
var last_autosave: int = -1

func _ready() -> void:
 get_tree().auto_accept_quit=false
 var cfg=ConfigFile.new()
 if cfg.load("user://settings.cfg")==OK:
  for k in settings: settings[k]=cfg.get_value("options",k,settings[k])
 Engine.max_fps=int(settings.fps)

func _process(delta: float) -> void:
 if state.is_empty() or speed==0: return
 advance_time(delta)

func advance_time(delta: float) -> void:
 accumulator+=delta*float(speed)*0.5
 var changed=false
 var budget: int=0
 while accumulator>=1.0 and budget<120:
  accumulator-=1.0
  Economy.hour(state)
  changed=true; budget+=1
 if changed:
  updated.emit()
  var day=int(state.hour)/24
  if day>0 and day%5==0 and day!=last_autosave:
   last_autosave=day
   SaveStore.save_game(state,0)

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_PAUSED:
  if not state.is_empty(): SaveStore.save_game(state,0)
  speed=0
 if what==NOTIFICATION_WM_CLOSE_REQUEST:
  if not state.is_empty(): SaveStore.save_game(state,0)
  get_tree().quit()

func set_option(key: String, value: Variant) -> void:
 settings[key]=value
 Engine.max_fps=int(settings.fps)
 var cfg=ConfigFile.new()
 for k in settings: cfg.set_value("options",k,settings[k])
 cfg.save("user://settings.cfg")

func company() -> Dictionary:
 if state.is_empty() or state.companies.is_empty(): return {}
 return state.companies[clampi(int(state.current),0,state.companies.size()-1)]

func ledger() -> Ledger:
 return Ledger.new(company().get("ledger",{}))

func day() -> int:
 return int(state.get("hour",9))/24

func start_game(founder: Dictionary, city_id: int, name_text: String, industry: int, capital: int, model: int, seed_value: int = 310031) -> void:
 state={"version":1,"hour":9,"current":0,"founder":founder.duplicate(true),"companies":[],"world":Economy.world_start(seed_value),"news":[],"investor_memory":{},"achievements":[]}
 state.founder.personal=30000000
 state.founder.career=[]
 state.founder.skills=[35.0,35.0,35.0,35.0,35.0,35.0,30.0]
 var bio=int(founder.get("bio",0))
 state.founder.skills[[3,1,4,2][bio]]+=15.0
 register_company(city_id,name_text,industry,capital,model)
 speed=0
 accumulator=0
 last_autosave=-1
 Economy.notify(state,"Добро пожаловать в CAPITAL","Арендуйте офис на карте, постройте комнату и наймите команду. Время стоит на паузе.","success")
 updated.emit()

func make_company(city_id: int, name_text: String, industry: int, capital: int, model: int, parent: int = -1) -> Dictionary:
 var l=Ledger.new()
 l.post(day(),"Взнос в капитал",{"cash":capital,"capital":capital},"financing")
 return {"id":state.companies.size(),"name":name_text,"logo":industry,"industry":industry,"city":city_id,"model":model,"parent":parent,"status":"Работает","day":day(),"ledger":l.export_data(),"office":{"rented":false,"owned":false,"floors":1,"rooms":[],"furniture":[],"walls":[],"next_room":0,"next_furniture":0},"employees":[],"products":[],"next_employee":0,"next_product":0,"cap_table":[{"id":"founder","name":state.founder.first+" "+state.founder.last,"share":1.0}],"rounds":[],"negotiation":{},"receivables":[],"history":[],"marketing":0,"founder_salary":0,"loan":{"rate":Catalog.CITIES[city_id].rate,"floating":true},"insolvent_days":0,"daily_depreciation":0}

func register_company(city_id: int, name_text: String, industry: int, capital: int, model: int) -> String:
 if capital<=0 or capital>int(state.founder.personal): return "Недостаточно личного капитала"
 state.founder.personal-=capital
 state.companies.append(make_company(city_id,name_text,industry,capital,model))
 state.current=state.companies.size()-1
 state.founder.career.append({"day":day(),"text":"Основана "+name_text+" · "+Catalog.CITIES[city_id].name})
 updated.emit()
 return ""

func commit_ledger(l: Ledger) -> void:
 company().ledger=l.export_data()
 updated.emit()

func rent_office() -> String:
 var c=company()
 if c.office.rented: return "Офис уже арендован"
 var cost=int(Catalog.CITIES[int(c.city)].rent)*2
 var l=ledger()
 if l.accounts.cash<cost: return "Недостаточно денег на депозит"
 l.post(day(),"Возвратный депозит аренды",{"cash":-cost,"deposit":cost},"investing")
 c.office.rented=true
 commit_ledger(l)
 Economy.notify(state,"Ваш первый офис","Этаж открыт. Войдите внутрь и постройте рабочее помещение.","success")
 office_changed.emit()
 return ""

func build_room(type: int, x: int, y: int, floor_id: int) -> String:
 var l=ledger()
 var cost=int(Catalog.ROOM_DEFS[type].cost)
 if l.accounts.cash<cost: return "Недостаточно средств"
 var error=OfficeSim.add_room(company(),type,x,y,floor_id)
 if not error.is_empty(): return error
 l.post(day(),"Строительство: "+Catalog.ROOM_DEFS[type].name,{"cash":-cost,"equipment":cost},"investing")
 company().daily_depreciation+=maxi(1,cost/1080)
 commit_ledger(l)
 office_changed.emit()
 return ""

func buy_furniture(type: int, x: int, y: int, floor_id: int, rotated: bool = false) -> String:
 var l=ledger()
 var cost=int(Catalog.FURNITURE[type].cost)
 if l.accounts.cash<cost: return "Недостаточно средств"
 var error=OfficeSim.add_furniture(company(),type,x,y,floor_id,rotated)
 if not error.is_empty(): return error
 l.post(day(),"Оборудование: "+Catalog.FURNITURE[type].name,{"cash":-cost,"equipment":cost},"investing")
 company().daily_depreciation+=maxi(1,cost/1080)
 commit_ledger(l)
 office_changed.emit()
 return ""

func alter_building(tool: String, x: int, y: int, floor_id: int) -> String:
 var c=company()
 var r=OfficeSim.room_at(c,x,y,floor_id)
 if tool=="cover":
  if r.is_empty(): return "Выберите комнату"
  var l=ledger()
  if l.accounts.cash<15000: return "Недостаточно средств"
  r.cover=(int(r.get("cover",0))+1)%3
  l.expense(day(),"Новое покрытие пола",15000,"maintenance")
  commit_ledger(l)
 elif tool=="door":
  if r.is_empty() or (x!=int(r.x) and x!=int(r.x+r.w-1) and y!=int(r.y) and y!=int(r.y+r.h-1)): return "Выберите край помещения"
  if OfficeSim.occupied(c,x,y,floor_id): return "Освободите место для двери"
  var old=[r.door_x,r.door_y]
  r.door_x=x; r.door_y=y
  if OfficeSim.path(c,Vector2i(0,6),Vector2i(x,y),floor_id).is_empty(): r.door_x=old[0]; r.door_y=old[1]; return "К двери нет доступа"
 elif tool=="wall":
  if x<1 or y<1 or x>=15 or y>=11 or OfficeSim.occupied(c,x,y,floor_id): return "Место занято"
  var wall={"x":x,"y":y,"floor":floor_id}
  var before=OfficeSim.stations(c).size()
  c.office.walls.append(wall)
  if OfficeSim.stations(c).size()<before: c.office.walls.erase(wall); return "Стена блокирует рабочее место"
 elif tool=="remove":
  var found=false
  for f in c.office.furniture.duplicate():
   if int(f.floor)==floor_id and int(f.x)==x and int(f.y)==y:
    var l=ledger()
    var def=Catalog.FURNITURE[int(f.type)]
    var original=mini(int(def.cost),int(l.accounts.equipment))
    var dep=int(float(original)*float(-l.accounts.depreciation)/maxi(1,int(l.accounts.equipment)))
    var book=original-dep
    var sale=int(book*0.6)
    l.post(day(),"Продажа оборудования",{"cash":sale,"equipment":-original,"depreciation":dep,"earnings":sale-book},"investing",{"maintenance":book-sale})
    c.office.furniture.erase(f)
    c.daily_depreciation=maxi(0,int(c.daily_depreciation)-int(def.cost)/1080)
    commit_ledger(l); found=true; break
  if not found:
   for wall in c.office.walls.duplicate():
    if int(wall.floor)==floor_id and int(wall.x)==x and int(wall.y)==y: c.office.walls.erase(wall); found=true; break
  if not found: return "Нажмите на предмет или стену"
 office_changed.emit(); updated.emit()
 return ""

func add_floor() -> String:
 if not company().office.rented: return "Сначала арендуйте офис"
 if company().office.floors>=4: return "Доступно максимум 4 этажа"
 var l=ledger()
 var cost=int(Catalog.CITIES[int(company().city)].rent)*2
 if l.accounts.cash<cost: return "Недостаточно средств"
 l.post(day(),"Депозит за дополнительный этаж",{"cash":-cost,"deposit":cost},"investing")
 company().office.floors+=1
 commit_ledger(l); office_changed.emit()
 return ""

func hire(candidate: Dictionary) -> String:
 if not company().office.rented: return "Нужен арендованный офис"
 if company().employees.size()>=40: return "Лимит команды: 40 сотрудников"
 var e=candidate.duplicate(true)
 e.id=company().next_employee
 company().next_employee+=1
 e.task=-1; e.fatigue=0.0; e.satisfaction=80.0; e.efficiency=0.0; e.experience=0.0; e.status="Идёт в офис"; e.x=0; e.y=6; e.floor=0; e.route=[]; e.start=8; e.end=18
 company().employees.append(e)
 updated.emit(); office_changed.emit()
 return ""

func candidates() -> Array:
 var result: Array=[]
 for i in range(6):
  var n=(day()*5+i*7+int(state.world.seed))%24
  var role=[0,4,6][int(company().industry)] if i<3 else [1,2,8][i-3]
  var skill=40.0+((n*13+i*7)%45)*Catalog.CITIES[int(company().city)].talent
  result.append({"name":Catalog.FIRST_NAMES[n]+" "+Catalog.LAST_NAMES[(n+i)%12],"role":role,"wage":int(Catalog.CITIES[int(company().city)].wage*state.world.wages*(0.7+skill/100.0)),"skill":minf(95,skill),"appearance":Catalog.appearance(n)})
 return result

func employee_action(index: int, action: String, value: int = -1) -> String:
 var c=company()
 if index<0 or index>=c.employees.size(): return "Сотрудник не найден"
 var e=c.employees[index]
 var l=ledger()
 if action=="fire":
  var severance=int(e.wage)*7
  if l.accounts.cash<severance: return "Нужно оплатить выходное пособие"
  l.expense(day(),"Выходное пособие: "+e.name,severance,"wages")
  c.employees.remove_at(index)
 elif action=="raise": e.wage=int(e.wage*1.10); e.satisfaction=minf(100,e.satisfaction+12)
 elif action=="train":
  if l.accounts.cash<50000: return "Обучение стоит €500"
  l.expense(day(),"Обучение: "+e.name,50000,"research"); e.skill=minf(100,e.skill+5)
 elif action=="promote": e.wage=int(e.wage*1.15); e.skill=minf(100,e.skill+3); e.satisfaction=minf(100,e.satisfaction+8)
 elif action=="task": e.task=value
 elif action=="role": e.role=value
 commit_ledger(l)
 return ""

func start_product(name_text: String, price: int, quality: int, audience: int, budget: int, kind: int) -> String:
 var c=company()
 if not c.office.rented or c.employees.is_empty(): return "Нужны офис и сотрудник"
 if OfficeSim.stations(c).is_empty(): return "Купите доступное рабочее место"
 if c.industry==1 and OfficeSim.bonus(c,["checkout"])<1: return "Нужен кассовый терминал в торговом зале"
 if c.industry==2 and OfficeSim.bonus(c,["machine"])<1: return "Нужна сборочная линия в цехе"
 var l=ledger()
 if l.accounts.cash<budget: return "Недостаточно денег на стартовый бюджет"
 l.expense(day(),"Разработка: "+name_text,budget,"research")
 var skills: float=0
 for e in c.employees: skills+=e.skill
 skills/=maxi(1,c.employees.size())
 c.products.append({"id":c.next_product,"name":name_text,"kind":kind,"audience":audience,"price":maxi(500,price),"quality":clampf(quality*0.45+skills*0.4+state.founder.skills[3]*0.15,15,98),"innovation":clampf(40+budget/20000.0,20,95),"fit":65.0+audience*5,"awareness":18.0,"satisfaction":50.0,"stage":"Исследование","progress":0.0,"required":100.0+quality*1.0,"customers":0,"revenue":0,"daily_revenue":0,"sales":0,"stock":0,"materials":0,"unit_cost":0,"auto_supply":false,"age":0})
 c.next_product+=1
 commit_ledger(l)
 return ""

func product_action(index: int, action: String, value: int = 0) -> String:
 var c=company()
 if index<0 or index>=c.products.size(): return "Продукт не найден"
 var p=c.products[index]
 var l=ledger()
 match action:
  "launch":
   if p.stage!="Готов к выпуску": return "Продукт ещё не готов"
   p.stage="Поддержка"; p.age=0
   Economy.notify(state,"Старт продаж",p.name+" вышел на рынок.","success")
  "price": p.price=maxi(500,value)
  "campaign":
   if l.accounts.cash<120000: return "Кампания стоит €1 200"
   l.expense(day(),"Продвижение: "+p.name,120000,"marketing"); p.awareness=minf(100,p.awareness+15)
  "update":
   if not p.stage in ["Поддержка","Рост","Спад"]: return "Сначала выпустите продукт"
   if l.accounts.cash<150000: return "Обновление стоит €1 500"
   l.expense(day(),"Обновление: "+p.name,150000,"research"); p.stage="Обновление"; p.progress=0.0; p.required=70.0
  "supply":
   if c.industry==0: return "IT не требует товарных запасов"
   if OfficeSim.bonus(c,["shelf"])<1: return "Купите стеллаж на складе"
   var held=int(p.stock)+int(p.materials)
   var cap=int(OfficeSim.bonus(c,["shelf"]))*100
   if held>=cap: return "Склад заполнен"
   if not Economy.procure(l,p,mini(50,cap-held),(0.50 if c.industry==1 else 0.28)*state.world.supply,day(),c.industry==2): return "Недостаточно денег на закупку"
  "auto": p.auto_supply=not p.auto_supply
  "stop": p.stage="Снят с продажи"
 commit_ledger(l)
 return ""

func finance_action(action: String, amount: int = 0, floating: bool = true) -> String:
 var c=company()
 var l=ledger()
 match action:
  "loan":
   if c.status=="Банкротство": return "Кредит недоступен при банкротстве"
   var limit=int(l.accounts.capital)*2
   if amount<=0 or l.accounts.debt+amount>limit: return "Превышен кредитный лимит"
   if state.world.event==9 and amount>l.accounts.capital/2: return "Кредитное сжатие: лимит снижен"
   if l.accounts.debt>0 and bool(c.loan.floating)!=floating: return "Сначала погасите текущий кредит для смены ставки"
   c.loan={"rate":Catalog.CITIES[int(c.city)].rate+(0.015+state.world.rate if not floating else 0.0),"floating":floating}
   l.post(day(),"Банковский кредит",{"cash":amount,"debt":amount},"financing")
  "repay":
   amount=mini(amount,int(l.accounts.debt))
   if amount<=0 or l.accounts.cash<amount: return "Недостаточно денег для погашения"
   l.post(day(),"Погашение кредита",{"cash":-amount,"debt":-amount},"financing")
  "invest":
   if amount<=0 or state.founder.personal<amount: return "Недостаточно личных средств"
   var value=Negotiation.valuation(c)
   var issued=float(amount)/(value+amount)
   for owner in c.cap_table: owner.share*=1-issued
   for owner in c.cap_table:
    if owner.id=="founder": owner.share+=issued
   state.founder.personal-=amount
   l.post(day(),"Вклад основателя",{"cash":amount,"capital":amount},"financing")
  "dividend":
   if amount<=0 or l.accounts.cash<amount or l.accounts.earnings<amount: return "Нужны накопленная прибыль и свободные деньги"
   var own: float=0
   for owner in c.cap_table:
    if owner.id=="founder": own=owner.share
   state.founder.personal+=int(amount*own)
   l.post(day(),"Дивиденды всем владельцам",{"cash":-amount,"earnings":-amount},"financing")
  "salary": c.founder_salary=maxi(0,amount)
  "property":
   if c.office.owned: return "Здание уже принадлежит компании"
   var price=int(Catalog.CITIES[int(c.city)].rent)*90
   if l.accounts.cash<price: return "Недостаточно денег на недвижимость"
   l.post(day(),"Покупка офиса",{"cash":-price,"equipment":price},"investing")
   c.office.rented=true; c.office.owned=true; c.daily_depreciation+=price/7200
  "restructure":
   var pay=mini(maxi(0,int(l.accounts.cash))/2,int(l.accounts.debt)/4)
   var forgiven=int(l.accounts.debt)/10
   if forgiven<=0: return "Нет банковского долга для реструктуризации"
   l.post(day(),"Реструктуризация долга",{"cash":-pay,"debt":-pay-forgiven,"earnings":forgiven},"financing",{"revenue":forgiven})
   c.loan.rate+=0.025
   state.founder.skills[6]=maxf(0,state.founder.skills[6]-3)
  "liquidate":
   var recovered=int((l.accounts.equipment+l.accounts.depreciation)*0.45+l.accounts.inventory*0.6+l.accounts.ar*0.8+l.accounts.deposit)
   var changes={"cash":recovered,"equipment":-int(l.accounts.equipment),"depreciation":-int(l.accounts.depreciation),"inventory":-int(l.accounts.inventory),"ar":-int(l.accounts.ar),"deposit":-int(l.accounts.deposit)}
   var assets=0
   for k in changes: assets+=int(changes[k])
   changes.earnings=assets
   l.post(day(),"Ликвидация: реализация активов",changes,"investing",{"maintenance":-assets})
   var liabilities=int(l.accounts.ap+l.accounts.tax_payable+l.accounts.debt)
   var paid=mini(maxi(0,int(l.accounts.cash)),liabilities)
   if liabilities>0:
    l.post(day(),"Расчёт с кредиторами",{"cash":-paid,"ap":-int(l.accounts.ap),"tax_payable":-int(l.accounts.tax_payable),"debt":-int(l.accounts.debt),"earnings":liabilities-paid},"financing",{"revenue":liabilities-paid})
   var remainder=maxi(0,int(l.accounts.cash))
   if remainder>0:
    for owner in c.cap_table:
     if owner.id=="founder": state.founder.personal+=int(remainder*owner.share)
    l.post(day(),"Возврат остатка владельцам",{"cash":-remainder,"capital":-remainder},"financing")
   c.status="Ликвидирована"; c.employees=[]; c.receivables=[]
   state.founder.career.append({"day":day(),"text":"Ликвидирована "+c.name})
   state.founder.skills[6]=maxf(0,state.founder.skills[6]-5)
 commit_ledger(l)
 return ""

func open_branch(city_id: int) -> String:
 var c=company()
 var l=ledger()
 var amount: int=4000000
 if l.accounts.cash<amount: return "Для филиала нужно €40 000"
 if city_id==int(c.city): return "Выберите другой город"
 l.post(day(),"Капитал филиала",{"cash":-amount,"investments":amount},"investing")
 c.ledger=l.export_data()
 var child=make_company(city_id,c.name+" · "+Catalog.CITIES[city_id].en,int(c.industry),amount,int(c.model),int(c.id))
 child.cap_table=[{"id":"company_%d"%int(c.id),"name":c.name,"share":1.0}]
 state.companies.append(child)
 Economy.notify(state,"Международное развитие","Филиал зарегистрирован. Выберите его и настройте местный офис.","success")
 updated.emit()
 return ""

func save_slot(slot: int) -> String:
 var err=SaveStore.save_game(state,slot)
 message.emit("Игра сохранена" if err.is_empty() else err,"success" if err.is_empty() else "warning")
 return err

func acquire_rival(rival_id: int) -> String:
 var rival=state.world.competitors[rival_id]
 if not rival.active: return "Компания недоступна для покупки"
 var c=company()
 var l=ledger()
 var price=maxi(3000000,int(rival.cash-rival.debt+rival.revenue*12))
 if l.accounts.cash<price: return "Недостаточно денег для приобретения"
 l.post(day(),"Покупка: "+rival.name,{"cash":-price,"investments":price},"investing")
 c.ledger=l.export_data()
 var child=make_company(int(rival.city),rival.name,int(rival.industry),maxi(1000000,int(rival.cash)),0,int(c.id))
 child.cap_table=[{"id":"company_%d"%int(c.id),"name":c.name,"share":1.0}]
 child.office.rented=true
 var room_type=[11,15,19][int(child.industry)]
 OfficeSim.add_room(child,room_type,1,1,0)
 var equipment=[0,7,8][int(child.industry)]
 OfficeSim.add_furniture(child,equipment,2,2,0)
 if child.industry!=0:
  OfficeSim.add_room(child,16 if child.industry==1 else 22,7,1,0)
  OfficeSim.add_furniture(child,6,8,2,0)
 state.companies.append(child)
 rival.active=false; rival.status="Приобретена"; rival.share=0
 Economy.notify(state,"Приобретение завершено",child.name+" вошла в вашу группу. Настройте её команду и продукт.","success")
 updated.emit()
 return ""

func load_slot(slot: int) -> String:
 var d=SaveStore.load_game(slot)
 if d.is_empty(): return "Сохранение отсутствует или повреждено"
 state=d; speed=0; accumulator=0; last_autosave=-1
 updated.emit(); office_changed.emit()
 return ""
