# l = eza viewer eza viewer
alias l 'eza -laH --icons --git --group-directories-first --time-style=long-iso --hyperlink'
alias lg 'l --git-ignore'
alias lr 'eza --tree --icons --group-directories-first --hyperlink'
alias lrg 'lr --git-ignore'
set -gx EZA_COLORS 'ur=92:uw=92:ux=92;1:ue=31;1:gr=92:gw=92:gx=31;1:tr=92:tw=92:tx=31;1:uu=34;1:uR=31;1:da=92:lc=34;1:nb=92'

# start claude with rest of args as a string
function haiku; claude --model haiku (string join " " $argv); end
function sonnet; claude --model sonnet (string join " " $argv); end
function opus; claude --model opus-5 (string join " " $argv); end
function fable; claude --model fable-5 (string join " " $argv); end

# one shot haiku, prints markdown
function huh
    claude -p --model claude-haiku-4-5-20251001 (string join " " $argv) | glow -s dark - 2>/dev/null
end

# cowsay nerd
function akshually; cowsay -f actually (string join " " $argv); end

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
    bind -e alt-c
    bind -M insert -e alt-c
    bind ctrl-g fzf-cd-widget
    bind -M insert ctrl-g fzf-cd-widget
end

# lazy no fish greeting ever
function fish_greeting; end
# theme, bobthefish prompt with Nerd Font icons
set -g theme_color_scheme catppuccin-mocha
set -g theme_nerd_fonts yes

# Wake-on-Lan ASUS
function wake-asus
    set -l mac (string replace -a : '\x' 24:4b:fe:06:e6:7f)
    begin
        printf '\xff%.0s' (seq 6)
        printf "\x$mac%.0s" (seq 16)
    end | ssh blahajresidence.nl 'socat - UDP-DATAGRAM:192.168.178.255:9,broadcast'
end

if status is-interactive
    fastfetch
end
