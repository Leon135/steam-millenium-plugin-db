#!/bin/bash

PYTHON_PLUGINS=()
LUA_PLUGINS=()

while IFS= read -r line; do
    submodule_path=$(echo "$line" | awk '{print $2}')

    if [[ -z "$submodule_path" ]]; then
        continue
    fi

    plugin_json="$submodule_path/plugin.json"
    plugin_name=$(basename "$submodule_path")

    if [[ -f "$plugin_json" ]]; then
        backend_type=$(jq -r '.backendType // "undefined"' "$plugin_json" 2>/dev/null)
        use_backend=$(jq -r 'if has("useBackend") then .useBackend else true end' "$plugin_json" 2>/dev/null)

        if [[ "$use_backend" == "false" || "$backend_type" == "lua" ]]; then
            LUA_PLUGINS+=("$plugin_name")
        else
            PYTHON_PLUGINS+=("$plugin_name")
        fi
    else
        echo "Warning: No plugin.json found in $submodule_path"
    fi
done < <(git submodule status)

TOTAL_PLUGINS=$(( ${#LUA_PLUGINS[@]} + ${#PYTHON_PLUGINS[@]} ))

echo "## Repository Manifest"
echo ""

# Determine the max rows needed
max_rows=${#LUA_PLUGINS[@]}
if (( ${#PYTHON_PLUGINS[@]} > max_rows )); then
    max_rows=${#PYTHON_PLUGINS[@]}
fi

echo "The following table describes the remaining deprecated Python plugins that need to be ported to Lua."
echo "Python is no longer officially supported by Millennium and will be removed entirely in a future update."

echo ""
echo "**Total**: ${TOTAL_PLUGINS}"
echo " * **Lua**: ${#LUA_PLUGINS[@]}"
echo " * **Python**: ${#PYTHON_PLUGINS[@]}"
echo ""
echo ""

echo "| Lua | Python |"
echo "|-----|--------|"

for (( i=0; i<max_rows; i++ )); do
    if (( i < ${#LUA_PLUGINS[@]} )); then
        lua_num="$(( i + 1 ))"
        lua_name="${LUA_PLUGINS[$i]}"
    else
        lua_num=""
        lua_name=""
    fi

    if (( i < ${#PYTHON_PLUGINS[@]} )); then
        py_num="$(( i + 1 ))"
        py_name="${PYTHON_PLUGINS[$i]}"
    else
        py_num=""
        py_name=""
    fi

    echo "| $lua_name | $py_name |"
done
