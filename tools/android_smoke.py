"""ADB smoke helper: real taps and screenshots on the local QA emulator."""
import pathlib,subprocess,sys,time,json
root=pathlib.Path(__file__).resolve().parents[1]
adb=str(root/'.toolchain/android-sdk/platform-tools/adb')
out=root/'docs/qa/android';out.mkdir(parents=True,exist_ok=True)
def run(*args):return subprocess.run([adb,*map(str,args)],capture_output=True,timeout=45,check=True).stdout
command=sys.argv[1]
if command=='tap':
 run('shell','input','tap',int(sys.argv[2]),int(sys.argv[3]))
 time.sleep(2)
elif command=='shot':
 name=sys.argv[2]
 data=run('exec-out','screencap','-p')
 assert data.startswith(b'\x89PNG\r\n\x1a\n'), 'Screenshot must be a real PNG'
 (out/(name+'.png')).write_bytes(data)
 print(out/(name+'.png'),len(data),'bytes')
elif command=='back':
 run('shell','input','keyevent',4);time.sleep(1)
elif command=='launch':
 run('shell','am','start','-n','com.capital31.empire/com.godot.game.GodotAppLauncher');time.sleep(3)
elif command=='restart':
 run('shell','input','keyevent',3);time.sleep(2)
 run('shell','am','force-stop','com.capital31.empire')
 run('shell','am','start','-n','com.capital31.empire/com.godot.game.GodotAppLauncher');time.sleep(4)
elif command=='save':
 run('shell','input','keyevent',3);time.sleep(2)
 data=run('exec-out','cat','/data/user/0/com.capital31.empire/files/saves/slot_0.capital')
 (root/'.toolchain/android-slot.capital').write_bytes(data)
 print('Pulled actual Android save:',len(data),'bytes')
elif command=='offline':
 run('shell','svc','wifi','disable');run('shell','svc','data','disable')
else:raise SystemExit('Unknown command')
