class_name MenuWizard
extends RefCounted

var ui: Control
var founder: Dictionary={"first":"Алекс","last":"Волков","bio":0,"appearance":Catalog.appearance(0)}
var city_id: int=0
var industry: int=0
var model: int=0
var capital_index: int=1
var company_name: String="NOVA Technologies"
var career_mode: bool=false

func _init(host: Control) -> void:ui=host

func show_menu() -> void:
 Game.speed=0;ui.close_panel();ui.game_layer.hide()
 if is_instance_valid(ui.menu_layer):ui.menu_layer.queue_free()
 ui.menu_layer=Control.new();ui.menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(ui.menu_layer)
 var image=TextureRect.new();image.texture=preload("res://assets/capital-city.png");image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.menu_layer.add_child(image)
 var shade=ColorRect.new();shade.color=Color(0.03,0.13,0.23,0.50);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.menu_layer.add_child(shade)
 var panel=PanelContainer.new();panel.add_theme_stylebox_override("panel",UI.style(Color(0.04,0.15,0.25,0.95),24));ui.menu_layer.add_child(panel)
 ui.place(panel,Rect2(Vector2(60,72),Vector2(465,ui.size.y-144)))
 var v=UI.column(panel);v.add_theme_constant_override("separation",19)
 UI.label(v,"▥  CAPITAL",45,Color.WHITE,true)
 UI.label(v,"B U S I N E S S   E M P I R E",14,Color("53ddec"),true)
 UI.separator(v)
 UI.text(v,"Ваша идея. Ваша компания.\nВаша история успеха.",24,Color.WHITE)
 UI.text(v,"Стройте офисы, создавайте продукты и меняйте правила рынка.",16,Color("abcddd"))
 var spacer=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;v.add_child(spacer)
 UI.button(v,"Начать новую историю  →",func():career_mode=false;show_founder(),true)
 var continue_button=UI.button(v,"Продолжить",func():
  if not Game.state.is_empty():ui.enter_game()
  else:ui.perform(func():return Game.load_slot(0),ui.enter_game))
 continue_button.disabled=Game.state.is_empty() and SaveStore.load_game(0).is_empty()
 UI.button(v,"Локальные сохранения",func():ui.global_screens.show_saves())
 UI.button(v,"Настройки",ui.global_screens.show_settings)
 UI.label(v,"OFFLINE  ·  ANDROID  ·  v1.0",12,Color("79b3ca"))
 UI.label(ui.menu_layer,"ПОСТРОЙТЕ СВОЮ ИМПЕРИЮ",23,Color.WHITE,true).position=Vector2(ui.size.x-525,ui.size.y-100)

func show_founder() -> void:
 var col=ui.open_panel("01 / Ваш предприниматель",1160)
 var row=UI.row(col)
 var profile=UI.column(row,false);profile.custom_minimum_size.x=260
 var portrait=UI.portrait(profile,founder.appearance,Vector2(250,300))
 UI.label(profile,"Личный капитал: €300 000",16,UI.BLUE,true)
 UI.text(profile,"Личные средства и деньги компании учитываются отдельно.",14)
 var form=UI.column(row)
 var names=UI.row(form)
 UI.field(UI.column(names),"Имя",founder.first,func(s):founder.first=s)
 UI.field(UI.column(names),"Фамилия",founder.last,func(s):founder.last=s)
 var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",8);form.add_child(grid)
 var fields=[
 ["gender","Пол",["Мужской","Женский"]],["face","Лицо",["Овал","Мягкое","Угловатое","Широкое"]],
 ["skin","Тон кожи",["Светлый","Тёплый","Золотистый","Смуглый","Тёмный","Фарфоровый"]],
 ["hair","Причёска",["Классика","Пробор","Длинные","Волны","Каре","Бритая","Свободная"]],
 ["hair_color","Цвет волос",["Чёрный","Каштановый","Рыжий","Блонд","Серебро"]],
 ["eyes","Глаза",["Голубые","Зелёные","Карие","Тёмные"]],
 ["outfit","Одежда",["Деловой синий","Electric Blue","Изумруд","Бордо","Терракота","Серый индиго"]],
 ["accessory","Аксессуары",["Без аксессуаров","Очки","Серьги","Очки и серьги"]],
 ["style","Стиль портрета",["Современный","Золотая рамка"]]]
 for field in fields:
  var box=UI.column(grid)
  UI.option(box,field[1],field[2],int(founder.appearance[field[0]]),func(n):founder.appearance[field[0]]=n;portrait.queue_redraw())
 UI.option(form,"Профессиональная биография",Catalog.BIOS,int(founder.bio),func(n):founder.bio=n)
 UI.label(col,"24 НАЧАЛЬНЫХ ОБРАЗА · каждый можно изменить",13,UI.BLUE,true)
 var presets=GridContainer.new();presets.columns=12;col.add_child(presets)
 for i in range(24):
  var button=UI.button(presets,"%02d"%(i+1),func():founder.appearance=Catalog.appearance(i);show_founder())
  button.custom_minimum_size.x=64
 UI.button(col,"Далее: страна и город  →",show_city,true)

