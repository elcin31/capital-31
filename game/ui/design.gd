class_name UI
extends RefCounted

const BG=Color("f3f8ff")
const TEXT=Color("102c50")
const MUTED=Color("718ca5")
const BLUE=Color("168bff")
const GREEN=Color("19c78b")
const FONT=preload("res://assets/fonts/DejaVuSans.ttf")
const BOLD=preload("res://assets/fonts/DejaVuSans-Bold.ttf")

static func style(color: Color = Color.WHITE, radius: int = 14, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=color; s.set_corner_radius_all(radius); s.border_color=border
 s.set_border_width_all(1 if border.a>0 else 0)
 s.content_margin_left=16; s.content_margin_right=16; s.content_margin_top=12; s.content_margin_bottom=12
 return s

static func theme() -> Theme:
 var t=Theme.new()
 t.default_font=FONT; t.default_font_size=17
 t.set_color("font_color","Label",TEXT)
 for type in ["Button","OptionButton"]:
  t.set_stylebox("normal",type,style(Color("eaf4ff"),10,Color("d6e8fa")))
  t.set_stylebox("hover",type,style(Color("d7edff"),10,Color("a9d8ff")))
  t.set_stylebox("pressed",type,style(BLUE,10))
  t.set_stylebox("focus",type,style(Color(0,0,0,0),10,Color("00cff3")))
  t.set_stylebox("disabled",type,style(Color("edf0f5"),10))
  t.set_color("font_color",type,TEXT);t.set_color("font_pressed_color",type,Color.WHITE);t.set_color("font_hover_color",type,TEXT);t.set_color("font_disabled_color",type,Color("9baec1"))
  t.set_font_size("font_size",type,16)
 t.set_stylebox("normal","LineEdit",style(Color("f5f9ff"),10,Color("d3e4f4")))
 t.set_stylebox("focus","LineEdit",style(Color.WHITE,10,BLUE))
 t.set_color("font_color","LineEdit",TEXT);t.set_color("caret_color","LineEdit",BLUE)
 t.set_stylebox("background","ProgressBar",style(Color("e2edf7"),6))
 t.set_stylebox("fill","ProgressBar",style(GREEN,6))
 t.set_color("font_color","ProgressBar",TEXT)
 t.set_stylebox("panel","PopupMenu",style(Color.WHITE,10,Color("c8dff2")))
 t.set_color("font_color","PopupMenu",TEXT)
 t.set_stylebox("hover","PopupMenu",style(Color("d9efff"),6))
 t.set_stylebox("panel","PanelContainer",style())
 t.set_constant("separation","VBoxContainer",12)
 t.set_constant("separation","HBoxContainer",12)
 return t

static func label(parent: Node, value: String, size_value: int = 17, color: Color = TEXT, bold: bool = false) -> Label:
 var l=Label.new();l.text=value;l.add_theme_font_size_override("font_size",size_value);l.add_theme_color_override("font_color",color)
 if bold:l.add_theme_font_override("font",BOLD)
 l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(l)
 return l

static func text(parent: Node, value: String, size_value: int = 16, color: Color = MUTED) -> Label:
 var l=label(parent,value,size_value,color)
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 return l

static func button(parent: Node, title: String, callback: Callable, primary: bool = false) -> Button:
 var b=Button.new();b.text=title;b.custom_minimum_size.y=44;b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 b.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 if primary:
  b.add_theme_stylebox_override("normal",style(BLUE,10));b.add_theme_stylebox_override("hover",style(Color("37a4ff"),10));b.add_theme_color_override("font_color",Color.WHITE);b.add_theme_color_override("font_hover_color",Color.WHITE)
 parent.add_child(b)
 b.pressed.connect(callback)
 return b

static func row(parent: Node, expand: bool = false) -> HBoxContainer:
 var r=HBoxContainer.new();parent.add_child(r)
 if expand:r.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 return r

static func column(parent: Node, expand: bool = true) -> VBoxContainer:
 var v=VBoxContainer.new();parent.add_child(v)
 if expand:v.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 return v

static func card(parent: Node, color: Color = Color.WHITE) -> VBoxContainer:
 var p=PanelContainer.new();p.add_theme_stylebox_override("panel",style(color,12,Color("deebf5")));p.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(p)
 return column(p)

static func scroll(parent: Node) -> VBoxContainer:
 var s=ScrollContainer.new();s.size_flags_vertical=Control.SIZE_EXPAND_FILL;s.size_flags_horizontal=Control.SIZE_EXPAND_FILL;s.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 parent.add_child(s)
 var v=column(s);v.add_theme_constant_override("separation",12)
 return v

static func field(parent: Node, title: String, value: String, callback: Callable = Callable()) -> LineEdit:
 label(parent,title,13,MUTED,true)
 var e=LineEdit.new();e.text=value;e.custom_minimum_size.y=44;e.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(e)
 if callback.is_valid():e.text_changed.connect(callback)
 return e

static func option(parent: Node, title: String, items: Array, selected: int = 0, callback: Callable = Callable()) -> OptionButton:
 if not title.is_empty():label(parent,title,13,MUTED,true)
 var b=OptionButton.new();b.custom_minimum_size.y=44;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for item in items:b.add_item(str(item))
 b.select(clampi(selected,0,maxi(0,items.size()-1)));parent.add_child(b)
 if callback.is_valid():b.item_selected.connect(callback)
 return b

static func metric(parent: Node, title: String, value: String, color: Color = TEXT) -> Label:
 var v=column(parent)
 label(v,title,12,MUTED)
 return label(v,value,22,color,true)

static func pair(parent: Node, title: String, value: String, color: Color = TEXT) -> Label:
 var r=row(parent)
 var l=label(r,title,15,MUTED);l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 return label(r,value,16,color,true)

static func progress(parent: Node, value: float) -> ProgressBar:
 var p=ProgressBar.new();p.value=value;p.show_percentage=false;p.custom_minimum_size.y=10;parent.add_child(p);return p

static func portrait(parent: Node, appearance: Dictionary, dimensions: Vector2 = Vector2(120,140)) -> Portrait:
 var p=Portrait.new();p.appearance=appearance;p.custom_minimum_size=dimensions;parent.add_child(p);return p

static func separator(parent: Node) -> void:
 var s=HSeparator.new();s.modulate=Color("c8dfef");parent.add_child(s)
