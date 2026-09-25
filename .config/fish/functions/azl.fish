function __azl_cache_current_tenant --argument-names tenant_cache
    set -l graph_record (command az rest \
        --method GET \
        --url 'https://graph.microsoft.com/v1.0/organization?$select=id,displayName,verifiedDomains' \
        --query 'value[0]' \
        --output json 2>/dev/null \
        | command jq -r '
            select(.id != null and .displayName != null)
            | [
                .id,
                (.displayName | gsub("[\\t\\r\\n]"; " ")),
                (([.verifiedDomains[]? | select(.isInitial == true) | .name] | first) // "")
              ]
            | @tsv
        ')

    test -n "$graph_record"; or return

    set -l tenant_id (string split \t -- $graph_record)[1]
    command mkdir -p (dirname $tenant_cache)
    set -l updated_cache (mktemp)
    or return 1

    if test -f $tenant_cache
        command awk -F '\t' -v tenant="$tenant_id" '$1 != tenant' $tenant_cache >$updated_cache
    end
    printf '%s\n' $graph_record >>$updated_cache
    command chmod 600 $updated_cache
    command mv $updated_cache $tenant_cache
end

function azl --description 'Choose a cached Azure tenant and sign in'
    if not command -q az
        echo 'azl: Azure CLI is not installed' >&2
        return 1
    end

    if not command -q jq
        echo 'azl: jq is required' >&2
        return 1
    end

    set -l entries (mktemp)
    or return 1
    set -l raw_entries (mktemp)
    or begin
        rm -f $entries
        return 1
    end

    set -l cache_root "$HOME/.cache"
    if set -q XDG_CACHE_HOME; and test -n "$XDG_CACHE_HOME"
        set cache_root $XDG_CACHE_HOME
    end
    set -l tenant_cache "$cache_root/azl/tenants.tsv"

    # Refresh the currently authenticated tenant even when the login happened
    # outside this picker.
    __azl_cache_current_tenant $tenant_cache

    command az account list --all --output json 2>/dev/null \
        | command jq -r '
            sort_by(.tenantId)
            | group_by(.tenantId)
            | .[]
            | ([.[].tenantDisplayName // empty] | map(select(length > 0)) | unique | first // "-") as $name
            | [$name, .[0].tenantId]
            | @tsv
        ' >$raw_entries
    set -l list_status $pipestatus[1]

    if test -f $tenant_cache
        command awk -F '\t' -v OFS='\t' '
            FNR == NR {
                if (NF >= 2 && $1 != "" && $2 != "") names[$1] = $2
                next
            }
            {
                if ($2 in names) $1 = names[$2]
                print
            }
        ' $tenant_cache $raw_entries >$entries
    else
        command cp $raw_entries $entries
    end
    rm -f $raw_entries

    if test $list_status -ne 0; or not test -s $entries
        rm -f $entries
        echo 'azl: no cached Azure tenants found; run az login once manually' >&2
        return 1
    end

    set -l selected (command fzf \
        --height=60% \
        --layout=reverse \
        --border \
        --delimiter='\t' \
        --with-nth=1,2 \
        --prompt='Azure tenant > ' \
        --header='Enter: sign in  •  Esc: cancel' \
        <$entries)
    set -l fzf_status $status
    rm -f $entries

    if test $fzf_status -ne 0; or test -z "$selected"
        commandline -f repaint
        return
    end

    set -l fields (string split \t -- $selected)
    set -l tenant_id $fields[-1]

    command az login --tenant $tenant_id
    set -l login_status $status

    if test $login_status -eq 0
        __azl_cache_current_tenant $tenant_cache
    end

    commandline -f repaint
    return $login_status
end
