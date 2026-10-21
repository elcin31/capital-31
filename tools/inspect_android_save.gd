extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var data=SaveStore.read_file("res://../.toolchain/android-slot.capital")
 if data.is_empty():print("ANDROID SAVE INVALID");quit(1);return
 var c=data.companies[int(data.current)]
 var l=Ledger.new(c.ledger)
 var products: Array=[]
 for p in c.products:products.append({"name":p.name,"stage":p.stage,"progress":p.progress,"required":p.required,"customers":p.customers,"revenue":p.revenue})
 var report={"hour":data.hour,"name":c.name,"founder":data.founder.first,"appearance":data.founder.appearance,"rented":c.office.rented,"rooms":c.office.rooms.size(),"furniture":c.office.furniture.size(),"employees":c.employees.size(),"products":products,"cash":l.accounts.cash,"personal":data.founder.personal,"rounds":c.rounds.size(),"cap_table":c.cap_table,"balance_error":l.balance_error(),"cashflow_reconciles":int(l.report().change)==int(l.accounts.cash)}
 var f=FileAccess.open("res://../docs/qa/android/SAVE-STATE.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print(JSON.stringify(report))
 quit(0)
