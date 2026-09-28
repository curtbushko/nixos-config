package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"

	"github.com/BurntSushi/toml"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type Item struct {
	Key    string `toml:"key"`
	Title  string `toml:"title"`
	Run    string `toml:"run"`
	Source string `toml:"source"`
	Action string `toml:"action"`
	Items  []Item `toml:"item"`
}

type Menu struct {
	Item []Item `toml:"item"`
}

type frame struct {
	title string
	items []Item
}

type model struct {
	stack       []frame
	dispatch    string
	width       int
	err         string
	prompting   bool
	promptLabel string
	promptTmpl  string
	input       string
}

type actionResult struct {
	cmd         string
	promptLabel string
	promptTmpl  string
}

func (m model) Init() tea.Cmd { return nil }

func (m model) top() frame { return m.stack[len(m.stack)-1] }

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		return m, nil
	case tea.KeyMsg:
		s := msg.String()
		if m.prompting {
			switch s {
			case "ctrl+c", "esc":
				m.prompting = false
				m.input = ""
				m.promptLabel = ""
				m.promptTmpl = ""
				return m, nil
			case "enter":
				if m.input == "" {
					return m, nil
				}
				m.dispatch = strings.ReplaceAll(m.promptTmpl, "{INPUT}", shellQuote(m.input))
				return m, tea.Quit
			case "backspace":
				if len(m.input) > 0 {
					m.input = m.input[:len(m.input)-1]
				}
				return m, nil
			}
			if len(s) == 1 {
				m.input += s
			} else if s == "space" {
				m.input += " "
			}
			return m, nil
		}
		switch s {
		case "ctrl+c":
			return m, tea.Quit
		case "esc":
			if len(m.stack) > 1 {
				m.stack = m.stack[:len(m.stack)-1]
				m.err = ""
				return m, nil
			}
			return m, tea.Quit
		case "backspace":
			if len(m.stack) > 1 {
				m.stack = m.stack[:len(m.stack)-1]
				m.err = ""
			}
			return m, nil
		}
		for _, it := range m.top().items {
			if it.Key != s {
				continue
			}
			if it.Source != "" {
				resolved, err := resolveSource(it.Source)
				if err != nil {
					m.err = fmt.Sprintf("source %q: %v", it.Source, err)
					return m, nil
				}
				m.stack = append(m.stack, frame{title: it.Title, items: resolved})
				m.err = ""
				return m, nil
			}
			if len(it.Items) > 0 {
				m.stack = append(m.stack, frame{title: it.Title, items: it.Items})
				m.err = ""
				return m, nil
			}
			if it.Action != "" {
				res, err := actionCommand(it.Action)
				if err != nil {
					m.err = fmt.Sprintf("action %q: %v", it.Action, err)
					return m, nil
				}
				if res.promptTmpl != "" {
					m.prompting = true
					m.promptLabel = res.promptLabel
					m.promptTmpl = res.promptTmpl
					m.input = ""
					m.err = ""
					return m, nil
				}
				m.dispatch = res.cmd
				return m, tea.Quit
			}
			if it.Run != "" {
				m.dispatch = it.Run
				return m, tea.Quit
			}
		}
	}
	return m, nil
}

var (
	headerStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("5")).Bold(true).MarginBottom(1)
	keyStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("6")).Bold(true)
	titleStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("15"))
	hintStyle   = lipgloss.NewStyle().Faint(true).MarginTop(1)
	errorStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("9")).MarginTop(1)
	boxStyle    = lipgloss.NewStyle().Padding(0, 1)
)

func (m model) View() string {
	if m.prompting {
		var b strings.Builder
		b.WriteString(headerStyle.Render(" "+m.promptLabel+" ") + "\n")
		b.WriteString(titleStyle.Render("> "+m.input+"_") + "\n")
		b.WriteString(hintStyle.Render("enter to confirm, esc to cancel"))
		box := boxStyle
		if m.width > 4 {
			box = box.Width(m.width - 2)
		}
		return box.Render(b.String())
	}
	f := m.top()
	title := "which-key"
	if f.title != "" {
		title = title + " " + f.title
	}
	var b strings.Builder
	b.WriteString(headerStyle.Render(" "+title+" ") + "\n")
	for _, it := range f.items {
		marker := ""
		if it.Source != "" || len(it.Items) > 0 {
			marker = "  >"
		}
		b.WriteString(keyStyle.Render(fmt.Sprintf("%-4s", it.Key)))
		b.WriteString(titleStyle.Render(it.Title + marker))
		b.WriteString("\n")
	}
	hint := "esc to cancel"
	if len(m.stack) > 1 {
		hint = "esc/backspace to go back"
	}
	b.WriteString(hintStyle.Render(hint))
	if m.err != "" {
		b.WriteString("\n" + errorStyle.Render(m.err))
	}
	box := boxStyle
	if m.width > 4 {
		box = box.Width(m.width - 2)
	}
	return box.Render(b.String())
}

