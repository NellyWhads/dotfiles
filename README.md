# dotfiles
My dotfiles for a clean OS rampup.

## Supported OSes (detected automatically)

- Ubuntu (Tested on >= 22.04)
- MacOS (Tested on >= 14)

## Usage

`sudo ./install.sh`

### Ubuntu

To preserve the user's HOME environment variable use
`sudo -E ./install.sh`

### Headless mode

`sudo ./install.sh --headless`

This installs only headless tools/applications and omits things such as Google Chrome and VSCode.
