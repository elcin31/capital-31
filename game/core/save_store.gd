class_name SaveStore
extends RefCounted

const VERSION: int = 1
static var base_path: String = "user://saves"

static func path_for(slot: int) -> String:
 return base_path + "/slot_%d.capital" % slot

static func save_game(state: Dictionary, slot: int) -> String:
 if state.is_empty(): return "Нет активной игры"
 if slot < 0 or slot > 3: return "Недопустимый слот"
 DirAccess.make_dir_recursive_absolute(base_path)
 var payload = Marshalls.raw_to_base64(var_to_bytes(state))
 var wrapper = {"version":VERSION,"encoding":"variant-v1","checksum":payload.sha256_text(),"payload":payload,"saved_at":Time.get_datetime_string_from_system(true)}
 var path = path_for(slot)
 var f = FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f == null: return "Не удалось записать файл"
 f.store_string(JSON.stringify(wrapper))
 f.flush()
 f.close()
 if FileAccess.file_exists(path):
  DirAccess.remove_absolute(path+".bak")
  if DirAccess.rename_absolute(path,path+".bak") != OK: return "Не удалось создать резервную копию"
 if DirAccess.rename_absolute(path+".tmp",path) != OK: return "Не удалось завершить сохранение"
 return ""

static func read_file(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {}
 var f = FileAccess.open(path,FileAccess.READ)
 if f == null or f.get_length() > 64000000: return {}
 var parser=JSON.new()
 if parser.parse(f.get_as_text())!=OK:return {}
 var j=parser.data
 if not j is Dictionary or int(j.get("version",0)) != VERSION: return {}
 var payload = j.get("payload","")
 if not payload is String or payload.sha256_text() != j.get("checksum",""): return {}
 var d
 if j.get("encoding","")=="variant-v1":d=bytes_to_var(Marshalls.base64_to_raw(payload))
 else:
  if parser.parse(payload)!=OK:return {}
  d=parser.data
 if not d is Dictionary or not validate(d): return {}
 return d

static func validate(d: Dictionary) -> bool:
 if int(d.get("version",0)) != VERSION: return false
 if not d.get("founder") is Dictionary or not d.get("companies") is Array: return false
 if not d.has("world") or not d.has("hour"): return false
 for c in d.companies:
  if not c is Dictionary or not c.get("ledger") is Dictionary: return false
  var l = Ledger.new(c.ledger)
  if l.balance_error() != 0: return false
 return true

static func load_game(slot: int) -> Dictionary:
 if slot < 0 or slot > 3: return {}
 var d = read_file(path_for(slot))
 if d.is_empty(): d = read_file(path_for(slot)+".bak")
 return d

static func slots() -> Array:
 var out: Array = []
 for i in range(4):
  var d = load_game(i)
  out.append({"slot":i,"valid":not d.is_empty(),"name":d.get("founder",{}).get("first","Пустой слот"),"day":int(d.get("hour",0))/24,"company":d.get("companies",[{}])[0].get("name","") if not d.is_empty() and not d.companies.is_empty() else ""})
 return out

static func delete_slot(slot: int) -> void:
 if slot < 0 or slot > 3: return
 for suffix in ["",".bak",".tmp"]: DirAccess.remove_absolute(path_for(slot)+suffix)
