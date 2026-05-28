if status is-interactive
# Commands to run in interactive sessions can go here
end

# opencode
fish_add_path $HOME/.opencode/bin
fish_add_path $HOME/.cargo/bin

function fish_greeting
    echo Hello Jeremy!
    echo The time is (set_color yellow)(date +%T)(set_color --reset).
end

starship init fish | source
zoxide init fish | source
