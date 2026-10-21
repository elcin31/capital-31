class_name Ledger
extends RefCounted

const ASSETS = ["cash","ar","inventory","equipment","depreciation","investments","deposit"]
const CLAIMS = ["ap","debt","tax_payable","capital","earnings"]
var accounts: Dictionary = {}
var journal: Array = []

func _init(data: Dictionary = {}) -> void:
 for key in ASSETS + CLAIMS: accounts[key] = int(data.get("accounts",{}).get(key,0))
 journal = data.get("journal",[]).duplicate(true)

func post(day: int, memo: String, changes: Dictionary, flow: String = "operating", pl: Dictionary = {}) -> bool:
 var left: int = 0
 var right: int = 0
 for k in changes:
  if k in ASSETS: left += int(changes[k])
  elif k in CLAIMS: right += int(changes[k])
  else:
   push_error("Unknown account: " + k)
   return false
 if left != right:
  push_error("Unbalanced entry: " + memo + ": " + str(left-right))
  return false
 for k in changes: accounts[k] += int(changes[k])
 journal.append({"day":day,"memo":memo,"changes":changes.duplicate(),"flow":flow,"cash":int(changes.get("cash",0)),"pl":pl.duplicate()})
 return true

func expense(day: int, memo: String, amount: int, category: String, accrue: bool = false) -> void:
 if amount <= 0: return
 var d = {"earnings":-amount}
 d["ap" if accrue else "cash"] = amount if accrue else -amount
 post(day,memo,d,"operating",{category:amount})

func export_data() -> Dictionary:
 return {"accounts":accounts.duplicate(),"journal":journal.duplicate(true)}

func balance_error() -> int:
 var result: int = 0
 for k in ASSETS: result += accounts[k]
 for k in CLAIMS: result -= accounts[k]
 return result

func report(from_day: int = 0, to_day: int = 999999) -> Dictionary:
 var r = {"revenue":0,"cogs":0,"wages":0,"rent":0,"marketing":0,"research":0,"maintenance":0,"interest":0,"tax":0,"depreciation":0,"operating":0,"investing":0,"financing":0}
 for entry in journal:
  if entry.day < from_day or entry.day > to_day: continue
  for k in entry.pl: r[k] = int(r.get(k,0)) + int(entry.pl[k])
  if r.has(entry.flow): r[entry.flow] += int(entry.cash)
 r["gross"] = r.revenue-r.cogs
 r["opex"] = r.wages+r.rent+r.marketing+r.research+r.maintenance
 r["ebitda"] = r.gross-r.opex
 r["ebit"] = r.ebitda-r.depreciation
 r["net"] = r.ebit-r.interest-r.tax
 r["change"] = r.operating+r.investing+r.financing
 return r
