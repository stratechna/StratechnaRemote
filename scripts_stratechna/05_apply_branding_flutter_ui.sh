#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1

FL="flutter"
BR="$FL/lib/stratechna_branding.dart"

# 0) garantir ficheiro de branding
if [[ ! -f "$BR" ]]; then
cat > "$BR" <<'DART'
import 'package:flutter/material.dart';

class StratechnaBranding {
  static const Color red = Color(0xFFB10008);
  static const Color blueGray = Color(0xFF48545C);

  static const LinearGradient gradient = LinearGradient(
    colors: [red, blueGray],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color hover = Color(0x1AB10008);
  static const Color highlight = Color(0x33B10008);
}
DART
fi

# 1) common.dart: trocar palette RustDesk -> Stratechna (apenas visual)
python3 - <<'PY'
from pathlib import Path

p = Path("flutter/lib/common.dart")
s = p.read_text(encoding="utf-8", errors="ignore")

# ensure import
if "stratechna_branding.dart" not in s:
    s = s.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:flutter_hbb/stratechna_branding.dart';",
        1
    )

# swaps típicos (do teu documento)
s = s.replace("static const Color accent = Color(0xFF0071FF);", "static const Color accent = StratechnaBranding.red;")
s = s.replace("static const Color accent50 = Color(0x770071FF);", "static const Color accent50 = StratechnaBranding.hover;")
s = s.replace("static const Color accent80 = Color(0xAA0071FF);", "static const Color accent80 = StratechnaBranding.highlight;")
s = s.replace("static const Color button = Color(0xFF2C8CFF);", "static const Color button = StratechnaBranding.red;")
s = s.replace("static const Color idColor = Color(0xFF00B6F0);", "static const Color idColor = StratechnaBranding.blueGray;")

p.write_text(s, encoding="utf-8")
print("patched:", p)
PY

# 2) substituir gradientes "rosa/laranja" e "azuis" por cores Stratechna em ficheiros UI (apenas UI)
python3 - <<'PY'
from pathlib import Path

targets = [
  Path("flutter/lib/common.dart"),
  Path("flutter/lib/desktop/widgets/titlebar_widget.dart"),
  Path("flutter/lib/desktop/pages/desktop_home_page.dart"),
  Path("flutter/lib/desktop/pages/server_page.dart"),
  Path("flutter/lib/desktop/pages/desktop_setting_page.dart"),
]
def ensure_import(s: str) -> str:
    if "package:flutter_hbb/stratechna_branding.dart" in s:
        return s
    needle = "import 'package:flutter/material.dart';"
    if needle in s:
        return s.replace(needle, needle + "\nimport 'package:flutter_hbb/stratechna_branding.dart';", 1)
    return "import 'package:flutter_hbb/stratechna_branding.dart';\n" + s

for p in targets:
    if not p.exists():
        continue
    s = p.read_text(encoding="utf-8", errors="ignore")
    s = ensure_import(s)

    # gradiente rosa/laranja
    s = s.replace("Color(0xFFFF5E8A)", "StratechnaBranding.red")
    s = s.replace("Color(0xFFFFA45C)", "StratechnaBranding.blueGray")

    # azuis do titlebar / UI
    s = s.replace("Color(0xFF0C6AF6)", "StratechnaBranding.red")
    s = s.replace("Color(0xFF0583EA)", "StratechnaBranding.red")
    s = s.replace("Color(0xFF0697EA)", "StratechnaBranding.blueGray")

    p.write_text(s, encoding="utf-8")
    print("patched:", p)
PY

# 3) remover menções diretas a "RustDesk" em strings UI (sem tocar em lógica/FFI)
python3 - <<'PY'
from pathlib import Path

root = Path("flutter/lib")
changed = 0
for p in root.rglob("*.dart"):
    s = p.read_text(encoding="utf-8", errors="ignore")
    s2 = s.replace('"RustDesk"', '"Stratechna Remote"').replace("'RustDesk'", "'Stratechna Remote'")
    if s2 != s:
        p.write_text(s2, encoding="utf-8")
        changed += 1
print("changed_files=", changed)
PY

echo "[OK] Stratechna branding applied (Flutter UI only)"
