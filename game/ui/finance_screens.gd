class_name FinanceScreens
extends RefCounted

var ui: Control
var page: int=0
var amount_text: String="10000"
var floating: bool=true

func _init(host: Control) -> void:ui=host

func show_finance() -> void:
 var col=ui.open_panel("Финансовый терминал · "+Game.company().name,1100)
 var tabs=UI.row(col)
 for item in [[0,"Обзор"],[1,"P&L"],[2,"Баланс"],[3,"Cash Flow"],[4,"Операции"],[5,"Капитал и кредиты"]]:
  UI.button(tabs,item[1],func():page=item[0];show_finance(),page==item[0])
 var l=Game.ledger();var r=l.report(maxi(0,Game.day()-29))
 UI.label(col,"Период: день %d–%d · все суммы в евро"%[maxi(1,Game.day()-28),Game.day()+1],13,UI.MUTED)
 if page==0:
  var row=UI.row(col)
  UI.metric(row,"ДЕНЕЖНЫЕ СРЕДСТВА",Catalog.money(l.accounts.cash),UI.BLUE)
  UI.metric(row,"ЧИСТАЯ ПРИБЫЛЬ",Catalog.money(r.net),UI.GREEN if r.net>=0 else Color("e8785c"))
  UI.metric(row,"ОЦЕНКА КОМПАНИИ",Catalog.money(Negotiation.valuation(Game.company())))
  var graph=HistoryChart.new();graph.history=Game.company().history;graph.custom_minimum_size.y=210;col.add_child(graph)
  UI.pair(col,"Выручка",Catalog.money(r.revenue));UI.pair(col,"Валовая прибыль",Catalog.money(r.gross))
  UI.pair(col,"Операционные расходы",Catalog.money(r.opex));UI.pair(col,"EBITDA",Catalog.money(r.ebitda))
  UI.pair(col,"Операционный денежный поток",Catalog.money(r.operating))
  UI.text(col,"Прибыль признаётся при продаже; 30% покупатели оплачивают через 7 дней. Зарплаты и аренда накапливаются в кредиторской задолженности и оплачиваются раз в 30 дней.",15)
 elif page==1:
  var rows=[["Revenue · Выручка","revenue"],["COGS · Себестоимость","cogs"],["Gross Profit · Валовая прибыль","gross"],["Зарплаты","wages"],["Аренда и эксплуатация","rent"],["Маркетинг","marketing"],["Исследования и разработка","research"],["Обслуживание","maintenance"],["EBITDA · До амортизации и процентов","ebitda"],["Depreciation · Амортизация","depreciation"],["EBIT · Операционная прибыль","ebit"],["Interest Expense · Проценты","interest"],["Taxes · Налог на прибыль","tax"],["Net Income · Чистая прибыль","net"]]
  for item in rows:UI.pair(col,item[0],Catalog.money(r[item[1]]),UI.BLUE if item[1] in ["net","ebitda","gross"] else UI.TEXT)
 elif page==2:
  var a=l.accounts
  UI.label(col,"АКТИВЫ",14,UI.BLUE,true)
  for item in [["Деньги","cash"],["Дебиторская задолженность","ar"],["Товарные и сырьевые запасы","inventory"],["Оборудование и отделка","equipment"],["Накопленная амортизация","depreciation"],["Вложения в филиалы","investments"],["Возвратные депозиты","deposit"]]:UI.pair(col,item[0],Catalog.money(a[item[1]]))
  var assets: int=0;var claims: int=0
  for k in Ledger.ASSETS:assets+=int(a[k])
  UI.pair(col,"Итого активы",Catalog.money(assets),UI.BLUE);UI.separator(col)
  UI.label(col,"ОБЯЗАТЕЛЬСТВА И КАПИТАЛ",14,UI.BLUE,true)
  for item in [["Кредиторская задолженность","ap"],["Банковский долг","debt"],["Налоги к уплате","tax_payable"],["Внесённый капитал","capital"],["Нераспределённая прибыль","earnings"]]:
   UI.pair(col,item[0],Catalog.money(a[item[1]]));claims+=int(a[item[1]])
  UI.pair(col,"Итого обязательства + капитал",Catalog.money(claims),UI.BLUE)
  UI.label(col,"Активы = Обязательства + Капитал · расхождение "+Catalog.money(l.balance_error()),16,UI.GREEN,true)
 elif page==3:
  UI.pair(col,"Деньги на начало периода",Catalog.money(l.accounts.cash-r.change))
  UI.pair(col,"Operating Cash Flow · Операционный",Catalog.money(r.operating))
  UI.pair(col,"Investing Cash Flow · Инвестиционный",Catalog.money(r.investing))
  UI.pair(col,"Financing Cash Flow · Финансовый",Catalog.money(r.financing))
  UI.separator(col);UI.pair(col,"Изменение денежных средств",Catalog.money(r.change),UI.BLUE)
  UI.pair(col,"Деньги на конец периода",Catalog.money(l.accounts.cash),UI.GREEN)
  UI.text(col,"Покупка оборудования и депозит — инвестиционные платежи. Вложения владельцев, кредит и дивиденды — финансовые. Амортизация не расходует деньги.",16)
 elif page==4:
  UI.text(col,"Последние 100 проводок. Все денежные операции проходят через единый журнал.",14)
  var entries=l.journal.slice(maxi(0,l.journal.size()-100));entries.reverse()
  for entry in entries:
   var box=UI.card(col);UI.pair(box,"День %d · %s"%[int(entry.day)+1,entry.memo],Catalog.money(entry.cash),UI.GREEN if entry.cash>0 else UI.TEXT)
   var details: Array=[]
   for account in entry.changes:details.append(account+": "+Catalog.money(entry.changes[account]))
   UI.text(box,"  ·  ".join(details),12)
 else:capital_page(col)

