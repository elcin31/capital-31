extends SceneTree
var failures: Array=[]
var checks: int=0
var game: Node
var evidence: Array=[]

func _initialize() -> void:call_deferred("run")
func check(condition: bool, title: String) -> void:
 checks+=1
 if not condition:failures.append(title);print("FAIL: ",title)
 else:print("PASS: ",title)

func fresh(industry: int = 0, city: int = 0) -> void:
 game.start_game({"first":"Тест","last":"Основатель","bio":0,"appearance":Catalog.appearance(3)},city,"QA Capital",industry,14000000,0,310031)
 check(game.rent_office().is_empty(),"Аренда · отрасль %d"%industry)
 check(game.build_room([11,15,19][industry],1,1,0).is_empty(),"Комната · отрасль %d"%industry)
 check(game.buy_furniture([0,7,8][industry],2,2,0).is_empty(),"Оборудование · отрасль %d"%industry)
 if industry!=0:
  check(game.build_room(16 if industry==1 else 22,7,1,0).is_empty(),"Склад · отрасль %d"%industry)
  check(game.buy_furniture(6,8,2,0).is_empty(),"Стеллаж · отрасль %d"%industry)
 check(game.hire(game.candidates()[0]).is_empty(),"Найм · отрасль %d"%industry)

func hours(n: int) -> void:
 for i in range(n):Economy.hour(game.state)

