function vim --description 'Open files in the parent nvim (if inside one), else with nvim'
    if not set -q NVIM
        nvim $argv
        return
    end

    if test (count $argv) -eq 0
        return
    end

    # Resolve paths against the shell's cwd: the parent nvim resolves
    # :drop relative to its own cwd, which may differ.
    set -l targets
    for path in $argv
        if string match -q -- '-*' $path
            set -a targets $path
        else
            set -a targets (realpath -m $path)
        end
    end

    nvim --server "$NVIM" --remote $targets
end