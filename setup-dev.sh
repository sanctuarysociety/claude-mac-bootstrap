#!/bin/zsh
# Dev environment setup for macOS (Apple Silicon).
# Installs: Xcode CLT, Homebrew, Oh My Zsh (powerlevel10k theme), Meslo Nerd
# Font, autosuggestions + syntax highlighting, Bun, Node, GitHub CLI, an SSH
# key for GitHub, and the Cloudflare wrangler CLI.
# Safe to run more than once: anything already installed is skipped.
#
# Several steps below need a human at the keyboard (a GUI installer window,
# a sudo password prompt, a passphrase prompt). The script stops and tells
# you what to do rather than trying to script around them.
set -e
step() { print -P "\n%F{magenta}==> $1%f"; }

step "Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
  echo "A macOS installer window opened. Finish it, then run this script again."
  exit 0
fi
echo "OK"

step "Homebrew"
if [[ ! -x /opt/homebrew/bin/brew ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
grep -q 'brew shellenv' ~/.zprofile 2>/dev/null || \
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
brew --version | head -1

step "Oh My Zsh"
if [[ ! -d ~/.oh-my-zsh ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
echo "OK"

step "Powerline font (Meslo Nerd Font)"
brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1 || brew install --cask font-meslo-lg-nerd-font
echo "OK"

step "Autocomplete plugins"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] || \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] || \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
echo "OK"

step "Powerlevel10k theme"
[[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]] || \
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
echo "OK"

step "Configuring ~/.zshrc"
[[ -f ~/.zshrc ]] && cp ~/.zshrc ~/.zshrc.backup-$(date +%Y%m%d-%H%M%S)
sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
sed -i '' 's/^plugins=(.*/plugins=(git macos zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
if ! grep -q '# >>> dev-setup >>>' ~/.zshrc; then
  cat >> ~/.zshrc <<'EOF'

# >>> dev-setup >>>
# Hide user@host in the prompt on her own account
DEFAULT_USER="$USER"
# Globally installed Bun packages (bun add -g)
export PATH="$HOME/.bun/bin:$PATH"
# Quick jump to the dev folder
alias dev="cd ~/Dev"
# <<< dev-setup <<<
EOF
fi
echo "OK (backup saved next to ~/.zshrc, if one existed)"

step "Bun"
brew list bun >/dev/null 2>&1 || brew install oven-sh/bun/bun
echo "bun $(bun --version) at $(command -v bun)"

step "Node"
# Needed even in a Bun-first project: some npm-ecosystem CLIs (e.g. wrangler)
# ship a binary shim with a `#!/usr/bin/env node` shebang. Without node on
# PATH, running them fails with "env: node: No such file or directory" even
# though `bun add -g` installed them successfully.
brew list node >/dev/null 2>&1 || brew install node
echo "node $(node --version)"

step "GitHub CLI"
brew list gh >/dev/null 2>&1 || brew install gh
gh --version | head -1

step "SSH key for GitHub"
if [[ ! -f ~/.ssh/id_ed25519 ]]; then
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  echo "Enter the email to label the key with, then follow the prompts"
  echo "(ssh-keygen will ask for a passphrase -- that's your call, empty is fine):"
  read "GIT_EMAIL?  Email: "
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f ~/.ssh/id_ed25519
  echo "Public key (add this to GitHub -> Settings -> SSH and GPG keys):"
  cat ~/.ssh/id_ed25519.pub
  echo "Then run: gh auth login"
else
  echo "OK (~/.ssh/id_ed25519 already exists)"
fi
touch ~/.ssh/known_hosts
grep -q '^github.com ' ~/.ssh/known_hosts 2>/dev/null || \
  ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null
echo "OK (github.com host key trusted)"

step "Cloudflare wrangler"
command -v wrangler >/dev/null 2>&1 || bun add -g wrangler
echo "wrangler $(wrangler --version 2>&1 | head -1)"

print -P "\n%F{green}All done!%f"
echo "Last step: Terminal > Settings > Profiles > Text > Font -> choose 'MesloLGS Nerd Font' (13pt)."
echo "Then open a new Terminal window. Powerlevel10k's configuration wizard will start automatically"
echo "the first time -- just answer its prompts to pick a prompt style."
echo "If a new SSH key was generated, add it to GitHub and run 'gh auth login' before using git over SSH."
