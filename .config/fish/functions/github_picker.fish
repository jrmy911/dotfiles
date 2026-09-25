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
            --json number,title,url \
            --jq '.[] | ["PR", ("#" + (.number | tostring)), .title, .url] | @tsv'
    end >$entries

    if not test -s $entries
        rm -f $entries
        echo 'github-picker: no recent runs or open pull requests found' >&2
        return 1
    end

    set -l selected (command fzf \
        --height=70% \
        --layout=reverse \
        --border \
        --delimiter='\t' \
        --with-nth=1,2,3,4 \
        --prompt='GitHub > ' \
        --header='Enter: open gh enhance in a new tmux window  •  Esc: cancel' \
        <$entries)
    set -l fzf_status $status
    rm -f $entries

    if test $fzf_status -ne 0; or test -z "$selected"
        commandline -f repaint
        return
    end

    set -l fields (string split \t -- $selected)
    set -l url $fields[-1]

    if set -q TMUX
        set -l enhance_command "gh enhance "(string escape -- $url)
        command tmux new-window \
            -n enhance \
            -c "$PWD" \
            "$enhance_command"
    else
        command gh enhance $url
    end

    commandline -f repaint
end
