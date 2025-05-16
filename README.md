# Arch Linux + Hyprland dotfiles

<!-- markdownlint-disable -->

<!-- toc -->

- [First Time Setup](#first-time-setup)
- [Setting up a new machine](#setting-up-a-new-machine)
- [References](#references)
- [Recommend Arch Linux and Hyprland Script](#recommend-arch-linux-and-hyprland-script)
- [VMware](#vmware)
    * [Known issues](#known-issues)
    * [Note](#note)
    * [Enable extra mouse actions (mouse5, mouse6)](#enable-extra-mouse-actions-mouse5-mouse6)
    * [Fix startup stuttering](#fix-startup-stuttering)
- [Hyprland](#hyprland)
    * [Zsh](#zsh)
        + [Oh My Zsh + Powerlevel10k](#oh-my-zsh--powerlevel10k)
        + [Useful CLI tools](#useful-cli-tools)
    * [Fcitx5 (Chinese input)](#fcitx5-chinese-input)
        + [Setup](#setup)
        + [Flags](#flags)
    * [Clipboard manager](#clipboard-manager)
    * [Remote Desktop using VNC (wayvnc)](#remote-desktop-using-vnc-wayvnc)

<!-- tocstop -->

<!-- markdownlint-enable -->

## First Time Setup

1. create bare repository

   ```bash
   mkdir $HOME/.dotfiles

   git init --bare $HOME/.dotfiles
   ```

2. make an alias for runing git commands (to .bashrc or .zshrc)

   ```bash
   alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
   ```

3. add a remote, and also set status not to show untracked files

   ```bash
   dot config --local status.showUntrackedFiles no

   dot remote add origin <repo>

   dot branch -m main
   ```

4. run `dotfiles.sh` to sync dotfiles automatically

## Setting up a new machine

```bash
git clone --separate-git-dir=$HOME/.dotfiles \
  git@github.com:gin31259461/arch-dotfiles.git tmpdotfiles

rsync --recursive --verbose --exclude '.git' tmpdotfiles/ $HOME/

rm -rf tmpdotfiles

# after restart terminal
dot config --local status.showUntrackedFiles no
```

## References

- [A simpler way to manage your dotfiles](https://www.anand-iyer.com/blog/2018/a-simpler-way-to-manage-your-dotfiles/)

## Recommend Arch Linux and Hyprland Script

1. [JaKooLit's Arch-Hyprland](https://github.com/JaKooLit/Arch-Hyprland)

   Installation script and configuration for hyprland.

## VMware

### Known issues

1. some `qt` or `gtk3` based app may not be able to run on hyprland, `electron`
   based app seems to work well so far
2. the app not using `qt`, `gtk3`, `electron` lib may also not be able to run on
   hyprland
3. [`xdg-desktop-portal-hyprland`](https://archlinux.org/packages/extra/x86_64/xdg-desktop-portal-hyprland/)
   (XDPH) may not working properly, you can try
   [`xdg-desktop-portal-wlr`](https://archlinux.org/packages/?name=xdg-desktop-portal-wlr)
   (XDPW)

### Note

- enable vmware to pass battery information to guest devices.

### Enable extra mouse actions (mouse5, mouse6)

Add the following configuration to vmx file (make sure the vm is power off).

```vmx
usb.generic.allowHID = "TRUE"
mouse.vusb.enable = "TRUE"
```

### Fix startup stuttering

Add the following configuration to vmx file (make sure the vm is power off).

```vmx
sound.highPriority = "TRUE"
```

Configure `wireplumber`

```bash
mkdir -p ~/.config/wireplumber/wireplumber.conf.d/
cd ~/.config/wireplumber/wireplumber.conf.d
```

Then make ~/.config/wireplumber/wireplumber.conf.d/50-alsa-config.conf in an
editor and add:

```conf
monitor.alsa.rules = [
  {
    matches = [
      # This matches the value of the 'node.name' property of the node.
      {
        node.name = "~alsa_output.*"
      }
    ]
    actions = {
      # Apply all the desired node specific settings here.
      update-props = {
        api.alsa.period-size   = 1024
        api.alsa.headroom      = 8192
      }
    }
  }
]
```

Other stuttering problem refer to following link:

- [Audio/Videao stuttering/crackling, Firefox + PipeWire in VMs](https://bbs.archlinux.org/viewtopic.php?id=280654)
- [Pipewire: Stuttering Audio (in Virtual Machine)](https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Troubleshooting#stuttering-audio-in-virtual-machine)

## Hyprland

### Zsh

#### Oh My Zsh + Powerlevel10k

After installed JaKooLit's Arch-Hyprland (include oh my zsh setting)

1. install powerlevel10k theme and zsh plugin

   ```bash
   git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

   git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
   ```

2. configure `.zshrc`

   ```bash
   ZSH_THEME="powerlevel10k/powerlevel10k"
   ```

3. configure p10k

   ```bash
   p10k configure
   ```

#### Useful CLI tools

refer to:

1. [josean-dev/dev-environment-files](https://github.com/josean-dev/dev-environment-files)
2. [7 Amazing CLI Tools You Need To Try](https://www.youtube.com/watch?v=mmqDYw9C30I&list=PLnu5gT9QrFg36OehOdECFvxFFeMHhb_07&index=13&t=92s)

- [fzf](https://github.com/junegunn/fzf.git)
- [fd](https://github.com/sharkdp/fd)
- [fzf-git](https://github.com/junegunn/fzf-git.sh)
- [bat](https://github.com/sharkdp/bat)
- [delta](https://github.com/dandavison/delta)
- [eza](https://github.com/eza-community/eza.git)
- [tldr](https://github.com/tldr-pages/tldr)
- [thefuck](https://github.com/nvbn/thefuck)

### Fcitx5 (Chinese input)

#### Setup

Run following command to install necessary packages.

```bash
paru -S fcitx5-im fcitx5-chewing
```

Using hyprland to autostart fcitx5 on startup.

```conf
exec-once = fcitx5 &
```

Adding the following setting to hyprland environment to enable fcitx5 be able to
use.

```conf
# env = GTK_IM_MODULE,fcitx
env = QT_IM_MODULE,fcitx
env = XMODIFIERS,@im=fcitx
env = GLFW_IM_MODULE,fcitx
env = INPUT_METHOD,fcitx
env = IMSETTINGS_MODULE,fcitx
env = SDL_IM_MODULE,fcitx
```

#### Flags

To enable fcitx5 used in third party apps, such as electron based apps, we need
to add flags.

- `Electron`

Adding flags to **~/.config/electron-flags.conf**

```conf
--enable-wayland-ime
```

- `Visual Studio Code`

Adding flags to **~/.config/code-flags.conf**

```conf
--enable-wayland-ime
```

### [Clipboard manager](https://wiki.hyprland.org/Useful-Utilities/Clipboard-Managers/)

Using `cliphist` as clipboard manager.

Start by adding the following lines to hyprland config

```conf
exec-once = wl-paste --type text --watch cliphist store # Stores only text data
exec-once = wl-paste --type image --watch cliphist store # Stores only image data
```

To bind `cliphist` to a hotkey for rofi

```conf
bind = SUPER, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
```

### Remote Desktop using VNC (wayvnc)

- [wayvnc](https://github.com/any1/wayvnc)

1. Install `wayvnc` from AUR

   ```bash
   paru -S wayvnc
   ```

2. Encryption & Authentication (RSA-AES)

   ```bash
   mkdir ~/.config/wayvnc

   ssh-keygen -m pem -f ~/.config/wayvnc/rsa_key.pem -t rsa -N ""

   nvim ~/.config/wayvnc/config
   ```

3. Setting parameters

   ```conf
   use_relative_paths=true
   address=0.0.0.0
   enable_auth=true
   username=user
   password=****
   rsa_private_key_file=rsa_key.pem
   ```

4. Finally, setting autostart

   ```conf
   exec-once = wayvnc 127.0.0.1 5900 &
   ```

5. Now we can access hyprland using vnc viewer
