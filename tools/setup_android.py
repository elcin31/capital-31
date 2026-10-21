"""Install pinned Godot Android export tools locally; no root or cloud resources."""
import io, os, pathlib, struct, urllib.request, zipfile, re, shutil

ROOT = pathlib.Path(__file__).resolve().parents[1]
TC = ROOT / '.toolchain'
TC.mkdir(exist_ok=True)

class RemoteZip(io.RawIOBase):
    def __init__(self, url, length):
        self.url, self.length, self.pos = url, length, 0
    def seekable(self): return True
    def tell(self): return self.pos
    def seek(self, n, whence=0):
        self.pos = n if whence == 0 else self.pos+n if whence == 1 else self.length+n
        return self.pos
    def read(self, n=-1):
        n = min(n if n >= 0 else self.length-self.pos, self.length-self.pos)
        if n <= 0: return b''
        req = urllib.request.Request(self.url, headers={'Range': f'bytes={self.pos}-{self.pos+n-1}'})
        with urllib.request.urlopen(req, timeout=120) as r:
            if r.status != 206: raise RuntimeError('Server must honor byte ranges')
            b = r.read()
        self.pos += len(b)
        return b

def fetch(url, name):
    dst = TC / name
    if not dst.exists():
        print('Downloading', name, flush=True)
        urllib.request.urlretrieve(url, dst)
    return dst

def install():
    templates = pathlib.Path.home()/'.local/share/godot/export_templates/4.6.3.stable'
    templates.mkdir(parents=True, exist_ok=True)
    if not (templates/'android_release.apk').exists():
        url = 'https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz'
        with zipfile.ZipFile(RemoteZip(url, 1255918323)) as z:
            for name in ('android_release.apk', 'android_debug.apk', 'version.txt'):
                member = next(i for i in z.namelist() if i.endswith('/'+name))
                print('Extracting', name, flush=True)
                (templates/name).write_bytes(z.read(member))
    sdk = TC/'android-sdk'
    sdk.mkdir(exist_ok=True)
    for url, name, target in [
        ('https://dl.google.com/android/repository/platform-tools-latest-linux.zip','platform-tools.zip',sdk),
        ('https://dl.google.com/android/repository/build-tools_r35_linux.zip','build-tools.zip',TC/'build-extract')]:
        if not (sdk/('platform-tools/adb' if name.startswith('platform') else 'build-tools/35.0.0/apksigner')).exists():
            with zipfile.ZipFile(fetch(url,name)) as z: z.extractall(target)
            if name=='build-tools.zip':
                (sdk/'build-tools').mkdir(exist_ok=True)
                (target/'android-15').rename(sdk/'build-tools/35.0.0')
    for path in sdk.rglob('*'):
        if path.is_file() and (path.suffix == '' or path.name == 'apksigner'): path.chmod(0o755)
    config_root=pathlib.Path(os.environ.get('XDG_CONFIG_HOME',str(pathlib.Path.home()/'.config')))/'godot'
    config_root.mkdir(parents=True,exist_ok=True)
    config=config_root/'editor_settings-4.6.tres'
    settings=config.read_text() if config.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    java=pathlib.Path(shutil.which('java')).resolve().parents[1]
    for key,value in {'android_sdk_path':str(sdk),'java_sdk_path':str(java),'shutdown_adb_on_exit':False}.items():
        text_value='false' if value is False else '"'+value+'"'
        line='export/android/'+key+' = '+text_value
        pattern=r'^export/android/'+key+r' = .*'
        settings=re.sub(pattern,lambda _:line,settings,flags=re.M) if re.search(pattern,settings,re.M) else settings+'\n'+line+'\n'
    config.write_text(settings)
    print('Android SDK ready:',sdk,flush=True)

if __name__ == '__main__': install()
