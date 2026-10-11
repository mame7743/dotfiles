#!/usr/bin/env bash
# agent-skills/install.sh — manifest.toml に従い、各 Agent のスキル読込先へ
# シンボリックリンクを作成する。スキル本体は変更しない。
#
# 使い方:
#   ./install.sh [-n|--dry-run] [--manifest FILE] [--dotfiles DIR]
#
# 設計上の約束:
#   - カレントディレクトリに依存しない（スクリプト位置から解決）。
#   - Git / submodule 操作はしない（README の手順と分離）。
#   - 外部スキルの付属スクリプトは実行しない（リンクのみ）。
#   - 正しいリンクが既にあれば何もしない（冪等）。
#   - 既存の通常ファイル/ディレクトリ/異なるリンクは上書きせず、競合として報告する。
#   - 同じ導入先 (agent × name) を複数スキルが使う設定はエラーにする。
#   - 検証と計画（フェーズ1）を先に行い、問題があればファイルを変更せず中断する。
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dotfiles_dir="$(cd "$script_dir/.." && pwd)"
manifest="$script_dir/manifest.toml"
dry_run=0

usage() { sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run) dry_run=1; shift ;;
    --manifest)   manifest="$2"; shift 2 ;;
    --dotfiles)   dotfiles_dir="$2"; shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    *) printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [ ! -f "$manifest" ]; then
  printf 'manifest not found: %s\n' "$manifest" >&2
  exit 2
fi

if [ -t 1 ]; then
  c_info=$'\033[34m'; c_ok=$'\033[32m'; c_warn=$'\033[33m'; c_err=$'\033[31m'; c_off=$'\033[0m'
else
  c_info=; c_ok=; c_warn=; c_err=; c_off=
fi
info() { printf '%s[info]%s  %s\n' "$c_info" "$c_off" "$*"; }
ok()   { printf '%s[ok]%s    %s\n' "$c_ok"   "$c_off" "$*"; }
warn() { printf '%s[warn]%s  %s\n' "$c_warn" "$c_off" "$*"; }
err()  { printf '%s[error]%s %s\n' "$c_err"  "$c_off" "$*" >&2; }

# ---------------------------------------------------------------------------
# manifest.toml の読み込み（このファイルが使う TOML サブセットのみ対応）
#   - 完全行コメント (# ...)、空行
#   - [agents]                : key = "value"
#   - [[skills]]              : name = "...", source = "...", agents = ["a", "b"]
#   - インラインコメント・複数行配列・テーブル配列の入れ子は非対応
# ---------------------------------------------------------------------------
agent_keys=(); agent_vals=()
sk_names=();   sk_sources=(); sk_agents=()
section=""; lineno=0
cur_name=""; cur_source=""; cur_agents=""

