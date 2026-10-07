# l = eza viewer eza viewer
alias l 'eza -laH --icons --git --group-directories-first --time-style=long-iso --hyperlink'
alias lg 'l --git-ignore'
alias lr 'eza --tree --icons --group-directories-first --hyperlink'
alias lrg 'lr --git-ignore'

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
