#!/bin/sh
set -euo pipefail

# First human user (uid 1000-59999), if one exists.
user=$(awk -F: '$3 >= 1000 && $3 < 60000 { print $1; exit }' /etc/passwd 2>/dev/null || true)

if [ -z "$user" ]; then
    printf '\nWelcome to Paddlefish OS.\n'
    printf 'No user account exists yet. Create one now.\n\n'

    while :; do
        printf 'Username: '
        read -r user || exit 1
        case "$user" in
            '' | *[!a-z0-9_-]* | [0-9]* | -* | _*)
                echo "Invalid username (lowercase letters, digits, '_' and '-' only)."
                ;;
            *) break ;;
        esac
    done

    while :; do
        printf 'Password: '
        read -rs pw && printf '\n' || exit 1
        [ -n "$pw" ] || { echo "Password cannot be empty."; continue; }
        printf 'Repeat password: '
        read -rs pw2 && printf '\n' || exit 1
        [ "$pw" = "$pw2" ] || { echo "Passwords do not match."; continue; }
        break
    done

    useradd --create-home --groups wheel --shell /usr/bin/fish "$user"
    printf '%s:%s\n' "$user" "$pw" | chpasswd
    echo
    echo "Account '$user' created."
fi

# greetd auto-login for that user.
cat > /etc/greetd/config.toml <<EOF
[terminal]
vt = 1

[default_session]
command = "/usr/libexec/paddlefish/niri-session"
user = "$user"

[initial_session]
command = "/usr/libexec/paddlefish/niri-session"
user = "$user"
EOF

systemctl enable greetd.service >/dev/null 2>&1 || true
mkdir -p /var/lib/paddlefish
touch /var/lib/paddlefish/firstboot.done

echo "Setup complete. Rebooting into your session..."
systemctl reboot
