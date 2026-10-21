class_name Economy
extends RefCounted

static func notify(state: Dictionary, title: String, text: String, kind: String = "info") -> void:
 state.news.push_front({"day":int(state.hour)/24,"title":title,"text":text,"kind":kind})
 if state.news.size()>120: state.news.resize(120)

static func world_start(seed_value: int) -> Dictionary:
 var competitors: Array=[]
 var names=["Kaiser Analytics","Nova Commerce","Atlas Works","Nexa Systems","Mercury Market","Helix Industries","Cloudline","Urban Goods","Forge & Co","Aurora Digital","Lotus Stores","Vector Manufacturing"]
 for i in range(12):
  competitors.append({"id":i,"name":names[i],"industry":i%3,"city":i%5,"cash":18000000+i*1500000,"debt":i*200000,"staff":4+i%5,"price":3500+i*200,"quality":45.0+i*2,"awareness":30.0+i*2,"share":0.0,"revenue":0,"profit":0,"age":0,"products":1,"strategy":i%3,"status":"Развивается","active":true,"history":[],"decision":"Изучает рынок"})
 return {"seed":seed_value,"event":0,"next_event":25,"demand":1.18,"wages":1.0,"supply":1.0,"rate":0.0,"competitors":competitors,"history":[]}

static func hour(state: Dictionary) -> void:
 state.hour+=1
 var h=int(state.hour)%24
 var day=int(state.hour)/24
 for c in state.companies:
  if c.status=="Ликвидирована": continue
  c.day=day
  var work=OfficeSim.employee_hour(c,h) if c.office.rented else 0.0
  c.work_today=float(c.get("work_today",0.0))+work
  var assigned: Array=[]
  for p in c.products:
   if p.stage in ["Идея","Исследование","Разработка","Тестирование","Обновление"]: assigned.append(p)
  for p in assigned:
   var product_work: float=0
   for e in c.employees:
    if int(e.task)==int(p.id) or (e.task<0 and assigned.size()>0): product_work+=float(e.efficiency)/(1 if e.task>=0 else assigned.size())
   if h>=8 and h<18:
    p.progress+=product_work*(1.12 if OfficeSim.has_room(c,"research") else 1.0)*(1.1 if OfficeSim.has_room(c,"testing") else 1.0)
    if p.progress>=p.required:
     p.progress=p.required
     if p.stage=="Обновление":
      p.quality=minf(100,p.quality+8); p.age=0; p.stage="Поддержка"
      notify(state,"Обновление готово",p.name+": качество выросло.","success")
     else:
      p.stage="Готов к выпуску"
      notify(state,"Продукт готов",p.name+": откройте «Продукты» и запустите продажи.","success")
    elif p.stage!="Обновление":
     var ratio=float(p.progress)/p.required
     p.stage="Исследование" if ratio<0.2 else ("Разработка" if ratio<0.82 else "Тестирование")
   if product_work>0: state.founder.skills[3]=minf(100,state.founder.skills[3]+0.001)
  if work>0: state.founder.skills[5]=minf(100,state.founder.skills[5]+0.001)
 if h==0: day_tick(state)

static func day_tick(state: Dictionary) -> void:
 var day=int(state.hour)/24
 var world=state.world
 if day>=int(world.next_event):
  if int(world.event)==1:world.survived_recession=true
  var event_id=(int(world.seed)+day/25*7)%Catalog.EVENTS.size()
  world.event=event_id
  var ev=Catalog.EVENTS[event_id]
  for k in ["demand","wages","supply","rate"]: world[k]=ev[k]
  world.next_event=day+25
  notify(state,ev.name,ev.text,"market")
 competitors_tick(state,day)
 for c in state.companies:
  if c.status=="Ликвидирована": continue
  company_day(state,c,day)
 world.history.append({"day":day,"demand":world.demand,"rate":world.rate})
 if world.history.size()>360: world.history.pop_front()
 missions(state)

