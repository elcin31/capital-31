class_name Portrait
extends Control

var appearance: Dictionary = Catalog.appearance(0)
var negotiating: bool = false

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)

func _draw() -> void:
 Art.portrait(self,Rect2(Vector2.ZERO,size),appearance,negotiating)
