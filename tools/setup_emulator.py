"""Optional local Android smoke-test environment, no backend."""
import json,pathlib,urllib.request,zipfile
root=pathlib.Path(__file__).resolve().parents[1]
tc=root/'.toolchain';sdk=tc/'android-sdk'
downloads=json.load(open('/tmp/capital-emulator-downloads.json'))
for kind,entry in downloads.items():
 archive=tc/(kind+'.zip')
 if not archive.exists():
  print('Downloading',kind,entry['size'],flush=True)
  urllib.request.urlretrieve(entry['url'],archive)
 target=sdk if kind=='emulator' else sdk/'system-images/android-30/default'
 target.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(archive) as z:z.extractall(target)
for p in (sdk/'emulator').rglob('*'):
 if p.is_file() and (p.suffix=='' or p.suffix=='.so'):p.chmod(0o755)
avd=tc/'avd';device=avd/'capital.avd';device.mkdir(parents=True,exist_ok=True)
(avd/'capital.ini').write_text(f'avd.ini.encoding=UTF-8\npath={device}\ntarget=android-30\n')
(device/'config.ini').write_text(f'''AvdId=capital
avd.ini.displayname=CAPITAL QA
abi.type=x86_64
hw.cpu.arch=x86_64
hw.cpu.ncore=4
hw.ramSize=2048
hw.lcd.width=1280
hw.lcd.height=720
hw.lcd.density=160
hw.gpu.enabled=yes
hw.gpu.mode=swiftshader_indirect
hw.keyboard=yes
hw.mainKeys=no
disk.dataPartition.size=2048M
image.sysdir.1={sdk}/system-images/android-30/default/x86_64/
tag.id=default
tag.display=Default
fastboot.forceColdBoot=yes
''')
print('Emulator ready',flush=True)
