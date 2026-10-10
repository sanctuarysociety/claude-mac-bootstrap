# Claude macOS Dev Bootstrap

Instructions for Claude to follow when setting up a fresh macOS machine (Apple
Silicon) for software development, starting from a clean install or a just
-upgraded system. Written from a real bootstrap session — the steps, order,
and gotchas below are things that actually came up, not a generic checklist.

[`setup-dev.sh`](./setup-dev.sh) in this repo runs everything below in one
idempotent pass — Xcode CLT, Homebrew, Oh My Zsh + powerlevel10k + Nerd Font,
Bun, Node, `gh`, an SSH key, and `wrangler`. It's meant to be read and
adapted, not run blindly: walk through it with the person, and be ready to
stop and hand control back to them at the interactive prompts called out
below (GUI installer, sudo password, SSH passphrase, `brew`'s y/n confirm
on big installs).

## Guiding principles

- **Idempotent.** Every step should check whether it's already done before
  doing it. The person running this may re-run it after a partial failure.
- **Several steps need a human.** Don't try to script around them — stop,
  explain what's needed, and wait.
- **Confirm before anything destructive or account-creating.** Installing
  packages and editing shell config in `~/Dev` or `~/.zshrc` is fine to do
  directly. Creating accounts, pushing to a *new* public repo, or anything
  that touches a service outside this machine should be confirmed first (see
  your own operating rules for the authoritative list — this doc doesn't
  override them).

## 1. Xcode Command Line Tools

```bash
xcode-select -p || xcode-select --install
```

If it wasn't already installed, this opens a **GUI installer window**. It
cannot be driven headlessly — tell the person to finish it, then come back
and continue. Don't loop waiting on it; just stop and ask.

## 2. Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
grep -q 'brew shellenv' ~/.zprofile 2>/dev/null || \
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
```

The installer asks for the account **password** (sudo) interactively. If
you're running this through a tool that can't accept typed input into an
already-running command (e.g. a one-shot command runner), run it in a
terminal the person can type into directly, and tell them to do so.

Also note: `brew install` will sometimes print `Do you want to proceed with
the installation? [y/n]` before a big formula (e.g. installing Node pulls in
~24 dependencies). Same issue — that needs a human at the keyboard unless
your shell tool supports sending input to a running process.

## 3. Zsh: Oh My Zsh + Powerlevel10k + a Nerd Font

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

brew install --cask font-meslo-lg-nerd-font
```

Then in `~/.zshrc`:

```bash
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git macos zsh-autosuggestions zsh-syntax-highlighting)
```

Prefer **powerlevel10k** over agnoster — it has a guided first-run wizard and
looks right out of the box with a Nerd Font, instead of needing manual color
tweaks. The person needs to set their terminal's font to "MesloLGS Nerd
Font" by hand (Terminal.app: Settings → Profiles → Text → Font) — this can't
be scripted. The p10k configuration wizard runs automatically the first time
a new interactive shell opens, if no `~/.p10k.zsh` exists yet.

If recommending a terminal emulator upgrade: **Ghostty** is a good default
for someone who doesn't want to hand-edit config files (GPU-accelerated,
sane defaults, renders Nerd Fonts correctly out of the box). iTerm2 is the
alternative if they want everything GUI-configurable instead. Kitty is fine
too but leans more config-file-first than most beginners want.

## 4. Bun

```bash
curl -fsSL https://bun.sh/install | bash
```

This installs to `~/.bun/bin` but does **not** add itself to `PATH` in a
fresh shell on its own — if there's no `~/.zshrc` yet (e.g. right after a
macOS reinstall, before Oh My Zsh has run), `bun` will exist on disk but not
resolve from a new Terminal window. Add explicitly:

```bash
export PATH="$HOME/.bun/bin:$PATH"
```

## 5. Node (yes, even in a Bun-first project)

```bash
brew install node
```

Don't skip this just because Bun is the intended JS runtime. Several
npm-ecosystem CLI tools (wrangler is one) ship a binary shim with a
`#!/usr/bin/env node` shebang — even if **Bun** installed the package
globally (`bun add -g <pkg>`), running the resulting binary directly still
needs `node` on `PATH`, or it fails with `env: node: No such file or
directory`. Installing Node via Homebrew is the simplest fix.

## 6. GitHub: SSH key + `gh` CLI

```bash
brew install gh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "<their email>" -f ~/.ssh/id_ed25519
```

`ssh-keygen` prompts for a passphrase interactively — ask the person whether
they want one (more secure, can be stored in macOS Keychain) or none
(simpler, no re-entry). Don't choose for them and don't type into that
prompt yourself.

Once the key exists, the person adds the public key
(`~/.ssh/id_ed25519.pub`) to their GitHub account's SSH keys and runs
`gh auth login` themselves (or you drive it if the flow doesn't need a
password/credential you'd otherwise have to type).

Before the first `git push`/`git clone` over SSH, GitHub's host key usually
needs to be trusted:

```bash
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
```

Verify with `ssh -o BatchMode=yes -T git@github.com` — a successful
response looks like `Hi <username>! You've successfully authenticated, but
GitHub does not provide shell access.`

## 7. Cloudflare: `wrangler`

```bash
bun add -g wrangler
```

Needs Node on `PATH` to actually run (see step 5). Verify with
`wrangler --version`.

## Verification checklist

After running through the above, confirm each of these works in a **new**
interactive terminal window (not just the one the script ran in — startup
files only apply to new shells):

- [ ] `brew --version`
- [ ] `bun --version`
- [ ] `node --version`
- [ ] `gh auth status` shows logged in
- [ ] `ssh -T git@github.com` authenticates
- [ ] `wrangler --version` runs without a `node: No such file` error
- [ ] New shell prompt shows the powerlevel10k theme, not the plain default
