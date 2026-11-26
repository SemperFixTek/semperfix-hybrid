#!/usr/bin/env bash

sfx-deploy() {
    local src="/mnt/c/semperfix/Git/repos/semperfix-hybrid/wsl/opt/semperfix"
    local dest="/opt/semperfix"
    local dry_run=0
    local target=""

    # Parse arguments (--dry-run / -n and optional subfolder name)
    for arg in "$@"; do
        case "$arg" in
            --dry-run|-n)
                dry_run=1
                ;;
            -*)
                echo "Error: Unknown option '$arg'. Usage: sfx-deploy [--dry-run|-n] [subdir]"
                return 1
                ;;
            *)
                if [ -n "$target" ]; then
                    echo "Error: Multiple target directories specified ('$target' and '$arg')."
                    return 1
                fi
                target="${arg%/}" # Strip trailing slash if present
                ;;
        esac
    done

    local excludes=(
        --exclude='logs/'
        --exclude='state/'
        --exclude='reports/'
    )
    local base_flags=(-rlptDv --delete --chown=root:semperfix "${excludes[@]}")

    if [ "$dry_run" -eq 1 ]; then
        base_flags+=(--dry-run)
        echo "=== DRY RUN MODE: No files, ownership, or permissions will be modified ==="
    fi

    # Helper to enforce root:semperfix, 755 dirs, and 644 files on logs/
    _fix_logs_perms() {
        if [ "$dry_run" -eq 1 ]; then
            echo "[Dry Run] Would enforce root:semperfix, 755 dirs, and 644 files on $dest/logs"
            return 0
        fi
        if [ -d "$dest/logs" ]; then
            sudo chown -R root:semperfix "$dest/logs"
            sudo find "$dest/logs" -type d -exec chmod 755 {} +
            sudo find "$dest/logs" -type f -exec chmod 644 {} +
        fi
    }

    if [ -n "$target" ]; then
        case "$target" in
            logs)
                echo "Info: 'logs' is a protected runtime directory (skipping file copy, enforcing 644 permissions)..."
                _fix_logs_perms
                return 0
                ;;
            state|reports)
                echo "Error: '$target' is a protected runtime directory and cannot be deployed."
                return 1
                ;;
        esac

        if [ ! -d "$src/$target" ]; then
            echo "Error: Source directory '$src/$target' does not exist."
            return 1
        fi

        local perms="D755,F755"
        [[ "$target" == config* ]] && perms="D755,F644"

        [ "$dry_run" -eq 0 ] && sudo mkdir -p "$dest/$target"
        sudo rsync "${base_flags[@]}" --chmod="$perms" "$src/$target/" "$dest/$target/"
    else
        # Deploy everything except protected directories, applying 644 to config/
        sudo rsync "${base_flags[@]}" --chmod=D755,F755 --exclude='config/' "$src/" "$dest/"
        if [ -d "$src/config" ]; then
            [ "$dry_run" -eq 0 ] && sudo mkdir -p "$dest/config"
            sudo rsync "${base_flags[@]}" --chmod=D755,F644 "$src/config/" "$dest/config/"
        fi
        _fix_logs_perms
    fi
}

# Tab-completion for sfx-deploy
_sfx-deploy_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local src="/mnt/c/semperfix/Git/repos/semperfix-hybrid/wsl/opt/semperfix"

    # Suggest flags if typing '-'
    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "--dry-run -n" -- "$cur") )
        return 0
    fi

    # Dynamically list subdirectories in src, excluding protected runtime folders
    if [ -d "$src" ]; then
        local dirs
        dirs=$(find "$src" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | grep -vxE 'state|reports')
        COMPREPLY=( $(compgen -W "$dirs logs --dry-run" -- "$cur") )
    fi
}
complete -F _sfx-deploy_completions sfx-deploy