static func company_day(state: Dictionary, c: Dictionary, day: int) -> void:
 var city=Catalog.CITIES[int(c.city)]
 var world=state.world
 var l=Ledger.new(c.ledger)
 var inflation=pow(1.0+float(city.inflation),float(day)/365.0)
 var wage_total: int=0
 for e in c.employees:
  wage_total+=int(e.wage)
  e.satisfaction=clampf(e.satisfaction+(0.08 if e.wage>=city.wage*world.wages else -0.18)+(0.1 if OfficeSim.has_room(c,"break") else 0),0,100)
  if e.satisfaction<15: e.status="Ищет другую работу"
 l.expense(day,"Зарплаты: начисление",wage_total,"wages",true)
 if c.office.rented:
  l.expense(day,"Аренда и эксплуатация",int(city.rent*inflation*int(c.office.floors)/30.0*(0.2 if c.office.get("owned",false) else 1.0)),"rent",true)
 if int(c.get("founder_salary",0))>0:
  var salary=int(c.founder_salary)/30
  l.expense(day,"Зарплата основателя",salary,"wages")
  state.founder.personal+=salary
 if c.marketing>0: l.expense(day,"Маркетинг",int(c.marketing),"marketing")
 var deprec=mini(maxi(0,int(l.accounts.equipment)+int(l.accounts.depreciation)),int(c.get("daily_depreciation",0)))
 if deprec>0: l.post(day,"Амортизация",{"depreciation":-deprec,"earnings":-deprec},"operating",{"depreciation":deprec})
 var debt=int(l.accounts.debt)
 if debt>0:
  var annual=float(c.loan.rate)+(float(world.rate) if c.loan.get("floating",true) else 0.0)
  l.expense(day,"Проценты по кредиту",int(round(debt*annual/365.0)),"interest",true)
 for receivable in c.receivables.duplicate():
  if int(receivable.due)<=day:
   l.post(day,"Оплата покупателя",{"cash":int(receivable.amount),"ar":-int(receivable.amount)})
   c.receivables.erase(receivable)
 var competition: float=0.7
 for rival in world.competitors:
  if rival.active and int(rival.industry)==int(c.industry): competition+=(rival.quality/100.0)*(rival.awareness/100.0)*0.4
 for p in c.products:
  if not p.stage in ["Поддержка","Рост","Спад"]: continue
  p.age+=1
  p.awareness=clampf(p.awareness+float(c.marketing)/12000.0-0.1,5,100)
  p.satisfaction=clampf(p.quality*0.7+p.fit*0.3-(p.price/100.0-49)*0.1,5,100)
  p.stage="Спад" if p.age>240 else ("Рост" if p.customers>100 else "Поддержка")
  var demand=float(world.demand)*float(city.demand[int(c.industry)])*float(city.market)
  if int(world.event)==1 and c.industry==1: demand*=0.85
  if int(world.event)==5 and c.industry==0: demand*=1.25
  var attraction=(p.quality/100.0)*(p.fit/100.0)*(0.3+p.awareness/70.0)*(4900.0/maxf(500,p.price))*city.power
  var potential=int(maxf(0,round(30*demand*attraction/(competition*city.competition))))
  if p.stage=="Спад": potential=int(potential*0.6)
  var sold: int=0
  var revenue: int=0
  if c.industry==0:
   var churn=int(p.customers*(1-p.satisfaction/110.0)*0.012)
   p.customers=maxi(0,int(p.customers)+potential-churn)
   sold=potential
   revenue=int(p.customers*p.price/30.0)
   l.expense(day,"Хостинг и поддержка: "+p.name,int(revenue*0.08)+150,"maintenance")
  elif c.industry==1:
   var capacity=int(OfficeSim.bonus(c,["shelf"]))*100
   var space=capacity
   for stock_product in c.products:space-=int(stock_product.stock)+int(stock_product.materials)
   if p.auto_supply and capacity>0 and p.stock<capacity/2:
    procure(l,p,mini(space,80),0.50*world.supply,day,false)
   sold=mini(int(p.stock),mini(potential,int(c.get("work_today",0)*2.5)) if OfficeSim.bonus(c,["checkout"])>0 else 0)
   revenue=sold*int(p.price)
  else:
   var capacity=int(OfficeSim.bonus(c,["shelf"]))*100
   var space=capacity
   for stock_product in c.products:space-=int(stock_product.stock)+int(stock_product.materials)
   if p.auto_supply and capacity>0 and p.materials<capacity/2: procure(l,p,mini(space,80),0.28*world.supply,day,true)
   var skill: float=float(c.get("work_today",0))/8.0
   var produced=mini(int(p.materials),int(OfficeSim.bonus(c,["machine"])*12*skill*city.infra))
   if int(world.event)==6: produced=int(produced*0.6)
   p.materials-=produced; p.stock+=produced
   sold=mini(int(p.stock),potential)
   revenue=sold*int(p.price)
  if c.industry!=0 and sold>0:
   p.stock-=sold
   var held_before=int(p.stock)+int(p.materials)+sold
   var stock_value=int(p.get("inventory_value",held_before*int(p.unit_cost)))
   var cost=stock_value if sold==held_before else int(stock_value*sold/maxi(1,held_before))
   p.inventory_value=stock_value-cost
   l.post(day,"Себестоимость: "+p.name,{"inventory":-cost,"earnings":-cost},"operating",{"cogs":cost})
   p.customers+=sold
  if revenue>0:
   var credit=int(revenue*0.3)
   l.post(day,"Продажи: "+p.name,{"cash":revenue-credit,"ar":credit,"earnings":revenue},"operating",{"revenue":revenue})
   c.receivables.append({"amount":credit,"due":day+7})
  p.revenue+=revenue
  p.daily_revenue=revenue
  p.sales=sold
 if day%30==0:
  var pl=l.report(0 if day==30 else day-29,day)
  var tax=maxi(0,int(pl.ebit-pl.interest)*float(city.tax))
  if tax>0: l.post(day,"Налог на прибыль",{"tax_payable":tax,"earnings":-tax},"operating",{"tax":tax})
  var payables=int(l.accounts.ap)
  if payables>0: l.post(day,"Выплата зарплат и счетов",{"cash":-payables,"ap":-payables})
  var taxes=int(l.accounts.tax_payable)
  if taxes>0: l.post(day,"Уплата налога",{"cash":-taxes,"tax_payable":-taxes})
 var summary=l.report(day,day)
 c.history.append({"day":day,"revenue":summary.revenue,"profit":summary.net,"cash":l.accounts.cash,"employees":c.employees.size(),"operating":summary.operating})
 if c.history.size()>360: c.history.pop_front()
 c.ledger=l.export_data()
 c.work_today=0.0
 if l.accounts.cash<0:
  c.insolvent_days+=1
  if c.insolvent_days==1: notify(state,"Кассовый разрыв",c.name+": 10 дней для восстановления ликвидности.","warning")
  if c.insolvent_days>=10 and c.status!="Банкротство":
   c.status="Банкротство"
   state.founder.skills[6]=maxf(0,state.founder.skills[6]-8)
   notify(state,"Банкротство",c.name+": реструктуризация, продажа активов или ликвидация.","warning")
 else:
  c.insolvent_days=0
  if c.status=="Банкротство": c.status="Работает"; notify(state,"Ликвидность восстановлена",c.name,"success")

