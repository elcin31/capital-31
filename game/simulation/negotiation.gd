class_name Negotiation
extends RefCounted

static func valuation(c: Dictionary) -> int:
 var l=Ledger.new(c.ledger)
 var r=l.report(maxi(0,int(c.get("day",0))-30))
 var quality: float=0
 for p in c.products: quality+=p.quality*40000+p.customers*1800
 return maxi(2000000,int(l.accounts.capital*1.4+r.revenue*24+quality-l.accounts.debt*0.8))

static func start(state: Dictionary, c: Dictionary, investor_id: int, amount: int) -> Dictionary:
 var inv=Catalog.INVESTORS[investor_id]
 var memory=state.investor_memory.get(str(investor_id),{"trust":50.0,"meetings":0,"deals":0,"refused":0,"invested":0})
 state.investor_memory[str(investor_id)]=memory
 memory.meetings+=1
 var l=Ledger.new(c.ledger)
 var r=l.report(maxi(0,int(state.hour)/24-30))
 var quality: float=0
 for p in c.products: quality=maxf(quality,p.quality)
 var interest=25.0+inv.risk*18.0+(20.0 if inv.industry==c.industry else -8.0)+quality*0.12+state.founder.skills[6]*0.12+(memory.trust-50)*0.2
 interest+=clampf(float(r.revenue)/150000.0,0,15)+clampf(float(r.net)/300000.0,-15,10)-minf(20,float(l.accounts.debt)/2000000)
 var value=valuation(c)
 var remaining=maxi(0,int(inv.capital)-int(memory.get("invested",0)))
 var offered=mini(remaining,clampi(amount,1000000,int(inv.capital*0.35)))
 var share=clampf(float(offered)/(value+offered)*(1.0+inv["return"]),0.05,0.65)
 if OfficeSim.has_room(c,"meeting") and OfficeSim.bonus(c,["table"])>0:interest+=5
 var n={"investor":investor_id,"amount":offered,"share":share,"pre_money":int(offered*(1-share)/share),"interest":clampf(interest,0,100),"patience":int(inv.patience),"stage":"pitch","used":[],"dialogue":"Расскажите о бизнесе. Почему сейчас подходящий момент для инвестиций?","closed":offered<=0 or c.status=="Ликвидирована","accepted":false}
 if offered<=0:n.dialogue="Мой инвестиционный капитал сейчас полностью размещён."
 c.negotiation=n
 return n

static func respond(state: Dictionary, c: Dictionary, action: String) -> String:
 var n=c.negotiation
 if n.is_empty() or n.closed: return "Встреча завершена"
 var inv=Catalog.INVESTORS[int(n.investor)]
 var mem=state.investor_memory[str(int(n.investor))]
 var l=Ledger.new(c.ledger)
 var r=l.report(maxi(0,int(state.hour)/24-30))
 if action=="decline" or action=="later":
  n.closed=true
  mem.refused+=1
  mem.trust=maxf(0,mem.trust-(1 if action=="later" else 3))
  n.dialogue="Вернёмся к разговору, когда изменятся обстоятельства."
  return "Встреча завершена"
 if action=="accept":
  if n.interest<35: n.dialogue="Риск пока слишком велик. Покажите прогресс и вернитесь."; return "Инвестор пока не готов"
  var share=float(n.share)
  for owner in c.cap_table: owner.share*=1.0-share
  var existing=false
  for owner in c.cap_table:
   if owner.id=="investor_%d" % int(n.investor): owner.share+=share; existing=true
  if not existing: c.cap_table.append({"id":"investor_%d"%int(n.investor),"name":inv.name,"share":share})
  l.post(int(state.hour)/24,"Раунд: "+inv.firm,{"cash":int(n.amount),"capital":int(n.amount)},"financing")
  c.ledger=l.export_data()
  c.rounds.append({"day":int(state.hour)/24,"investor":inv.name,"amount":n.amount,"share":share,"pre":int(n.amount*(1.0-share)/share),"post":int(n.amount/share)})
  mem.deals+=1; mem.trust=minf(100,mem.trust+8)
  mem.invested=int(mem.get("invested",0))+int(n.amount)
  n.closed=true; n.accepted=true; n.dialogue="Сделка заключена. Средства поступили на счёт компании. За работу!"
  state.founder.skills[2]=minf(100,state.founder.skills[2]+2)
  return "Инвестиции получены"
 if action in n.used: return "Этот аргумент уже использован"
 n.used.append(action)
 n.patience-=1
 match action:
  "reports":
   var gain=12 if r.net>0 else (6 if r.revenue>0 else -3)
   n.interest+=gain
   n.dialogue="Положительная прибыль — хороший знак." if r.net>0 else "Прозрачность ценю. Но мне нужен путь к прибыли."
  "growth":
   var customers=0
   for p in c.products: customers+=int(p.customers)
   n.interest+=14 if customers>100 else (7 if customers>0 else -6)
   n.dialogue="Клиентская база подтверждает спрос." if customers>0 else "Пока нет клиентов, это прогноз, а не доказательство."
  "vision":
   n.interest+=state.founder.skills[2]*0.12+state.founder.skills[3]*0.06
   n.dialogue="Амбициозный план. Я учитываю опыт вашей команды."
  "counter":
   var reduction=0.03+state.founder.skills[2]*0.0005
   if n.interest>48:
    n.share=maxf(0.04,n.share-reduction); n.interest-=8
    n.dialogue="Соглашусь на меньшую долю при этих условиях."
   else:
    n.interest-=12; n.dialogue="Текущие риски не позволяют снизить долю."
  "more":
   if n.interest>60 and n.amount*1.25<minf(inv.capital*0.4,inv.capital-int(mem.get("invested",0))):
    n.amount=int(n.amount*1.25); n.share=minf(0.70,n.share+0.035); n.interest-=5
    n.dialogue="Готов увеличить сумму, но потребуется большая доля."
   else: n.interest-=10; n.dialogue="Большая сумма сейчас не оправдана."
  "middle":
   n.amount=int(n.amount*0.75); n.share=maxf(0.04,n.share*0.8); n.interest+=5
   n.dialogue="Меньший раунд снижает риск. Это разумный компромисс."
 n.interest=clampf(n.interest,0,100)
 n.pre_money=int(n.amount*(1-n.share)/n.share)
 if n.patience<=0 or n.interest<15:
  n.closed=true; mem.trust=maxf(0,mem.trust-4); n.dialogue="На сегодня закончим. Подготовьте новые результаты к следующей встрече."
 state.founder.skills[2]=minf(100,state.founder.skills[2]+0.15)
 return ""
