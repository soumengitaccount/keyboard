# Debian package

Build the Linux release bundle and create an installable Debian package:

```bash
./packaging/build-deb.sh
```

The Linux build includes an IBus input-method engine. Install the build
dependency first:

```bash
sudo apt install libibus-1.0-dev
```

After installing the generated package, restart IBus, then add **Bangla Avro**
in IBus Preferences (Input Method → Add). For a quick test in the current
session:

```bash
ibus restart
ibus engine bangla-avro
```

The build host needs Flutter, CMake, a C++ compiler, `pkg-config`, and the GTK
and IBus development files. On Debian or Ubuntu, install the missing native
build tools with `sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libibus-1.0-dev`.

The package is written to `dist/bangla-keyboard_<version>_<architecture>.deb`.

Install it with:

```bash
sudo apt install ./dist/bangla-keyboard_*.deb
```

The application bundle is installed in `/opt/bangla-keyboard`, with a launcher
at `/usr/bin/bangla-keyboard` and a desktop-menu entry named **Bangla Keyboard**.