add_agent() { agent_keys[${#agent_keys[@]}]="$1"; agent_vals[${#agent_vals[@]}]="$2"; }
add_skill() { sk_names[${#sk_names[@]}]="$1"; sk_sources[${#sk_sources[@]}]="$2"; sk_agents[${#sk_agents[@]}]="$3"; }

flush_skill() {
  if [ "$section" = "skills" ] && { [ -n "$cur_name" ] || [ -n "$cur_source" ] || [ -n "$cur_agents" ]; }; then
    if [ -z "$cur_name" ] || [ -z "$cur_source" ] || [ -z "$cur_agents" ]; then
      err "manifest: $lineno 行目付近: name / source / agents のいずれかが不足しています"
      exit 2
    fi
    add_skill "$cur_name" "$cur_source" "$cur_agents"
  fi
}

while IFS= read -r raw || [ -n "$raw" ]; do
  lineno=$((lineno + 1))
  line="$raw"
  case "$line" in \#*) continue ;; esac
  line="${line#"${line%%[![:space:]]*}"}"   # 先頭の空白を除去
  line="${line%"${line##*[![:space:]]}"}"   # 末尾の空白を除去
  [ -z "$line" ] && continue
  case "$line" in
    "[agents]")   flush_skill; section="agents"; continue ;;
    "[[skills]]") flush_skill; section="skills"; cur_name=""; cur_source=""; cur_agents=""; continue ;;
  esac
  if [ "$section" = "agents" ]; then
    if [[ "$line" =~ ^([A-Za-z0-9_-]+)[[:space:]]*=[[:space:]]*\"(.*)\"$ ]]; then
      add_agent "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    else
      err "manifest: $lineno 行目: 解釈できない記述: $line"; exit 2
    fi
  elif [ "$section" = "skills" ]; then
    if   [[ "$line" =~ ^name[[:space:]]*=[[:space:]]*\"(.*)\"$ ]];   then cur_name="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^source[[:space:]]*=[[:space:]]*\"(.*)\"$ ]]; then cur_source="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^agents[[:space:]]*=[[:space:]]*\[(.*)\]$ ]]; then cur_agents="${BASH_REMATCH[1]}"
    else
      err "manifest: $lineno 行目: 解釈できない記述: $line"; exit 2
    fi
  else
    err "manifest: $lineno 行目: テーブル宣言より前の記述: $line"; exit 2
  fi
done < "$manifest"
flush_skill

if [ "${#agent_keys[@]}" -eq 0 ]; then err "manifest: [agents] が空です"; exit 2; fi
if [ "${#sk_names[@]}" -eq 0 ];  then err "manifest: スキルが1つも定義されていません"; exit 2; fi

# ---------------------------------------------------------------------------
# ヘルパー
# ---------------------------------------------------------------------------
name_ok() {
  case "$1" in
    ''|*[!a-z0-9-]*|-*|*-|*--*) return 1 ;;
    *) return 0 ;;
  esac
}

expand_tilde() {
  case "$1" in
    "~/"*) printf '%s/%s\n' "$HOME" "${1#\~/}" ;;
    "~")   printf '%s\n' "$HOME" ;;
    *)     printf '%s\n' "$1" ;;
  esac
}

agent_dir() {
  local key="$1" k=0
  while [ "$k" -lt "${#agent_keys[@]}" ]; do
    if [ "${agent_keys[$k]}" = "$key" ]; then printf '%s\n' "${agent_vals[$k]}"; return 0; fi
    k=$((k + 1))
  done
  return 1
}

# ---------------------------------------------------------------------------
# フェーズ1: 検証と計画（ファイルは変更しない）
# ---------------------------------------------------------------------------
plan_names=(); plan_srcs=(); plan_targets=()
seen_targets=$'\n'
plan_errors=0

i=0
while [ "$i" -lt "${#sk_names[@]}" ]; do
  name="${sk_names[$i]}"
  source_path="${sk_sources[$i]}"
  agents_list="${sk_agents[$i]}"

  if ! name_ok "$name"; then
    err "無効な skill name: $name (小文字英数と単一ハイフン、前後のハイフン不可)"
    plan_errors=$((plan_errors + 1)); i=$((i + 1)); continue
  fi
  case "$source_path" in
    /*) src="$source_path" ;;
    *)  src="$dotfiles_dir/$source_path" ;;
  esac
  if [ ! -d "$src" ]; then
    err "$name: ソースディレクトリがありません: $src"
    err "  → submodule を初期化しましたか? (git submodule update --init --recursive)"
    plan_errors=$((plan_errors + 1)); i=$((i + 1)); continue
  fi
  if [ ! -f "$src/SKILL.md" ]; then
    err "$name: SKILL.md がありません: $src/SKILL.md"
    plan_errors=$((plan_errors + 1)); i=$((i + 1)); continue
  fi
  fm_name="$(awk -F': *' '/^name:/{print $2; exit}' "$src/SKILL.md" | tr -d '\r')"
  fm_name="${fm_name%\"}"; fm_name="${fm_name#\"}"
  if [ "$fm_name" != "$name" ]; then
    err "$name: SKILL.md の frontmatter name ($fm_name) が識別名と一致しません"
    plan_errors=$((plan_errors + 1)); i=$((i + 1)); continue
  fi

  al="${agents_list//,/ }"
  for a in $al; do
    a="${a//\"/}"; a="${a//[[:space:]]/}"
    [ -z "$a" ] && continue
    dir_raw="$(agent_dir "$a")" || { err "$name: 未定義の agent: $a"; plan_errors=$((plan_errors + 1)); continue; }
    target_dir="$(expand_tilde "$dir_raw")"
    target="$target_dir/$name"
    if printf '%s\n' "$seen_targets" | grep -Fxq "$target"; then
      err "同じ導入先に複数のスキルが割り当てられています: $target"
      plan_errors=$((plan_errors + 1)); continue
    fi
    seen_targets="$seen_targets$target"$'\n'
    plan_names[${#plan_names[@]}]="$name"
    plan_srcs[${#plan_srcs[@]}]="$src"
    plan_targets[${#plan_targets[@]}]="$target"
  done
  i=$((i + 1))
done

if [ "$plan_errors" -ne 0 ]; then
  err "設定または前提に ${plan_errors} 件の問題があります。ファイルは変更していません。"
  exit 2
fi

# ---------------------------------------------------------------------------
# フェーズ2: リンク作成（plan に従う）
# ---------------------------------------------------------------------------
created=0; noop=0; planned=0; conflicts=0

j=0
while [ "$j" -lt "${#plan_targets[@]}" ]; do
  src="${plan_srcs[$j]}"
  target="${plan_targets[$j]}"
  target_dir="$(dirname "$target")"

  if [ -L "$target" ]; then
    cur="$(readlink "$target")"
    if [ "$cur" = "$src" ]; then
      noop=$((noop + 1))
      [ "$dry_run" = 1 ] && info "変更なし(リンク済み): $target"
    else
      err "競合: $target は別のリンク先を指しています -> $cur"
      conflicts=$((conflicts + 1))
    fi
  elif [ -e "$target" ]; then
    err "競合: $target に既存のファイル/ディレクトリがあります（上書きしません）"
    conflicts=$((conflicts + 1))
  else
    planned=$((planned + 1))
    if [ "$dry_run" = 1 ]; then
      info "作成予定: $target -> $src"
    else
      mkdir -p "$target_dir"
      ln -s "$src" "$target"
      ok "$target -> $src"
      created=$((created + 1))
    fi
  fi
  j=$((j + 1))
done

echo
if [ "$dry_run" = 1 ]; then
  info "dry-run: 作成予定 ${planned} 件 / 既存リンク ${noop} 件 / 競合 ${conflicts} 件（ファイルは変更していません）"
else
  info "作成 ${created} 件 / 既存リンク ${noop} 件 / 競合 ${conflicts} 件"
fi
if [ "$conflicts" -ne 0 ]; then
  err "競合が ${conflicts} 件あります。上書きはしていません。"
  exit 1
fi
exit 0
