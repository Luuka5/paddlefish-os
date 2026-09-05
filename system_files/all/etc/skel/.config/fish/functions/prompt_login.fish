function prompt_login --description 'Print user@host with srcery colors'
    set -l color_user (set_color $fish_color_user)
    set -l color_at (set_color $fish_color_normal)
    set -l color_host (set_color $fish_color_host)

    echo -n -s $color_user "$USER" \
        $color_at '@' \
        $color_host (prompt_hostname) \
        $color_at
end