static func procure(l: Ledger, p: Dictionary, units: int, ratio: float, day: int, raw: bool) -> bool:
 if units<=0:return false
 var cost=int(p.price*ratio)
 units=mini(units,int(maxi(0,int(l.accounts.cash))/maxi(1,cost)))
 if units<=0: return false
 var held=int(p.stock)+int(p.materials)
 p.inventory_value=int(p.get("inventory_value",held*int(p.unit_cost)))+units*cost
 p.unit_cost=int((held*int(p.unit_cost)+units*cost)/maxi(1,held+units))
 if raw: p.materials+=units
 else: p.stock+=units
 return l.post(day,"Закупка: "+p.name,{"cash":-units*cost,"inventory":units*cost})

static func competitors_tick(state: Dictionary, day: int) -> void:
 var total: float=0.0
 for c in state.world.competitors:
  if not c.active: c.share=0; continue
  c.age+=1
  if day%7==0:
   var choice=(int(state.world.seed)+day*13+int(c.id)*7)%8
   if c.cash<1000000:
    if c.debt<5000000: c.cash+=2000000; c.debt+=2000000; c.decision="Привлекла кредит"
    else: c.staff=maxi(1,int(c.staff)-1); c.decision="Сократила расходы"
   elif choice==0: c.staff+=1; c.cash-=180000; c.decision="Наняла сотрудника"
   elif choice==1: c.quality=minf(98,c.quality+2); c.cash-=160000; c.decision="Улучшила продукт"
   elif choice==2: c.price=maxi(800,int(c.price*0.94)); c.decision="Снизила цену"
   elif choice==3: c.awareness=minf(95,c.awareness+4); c.cash-=120000; c.decision="Усилила рекламу"
   elif choice==4: c.price=int(c.price*1.04); c.decision="Повысила цену"
   elif choice==5 and c.cash>25000000: c.products+=1; c.cash-=3000000; c.decision="Вышла на новый рынок"
   elif choice==6: c.cash+=1000000; c.decision="Привлекла инвестора"
   else: c.decision="Пересмотрела стратегию"
  var city=Catalog.CITIES[int(c.city)]
  c.revenue=int(300000*state.world.demand*city.market*(c.quality/70.0)*(c.awareness/60.0)*minf(2,c.products))
  c.profit=int(c.revenue*(0.75 if c.industry==0 else 0.42)-c.staff*city.wage-city.rent/30.0-c.debt*(city.rate+state.world.rate)/365.0)
  c.cash+=c.profit
  if c.cash<0: c.active=false; c.status="Банкротство"; notify(state,"Конкурент ушёл с рынка",c.name,"market")
  c.share=(c.quality/c.price)*c.awareness if c.active else 0
  total+=c.share
  c.history.append(c.revenue)
  if c.history.size()>60: c.history.pop_front()
 for c in state.world.competitors: c.share=c.share/maxf(0.01,total)

