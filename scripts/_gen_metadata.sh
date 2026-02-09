#!/bin/bash

parse_plugin() {
    # Abstract:
    # plugin_name = unique hash in the git repository that will not change unless the history is force deleted.
    # commit_id = latest commit from the repository
    #
    # We need to use an ID for a plugin name because we have no other static information that will *always*
    # identify a repository. Ex: using actual owner/repo if the user changed their name or repo name it would break millennium.

    local plugins_dir=$1
    local submodule=$2
    local submodule_path="$plugins_dir/$submodule"
    local plugin_name commit_id

    # Get the first commit that isn't from me (i.e if they used the plugin template)
    plugin_name=$(git -C "$submodule_path" log --format='%H %ae' --reverse 2>/dev/null | grep -Fv '81448108+shdwmtr@users.noreply.github.com' | head -1 | cut -d' ' -f1 | tr -d '\n')
    # Fallback to root commit if all commits are ours
    [[ -z "$plugin_name" ]] && plugin_name=$(git -C "$submodule_path" rev-list --max-parents=0 HEAD 2>/dev/null | tr -d '\n')
    commit_id=$(git -C "$submodule_path" rev-parse HEAD 2>/dev/null | tr -d '\n')

    echo "{\"id\": \"$plugin_name\", \"commitId\": \"$commit_id\"}"
}

plugins_dir="$(pwd)/plugins"
plugin_ids=()

if [[ -d "$plugins_dir" ]]; then
    while IFS= read -r submodule; do
        parse_plugin "$plugins_dir" "$submodule"
    done < <(ls "$plugins_dir")
fi | jq -s '.' > metadata.json
