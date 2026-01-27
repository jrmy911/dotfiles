#eval "$(keychain --eval --agents ssh id_ecdsa)"
#export PATH="$PATH:/home/fedora/.local/bin"

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit ice depth=1

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
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
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='eza -lh --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --long --icons --git'
alias vim='nvim'
alias cat='bat'
alias c='clear'
alias tf='terraform'
alias ds='ddgr -j'
alias d='ddgr'
alias bwup='export BW_SESSION=$(bw unlock --raw)'
alias gcaz='git clone -c "core.sshCommand=ssh -i ~/.ssh/id_rsa"'
alias azpr='az repos pr create'
alias music='ncmpcpp'

# Function to fuzzy search Bitwarden and copy to Wayland clipboard
bwp() {
  # 1. Fetch names and IDs from Bitwarden
  # 2. Use fzf to let you pick one
  local selection=$(bw list items | jq -r '.[] | .name' | fzf --height 40% --reverse --header="Select account:")

  # If you didn't escape out of fzf
  if [[ -n "$selection" ]]; then
    bw get password "$selection" | wl-copy --trim
    print -P "%F{green}✓%f Password for %B$selection%b copied back to clipboard."
    
    # Optional: Clear clipboard after 45 seconds in the background
    (sleep 45 && wl-copy --clear) &!
  fi
}


if [[ -z "$BW_SESSION" ]]; then
    
    if [[ -n "$TMUX" ]]; then
        export BW_SESSION=$(tmux show-environment | grep "^BW_SESSION=" | cut -d= -f2-)
    fi

    if [[ -z "$BW_SESSION" ]]; then
        echo -n "Unlock Bitwarden Vault? (y/n): "
        read -k 1 -r response
        echo "" 

        if [[ "$response" =~ ^[Yy]$ ]]; then
            SESSION_TOKEN=$(bw unlock --raw)
            
            if [[ -n "$SESSION_TOKEN" ]]; then
                export BW_SESSION="$SESSION_TOKEN"
                
                if [[ -n "$TMUX" ]]; then
                    tmux set-environment BW_SESSION "$SESSION_TOKEN"
                fi
                print -P "%F{green}✓%f Vault unlocked and synced to tmux."
            else
                print -P "%F{red}✗%f Login failed."
            fi
        else
            export BW_SESSION="skipped"
            print -P "%F{yellow}◌%f Vault remains locked."
        fi
    fi
fi

if [[ "$BW_SESSION" == "skipped" ]]; then
    unset BW_SESSION
fi

alias bwup='export BW_SESSION=$(bw unlock --raw) && tmux set-environment BW_SESSION "$BW_SESSION"'

export BROWSER=vimb
export EDITOR=vim

reddit() {
  if [ "$#" -lt 2 ]; then
    echo "Usage: reddit <subreddit> <keywords>"
    return 1
  fi

  # Extract the first argument as the subreddit
  local sub=$1
  # Join the rest of the arguments as the search query
  shift
  local query=$*
  
  # URL encode the query (replaces spaces with +)
  local encoded_query=$(echo "$query" | tr ' ' '+')

  # The URL for searching a specific subreddit
  # restrict_sr=1 limits results to the subreddit provided
  local url="https://www.reddit.com/r/${sub}/search/?q=${encoded_query}&restrict_sr=1"

  # Launch in your preferred TUI browser
  # Change 'w3m' to 'lynx' or 'carbonyl' if preferred
  vimb "$url" &
}

if [ -n "$DESKTOP_SESSION" ]; then
    eval $(echo -n "unlocked_password" | gnome-keyring-daemon --unlock)
fi

# Search Azure Docs via Terminal
azdoc() {
  local query=$(echo "$*" | tr ' ' '+')
  # Using the 'learn' search engine which is TUI-friendly
  local url="https://learn.microsoft.com/en-us/search/?scope=Azure&terms=${query}"
  
  cha "$url"
}

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"
