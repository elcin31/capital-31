extends SceneTree
func _initialize() -> void:
 var image=Image.load_from_file("res://assets/icon.svg")
 if image==null:quit(1);return
 quit(0 if image.save_png("res://assets/icon.png")==OK else 1)
