printf '\n\e[34;1m%s\e[0m\n\n' "--------VSCode Installation--------" 1>&2

printf '\e[34m%s\e[0m\n' "Installing Visual Studio Code..." 1>&2
if [ "$MACHINE" = "Ubuntu" ]; then
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
    sudo install -o root -g root -m 644 /tmp/microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    sudo apt-get install apt-transport-https -y
    sudo apt-get update
    sudo apt-get install code -y # or code-insiders
elif [ "$MACHINE" = "MacOS" ]; then
    brew cask install visual-studio-code
fi