static func missions(state: Dictionary) -> void:
 var conditions=[false,false,false,false,false,false,false,false,false,false]
 var revenue: int=0
 for c in state.companies:
  conditions[0]=conditions[0] or c.office.rented
  conditions[1]=conditions[1] or c.employees.size()>0
  conditions[2]=conditions[2] or c.products.size()>0
  var l=Ledger.new(c.ledger)
  var pl=l.report(maxi(0,int(state.hour)/24-30))
  conditions[4]=conditions[4] or pl.ebitda>0
  conditions[5]=conditions[5] or c.rounds.size()>0
  revenue+=int(pl.revenue)
  for p in c.products:
   conditions[3]=conditions[3] or p.customers>=100
   conditions[9]=conditions[9] or p.revenue>0
 conditions[6]=state.companies.size()>1
 conditions[7]=revenue*12>=100000000
 conditions[8]=bool(state.world.get("survived_recession",false))
 var titles=["Первый офис","Первая команда","От идеи к продукту","100 клиентов","Операционная прибыль","Первый инвестор","Новый филиал","Миллион в год","Через экономический цикл","Первая выручка"]
 for i in range(conditions.size()):
  if conditions[i] and not str(i) in state.achievements:
   state.achievements.append(str(i))
   state.founder.skills[6]=minf(100,state.founder.skills[6]+1)
   notify(state,"Достижение: "+titles[i],"Репутация основателя +1","success")
