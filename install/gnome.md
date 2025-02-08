# Install squeak-app in Gnome

This guide describes a user-local installation.

## Binaries

- Download a compatible Linux bundle from <https://github.com/OpenSmalltalk/opensmalltalk-vm>

- Extract its contents to `~/.local/squeak/<version>/`

- Copy `balloon.svg` to `~/.local/squeak/squeak.svg`

- Create `~/.ocal/bin/squeak`:

  ```sh
  #!/bin/sh
  set -e
  version=202502080249
  cd "$HOME/.local/squeak/$version/"
  exec ./squeak "$@"
  ```

  - Make it executable (`chmod +x`)

- Verify that in a terminal, `squeak myimage.image` works

> [!NOTE]
> Not sure whether this aligns ideally with Ubuntu’s update-alternatives mechanism

## Gnome Launcher

- Create `nano ~/.local/share/applications/squeak.desktop`:

  ```ini
  [Desktop Entry]
  Type=Application
  Name=Squeak
  Exec=/home/<USER>/.local/bin/squeak %F
  Icon=/home/<USER>/.local/squeak/squeak.svg
  Terminal=false
  Categories=Development;
  MimeType=application/x-squeakimage;
  ```

  - Replace `<USER>` in the above with your local user name (`echo "$USER"`)
  - Make it executable (`chmod +x`)

- Optionally, validate: `desktop-file-validate ~/.local/share/applications/squeak.desktop`

- `update-desktop-database ~/.local/share/applications`

## Open With

- `mkdir -p ~/.local/share/mime/packages/`

- Create `~/.local/share/mime/packages/squeak.xml`:

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
    <mime-type type="application/x-squeakimage">
      <comment>Squeak Image</comment>
      <glob pattern="*.image"/>
    </mime-type>
  </mime-info>
  ```

- `update-mime-database ~/.local/share/mime`

## File Icon

> [!CAUTION]
> Currently not working, breaks other icons of local-user applications!
>
> ChatGPT said it should work like this, though…

- `mkdir -p .local/share/icons/hicolor/128x128/mimetypes/ && convert .local/squeak/squeak.svg -resize 128x128 -gravity center -background none -extent 128x128 .local/share/icons/hicolor/128x128/mimetypes/application-x-squeakimage.png`

  - Same for other powers of two
  - Requires ImageMagick (`sudo apt-get install imagemagick`)

- Create `nano ~/.local/share/icons/hicolor/index.theme`:

  ```ini
  [Icon Theme]
  Name=Hicolor
  Comment=User local hicolor icon theme
  Directories=128x128/mimetypes
  
  [128x128/mimetypes]
  Size=128
  Context=Mimetypes
  Type=Fixed
  ```

- `gtk-update-icon-cache -f ~/.local/share/icons/hicolor`
