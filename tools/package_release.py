"""Package the actual signed APK, test evidence and build provenance."""
import datetime,hashlib,json,pathlib,subprocess,zipfile
root=pathlib.Path(__file__).resolve().parents[1]
dist=root/'dist';apk=dist/'CAPITAL-v1.0.apk'
assert apk.is_file() and apk.stat().st_size>1000000, 'Real APK required'
sdk=root/'.toolchain/android-sdk/build-tools/35.0.0'
verify=subprocess.run([str(sdk/'apksigner'),'verify','--verbose',str(apk)],capture_output=True,text=True,check=True).stdout
badging=subprocess.run([str(sdk/'aapt2'),'dump','badging',str(apk)],capture_output=True,text=True,check=True).stdout
commit=(dist/'SOURCE-COMMIT.txt').read_text().strip() if (dist/'SOURCE-COMMIT.txt').exists() else subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
digest=hashlib.sha256(apk.read_bytes()).hexdigest()
economy=json.loads((root/'docs/QA-ECONOMY.json').read_text())
gui=json.loads((root/'docs/QA-GUI.json').read_text())
restart=json.loads((root/'docs/QA-RESTART.json').read_text())
android=json.loads((root/'docs/QA-ANDROID.json').read_text()) if (root/'docs/QA-ANDROID.json').exists() else {'status':'Not yet recorded'}
readme='''CAPITAL: Business Empire — Android 1.0
Подписанная игровая тестовая сборка для личного использования.

УСТАНОВКА
1. Распакуйте ZIP на Android-устройстве.
2. Откройте CAPITAL-v1.0.apk.
3. При запросе Android разрешите установку из этого источника.
4. Запустите CAPITAL. Интернет не требуется.
Android 7.0+ (API 24), OpenGL ES 3.0+. ARM64, ARMv7; x86_64 для эмулятора.
Это не Google Play / production-подпись. Старую сборку с другой подписью
нужно удалить перед установкой; удаление приложения удаляет его сохранения.

ПЕРВЫЕ ШАГИ
Новая история → персонаж → город → компания → аренда офиса.
В офисе: «Строить» → «Разработка» → нажмите на сетку, оставив проход
слева от двери. Мебель → рабочее место. Наймите разработчика.
Создайте продукт, включите ×5 / ×10, дождитесь готовности и выпустите его.
Для торговли нужны касса, товарный стеллаж и закупка товаров;
для производства — сборочная линия, сырьевой склад и материалы.
«Финансы» показывает фактические отчёты. «Инвесторы» открывает переговоры.
Кнопка Ⅱ ставит время на паузу. Back закрывает окно / строительство.
Сохранения: меню CAPITAL → Сохранить / загрузить. Автослот — каждые 5 дней
и при сворачивании; три дополнительных ручных слота.

ОГРАНИЧЕНИЯ ЭТОГО РЕЛИЗА
Город использует оригинальные иллюстрированные 2.5D-карты с интерактивными
зданиями и отдельными анимациями. Большинство фоновых прохожих нарисованы
на карте. Полноценные агенты симулируются внутри офиса.
Основной размер комнаты в UI — 4×4 клетки; доступно до 4 этажей.
Переговоры офлайн и доступны сразу после заявки; отдельного календаря встреч
и механики обещаний инвесторам в этой версии нет.
Для закрытия холдинга сначала закройте его дочерние компании.
Баланс и денежные потоки рассчитаны игровой моделью; отрицательный остаток
обозначает кассовый разрыв и запускает последствия.
Длительная балансировка и 30 FPS на реальном Redmi Note 12 не подтверждены.
Подробности проверок, точная версия и commit — в BUILD-INFO.txt.
'''
(dist/'README.txt').write_text(readme,encoding='utf-8')
metadata=[line for line in badging.splitlines() if line.startswith(('package:','minSdkVersion:','targetSdkVersion:','native-code:','application-label:'))]
info=f'''CAPITAL Android 1.0.0 — signed personal test release
Build UTC: {datetime.datetime.now(datetime.timezone.utc).isoformat()}
Git commit: {commit}
Repository: https://github.com/elcin31/capital-31
Engine: Godot 4.6.3 stable (7d41c59c4), GDScript, OpenGL ES 3 compatibility
Android minimum: API 24 (Android 7.0)
Android compile / target: API 36 (Android 16)
APK architectures: arm64-v8a, armeabi-v7a, x86_64
Signing: RSA 2048, local test certificate, alias capitaltest; APK v2 and v3
No Internet permission, backend, accounts, ads or paid gameplay API.
APK SHA-256: {digest}

ACTUALLY EXECUTED CHECKS
Economy: {economy['checks']} checks, {economy['failed']} failures (Godot headless).
GUI: {gui['checks']} checks, {gui['failed']} failures (Xvfb/Mesa, actual pointer events,
plus touch gesture events; this suite is a desktop test of Android game logic).
New-process save restoration: {restart['passed']} — {restart['scenario']}
Android emulator evidence:
{json.dumps(android,ensure_ascii=False,indent=2)}
Physical smartphone performance: NOT MEASURED.
No claim of a physical Redmi Note 12 FPS test.

APK MANIFEST
{chr(10).join(metadata)}

SIGNATURE VERIFICATION
{verify}
'''
(dist/'BUILD-INFO.txt').write_text(info,encoding='utf-8')
archive=dist/'CAPITAL-Android-Release.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for name in ('CAPITAL-v1.0.apk','README.txt','BUILD-INFO.txt'):z.write(dist/name,name)
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 assert z.namelist()==['CAPITAL-v1.0.apk','README.txt','BUILD-INFO.txt']
 assert hashlib.sha256(z.read('CAPITAL-v1.0.apk')).hexdigest()==digest
print(archive,archive.stat().st_size,'bytes',digest)
