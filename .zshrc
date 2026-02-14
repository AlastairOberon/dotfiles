ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
	mkdir -p "$(dirname $ZINIT_HOME)"
	git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

#source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

#Plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Load completions
autoload -U compinit && compinit

#History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm: {a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls -color'
alias snapup='sudo snapper -c root create --description "Snapshot_Root $(date +%F_%T)" && sudo snapper -c home create --description "Snapshot_Home $(date +%F_%T)"'
alias snaplist='echo "Root snapshots:" && sudo snapper -c root list && echo "" && echo "Home snapshots:" && sudo snapper -c home list'


#Keybinds
bindkey -v

#Shell Integrations
eval "$(fzf --zsh)"

#Starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

[[ -f ~/.local/bin/env ]] && source ~/.local/bin/env


#YaziDirUpdate
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

#QMLStuff
export PATH=/usr/lib/qt6/bin:$PATH


. "$HOME/.local/bin/env"

export EDITOR="nvim"

#Cuda for GPU

export CUDA_HOME=/opt/cuda
export PATH=$PATH:$CUDA_HOME/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_HOME/lib64

# Add this to your shell config to let TensorFlow find the bundled CUDA libs
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/.venv/lib/python3.12/site-packages/nvidia/cuda_runtime/lib/
