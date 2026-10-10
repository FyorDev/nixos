# l = eza viewer eza viewer
alias l 'eza -laH --icons --git --group-directories-first --time-style=long-iso --hyperlink'
alias lg 'l --git-ignore'
alias lr 'eza --tree --icons --group-directories-first --hyperlink'
alias lrg 'lr --git-ignore'

# start claude with rest of args as a string
function haiku; claude --model haiku (string join " " $argv); end
function sonnet; claude --model sonnet (string join " " $argv); end
function opus; claude --model opus-5 (string join " " $argv); end
function fable; claude --model fable-5 (string join " " $argv); end

# one shot haiku, prints markdown
function huh
    claude -p --model claude-haiku-4-5-20251001 (string join " " $argv) | glow -s dark - 2>/dev/null
end

# haiku generated diff and conventional commit suggestion
function haikudiff
    begin
        echo "=== STAGED ==="
        git diff --staged
        echo "=== UNSTAGED ==="
        git diff
        echo "=== UNTRACKED ==="
        for f in (git ls-files --others --exclude-standard)
            git diff --no-index -- /dev/null $f
        end
    end | huh "Summarize what changed in each of the STAGED, UNSTAGED, UNTRACKED sections above in a few short bullet points. Then write a conventional commit message for everything, and suggest one alternative."
end

function fish_user_key_bindings
    bind ctrl-n nvim
end

# lazy no fish greeting ever
function fish_greeting; end
# theme, bobthefish prompt with Nerd Font icons
set -g theme_color_scheme catppuccin-mocha
set -g theme_nerd_fonts yes

if status is-interactive
    fastfetch
end