func run() -> void:
 game=root.get_node("Game")
 SaveStore.base_path="user://qa_saves"
 var l=Ledger.new()
 check(l.post(0,"Капитал",{"cash":1000000,"capital":1000000},"financing"),"Сбалансированная проводка")
 l.post(1,"Продажа в кредит",{"ar":200000,"earnings":200000},"operating",{"revenue":200000})
 check(l.report().net==200000 and l.accounts.cash==1000000,"Прибыль отличается от денег")
 l.post(2,"Оплата покупателя",{"cash":200000,"ar":-200000})
 check(l.report().change==1200000 and l.accounts.cash==1200000,"Cash Flow = изменение денег")
 l.expense(3,"Начисление зарплаты",100000,"wages",true)
 check(l.accounts.ap==100000 and l.report().wages==100000 and l.accounts.cash==1200000,"Зарплата начисляется до оплаты")
 l.post(4,"Оплата зарплаты",{"cash":-100000,"ap":-100000})
 check(l.balance_error()==0 and l.report().net==100000,"Базовое равенство баланса")
 for industry in range(3):
  fresh(industry)
  check(game.start_product("QA Product",4900,75,1,250000,0).is_empty(),"Старт разработки · %d"%industry)
  var c=game.company()
  hours(24*60)
  var p=c.products[0]
  check(p.stage=="Готов к выпуску","Полная разработка · %d"%industry)
  check(game.product_action(0,"launch").is_empty(),"Выпуск продукта · %d"%industry)
  if industry!=0:
   check(game.product_action(0,"supply").is_empty(),"Закупка товаров / сырья · %d"%industry)
   game.product_action(0,"auto")
  hours(24*30)
  var fin=game.ledger()
  check(p.customers>0 and p.revenue>0,"Реальные клиенты и выручка · %d"%industry)
  check(int(fin.accounts.inventory)==int(p.get("inventory_value",0)),"Стоимость запасов совпадает с количеством и закупками · %d"%industry)
  check(fin.balance_error()==0,"Баланс после 90 дней · %d"%industry)
  check(fin.accounts.cash==fin.report().change,"Все деньги объясняются Cash Flow · %d"%industry)
  check(fin.report().wages>0 and fin.report().rent>0,"Начислены зарплата и аренда · %d"%industry)
  check(fin.report().revenue-fin.report().cogs-fin.report().opex-fin.report().depreciation-fin.report().interest-fin.report().tax==fin.report().net,"P&L арифметика · %d"%industry)
  evidence.append({"industry":industry,"customers":p.customers,"revenue":p.revenue,"balance_error":fin.balance_error(),"cash":fin.accounts.cash})
  var before=int(p.daily_revenue)
  game.state.world.demand=0.01
  Economy.company_day(game.state,c,game.day()+1)
  check(int(p.daily_revenue)<=before,"Спрос меняет продажи · %d"%industry)
 fresh()
 var c=game.company()
 var initial_cash=game.ledger().accounts.cash
 game.finance_action("loan",3000000)
 hours(24*30)
 var loan_report=game.ledger().report()
 check(game.ledger().accounts.debt==3000000 and loan_report.interest>0,"Кредит и ежедневные проценты")
 check(game.ledger().accounts.ap==0,"Начисленные счета оплачены на 30-й день")
 check(game.ledger().accounts.cash<initial_cash+3000000,"Кредит не превращает расходы в прибыль")
 var base=game.state.duplicate(true)
 var fixed=base.duplicate(true);fixed.companies[0].loan.floating=false
 var floating_state=base.duplicate(true);floating_state.world.rate=0.1
 var fixed_c=fixed.companies[0];var float_c=floating_state.companies[0]
 Economy.company_day(fixed,fixed_c,31);Economy.company_day(floating_state,float_c,31)
 check(Ledger.new(float_c.ledger).report(31,31).interest>Ledger.new(fixed_c.ledger).report(31,31).interest,"Рост ставок влияет на плавающий долг")
 var before_rival=JSON.stringify(game.state.world.competitors)
 hours(24*8)
 check(before_rival!=JSON.stringify(game.state.world.competitors),"Автономные решения конкурентов")
 var n=Negotiation.start(game.state,c,0,5000000)
 var cash_before=game.ledger().accounts.cash
 Negotiation.respond(game.state,c,"vision");Negotiation.respond(game.state,c,"accept")
 check(n.accepted and game.ledger().accounts.cash==cash_before+5000000,"Инвестиция меняет деньги компании")
 var sum: float=0
 for owner in c.cap_table:sum+=float(owner.share)
 check(absf(sum-1.0)<0.000001 and c.cap_table[0].share<1,"Корректное размытие долей")
 var share_before=c.cap_table[0].share
 Negotiation.start(game.state,c,1,3000000);Negotiation.respond(game.state,c,"vision");Negotiation.respond(game.state,c,"accept")
 sum=0
 for owner in c.cap_table:sum+=float(owner.share)
 check(absf(sum-1)<0.000001 and c.cap_table[0].share<share_before,"Повторный раунд и права инвесторов")
 check(game.state.investor_memory["0"].deals==1,"Память инвестора сохраняет сделку")
 var snapshot=game.state.duplicate(true)
 for rate in [1,2,5,10]:
  game.state=snapshot.duplicate(true);game.accumulator=0.0;game.speed=rate
  for frame in range(480):game.advance_time(0.25/rate)
  check(int(game.state.hour)==int(snapshot.hour)+60,"Часы на ×%d"%rate)
  if rate==1:base=game.state.duplicate(true)
  else:check(JSON.stringify(game.state)==JSON.stringify(base),"Одинаковая симуляция при ×%d"%rate)
 game.speed=0;game.state=snapshot.duplicate(true)
 check(SaveStore.save_game(game.state,1).is_empty(),"Сохранение с контрольной суммой")
 var loaded=SaveStore.load_game(1)
 check(JSON.stringify(loaded)==JSON.stringify(game.state),"Точное восстановление всех систем")
 check(SaveStore.save_game(game.state,1).is_empty(),"Повторная атомарная запись")
 var file=FileAccess.open(SaveStore.path_for(1),FileAccess.WRITE);file.store_string("{broken");file.close()
 check(not SaveStore.load_game(1).is_empty(),"Повреждение основного файла: восстановление из .bak")
 SaveStore.delete_slot(1)
 check(SaveStore.load_game(1).is_empty(),"Удаление слота и резервной копии")
 fresh()
 c=game.company()
 var old_count=c.office.furniture.size()
 var error=game.buy_furniture(0,2,2,0)
 check(not error.is_empty() and c.office.furniture.size()==old_count,"Пересечения мебели запрещены")
 check(not game.build_room(0,1,1,0).is_empty(),"Пересечения комнат запрещены")
 check(not game.alter_building("wall",1,2,0).is_empty(),"Нельзя перекрыть доступ к рабочему месту")
 check(not OfficeSim.path(c,Vector2i(0,6),Vector2i(2,3),0).is_empty(),"Сотрудник находит путь через дверь")
 var parent_cash=game.ledger().accounts.cash
 check(game.open_branch(1).is_empty(),"Создание международного филиала")
 var group_cash=0
 for comp in game.state.companies:group_cash+=int(Ledger.new(comp.ledger).accounts.cash)
 check(group_cash==parent_cash,"Внутренний перевод не создаёт денег группы")
 fresh()
 c=game.company()
 l=game.ledger()
 l.post(0,"Высокий доход",{"cash":6000000,"earnings":6000000},"operating",{"revenue":6000000});game.commit_ledger(l)
 hours(24*30)
 check(game.ledger().report().tax>0 and game.ledger().accounts.tax_payable==0,"Налоги начислены и уплачены")
 fresh()
 var broke=game.ledger();var burn=int(broke.accounts.cash)+1000000
 broke.expense(0,"Потеря ликвидности",burn,"maintenance");game.commit_ledger(broke)
 hours(24*11)
 check(game.company().status=="Банкротство","Банкротство после 10 дней кассового разрыва")
 var person=game.state.founder.duplicate(true)
 check(game.finance_action("liquidate").is_empty(),"Ликвидация и расчёт с кредиторами")
 check(game.ledger().balance_error()==0,"Баланс после ликвидации")
 check(game.register_company(3,"Новый старт",1,4000000,0).is_empty(),"Новая компания тем же основателем")
 check(game.state.founder.first==person.first and game.state.founder.skills[3]==person.skills[3] and game.state.companies.size()==2,"Карьера и навыки переживают банкротство")
 fresh()
 var prior_cash=game.ledger().accounts.cash
 var prior_personal=game.state.founder.personal
 check(game.finance_action("sell_stake",500000).is_empty(),"Продажа личной доли")
 check(game.ledger().accounts.cash==prior_cash and game.state.founder.personal==prior_personal+500000,"Вторичная сделка не смешивает личные и корпоративные деньги")
 sum=0
 for owner in game.company().cap_table:sum+=float(owner.share)
 check(absf(sum-1.0)<0.000001,"Cap table после продажи личной доли")
 fresh()
 prior_cash=game.ledger().accounts.cash
 game.open_branch(1)
 check(not game.finance_action("liquidate").is_empty(),"Активы дочерней компании защищены при ликвидации родителя")
 game.state.current=1
 check(game.finance_action("liquidate").is_empty(),"Ликвидация филиала")
 game.state.current=0
 check(game.ledger().accounts.cash==prior_cash and game.ledger().accounts.investments==0,"Капитал филиала вернулся владельцу без потери денег")
 fresh()
 game.open_branch(1);game.state.current=1
 check(game.finance_action("invest",1000000).is_empty(),"Личная инвестиция в филиал")
 sum=0
 for owner in game.company().cap_table:sum+=float(owner.share)
 check(absf(sum-1.0)<0.000001 and game.company().cap_table.size()==2,"В филиале корректно выпускаются доли основателю")
 fresh()
 game.finance_action("loan",10000000)
 var net_before=game.ledger().accounts.cash-game.ledger().accounts.debt
 check(game.acquire_rival(1).is_empty(),"Приобретение действующей розничной компании")
 var child=game.state.companies[1]
 check(child.employees.size()>0 and child.products.size()>0 and child.products[0].quality==game.state.world.competitors[1].quality,"Приобретение сохраняет команду и характеристики продукта")
 var parent_fin=game.ledger();var child_fin=Ledger.new(child.ledger)
 check(parent_fin.accounts.cash+child_fin.accounts.cash-parent_fin.accounts.debt-child_fin.accounts.debt==net_before,"Сделка переносит и деньги, и долг конкурента")
 check(child_fin.balance_error()==0 and parent_fin.balance_error()==0,"Баланс обеих компаний после приобретения")
 fresh()
 game.finance_action("loan",2000000,false)
 var old_rate=float(game.company().loan.rate)
 game.state.world.rate=0.10
 check(float(game.company().loan.rate)==old_rate,"Рост рыночной ставки не меняет старый фиксированный кредит")
 game.finance_action("loan",2000000,false)
 check(absf(game.company().loan.rate-(old_rate+0.05))<0.000001,"Новый фиксированный кредит учитывается средневзвешенной ставкой")
 check(not game.finance_action("restructure").is_empty(),"Нельзя бесконечно списывать долг платёжеспособной компании")
 var result={"checks":checks,"failed":failures.size(),"failures":failures,"industry_evidence":evidence,"godot":Engine.get_version_info().string}
 var out=FileAccess.open("res://../docs/QA-ECONOMY.json",FileAccess.WRITE);out.store_string(JSON.stringify(result,"  "));out.close()
 print("RESULT: ",checks," checks, ",failures.size()," failed")
 quit(0 if failures.is_empty() else 1)
