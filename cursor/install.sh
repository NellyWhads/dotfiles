printf '\n\e[34;1m%s\e[0m\n\n' "--------Cursor Installation--------" 1>&2

printf '\e[34m%s\e[0m\n' "Installing Cursor..." 1>&2
if [ "$MACHINE" = "Ubuntu" ] && [ "$UI_TYPE" != "headless" ]; then
    curl -fsSL https://cursor.sh/install | bash
elif [ "$MACHINE" = "MacOS" ] && [ "$UI_TYPE" != "headless" ]; then
    brew install cursor
else
    printf '\e[31m%s\e[0m\n' "Cursor not installed..." 1>&2
fi
