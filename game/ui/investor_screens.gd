class_name InvestorScreens
extends RefCounted

var ui: Control
var request_text: String="100000"

func _init(host: Control) -> void:ui=host

func show_investors() -> void:
 var col=ui.open_panel("Инвесторы · Убедите рынок поверить в вас",1100)
 UI.text(col,"Инвесторы изучают продукт, выручку, долги, репутацию и условия сделки. Переговоры полностью офлайн. Новые раунды меняют доли всех владельцев.",16)
 UI.field(col,"Запрашиваемая сумма в евро",request_text,func(s):request_text=s)
 UI.button(col,"Подготовить презентацию · €300",prepare_pitch)
 for i in range(Catalog.INVESTORS.size()):
  var inv=Catalog.INVESTORS[i];var box=UI.card(col);var row=UI.row(box)
  UI.portrait(row,Catalog.appearance(int(inv.portrait)),Vector2(92,110))
  var info=UI.column(row)
  UI.label(info,inv.name+" · "+inv.firm,20,UI.TEXT,true)
  UI.label(info,inv.type+" · "+inv.temper+" · "+Catalog.INDUSTRIES[int(inv.industry)],13,UI.BLUE)
  UI.text(info,inv.bio,15,UI.TEXT)
  var mem=Game.state.investor_memory.get(str(i),{})
  UI.label(info,"Капитал "+Catalog.money(inv.capital)+" · Встреч %d · Доверие %.0f/100"%[int(mem.get("meetings",0)),float(mem.get("trust",50))],13,UI.MUTED)
  UI.button(row,"Предложить встречу",func():begin_meeting(i),true)

func prepare_pitch() -> void:
 var l=Game.ledger()
 if l.accounts.cash<30000:ui.show_toast("Недостаточно денег на подготовку","warning");return
 if Game.company().get("pitch_prepared",false):ui.show_toast("Презентация уже подготовлена","info");return
 l.expense(Game.day(),"Подготовка инвестиционной презентации",30000,"marketing")
 Game.company().pitch_prepared=true;Game.state.founder.skills[2]=minf(100,Game.state.founder.skills[2]+1)
 Game.commit_ledger(l);ui.show_toast("Презентация готова: интерес на следующей встрече +5","success")

func begin_meeting(id: int) -> void:
 if not request_text.is_valid_int() or int(request_text)<10000:ui.show_toast("Минимальный запрос — €10 000","warning");return
 Game.speed=0
 var n=Negotiation.start(Game.state,Game.company(),id,int(request_text)*100)
 if Game.company().get("pitch_prepared",false):n.interest=minf(100,n.interest+5);Game.company().pitch_prepared=false
 show_negotiation()

func show_negotiation() -> void:
 var c=Game.company();var n=c.negotiation
 if n.is_empty():show_investors();return
 var inv=Catalog.INVESTORS[int(n.investor)]
 var col=ui.open_panel("Переговорная · "+inv.firm,1100)
 var stage=UI.card(col,Color("e9f6ff"))
 var room=MeetingBackdrop.new();stage.get_parent().add_child(room);stage.get_parent().move_child(room,0)
 var people=UI.row(stage)
 var founder=UI.column(people);UI.portrait(founder,Game.state.founder.appearance,Vector2(230,230));UI.label(founder,Game.state.founder.first+" "+Game.state.founder.last,18,UI.TEXT,true)
 var offer=UI.column(people)
 UI.label(offer,"ИНВЕСТИЦИОННОЕ ПРЕДЛОЖЕНИЕ",13,UI.BLUE,true)
 UI.label(offer,Catalog.money(n.amount),36,UI.BLUE,true)
 UI.pair(offer,"Доля инвестора","%.1f%%"%(n.share*100))
 UI.pair(offer,"Pre-money",Catalog.money(n.pre_money))
 UI.pair(offer,"Post-money",Catalog.money(n.amount+n.pre_money))
 UI.label(offer,"Интерес %.0f / 100 · Терпение %d"%[n.interest,n.patience],14,UI.TEXT,true)
 UI.progress(offer,n.interest)
 var investor=UI.column(people);UI.portrait(investor,Catalog.appearance(int(inv.portrait)),Vector2(230,230));UI.label(investor,inv.name,18,UI.TEXT,true)
 var dialogue=UI.card(col,Color("133e59"))
 UI.text(dialogue,"«"+n.dialogue+"»",19,Color.WHITE)
 if n.closed:
  UI.button(col,"Вернуться к компании",func():ui.close_panel();Game.updated.emit(),true)
 else:
  var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);col.add_child(grid)
  var actions=[["accept","Принять предложение"],["counter","Предложить меньшую долю"],["more","Запросить большую сумму"],["reports","Показать финансовые отчёты"],["growth","Показать рост клиентов"],["vision","Представить стратегию"],["middle","Предложить меньший раунд"],["later","Перенести встречу"],["decline","Отказаться"]]
  for a in actions:
   var b=UI.button(grid,a[1],func():respond(a[0]),a[0]=="accept");b.custom_minimum_size.x=320
   b.disabled=a[0] in n.used

func respond(action: String) -> void:
 var err=Negotiation.respond(Game.state,Game.company(),action)
 if not err.is_empty():ui.show_toast(err,"success" if Game.company().negotiation.accepted else "info")
 if Game.company().negotiation.accepted:ui.audio.play_cue("funding")
 else:ui.audio.play_cue("click")
 Game.updated.emit();show_negotiation()