func defaultConfigPath() string {
	if p := os.Getenv("WHICHKEY_MENU"); p != "" {
		return p
	}
	xdg := os.Getenv("XDG_CONFIG_HOME")
	if xdg == "" {
		xdg = filepath.Join(os.Getenv("HOME"), ".config")
	}
	return filepath.Join(xdg, "herdr", "plugins", "config", "whichkey", "menu.toml")
}

func herdrBin() string {
	if p := os.Getenv("HERDR_BIN_PATH"); p != "" {
		return p
	}
	return "herdr"
}

func expand(cmd string) string {
	return strings.ReplaceAll(cmd, "{HERDR}", herdrBin())
}

func run(cmd string) error {
	// Detach and delay: herdr closes the popup pane when whichkey exits and
	// restores focus to the caller pane. Running focus commands inline gets
	// clobbered by that restore. Start a session-leader child that sleeps
	// briefly, then executes after the popup has torn down.
	expanded := expand(cmd)
	logged := "{ echo \"[$(date +%H:%M:%S)] dispatch: " + strings.ReplaceAll(expanded, "\"", "\\\"") + "\"; " + expanded + "; echo \"[$(date +%H:%M:%S)] exit=$?\"; } >>/tmp/whichkey.log 2>&1"
	c := exec.Command("sh", "-c", "sleep 0.15; "+logged)
	c.Stdout = nil
	c.Stderr = nil
	c.Stdin = nil
	c.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	return c.Start()
}

func actionCommand(name string) (actionResult, error) {
	switch name {
	case "tab_next":
		c, err := neighborTabCommand(1)
		return actionResult{cmd: c}, err
	case "tab_prev":
		c, err := neighborTabCommand(-1)
		return actionResult{cmd: c}, err
	case "workspace_next":
		c, err := neighborWorkspaceCommand(1)
		return actionResult{cmd: c}, err
	case "workspace_prev":
		c, err := neighborWorkspaceCommand(-1)
		return actionResult{cmd: c}, err
	case "workspace_close":
		ws := currentWorkspaceID()
		if ws == "" {
			return actionResult{}, fmt.Errorf("no workspace")
		}
		return actionResult{cmd: "{HERDR} workspace close " + ws}, nil
	case "tab_close":
		tab := currentTabID()
		if tab == "" {
			return actionResult{}, fmt.Errorf("no tab")
		}
		return actionResult{cmd: "{HERDR} tab close " + tab}, nil
	case "workspace_rename":
		ws := currentWorkspaceID()
		if ws == "" {
			return actionResult{}, fmt.Errorf("no workspace")
		}
		return actionResult{promptLabel: "New workspace label", promptTmpl: "{HERDR} workspace rename " + ws + " {INPUT}"}, nil
	case "tab_rename":
		tab := currentTabID()
		if tab == "" {
			return actionResult{}, fmt.Errorf("no tab")
		}
		return actionResult{promptLabel: "New tab label", promptTmpl: "{HERDR} tab rename " + tab + " {INPUT}"}, nil
	case "worktree_new":
		return actionResult{promptLabel: "New worktree branch", promptTmpl: "{HERDR} worktree create --branch {INPUT} --focus"}, nil
	case "worktree_open":
		return actionResult{promptLabel: "Open worktree branch", promptTmpl: "{HERDR} worktree open --branch {INPUT} --focus"}, nil
	}
	return actionResult{}, fmt.Errorf("unknown action")
}

func shellQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", "'\\''") + "'"
}

func currentTabID() string {
	if t := os.Getenv("HERDR_TAB_ID"); t != "" {
		return t
	}
	v, err := herdrJSON("pane", "current", "--current")
	if err != nil {
		return ""
	}
	if m, ok := v.(map[string]any); ok {
		if r, ok := m["result"].(map[string]any); ok {
			if t, ok := r["tab_id"].(string); ok {
				return t
			}
			if p, ok := r["pane"].(map[string]any); ok {
				if t, ok := p["tab_id"].(string); ok {
					return t
				}
			}
		}
	}
	return ""
}

func neighborWorkspaceCommand(delta int) (string, error) {
	v, err := herdrJSON("workspace", "list")
	if err != nil {
		return "", err
	}
	arr := extractArray(v, "workspaces")
	if len(arr) == 0 {
		return "", fmt.Errorf("no workspaces")
	}
	current := currentWorkspaceID()
	ids := make([]string, 0, len(arr))
	focused := -1
	for _, x := range arr {
		obj, ok := x.(map[string]any)
		if !ok {
			continue
		}
		id, _ := obj["workspace_id"].(string)
		if id == "" {
			continue
		}
		ids = append(ids, id)
		if f, _ := obj["focused"].(bool); f {
			focused = len(ids) - 1
		} else if current != "" && id == current {
			focused = len(ids) - 1
		}
	}
	if len(ids) == 0 {
		return "", fmt.Errorf("no workspaces")
	}
	if focused < 0 {
		focused = 0
	}
	next := (focused + delta + len(ids)) % len(ids)
	return "{HERDR} workspace focus " + ids[next], nil
}

