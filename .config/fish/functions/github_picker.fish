function github_picker --description 'Pick a GitHub Actions run or PR and open it in gh enhance'
    if not command gh repo view >/dev/null 2>&1
        echo 'github-picker: current directory is not a GitHub repository' >&2
        return 1
    end

    set -l entries (mktemp)
    or return 1

    begin
        command gh run list --limit 10 \
            --json conclusion,displayTitle,status,url \
            --jq '.[] | ["RUN", (if .conclusion == "" then .status else .conclusion end), .displayTitle, .url] | @tsv'

        command gh pr list --state open --limit 50 \
            --json number,state,title,url \
            --jq '.[] | ["PR", ("#" + (.number | tostring) + " · " + .state), .title, .url] | @tsv'

        command gh pr list --state closed --limit 5 \
            --json number,state,title,url \
            --jq '.[] | ["PR", ("#" + (.number | tostring) + " · " + .state), .title, .url] | @tsv'
    end >$entries

    if not test -s $entries
        rm -f $entries
        echo 'no recent runs or open pull requests found.' >&2
        return 1
    end

    set -l fzf_height 70%
    if set -q PICKER_FZF_HEIGHT
        set fzf_height $PICKER_FZF_HEIGHT
    end
    set -l fzf_margin 0
    if set -q PICKER_FZF_MARGIN
        set fzf_margin $PICKER_FZF_MARGIN
    end

    set -l picker_output (command fzf \
        --height=$fzf_height \
        --margin=$fzf_margin \
        --layout=reverse \
        --border \
        --delimiter='\t' \
        --with-nth=1,2,3,4 \
        --prompt='GitHub > ' \
        --header='Enter: View GitHub Actions  •  Ctrl+O: View PR  •  Esc: cancel' \
        --expect=ctrl-o \
        --preview='if test {1} = PR; GH_FORCE_TTY=$FZF_PREVIEW_COLUMNS gh pr view {4} 2>&1; end' \
        --preview-window='right,60%,border-left,wrap' \
        <$entries)
    set -l fzf_status $status
    rm -f $entries

    if test $fzf_status -ne 0; or test (count $picker_output) -lt 2
        status is-interactive; and commandline -f repaint
        return
    end

    set -l pressed_key $picker_output[1]
    set -l selected $picker_output[2]
    set -l fields (string split \t -- $selected)
    set -l item_type $fields[1]
    set -l url $fields[-1]

    if test "$pressed_key" = ctrl-o
        if test "$item_type" != PR
            echo 'Ctrl+O is only available for pull requests' >&2
            status is-interactive; and commandline -f repaint
            return 1
        end

        set -l url_parts (string match -r '^https://[^/]+/([^/]+)/([^/]+)/pull/([0-9]+)' -- $url)
        if test (count $url_parts) -ne 4
            echo 'could not parse pull request URL' >&2
            status is-interactive; and commandline -f repaint
            return 1
        end

        set -l owner $url_parts[2]
        set -l repo $url_parts[3]
        set -l pr_number $url_parts[4]
        set -l dash_config (mktemp)
        or return 1

        printf '%s\n' \
            'prSections:' \
            '  - title: Selected Pull Request' \
            "    filters: 'repo:$owner/$repo is:pr $pr_number'" \
            'issuesSections: []' \
            'defaults:' \
            '  view: prs' \
            '  prsLimit: 5' \
            '  preview:' \
            '    open: true' \
            '    width: 0.5' \
            >$dash_config

        if set -q TMUX
            set -l dash_command "gh dash --config "(string escape -- $dash_config)"; rm -f "(string escape -- $dash_config)
            command tmux new-window -n dash -c "$PWD" "$dash_command"
            or rm -f $dash_config
        else
            command gh dash --config $dash_config
            rm -f $dash_config
        end
    else if set -q TMUX
        set -l enhance_command "gh enhance "(string escape -- $url)
        command tmux new-window -n enhance -c "$PWD" "$enhance_command"
    else
        command gh enhance $url
    end

    status is-interactive; and commandline -f repaint
end
