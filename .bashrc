# Set Starship theme
eval "$(starship init bash)"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --bash)"

# Load local custom extra commands if needed
# This file is in my dotfiles and single host specific stuff should not be
single_computer_specific="$HOME/.single_computer_specific"
[[ -s $single_computer_specific ]] && source "$single_computer_specific"