func neighborTabCommand(delta int) (string, error) {
	ws := currentWorkspaceID()
	if ws == "" {
		return "", fmt.Errorf("no workspace")
	}
	v, err := herdrJSON("tab", "list", "--workspace", ws)
	if err != nil {
		return "", err
	}
	arr := extractArray(v, "tabs")
	if len(arr) == 0 {
		return "", fmt.Errorf("no tabs")
	}
	ids := make([]string, 0, len(arr))
	focused := -1
	for _, x := range arr {
		obj, ok := x.(map[string]any)
		if !ok {
			continue
		}
		id, _ := obj["tab_id"].(string)
		if id == "" {
			continue
		}
		ids = append(ids, id)
		if f, _ := obj["focused"].(bool); f {
			focused = len(ids) - 1
		}
	}
	if len(ids) == 0 {
		return "", fmt.Errorf("no tabs")
	}
	if focused < 0 {
		focused = 0
	}
	next := (focused + delta + len(ids)) % len(ids)
	return "{HERDR} tab focus " + ids[next], nil
}

func resolveSource(name string) ([]Item, error) {
	switch name {
	case "workspaces":
		return listWorkspaces()
	case "tabs":
		return listTabs()
	}
	return nil, fmt.Errorf("unknown source")
}

func herdrJSON(args ...string) (any, error) {
	c := exec.Command(herdrBin(), args...)
	c.Stderr = os.Stderr
	out, err := c.Output()
	if err != nil {
		return nil, err
	}
	var v any
	if err := json.Unmarshal(out, &v); err != nil {
		return nil, fmt.Errorf("parse json: %w", err)
	}
	return v, nil
}

func extractArray(v any, keys ...string) []any {
	m, ok := v.(map[string]any)
	if !ok {
		if a, ok := v.([]any); ok {
			return a
		}
		return nil
	}
	if r, ok := m["result"].(map[string]any); ok {
		for _, k := range keys {
			if a, ok := r[k].([]any); ok {
				return a
			}
		}
		if a, ok := r["items"].([]any); ok {
			return a
		}
	}
	for _, k := range keys {
		if a, ok := m[k].([]any); ok {
			return a
		}
	}
	return nil
}

func nodesToItems(arr []any, cmdTemplate, idField string) []Item {
	out := make([]Item, 0, len(arr))
	used := map[string]bool{}
	for i, x := range arr {
		obj, ok := x.(map[string]any)
		if !ok {
			continue
		}
		id, _ := obj[idField].(string)
		if id == "" {
			id, _ = obj["id"].(string)
		}
		if id == "" {
			continue
		}
		label, _ := obj["label"].(string)
		if label == "" {
			label, _ = obj["name"].(string)
		}
		if label == "" {
			label, _ = obj["title"].(string)
		}
		key := strconv.Itoa(i + 1)
		if used[key] {
			continue
		}
		used[key] = true
		title := label
		if title == "" {
			title = id
		}
		out = append(out, Item{
			Key:   key,
			Title: title,
			Run:   strings.ReplaceAll(cmdTemplate, "{ID}", id),
		})
	}
	return out
}

func listWorkspaces() ([]Item, error) {
	v, err := herdrJSON("workspace", "list")
	if err != nil {
		return nil, err
	}
	arr := extractArray(v, "workspaces")
	return nodesToItems(arr, "{HERDR} workspace focus {ID}", "workspace_id"), nil
}

func currentWorkspaceID() string {
	if ws := os.Getenv("HERDR_WORKSPACE_ID"); ws != "" {
		return ws
	}
	v, err := herdrJSON("pane", "current", "--current")
	if err != nil {
		return ""
	}
	if m, ok := v.(map[string]any); ok {
		if r, ok := m["result"].(map[string]any); ok {
			if ws, ok := r["workspace_id"].(string); ok {
				return ws
			}
			if p, ok := r["pane"].(map[string]any); ok {
				if ws, ok := p["workspace_id"].(string); ok {
					return ws
				}
			}
		}
	}
	return ""
}

func listTabs() ([]Item, error) {
	args := []string{"tab", "list"}
	if ws := currentWorkspaceID(); ws != "" {
		args = append(args, "--workspace", ws)
	}
	v, err := herdrJSON(args...)
	if err != nil {
		return nil, err
	}
	arr := extractArray(v, "tabs")
	return nodesToItems(arr, "{HERDR} tab focus {ID}", "tab_id"), nil
}

func main() {
	cfgPath := flag.String("config", defaultConfigPath(), "path to menu.toml")
	flag.Parse()

	var menu Menu
	if _, err := toml.DecodeFile(*cfgPath, &menu); err != nil {
		fmt.Fprintln(os.Stderr, "whichkey: load config:", err)
		os.Exit(1)
	}

	m := model{stack: []frame{{items: menu.Item}}}
	final, err := tea.NewProgram(m).Run()
	if err != nil {
		fmt.Fprintln(os.Stderr, "whichkey:", err)
		os.Exit(1)
	}
	fm := final.(model)
	if fm.dispatch == "" {
		return
	}
	if err := run(fm.dispatch); err != nil {
		fmt.Fprintln(os.Stderr, "whichkey: dispatch:", err)
		os.Exit(1)
	}
}
