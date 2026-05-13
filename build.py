

import subprocess
import sys
import os
import shutil
import urllib.request
import urllib.error
import zipfile
import tempfile

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
NSI_FILE = os.path.join(SCRIPT_DIR, "Setup", "Setup.nsi")
OUTPUT_EXE = os.path.join(SCRIPT_DIR, "KoshadeSetup.exe")
PLUGINS_DIR = os.path.join(SCRIPT_DIR, "nsis_plugins", "x86-unicode")

NSIS_PATHS = [
    r"C:\Program Files (x86)\NSIS\makensis.exe",
    r"C:\Program Files\NSIS\makensis.exe",
]

PLUGINS = [
    ("LogEx",
     "https://nsis.sourceforge.io/mediawiki/images/d/d1/LogEx.zip",
     "Plugins"),
    ("NsisUnz",
     "https://nsis.sourceforge.io/mediawiki/images/1/1c/Nsisunz.zip",
     ""),
    ("NsCurl",
     "https://github.com/negrutiu/nsis-nscurl/releases/download/v1.2022.6.7/NScurl-1.2022.6.7.7z",
     "x86-unicode"),
    ("NsProcess",
     "https://github.com/uglide/NSISPlugnsInstaller/raw/master/Unicode/Plugins/nsProcess.dll",
     None),  # None = прямой dll, не архив
    ("TitlebarProgress",
     "https://nsis.sourceforge.io/mediawiki/images/f/fc/TitlebarProgress.zip",
     ""),
    ("TaskbarProgress",
     "https://nsis.sourceforge.io/mediawiki/images/6/6f/Win7TaskbarProgress_20091109.zip",
     ""),
    ("NsJSON",
     "https://nsis.sourceforge.io/mediawiki/images/f/f0/NsJSON.zip",
     "Plugins/x86-unicode"),
    ("AccessControl",
     "https://nsis.sourceforge.io/mediawiki/images/4/4a/AccessControl.zip",
     "Plugins/i386-unicode"),
]


NSH_FILES = [
    ("MoveFileFolder.nsh",
     "https://raw.githubusercontent.com/moai/moai-beta/master/distribute/windows-installer/nsis-includes/MoveFileFolder.nsh"),
    ("StrContains.nsh",
     "https://raw.githubusercontent.com/vvaldez/yumi/master/StrContains.nsh"),
]


def find_makensis():
    found = shutil.which("makensis")
    if found:
        return found
    for path in NSIS_PATHS:
        if os.path.isfile(path):
            return path
    return None


def find_7z():
    found = shutil.which("7z")
    if found:
        return found
    for path in [r"C:\Program Files\7-Zip\7z.exe", r"C:\Program Files (x86)\7-Zip\7z.exe"]:
        if os.path.isfile(path):
            return path
    return None


def download(url, dest):
    print(f"  Скачиваю {url.split('/')[-1].split('?')[0]} ...")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as resp, open(dest, "wb") as f:
        f.write(resp.read())


def is_valid_zip(path):
    try:
        with zipfile.ZipFile(path, "r"):
            return True
    except Exception:
        return False


def extract_dlls_zip(archive, subpath, out_dir):
    with zipfile.ZipFile(archive, "r") as z:
        extracted = 0
        for member in z.namelist():
            if not member.endswith(".dll"):
                continue
            norm = member.replace("\\", "/")
            if subpath:
                prefix = subpath.rstrip("/") + "/"
                if not norm.lower().startswith(prefix.lower()):
                    continue
            filename = os.path.basename(norm)
            if not filename:
                continue
            dest_path = os.path.join(out_dir, filename)
            with z.open(member) as src, open(dest_path, "wb") as dst:
                dst.write(src.read())
            print(f"  -> {filename}")
            extracted += 1
        if extracted == 0:
            print(f"  [WARN] dll не найдены в '{subpath}', ищу везде...")
            for member in z.namelist():
                if not member.endswith(".dll"):
                    continue
                filename = os.path.basename(member.replace("\\", "/"))
                if not filename:
                    continue
                dest_path = os.path.join(out_dir, filename)
                with z.open(member) as src, open(dest_path, "wb") as dst:
                    dst.write(src.read())
                print(f"  -> {filename}")


