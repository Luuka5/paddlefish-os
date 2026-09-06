function fish_prompt --description 'Write out the prompt'
    set -l last_status $status
    set -l normal (set_color normal)

    # Srcery Exact Palette Mapping
    set -l cwd_color (set_color 2c78bf)       # Blue (regular4)
    set -l vcs_color (set_color 519f50)       # Green (regular2)
    set -l suffix_color (set_color fce8c3)    # White (foreground)
    set -l error_color (set_color f75341)     # Bright Red (bright1)
    set -l prompt_status ""

    # Since we display the prompt on a new line allow the directory names to be longer.
    set -q fish_prompt_pwd_dir_length
    or set -lx fish_prompt_pwd_dir_length 0

    # Color the prompt differently when we're root
    set -l suffix '$'
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set cwd_color (set_color $fish_color_cwd_root)
        end
        set suffix '#'
    end

    # Format the error indicator if the last command failed
    if test $last_status -ne 0
        set prompt_status $error_color "[" $last_status "]" $normal
    end

    # Print error status if it exists, followed by the prompt arrow (Red) on line two
    if test -n "$prompt_status"
        echo -s $prompt_status ' '
    end

    # newline to make output more spacy and nicer to navigate with vim keybinds
    echo

    # Print login, directory (Blue), and Jujutsu/Git status (Green) inline on line one
    echo -s (prompt_login) ' ' $cwd_color (prompt_pwd) ' ' $vcs_color (fish_vcs_prompt) $normal

    echo -n -s $suffix_color $suffix ' ' $normal
end

