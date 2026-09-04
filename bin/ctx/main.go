package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
)

var ansiEscape = regexp.MustCompile(`\x1B\[[0-9;]*[mGKHF]`)
var progressBar = regexp.MustCompile(`[\[#=\-]{3,}|(\d+\s*%)`)
var separatorLine = regexp.MustCompile(`^[\-=*]{3,}\s*$`)

const maxLineLen = 200
const autoTrimThreshold = 10
const contextLines = 3

// ── クリーニング ──────────────────────────────────────────

func cleanLines(lines []string) []string {
	var result []string
	prev := ""
	for _, line := range lines {
		line = ansiEscape.ReplaceAllString(line, "")
		line = strings.TrimRight(line, " \t\r")
		if line == "" {
			continue
		}
		if progressBar.MatchString(line) {
			continue
		}
		if separatorLine.MatchString(line) {
			continue
		}
		if len(line) > maxLineLen {
			line = line[:maxLineLen] + " ...[truncated]"
		}
		if line == prev {
			continue
		}
		result = append(result, line)
		prev = line
	}
	return result
}

// ── 中略: 10行超えたら先頭3 + 末尾3 ─────────────────────

func trimMiddle(lines []string) []string {
	if len(lines) <= autoTrimThreshold {
		return lines
	}
	var result []string
	result = append(result, lines[:contextLines]...)
	result = append(result, fmt.Sprintf("... (%d lines omitted) ...", len(lines)-contextLines*2))
	result = append(result, lines[len(lines)-contextLines:]...)
	return result
}

// ── grep: キーワード周辺±3行 ─────────────────────────────