func show_city() -> void:
 var col=ui.open_panel("02 / Где начнётся ваша история?",1120)
 UI.text(col,"Все параметры ниже — сбалансированные игровые величины, а не актуальная статистика стран.",14)
 var options=UI.row(col)
 for i in range(5):
  var b=UI.button(options,Catalog.CITIES[i].name,func():city_id=i;show_city(),i==city_id)
  b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_font_size_override("font_size",14)
 var city=Catalog.CITIES[city_id]
 var content=UI.row(col)
 var preview=PanelContainer.new();preview.clip_contents=true;preview.custom_minimum_size=Vector2(460,265);preview.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_child(preview)
 var canvas=CityCanvas.new();canvas.position=Vector2(240,-95);canvas.scale=Vector2.ONE*0.43;preview.add_child(canvas);canvas.setup(city_id)
 var info=UI.column(content)
 UI.label(info,city.name+" · "+city.country,24,UI.TEXT,true)
 UI.pair(info,"Аренда / месяц",Catalog.money(city.rent))
 UI.pair(info,"Зарплата / день",Catalog.money(city.wage))
 UI.pair(info,"Размер рынка","%.2f×"%city.market)
 UI.pair(info,"Покупательная способность","%.2f×"%city.power)
 UI.pair(info,"Таланты / конкуренция","%.2f / %.2f"%[city.talent,city.competition])
 UI.pair(info,"Налог / кредит","%.0f%% / %.1f%%"%[city.tax*100,city.rate*100])
 UI.text(col,["Берлин: сбалансированный рынок и сильные специалисты. Налоги требуют дисциплины.","Сан-Франциско: большой IT-рынок и венчурный капитал, высокая стоимость команды.","Дубай: торговля, инфраструктура и низкий налог. Меньше локальных клиентов.","Бангалор: доступные инженеры и большой рынок, ниже выручка на клиента.","Москва: сильные инженеры и промышленный спрос, дорогие кредиты."][city_id],17,UI.TEXT)
 var r=UI.row(col)
 UI.button(r,"← Персонаж",show_founder)
 UI.button(r,"Далее: регистрация компании  →",show_company,true)

func show_company() -> void:
 var col=ui.open_panel("03 / Создайте компанию",940)
 UI.label(col,"От маленького офиса — к международной группе",23,UI.BLUE,true)
 UI.field(col,"Название компании",company_name,func(s):company_name=s)
 UI.option(col,"Отрасль",Catalog.INDUSTRIES,industry,func(n):industry=n;model=0;show_company())
 UI.option(col,"Направление и бизнес-модель",Catalog.MODELS[industry],model,func(n):model=n)
 UI.option(col,"Логотип",["▥ Стеклянная башня","◈ Геометрия роста","◎ Новые горизонты"],industry)
 UI.option(col,"Вклад из личных средств",["€40 000 · осторожный старт","€80 000 · сбалансированный старт","€140 000 · быстрый рост"],capital_index,func(n):capital_index=n)
 UI.pair(col,"Штаб-квартира",Catalog.CITIES[city_id].name)
 UI.text(col,["IT: разработка → тестирование → запуск → подписки и поддержка. Нужны разработчики и компьютеры.","Розница: торговый зал и касса → закупка товаров → склад → продажи. Следите за запасами.","Производство: цех и линия → закупка сырья → сборка → контроль качества → отгрузка."][industry],17,UI.TEXT)
 var r=UI.row(col)
 UI.button(r,"← Выбрать город",show_city)
 UI.button(r,"Зарегистрировать компанию  →",finish,true)

func finish() -> void:
 if founder.first.strip_edges().is_empty() or company_name.strip_edges().is_empty():ui.show_toast("Введите имя и название компании","warning");return
 var capital=[4000000,8000000,14000000][capital_index]
 if career_mode:
  var error=Game.register_company(city_id,company_name,industry,capital,model)
  if not error.is_empty():ui.show_toast(error,"warning");return
 else:Game.start_game(founder,city_id,company_name,industry,capital,model)
 ui.audio.play_cue("level");ui.enter_game()

func save_frame(name: String) -> void:
 for i in range(4):await ui.get_tree().process_frame
 var dir=ProjectSettings.globalize_path("res://../docs/design/screens")
 DirAccess.make_dir_recursive_absolute(dir)
 ui.get_viewport().get_texture().get_image().save_png(dir+"/"+name+".png")

func capture_all() -> void:
 await save_frame("01-menu");show_founder();await save_frame("02-founder");show_city();await save_frame("03-city-selection");show_company();await save_frame("04-company")
 finish();Game.rent_office();Game.build_room(11,1,1,0);Game.buy_furniture(0,2,2,0);Game.buy_furniture(1,3,3,0)
 Game.hire(Game.candidates()[0]);Game.hire(Game.candidates()[1]);Game.start_product("Nexa AI",4900,75,1,250000,4)
 for i in range(24*38):Economy.hour(Game.state)
 Game.product_action(0,"launch")
 for i in range(24*18):Economy.hour(Game.state)
 ui.refresh_values();ui.world.refresh()
 await save_frame("05-city");ui.navigate("office");await save_frame("06-office");ui.business.show_build();await save_frame("07-construction")
 ui.business.show_employees();await save_frame("08-employees");ui.business.show_products();await save_frame("09-products")
 ui.finances.show_finance();await save_frame("10-finance");ui.funding.show_investors();await save_frame("11-investors")
 Negotiation.start(Game.state,Game.company(),0,10000000);ui.funding.show_negotiation();await save_frame("12-negotiation")
 ui.global_screens.show_competitors();await save_frame("13-competitors");ui.global_screens.show_world();await save_frame("14-world")
 ui.global_screens.show_news();await save_frame("15-events");ui.global_screens.show_career();await save_frame("16-career")
 ui.global_screens.show_bankruptcy();await save_frame("17-bankruptcy")
 ui.get_tree().quit()
