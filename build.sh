#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/colores-skim.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
app_dir="$build_dir/Colores para Skim.app"
mkdir -p "$app_dir/Contents/MacOS" "$project_dir/.build/module-cache" "$project_dir/dist"
cp "$project_dir/resources/Info.plist" "$app_dir/Contents/Info.plist"

swiftc -O -module-cache-path "$project_dir/.build/module-cache" \
    "$project_dir/src/ColoresSkim.swift" -o "$app_dir/Contents/MacOS/ColoresSkim"
"$app_dir/Contents/MacOS/ColoresSkim" --check
xattr -cr "$app_dir"
codesign --force --sign - "$app_dir"
codesign --verify --deep --strict "$app_dir"

python3 - "$app_dir" "$project_dir/dist/Colores_para_Skim.zip" <<'PY'
import sys
import zipfile
from pathlib import Path
app = Path(sys.argv[1])
with zipfile.ZipFile(sys.argv[2], 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(app.rglob('*')):
        if path.is_file():
            archive.write(path, Path(app.name) / path.relative_to(app))
with zipfile.ZipFile(sys.argv[2]) as archive:
    assert archive.testzip() is None
PY

ditto --norsrc --noextattr "$app_dir" "$project_dir/dist/Colores para Skim.app"
printf 'Aplicación y ZIP preparados en: %s/dist\n' "$project_dir"
