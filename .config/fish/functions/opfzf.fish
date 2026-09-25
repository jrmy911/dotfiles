function opfzf --description 'Choose a 1Password item and copy its password'
    if not command -q op
        echo '1Password CLI is not installed' >&2
        return 1
    end

    if not command -q jq
        echo 'jq is required' >&2
        return 1
    end

    set -l entries (mktemp)
    or return 1
    set -l items_json (mktemp)
    or begin
        rm -f $entries
        return 1
    end
    set -l op_error (mktemp)
    or begin
        rm -f $entries $items_json
        return 1
    end

    command op item list --format json >$items_json 2>$op_error
    set -l list_status $status

    if test $list_status -ne 0; and command grep -q 'You are not currently signed in' $op_error
        eval (command op signin)
        set -l signin_status $status

        if test $signin_status -eq 0
            command op item list --format json >$items_json 2>$op_error
            set list_status $status
        end
    end

    if test $list_status -ne 0
        command cat $op_error >&2
        rm -f $entries $items_json $op_error
        echo 'Unable to sign in or list 1Password items' >&2
        status is-interactive; and commandline -f repaint
        return 1
    end

    command jq -r '
        .[]
        | [
            (.title | gsub("[\\t\\r\\n]"; " ")),
            (.category // "-"),
            (.vault.name // "-" | gsub("[\\t\\r\\n]"; " ")),
            .id
          ]
        | @tsv
    ' $items_json >$entries
    set -l parse_status $status
    rm -f $items_json $op_error

    if test $parse_status -ne 0
        rm -f $entries
        echo 'Unable to parse the 1Password item list' >&2
        status is-interactive; and commandline -f repaint
        return 1
    end

    if not test -s $entries
        rm -f $entries
        echo 'No accessible items found. ❌' >&2
        status is-interactive; and commandline -f repaint
        return 1
    end

    set -l fzf_height 65%
    if set -q PICKER_FZF_HEIGHT
        set fzf_height $PICKER_FZF_HEIGHT
    end
    set -l fzf_margin 0
    if set -q PICKER_FZF_MARGIN
        set fzf_margin $PICKER_FZF_MARGIN
    end

    set -l selected (command fzf \
        --height=$fzf_height \
        --margin=$fzf_margin \
        --layout=reverse \
        --border \
        --delimiter='\t' \
        --with-nth=1,2,3 \
        --prompt='1Password > ' \
        --header='Enter: copy password  •  Esc: cancel' \
        <$entries)
    set -l fzf_status $status
    rm -f $entries

    if test $fzf_status -ne 0; or test -z "$selected"
        status is-interactive; and commandline -f repaint
        return
    end

    set -l fields (string split \t -- $selected)
    set -l item_id $fields[-1]
    set -l copy_status 1

    if command -q wl-copy; and set -q WAYLAND_DISPLAY
        command op item get $item_id --fields label=password --reveal \
            | command wl-copy --paste-once
        set copy_status $pipestatus[1]
    else if command -q xclip; and set -q DISPLAY
        command op item get $item_id --fields label=password --reveal \
            | command xclip -selection clipboard
        set copy_status $pipestatus[1]
    else if command -q xsel; and set -q DISPLAY
        command op item get $item_id --fields label=password --reveal \
            | command xsel --clipboard --input
        set copy_status $pipestatus[1]
    else if command -q clip.exe
        command op item get $item_id --fields label=password --reveal \
            | command clip.exe
        set copy_status $pipestatus[1]
    else
        echo 'No supported clipboard command found' >&2
        status is-interactive; and commandline -f repaint
        return 1
    end

    if test $copy_status -eq 0
        if command -q wl-copy; and set -q WAYLAND_DISPLAY
            echo 'Password copied; it will clear after one paste. ✔' \n
        else
            echo 'Password copied to clipboard. ✔' \n
        end
    else
        echo 'The selected item has no accessible password field. 🙈' >&2 \n
    end

    status is-interactive; and commandline -f repaint
    return $copy_status
end