func grepContext(lines []string, pattern string) []string {
	re, err := regexp.Compile("(?i)" + pattern)
	if err != nil {
		fmt.Fprintf(os.Stderr, "grep pattern error: %v\n", err)
		return lines
	}

	include := make([]bool, len(lines))
	for i, line := range lines {
		if re.MatchString(line) {
			for j := maxInt(0, i-contextLines); j <= minInt(len(lines)-1, i+contextLines); j++ {
				include[j] = true
			}
		}
	}

	var result []string
	omitted := 0
	for i, line := range lines {
		if include[i] {
			if omitted > 0 {
				result = append(result, fmt.Sprintf("... (%d lines omitted) ...", omitted))
				omitted = 0
			}
			result = append(result, line)
		} else {
			omitted++
			if i == len(lines)-1 {
				result = append(result, fmt.Sprintf("... (%d lines omitted) ...", omitted))
			}
		}
	}
	return result
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// ── 環境情報 ─────────────────────────────────────────────

type Env struct {
	OS    string // "macOS 14.5" / "Ubuntu 22.04" / "Windows 11"
	Shell string // "zsh 5.9"
	Dir   string
}

func runCmd(name string, args ...string) string {
	out, err := exec.Command(name, args...).Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func osInfo() string {
	switch runtime.GOOS {
	case "darwin":
		name := runCmd("sw_vers", "-productName")    // "macOS"
		ver := runCmd("sw_vers", "-productVersion")  // "14.5"
		if name != "" && ver != "" {
			return name + " " + ver
		}
	case "linux":
		data, err := os.ReadFile("/etc/os-release")
		if err == nil {
			var name, ver string
			for _, line := range strings.Split(string(data), "\n") {
				if v, ok := strings.CutPrefix(line, "NAME="); ok {
					name = strings.Trim(v, `"`)
				}
				if v, ok := strings.CutPrefix(line, "VERSION_ID="); ok {
					ver = strings.Trim(v, `"`)
				}
			}
			if name != "" && ver != "" {
				return name + " " + ver
			}
			if name != "" {
				return name
			}
		}
	case "windows":
		if v := runCmd("cmd", "/c", "ver"); v != "" {
			return v
		}
	}
	return runtime.GOOS
}

func shellInfo() string {
	shell := os.Getenv("SHELL")
	if shell == "" {
		shell = os.Getenv("ComSpec")
	}
	if shell == "" {
		return "unknown"
	}
	name := filepath.Base(strings.ReplaceAll(shell, "\\", "/"))

	out := runCmd(name, "--version")
	if out == "" {
		return name
	}
	// First line only
	line := strings.SplitN(out, "\n", 2)[0]
	// Extract first version-like token (digits with dots)
	for _, field := range strings.Fields(line) {
		if len(field) > 0 && field[0] >= '0' && field[0] <= '9' {
			ver := strings.Split(field, "(")[0]
			ver = strings.TrimRight(ver, ".-")
			if ver != "" {
				return name + " " + ver
			}
		}
	}
	return name
}

func getEnv() Env {
	dir, _ := os.Getwd()
	return Env{OS: osInfo(), Shell: shellInfo(), Dir: dir}
}

// ── フォーマット ──────────────────────────────────────────

// デフォルト: ヘッダー + コマンド + 出力
func formatDefault(cmd string, lines []string) string {
	env := getEnv()
	var sb strings.Builder
	fmt.Fprintf(&sb, "# OS: %s\n", env.OS)
	fmt.Fprintf(&sb, "# Shell: %s\n", env.Shell)
	sb.WriteString("\n")
	if cmd != "" {
		fmt.Fprintf(&sb, "$ %s\n", cmd)
	}
	sb.WriteString(strings.Join(lines, "\n") + "\n")
	return sb.String()
}

// --raw: クリーニングのみ、ヘッダーなし
func formatRaw(lines []string) string {
	return strings.Join(lines, "\n") + "\n"
}

// --llm: 環境情報1行 + プレーンテキスト（LLMへの入力向け）
func formatLLM(cmd string, lines []string) string {
	env := getEnv()
	var sb strings.Builder
	envLine := fmt.Sprintf("OS: %s / Shell: %s / Dir: %s", env.OS, env.Shell, env.Dir)
	if cmd != "" {
		envLine += fmt.Sprintf(" / Cmd: %s", cmd)
	}
	sb.WriteString(envLine + "\n\n")
	sb.WriteString(strings.Join(lines, "\n") + "\n")
	return sb.String()
}

// --md: Markdownコードブロック + 中略
func formatMD(cmd string, lines []string, grepPattern string) string {
	var trimmed []string
	if grepPattern != "" {
		trimmed = grepContext(lines, grepPattern)
	} else {
		trimmed = trimMiddle(lines)
	}

	var sb strings.Builder
	if cmd != "" {
		fmt.Fprintf(&sb, "$ %s\n", cmd)
	}
	sb.WriteString("```bash\n")
	sb.WriteString(strings.Join(trimmed, "\n") + "\n")
	sb.WriteString("```\n")
	return sb.String()
}

// --json: 環境情報 + output配列
func formatJSON(cmd string, lines []string) string {
	env := getEnv()
	data := map[string]any{
		"os":     env.OS,
		"shell":  env.Shell,
		"dir":    env.Dir,
		"cmd":    cmd,
		"output": lines,
	}
	b, _ := json.MarshalIndent(data, "", "  ")
	return string(b) + "\n"
}

// ── コマンド名自動検出 ────────────────────────────────────

func detectCmd() string {
	if runtime.GOOS != "windows" {
		ppid := os.Getppid()
		out, err := exec.Command("ps", "-p", fmt.Sprint(ppid), "-o", "comm=").Output()
		if err == nil {
			return strings.TrimSpace(string(out))
		}
	}
	return ""
}

// ── usage ─────────────────────────────────────────────────

func usage() {
	fmt.Fprintln(os.Stderr, "Usage: <command> 2>&1 | ctx [-c CMD] [options]")
	fmt.Fprintln(os.Stderr, "")
	fmt.Fprintln(os.Stderr, "Options:")
	fmt.Fprintln(os.Stderr, "  (none)        # OS / # Shell ヘッダー + 出力  [default]")
	fmt.Fprintln(os.Stderr, "  --raw         クリーニングのみ、ヘッダーなし")
	fmt.Fprintln(os.Stderr, "  --llm         環境情報1行 + プレーンテキスト（LLM入力向け）")
	fmt.Fprintln(os.Stderr, "  --md          Markdownコードブロック + 中略")
	fmt.Fprintln(os.Stderr, "  --json        JSON（環境情報 + output配列）")
	fmt.Fprintln(os.Stderr, "  -g PATTERN    grep中略（--mdと併用）")
	fmt.Fprintln(os.Stderr, "  -c TEXT       コマンド名を明示")
	fmt.Fprintln(os.Stderr, "")
	fmt.Fprintln(os.Stderr, "Examples:")
	fmt.Fprintln(os.Stderr, "  ls -la | ctx -c 'ls -la'")
	fmt.Fprintln(os.Stderr, "  cargo build 2>&1 | ctx -c 'cargo build' --md -g error")
	fmt.Fprintln(os.Stderr, "  go test ./... 2>&1 | ctx --llm | pbcopy")
}

// ── main ──────────────────────────────────────────────────

func main() {
	var mode string // "", "raw", "llm", "md", "json"
	var cmd string
	var grepPattern string

	args := os.Args[1:]
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--raw":
			mode = "raw"
		case "--llm":
			mode = "llm"
		case "--md":
			mode = "md"
		case "--json":
			mode = "json"
		case "-g":
			if i+1 < len(args) {
				grepPattern = args[i+1]
				i++
			}
		case "-c":
			if i+1 < len(args) {
				cmd = args[i+1]
				i++
			}
		case "-h", "--help":
			usage()
			os.Exit(0)
		}
	}

	if cmd == "" {
		cmd = detectCmd()
	}

	// stdin読み込み
	var lines []string
	scanner := bufio.NewScanner(os.Stdin)
	buf := make([]byte, 1024*1024)
	scanner.Buffer(buf, len(buf))
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "Error reading stdin: %v\n", err)
		os.Exit(1)
	}

	cleaned := cleanLines(lines)

	var result string
	switch mode {
	case "raw":
		result = formatRaw(cleaned)
	case "llm":
		result = formatLLM(cmd, cleaned)
	case "md":
		result = formatMD(cmd, cleaned, grepPattern)
	case "json":
		result = formatJSON(cmd, cleaned)
	default:
		result = formatDefault(cmd, cleaned)
	}

	fmt.Print(result)

	// 削減率をstderrへ
	original := len(lines)
	final := len(cleaned)
	if original > 0 {
		reduction := (1 - float64(final)/float64(original)) * 100
		fmt.Fprintf(os.Stderr, "Lines: %d → %d (%.0f%% reduction)\n", original, final, reduction)
	}
}
