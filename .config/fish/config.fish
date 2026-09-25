if status is-interactive
    # Open the project picker from the bottom of the current terminal. The
    # selected project is then opened in (or switched to) its tmux session.
    function tmux_project_picker
        if set -q TMUX
            command tmux display-popup \
                -E \
                -e TMUX_PROJECT_FZF_HEIGHT=100% \
                -w 85% \
                -h 75% \
                -d '#{pane_current_path}' \
                -T ' Projects ' \
                "$HOME/.local/bin/tmux-project"
        else
            command env \
                TMUX_PROJECT_FZF_HEIGHT=75% \
                $HOME/.local/bin/tmux-project
        end
        commandline -f repaint
    end

    bind \cp tmux_project_picker

    # Pick a recent GitHub Actions run or open PR from the current repository,
    # then inspect it with gh enhance.
    function github_picker_popup
        if set -q TMUX
            command tmux display-popup \
                -E \
                -e PICKER_FZF_HEIGHT=100% \
                -w 90% \
                -h 80% \
                -d '#{pane_current_path}' \
                -T ' GitHub ' \
                'fish -c github_picker'
        else
            set -lx PICKER_FZF_HEIGHT 80%
            github_picker
        end
        commandline -f repaint
    end
    bind \cg github_picker_popup

    # Replace Fish's clear-screen binding with an Azure tenant login picker.
    function azure_login_picker_popup
        if set -q TMUX
            command tmux display-popup \
                -E \
                -e PICKER_FZF_HEIGHT=100% \
                -w 80% \
                -h 65% \
                -d '#{pane_current_path}' \
                -T ' Azure tenants ' \
                'fish -c azl'
        else
            set -lx PICKER_FZF_HEIGHT 60%
            azl
        end
        commandline -f repaint
    end
    bind \cl azure_login_picker_popup

    # Search 1Password items and copy the selected password to the clipboard.
    function onepassword_picker_popup
        if set -q TMUX
            command tmux display-popup \
                -E \
                -e PICKER_FZF_HEIGHT=100% \
                -w 80% \
                -h 70% \
                -d '#{pane_current_path}' \
                -T ' 1Password ' \
                'fish -c opfzf'
        else
            set -lx PICKER_FZF_HEIGHT 65%
            opfzf
        end
        commandline -f repaint
    end
    bind \co onepassword_picker_popup
end

fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/go/bin/

function fish_greeting
    echo Hello Jeremy!
    echo The time is (set_color yellow)(date +%T)(set_color --reset). 

    fastfetch
end

starship init fish | source
zoxide init fish | source

test -s ~/.config/envman/load.fish; and source ~/.config/envman/load.fish

eval "$(keychain add id_ecdsa --eval --quiet)"