def extract_dlls_7z(archive, subpath, out_dir, sz_exe):
    pattern = f"{subpath}/*.dll" if subpath else "*.dll"
    result = subprocess.run(
        [sz_exe, "e", f"-o{out_dir}", archive, pattern, "-y"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"  [WARN] 7z вернул код {result.returncode}: {result.stderr.strip()}")


def install_plugins():
    os.makedirs(PLUGINS_DIR, exist_ok=True)
    sz = find_7z()

    with tempfile.TemporaryDirectory() as tmp:
        for name, url, subpath in PLUGINS:
            print(f"[PLUGIN] {name}")

            # Прямой dll файл
            if subpath is None:
                filename = url.split("/")[-1]
                dest = os.path.join(PLUGINS_DIR, filename)
                if os.path.isfile(dest):
                    print(f"  уже есть, пропускаю")
                    continue
                try:
                    download(url, dest)
                    print(f"  -> {filename}")
                except Exception as e:
                    print(f"  [ERROR] {e}")
                continue

            filename = url.split("/")[-1].split("?")[0]
            archive = os.path.join(tmp, filename)

            try:
                download(url, archive)
            except Exception as e:
                print(f"  [ERROR] Не удалось скачать: {e}")
                continue

            if filename.endswith(".7z"):
                if not sz:
                    print(f"  [WARN] 7z не найден, пропускаю {name}. Установи 7-Zip.")
                    continue
                extract_dlls_7z(archive, subpath, PLUGINS_DIR, sz)
            else:
                if not is_valid_zip(archive):
                    print(f"  [ERROR] Скачанный файл не является zip архивом (возможно редирект или ошибка сервера)")
                    continue
                extract_dlls_zip(archive, subpath, PLUGINS_DIR)


def install_nsh_files():
    util_dir = os.path.join(SCRIPT_DIR, "Setup", "Util")
    os.makedirs(util_dir, exist_ok=True)
    for filename, url in NSH_FILES:
        dest = os.path.join(util_dir, filename)
        if os.path.isfile(dest):
            print(f"[NSH] {filename} уже есть, пропускаю")
            continue
        print(f"[NSH] {filename}")
        try:
            download(url, dest)
        except Exception as e:
            print(f"  [ERROR] {e}")


def build(production=False, skip_plugins=False):
    makensis = find_makensis()
    if not makensis:
        print("[ERROR] makensis не найден. Установи NSIS: https://nsis.sourceforge.io/Download")
        sys.exit(1)

    if not skip_plugins:
        print("\n=== Установка плагинов ===")
        install_plugins()
        install_nsh_files()

    print(f"\n=== Сборка ===")
    print(f"[INFO] makensis: {makensis}")

    cmd = [makensis, "/V3", f"/DADDPLUGINDIR={PLUGINS_DIR}"]
    if production:
        cmd += ['/X"SetCompressor /FINAL lzma"']
        print("[INFO] Режим: production (lzma)")
    else:
        print("[INFO] Режим: debug")

    cmd.append(NSI_FILE)

    result = subprocess.run(cmd, cwd=os.path.join(SCRIPT_DIR, "Setup"))

    if result.returncode != 0:
        print(f"\n[ERROR] Сборка упала с кодом {result.returncode}")
        sys.exit(result.returncode)

    if os.path.isfile(OUTPUT_EXE):
        size = os.path.getsize(OUTPUT_EXE) / (1024 * 1024)
        print(f"\n[OK] Готово: {OUTPUT_EXE} ({size:.2f} MB)")
    else:
        print("\n[WARN] Сборка завершилась, но KoshadeSetup.exe не найден")


if __name__ == "__main__":
    prod = "--prod" in sys.argv or "-p" in sys.argv
    skip = "--skip-plugins" in sys.argv
    build(production=prod, skip_plugins=skip)
