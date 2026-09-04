#!/usr/bin/env python3
"""
install.py — dotfiles/bin ツールのクロスプラットフォームインストーラー
依存: 標準ライブラリのみ
"""

import os
import sys
import shutil
import platform
import subprocess
from pathlib import Path

# ---------------------------------------------------------------------------
# 定数
# ---------------------------------------------------------------------------

DOTFILES_DIR = Path(__file__).parent.resolve()
BIN_DIR      = DOTFILES_DIR / "bin"

def install_dir() -> Path:
    if platform.system() == "Windows":
        base = os.environ.get("LOCALAPPDATA", Path.home() / "AppData" / "Local")
        return Path(base) / "bin"
    return Path.home() / ".local" / "bin"

# ---------------------------------------------------------------------------
# ツール定義
# ---------------------------------------------------------------------------
# 各エントリのキー:
#   src      : BIN_DIR からの相対パス（ディレクトリ or ファイル）
#   build    : ビルド関数（省略可）。呼ばれた時点でのカレントは src ディレクトリ
#   artifact : ビルド後にコピーするファイル名（BIN_DIR/src/ からの相対）
#   dest     : install_dir() に置くファイル名

def _build_go(src_dir: Path) -> Path:
    """go build して成果物パスを返す"""
    exe = src_dir.name + (".exe" if platform.system() == "Windows" else "")
    out = src_dir / exe
    run(["go", "build", "-o", str(out), "."], cwd=src_dir)
    return out

TOOLS = [
    {
        "name":     "ctx",
        "src_dir":  BIN_DIR / "ctx",
        "build":    _build_go,
        "dest":     "ctx" + (".exe" if platform.system() == "Windows" else ""),
    },
    {
        "name":     "new",
        "src_file": BIN_DIR / "new" / "new.py",
        "dest":     "new",
    },
    # tdd は移行中のためコメントアウト
    # {
    #     "name":     "tdd",
    #     "src_file": BIN_DIR / "tdd" / "tdd.py",
    #     "dest":     "tdd",
    # },
]

# ---------------------------------------------------------------------------
# ヘルパー
# ---------------------------------------------------------------------------

def _color(code: str, text: str) -> str:
    if platform.system() == "Windows" and not os.environ.get("WT_SESSION"):
        return text
    return f"\033[{code}m{text}\033[0m"

info    = lambda t: print(_color("34", f"[info]  {t}"))
ok      = lambda t: print(_color("32", f"[ok]    {t}"))
warn    = lambda t: print(_color("33", f"[warn]  {t}"))
error   = lambda t: print(_color("31", f"[error] {t}"), file=sys.stderr)

def run(cmd: list, cwd: Path = None):
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"{cmd[0]} failed")

def require_command(name: str) -> bool:
    if shutil.which(name) is None:
        warn(f"{name} が見つかりません。スキップします。")
        return False
    return True

# ---------------------------------------------------------------------------
# インストール処理
# ---------------------------------------------------------------------------

def install_tool(tool: dict, dest_dir: Path):
    name = tool["name"]

    if "build" in tool:
        src_dir: Path = tool["src_dir"]
        if not src_dir.exists():
            warn(f"{name}: ソースが見つかりません ({src_dir}) — スキップ")
            return
        if not require_command("go"):
            return
        info(f"{name}: ビルド中 ...")
        try:
            artifact = tool["build"](src_dir)
        except RuntimeError as e:
            error(f"{name}: ビルド失敗 — {e}")
            return
        src = artifact
    else:
        src: Path = tool["src_file"]
        if not src.exists():
            warn(f"{name}: ソースが見つかりません ({src}) — スキップ")
            return

    dest = dest_dir / tool["dest"]
    shutil.copy2(src, dest)

    # Unix ではスクリプトに実行権限を付与
    if platform.system() != "Windows":
        dest.chmod(dest.stat().st_mode | 0o111)

    ok(f"{name} → {dest}")

def check_path(dest_dir: Path):
    path_dirs = os.environ.get("PATH", "").split(os.pathsep)
    if str(dest_dir) not in path_dirs:
        print()
        warn(f"{dest_dir} が PATH に含まれていません。")
        shell = Path(os.environ.get("SHELL", "")).name
        if shell in ("zsh", "bash"):
            rc = "~/.zshrc" if shell == "zsh" else "~/.bashrc"
            print(f'  → {rc} に追加: export PATH="{dest_dir}:$PATH"')
        elif platform.system() == "Windows":
            print(f"  → システム環境変数 PATH に {dest_dir} を追加してください。")

# ---------------------------------------------------------------------------
# エントリポイント
# ---------------------------------------------------------------------------

def main():
    dest_dir = install_dir()
    dest_dir.mkdir(parents=True, exist_ok=True)
    info(f"インストール先: {dest_dir}")
    print()

    for tool in TOOLS:
        install_tool(tool, dest_dir)

    check_path(dest_dir)
    print()
    info("完了。新しいシェルを開くか、PATH を再読み込みしてください。")

if __name__ == "__main__":
    main()
