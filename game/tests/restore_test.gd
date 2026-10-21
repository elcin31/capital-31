extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 SaveStore.base_path="user://qa_gui_saves"
 var game=root.get_node("Game")
 var error=game.load_slot(2)
 var ok=error.is_empty() and game.company().products.size()==1 and game.company().products[0].revenue>0 and game.company().rounds.size()==1
 var before=int(game.state.hour)
 if ok:
  game.speed=10;game.advance_time(0.2);game.speed=0
 ok=ok and int(game.state.hour)==before+1 and game.ledger().balance_error()==0
 var result={"passed":ok,"scenario":"Load GUI test slot in a new OS process, verify product revenue and investment round, advance one hour"}
 var file=FileAccess.open("res://../docs/QA-RESTART.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
 print("PROCESS RESTART: ","PASS" if ok else "FAIL")
 quit(0 if ok else 1)
