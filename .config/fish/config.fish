if status is-interactive
    function tmux_project_picker
        command $HOME/.local/bin/tmux-project
        commandline -f repaint
    end

    bind \cp tmux_project_picker
end

fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/go/bin/

function fish_greeting
    echo Hello Jeremy!
    echo The time is (set_color yellow)(date +%T)(set_color --reset). 
end

starship init fish | source
zoxide init fish | source

test -s ~/.config/envman/load.fish; and source ~/.config/envman/load.fish

eval "$(keychain add id_ecdsa --eval)"
