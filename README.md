Teensy Project Toolchain
===========================
 
Purpose
-------
A set of tool for compiling and uploading to a Teensy on Windows.

This Toolchain was made specifically for the Teensy 3.6, however other teensy cores are included.

Where everything came from
--------------------------

### ARM Toolchain
- The folders with the names `arm-none-eabi`, `bin`, and `lib` all come from the arduino install directory `hardware/tools/arm`
  - If you wish, you can substitute this for a newer version
### Teensy Core
- The `teensy` sub-folder is taken from a [Teensyduino](http://www.pjrc.com/teensy/td_download.html) installation from the arduino install directory `hardware/teensy`
### Tools
- `ComMonitor.exe` is from [ComMonitor-CLI](https://github.com/LeHuman/ComMonitor-CLI)
  - More info about usage on it's repository, this repo may get special builds of the CLI
- `teensy_loader_cli.exe` is the [Teensy Loader Command Line](https://www.pjrc.com/teensy/loader_cli.html) compiled for Windows
- `ninja.exe` is the [Ninja Build System](https://github.com/ninja-build/ninja) binary for Windows