func capital_page(col: VBoxContainer) -> void:
 var c=Game.company();var l=Game.ledger()
 UI.pair(col,"Личные деньги основателя",Catalog.money(Game.state.founder.personal),UI.GREEN)
 UI.pair(col,"Деньги компании",Catalog.money(l.accounts.cash),UI.BLUE)
 UI.pair(col,"Банковский долг",Catalog.money(l.accounts.debt))
 var rate=float(c.loan.rate)+(Game.state.world.rate if c.loan.floating else 0)
 UI.pair(col,"Текущая ставка","%.1f%% · %s"%[rate*100,"плавающая" if c.loan.floating else "фиксированная"])
 var input_row=UI.row(col)
 UI.field(UI.column(input_row),"Сумма в евро",amount_text,func(s):amount_text=s)
 UI.option(UI.column(input_row),"Ставка нового кредита",["Плавающая","Фиксированная (+1.5 п.п.)"],0 if floating else 1,func(n):floating=n==0)
 var buttons=UI.row(col)
 UI.button(buttons,"Взять кредит",func():execute("loan"),true)
 UI.button(buttons,"Погасить долг",func():execute("repay"))
 UI.button(buttons,"Вложить личные деньги",func():execute("invest"))
 UI.button(buttons,"Выплатить дивиденды",func():ui.global_screens.confirm("Выплатить дивиденды всем владельцам пропорционально их долям?",func():execute("dividend")))
 UI.button(col,"Установить зарплату основателя / месяц",func():execute("salary"))
 UI.text(col,"Ввод 0 отключает зарплату. Дивиденды доступны только из накопленной прибыли. Инвестиция основателя выпускает новые доли и размывает остальных владельцев.",14)
 UI.separator(col);UI.label(col,"ВЛАДЕНИЕ · CAP TABLE",15,UI.BLUE,true)
 for owner in c.cap_table:UI.pair(col,owner.name,"%.3f%%"%(owner.share*100))
 UI.label(col,"ИНВЕСТИЦИОННЫЕ РАУНДЫ",14,UI.BLUE,true)
 if c.rounds.is_empty():UI.text(col,"Раундов пока не было. Начните поиск во вкладке «Инвесторы».",14)
 for round_data in c.rounds:
  UI.pair(col,"День %d · %s"%[int(round_data.day)+1,round_data.investor],Catalog.money(round_data.amount))
  UI.text(col,"Pre-money %s → Post-money %s · новая доля %.1f%%"%[Catalog.money(round_data.pre),Catalog.money(round_data.post),round_data.share*100],13)

func execute(action: String) -> void:
 if not amount_text.is_valid_int() or int(amount_text)<0:ui.show_toast("Введите целую неотрицательную сумму в евро","warning");return
 ui.perform(func():return Game.finance_action(action,int(amount_text)*100,floating),show_finance,"deal")
