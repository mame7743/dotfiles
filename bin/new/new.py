#!/usr/bin/env python3
"""
new — project scaffolding tool
Usage: new <lang> <project-name>

Supported: go, c, zig, rust, python, node
Custom templates: ~/.config/new/templates/<lang>/
"""

import os
import sys
import shutil
import subprocess
from pathlib import Path
from textwrap import dedent

# ---------------------------------------------------------------------------
# Built-in templates  ({{name}} is replaced with the project name)
# ---------------------------------------------------------------------------

TEMPLATES: dict[str, dict[str, str]] = {
    "go": {
        "main.go": dedent("""\
            package main

            import "fmt"

            func main() {
            \tfmt.Println("Hello, {{name}}!")
            }
            """),
    },
    "c": {
        "main.c": dedent("""\
            #include <stdio.h>

            int main(void) {
                printf("Hello, {{name}}!\\n");
                return 0;
            }
            """),
        "Makefile": dedent("""\
            CC     = gcc
            CFLAGS = -Wall -Wextra -O2
            TARGET = {{name}}
            SRCS   = main.c
            OBJS   = $(SRCS:.c=.o)

            .PHONY: all clean

            all: $(TARGET)

            $(TARGET): $(OBJS)
            \t$(CC) $(CFLAGS) -o $@ $^

            %.o: %.c
            \t$(CC) $(CFLAGS) -c $<

            clean:
            \trm -f $(TARGET) $(OBJS)
            """),
    },
    "zig": {
        "src/main.zig": dedent("""\
            const std = @import("std");

            pub fn main() void {
                std.debug.print("Hello, {s}!\\n", .{"{{name}}"});
            }
            """),
        "build.zig": dedent("""\
            const std = @import("std");

            pub fn build(b: *std.Build) void {
                const target   = b.standardTargetOptions(.{});
                const optimize = b.standardOptimizeOption(.{});

                const exe = b.addExecutable(.{
                    .name             = "{{name}}",
                    .root_source_file = b.path("src/main.zig"),
                    .target           = target,
                    .optimize         = optimize,
                });
                b.installArtifact(exe);

                const run_cmd  = b.addRunArtifact(exe);
                run_cmd.step.dependOn(b.getInstallStep());
                const run_step = b.step("run", "Run the app");
                run_step.dependOn(&run_cmd.step);
            }
            """),
        "Makefile": dedent("""\
            .PHONY: build run clean

            build:
            \tzig build

            run:
            \tzig build run

            clean:
            \trm -rf .zig-cache zig-out
            """),
    },
}

GITIGNORES: dict[str, str] = {
    "go": dedent("""\
        /{{name}}
        /{{name}}.exe
        *.test
        vendor/
        """),
    "c": dedent("""\
        {{name}}
        *.o
        *.d
        """),
    "zig": dedent("""\
        .zig-cache/
        zig-out/
        """),
    "rust": dedent("""\
        /target/
        """),
    "python": dedent("""\
        __pycache__/
        *.pyc
        .venv/
        dist/
        *.egg-info/
        .python-version
        """),
    "node": dedent("""\
        node_modules/
        dist/
        .env
        *.log
        """),
}

LANGS = list(TEMPLATES) + ["rust", "python", "node"]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _color(code: str, text: str) -> str:
    if sys.platform == "win32" and not os.environ.get("WT_SESSION"):
        return text
    return f"\033[{code}m{text}\033[0m"

def info(msg: str)  -> None: print(_color("34", f"  {msg}"))
def ok(msg: str)    -> None: print(_color("32", f"  {msg}"))
def die(msg: str)   -> None: print(_color("31", f"  error: {msg}"), file=sys.stderr); sys.exit(1)

def run(cmd: list[str], cwd: Path | None = None) -> None:
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        die(f"`{' '.join(cmd)}` failed\n{result.stderr.strip()}")

def require(cmd: str) -> None:
    if shutil.which(cmd) is None:
        die(f"`{cmd}` が見つかりません。インストールしてください。")

def render(text: str, name: str) -> str:
    return text.replace("{{name}}", name)

# ---------------------------------------------------------------------------
# Template application
# ---------------------------------------------------------------------------

def custom_template_dir(lang: str) -> Path | None:
    d = Path.home() / ".config" / "new" / "templates" / lang
    return d if d.exists() else None

def apply_builtin(lang: str, dest: Path, name: str) -> None:
    for rel, content in TEMPLATES[lang].items():
        path = dest / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(render(content, name), encoding="utf-8")

def apply_custom(template_dir: Path, dest: Path, name: str) -> None:
    for src in sorted(template_dir.rglob("*")):
        if not src.is_file():
            continue
        dst = dest / src.relative_to(template_dir)
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(render(src.read_text(errors="replace"), name), encoding="utf-8")

def write_gitignore(dest: Path, lang: str, name: str) -> None:
    path = dest / ".gitignore"
    if not path.exists():
        path.write_text(render(GITIGNORES.get(lang, ""), name), encoding="utf-8")

def git_init(dest: Path) -> None:
    if not (dest / ".git").exists():
        run(["git", "init"], cwd=dest)

# ---------------------------------------------------------------------------
# Language-specific scaffolding
# ---------------------------------------------------------------------------

def scaffold_template(lang: str, dest: Path, name: str) -> None:
    """go / c / zig: テンプレートを展開してセットアップ"""
    custom = custom_template_dir(lang)
    if custom:
        info(f"カスタムテンプレートを使用: {custom}")
        apply_custom(custom, dest, name)
    else:
        apply_builtin(lang, dest, name)

    if lang == "go":
        require("go")
        run(["go", "mod", "init", name], cwd=dest)

def scaffold_rust(dest: Path, name: str) -> None:
    require("cargo")
    run(["cargo", "new", name], cwd=dest.parent)

def scaffold_python(dest: Path, name: str) -> None:
    require("uv")
    run(["uv", "init", name], cwd=dest.parent)

def scaffold_node(dest: Path, name: str) -> None:
    require("npm")
    dest.mkdir()
    run(["npm", "init", "-y"], cwd=dest)

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

SCAFFOLDERS = {
    "rust":   scaffold_rust,
    "python": scaffold_python,
    "node":   scaffold_node,
}

def main() -> None:
    if len(sys.argv) != 3:
        print(f"Usage: new <lang> <project-name>")
        print(f"Langs:  {', '.join(LANGS)}")
        sys.exit(1)

    lang, name = sys.argv[1], sys.argv[2]

    if lang not in LANGS:
        die(f"未対応の言語: {lang}\n対応: {', '.join(LANGS)}")

    dest = Path.cwd() / name
    if dest.exists():
        die(f"'{name}' は既に存在します")

    print(f"\n新規プロジェクト: {_color('36', name)} ({lang})\n")

    if lang in SCAFFOLDERS:
        SCAFFOLDERS[lang](dest, name)
    else:
        dest.mkdir()
        scaffold_template(lang, dest, name)

    write_gitignore(dest, lang, name)
    git_init(dest)

    ok(f"作成完了\n")
    print(f"  cd {name}")
    print()

if __name__ == "__main__":
    main()
