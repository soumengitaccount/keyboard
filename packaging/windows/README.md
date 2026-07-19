# Windows executable

On a Windows x64 machine with Flutter's Windows desktop support, Visual Studio
with the **Desktop development with C++** workload, and Inno Setup 6 installed,
run from PowerShell:

```powershell
.\packaging\windows\build-exe.ps1
```

This creates the installable executable:

`dist\BanglaKeyboardSetup-<version>-windows-x64.exe`

The installer contains `bangla_keyboard.exe` together with its required Flutter
engine DLLs, plugins, data, and assets. Do not distribute the inner executable
by itself.

To create a portable bundle instead of an installer executable:

```powershell
.\packaging\windows\build-exe.ps1 -SkipInstaller
```
