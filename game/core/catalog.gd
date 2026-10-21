class_name Catalog
extends RefCounted

const CITIES = [
 {"name":"Берлин","en":"Berlin","country":"Германия","flag":"DE","rent":210000,"wage":13000,"talent":0.88,"power":1.12,"competition":1.0,"climate":0.85,"market":1.0,"infra":0.93,"demand":[1.10,1.0,1.06],"rate":0.065,"tax":0.28,"inflation":0.025,"investors":1.0,"color":"168bff","style":"europe","lat":52.5,"lon":13.4},
 {"name":"Сан-Франциско","en":"San Francisco","country":"США","flag":"US","rent":410000,"wage":22000,"talent":1.18,"power":1.5,"competition":1.45,"climate":0.92,"market":1.5,"infra":0.94,"demand":[1.40,1.05,0.85],"rate":0.085,"tax":0.26,"inflation":0.03,"investors":1.5,"color":"ffaa32","style":"bay","lat":37.8,"lon":-122.4},
 {"name":"Дубай","en":"Dubai","country":"ОАЭ","flag":"AE","rent":300000,"wage":16000,"talent":0.85,"power":1.35,"competition":1.10,"climate":1.0,"market":0.92,"infra":1.1,"demand":[1.0,1.30,1.1],"rate":0.075,"tax":0.09,"inflation":0.03,"investors":1.2,"color":"ffd24a","style":"desert","lat":25.2,"lon":55.3},
 {"name":"Бангалор","en":"Bengaluru","country":"Индия","flag":"IN","rent":100000,"wage":7000,"talent":0.98,"power":0.65,"competition":1.18,"climate":0.78,"market":1.75,"infra":0.72,"demand":[1.24,1.20,1.1],"rate":0.105,"tax":0.25,"inflation":0.05,"investors":0.85,"color":"19c78b","style":"garden","lat":12.9,"lon":77.6},
 {"name":"Москва","en":"Moscow","country":"Россия","flag":"RU","rent":160000,"wage":10000,"talent":0.92,"power":0.85,"competition":0.95,"climate":0.68,"market":1.2,"infra":0.91,"demand":[1.12,1.15,1.25],"rate":0.145,"tax":0.25,"inflation":0.065,"investors":0.70,"color":"b28aff","style":"metro","lat":55.8,"lon":37.6}
]
const INDUSTRIES = ["IT / Технологии","Розница / Торговля","Производство"]
const MODELS = [["Подписка SaaS","Мобильное приложение","Игра","Корпоративное ПО","AI-сервис","Автоматизация"],["Магазин","Интернет-торговля","Поставки товаров","Торговая сеть"],["Электроника","Бытовые товары","Промышленное оборудование","Компоненты"]]
const ROOM_DEFS = [
 {"name":"Открытый офис","kind":"work","cost":180000,"color":"bde6ff","industry":-1},
 {"name":"Кабинет CEO","kind":"ceo","cost":160000,"color":"cad8ff","industry":-1},
 {"name":"Переговорная","kind":"meeting","cost":190000,"color":"d9cbff","industry":-1},
 {"name":"Комната отдыха","kind":"break","cost":120000,"color":"b6f3d8","industry":-1},
 {"name":"Кухня","kind":"kitchen","cost":130000,"color":"ffe4b3","industry":-1},
 {"name":"Приёмная","kind":"reception","cost":140000,"color":"b9e9f4","industry":-1},
 {"name":"Финансовый отдел","kind":"finance","cost":150000,"color":"c7e9da","industry":-1},
 {"name":"Отдел кадров","kind":"hr","cost":140000,"color":"ffdcce","industry":-1},
 {"name":"Маркетинг","kind":"marketing","cost":170000,"color":"ffd8e9","industry":-1},
 {"name":"Санузел","kind":"restroom","cost":100000,"color":"d6eff2","industry":-1},
 {"name":"Склад","kind":"storage","cost":140000,"color":"f3dfbf","industry":-1},
 {"name":"Разработка","kind":"development","cost":200000,"color":"bce7ff","industry":0},
 {"name":"Серверная","kind":"server","cost":220000,"color":"b5c8ef","industry":0},
 {"name":"Тестовая лаборатория","kind":"testing","cost":180000,"color":"d6c5ff","industry":0},
 {"name":"Исследовательская","kind":"research","cost":240000,"color":"b4f4ed","industry":0},
 {"name":"Торговый зал","kind":"shop","cost":200000,"color":"ffe9b8","industry":1},
 {"name":"Склад товаров","kind":"warehouse","cost":190000,"color":"f2d8aa","industry":1},
 {"name":"Учёт запасов","kind":"inventory","cost":150000,"color":"d2e6bc","industry":1},
 {"name":"Логистика","kind":"logistics","cost":210000,"color":"b7dbe8","industry":1},
 {"name":"Производственный цех","kind":"production","cost":250000,"color":"ffe3a3","industry":2},
 {"name":"Контроль качества","kind":"quality","cost":190000,"color":"c6eadc","industry":2},
 {"name":"Машинный зал","kind":"machinery","cost":250000,"color":"d7dcf2","industry":2},
 {"name":"Сырьевой склад","kind":"materials","cost":170000,"color":"ecd5b2","industry":2}
]
const FURNITURE = [
 {"name":"Рабочее место","kind":"desk","cost":90000,"w":1,"h":1,"bonus":1.0,"rooms":["work","development","ceo","finance","hr","marketing","research","testing","inventory","logistics","quality"]},
 {"name":"Станция Pro","kind":"computer","cost":180000,"w":1,"h":1,"bonus":1.45,"rooms":["work","development","ceo","research","testing","quality"]},
 {"name":"Стол переговоров","kind":"table","cost":110000,"w":2,"h":1,"bonus":1.15,"rooms":["meeting"]},
 {"name":"Диван","kind":"sofa","cost":60000,"w":2,"h":1,"bonus":1.2,"rooms":["break","reception"]},
 {"name":"Кофе-станция","kind":"coffee","cost":45000,"w":1,"h":1,"bonus":1.1,"rooms":["kitchen","break"]},
 {"name":"Серверная стойка","kind":"server","cost":220000,"w":1,"h":1,"bonus":1.3,"rooms":["server"]},
 {"name":"Стеллаж товаров","kind":"shelf","cost":80000,"w":1,"h":1,"bonus":100,"rooms":["shop","warehouse","storage","materials"]},
 {"name":"Кассовый терминал","kind":"checkout","cost":100000,"w":1,"h":1,"bonus":1.2,"rooms":["shop"]},
 {"name":"Сборочная линия","kind":"machine","cost":380000,"w":2,"h":1,"bonus":20,"rooms":["production","machinery"]},
 {"name":"Испытательный стенд","kind":"lab","cost":160000,"w":1,"h":1,"bonus":1.2,"rooms":["testing","quality","research"]},
 {"name":"Растение","kind":"plant","cost":12000,"w":1,"h":1,"bonus":0.02,"rooms":[]},
 {"name":"Шкаф","kind":"cabinet","cost":35000,"w":1,"h":1,"bonus":1.03,"rooms":[]}
]
const ROLES = ["Разработчик","Маркетолог","Финансист","HR-менеджер","Продавец","Логист","Инженер","Контролёр качества","Исследователь"]
const SKILLS = ["Лидерство","Финансы","Переговоры","Технологии","Маркетинг","Управление","Репутация"]
const BIOS = ["Инженер: +15 к технологиям","Финансист: +15 к финансам","Маркетолог: +15 к маркетингу","Предприниматель: +15 к переговорам"]
const FIRST_NAMES = ["Алекс","Мария","Даниил","София","Марк","Амина","Леон","Елена","Никита","Лейла","Артём","Вера","Адам","Майя","Роман","Нина","Эмиль","Алиса","Илья","Яна","Давид","Зара","Тимур","Анна"]
const LAST_NAMES = ["Волков","Ким","Вебер","Ковалёва","Райт","Мехта","Соколов","Беккер","Парк","Иванова","Новак","Хан"]
const INVESTORS = [
 {"name":"Клара Вебер","firm":"Vertex Capital","type":"Венчурный фонд","bio":"Инженер в прошлом. Ищет технологичные продукты с повторяющейся выручкой.","capital":90000000,"industry":0,"risk":0.75,"return":0.25,"patience":5,"temper":"Аналитик","portrait":25},
 {"name":"Джеймс Брукс","firm":"Pacific Angels","type":"Бизнес-ангел","bio":"Основал и продал три стартапа. Верит в сильных основателей.","capital":35000000,"industry":0,"risk":0.9,"return":0.18,"patience":5,"temper":"Наставник","portrait":26},
 {"name":"Амира Хадид","firm":"Oasis Ventures","type":"Частный инвестор","bio":"Развивает торговые сети и международную логистику.","capital":70000000,"industry":1,"risk":0.55,"return":0.22,"patience":4,"temper":"Прагматик","portrait":27},
 {"name":"Раджив Мехта","firm":"Foundry India","type":"Стратегический инвестор","bio":"Инвестирует в производство и эффективные цепочки поставок.","capital":65000000,"industry":2,"risk":0.6,"return":0.20,"patience":5,"temper":"Стратег","portrait":28},
 {"name":"Анна Морозова","firm":"Север Капитал","type":"Инвестиционная компания","bio":"Ценит устойчивый денежный поток и финансовую дисциплину.","capital":55000000,"industry":2,"risk":0.4,"return":0.20,"patience":4,"temper":"Аналитик","portrait":29},
 {"name":"Дэвид Парк","firm":"Blue Seed","type":"Бизнес-ангел","bio":"Поддерживает ранние AI-проекты. Готов рисковать ради инноваций.","capital":28000000,"industry":0,"risk":0.95,"return":0.24,"patience":3,"temper":"Визионер","portrait":30},
 {"name":"Элиза Росси","firm":"Meridian Retail","type":"Стратегический инвестор","bio":"Специалист по рознице. Требует понятной юнит-экономики.","capital":80000000,"industry":1,"risk":0.45,"return":0.18,"patience":5,"temper":"Прагматик","portrait":31},
 {"name":"Омар Рашид","firm":"Atlas Holdings","type":"Инвестиционная компания","bio":"Покупает доли в растущих международных компаниях.","capital":120000000,"industry":2,"risk":0.65,"return":0.25,"patience":3,"temper":"Жёсткий","portrait":32},
 {"name":"Сара Чен","firm":"Horizon Labs","type":"Венчурный фонд","bio":"Изучает качество продукта и размер доступного рынка.","capital":110000000,"industry":0,"risk":0.8,"return":0.28,"patience":4,"temper":"Стратег","portrait":33},
 {"name":"Михаэль Краузе","firm":"Rhine Partners","type":"Частный инвестор","bio":"Предпочитает долговечные предприятия с материальными активами.","capital":48000000,"industry":2,"risk":0.35,"return":0.16,"patience":6,"temper":"Осторожный","portrait":34},
 {"name":"Прия Шарма","firm":"Lotus Growth","type":"Венчурный фонд","bio":"Расширяет доступ потребителей к цифровым и торговым услугам.","capital":75000000,"industry":1,"risk":0.7,"return":0.23,"patience":5,"temper":"Наставник","portrait":35},
 {"name":"Алексей Орлов","firm":"Новый Вектор","type":"Бизнес-ангел","bio":"Ищет предпринимателей, которые умеют выходить из кризисов.","capital":32000000,"industry":1,"risk":0.8,"return":0.21,"patience":4,"temper":"Визионер","portrait":36}
]
const EVENTS = [
 {"name":"Экономический рост","text":"Рынок оживает: спрос +18%, инвестиционный интерес растёт.","demand":1.18,"wages":1.0,"supply":1.0,"rate":0.0},
 {"name":"Рецессия","text":"Покупатели экономят. Спрос −25%; розница особенно уязвима.","demand":0.75,"wages":1.0,"supply":1.0,"rate":0.0},
 {"name":"Высокая инфляция","text":"Сырьё +22%, ожидания зарплат +12%. Проверьте маржинальность.","demand":0.96,"wages":1.12,"supply":1.22,"rate":0.02},
 {"name":"Повышение ставок","text":"Новые и плавающие кредиты дороже на 3 п.п.","demand":0.94,"wages":1.0,"supply":1.0,"rate":0.03},
 {"name":"Потребительский бум","text":"Спрос +30%. Складские запасы могут быстро закончиться.","demand":1.3,"wages":1.0,"supply":1.04,"rate":0.0},
 {"name":"Технологический прорыв","text":"IT-спрос +25%, оборудование доступнее. Конкуренты тоже ускоряются.","demand":1.08,"wages":1.0,"supply":0.94,"rate":0.0},
 {"name":"Сбой поставок","text":"Сырьё дороже на 40%; производство получает меньше материалов.","demand":0.97,"wages":1.0,"supply":1.4,"rate":0.0},
 {"name":"Дефицит специалистов","text":"Новые кандидаты ждут зарплату на 25% выше. Берегите команду.","demand":1.04,"wages":1.25,"supply":1.0,"rate":0.0},
 {"name":"Отраслевой кризис","text":"Локальный спрос −35%. Помогут новые рынки и запас ликвидности.","demand":0.65,"wages":0.98,"supply":1.1,"rate":0.01},
 {"name":"Кредитное сжатие","text":"Ставки +5 п.п.; получить крупный кредит сложнее.","demand":0.86,"wages":1.0,"supply":1.03,"rate":0.05}
]

static func money(cents: float, compact: bool = false) -> String:
 var n = cents / 100.0
 var sign_text = "−" if n < 0 else ""
 n = absf(n)
 if compact and n >= 1000000: return sign_text + "€%.2f млн" % (n/1000000.0)
 if compact and n >= 10000: return sign_text + "€%.1f тыс" % (n/1000.0)
 var s = str(int(round(n)))
 var out = ""
 for i in range(s.length()):
  if i > 0 and (s.length()-i) % 3 == 0: out += " "
  out += s[i]
 return sign_text + "€" + out

static func appearance(index: int) -> Dictionary:
 return {"preset":index,"gender":index%2,"face":index%4,"skin":index%6,"hair":index%7,"hair_color":index%5,"eyes":index%4,"outfit":index%6,"accessory":index%4,"style":0}
