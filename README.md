# Copilot Key Remapper & Launcher

A lightweight Windows 11 utility written in Rust that integrates directly into Windows settings to remap physical **Copilot hardware keys** (or `Win` + `Shift` + `F23`) to launch Google Gemini or any custom binary.

Pakaged as a native MSIX container, it exposes the `com.microsoft.windows.copilotkeyprovider` Windows App Extension, enabling it to appear directly inside:
> **Settings → Personalization → Text input / Keyboard → Customize Copilot key on keyboard**

---

## Features

- **Windows Integration:** Fully compliant with Microsoft's official Copilot hardware key extension contract.
- **Custom App Execution:** Launches Google Gemini (`%LOCALAPPDATA%\Google\Gemini\Gemini.exe`) by default, or prompts with a high-DPI scaling Rust setup GUI to configure any alternative executable and optional arguments.
- **DPI-Aware & Console-Free:** Runs seamlessly without opening terminal windows (`windows_subsystem = "windows"`) and respects system DPI scale factors.
- **Minimal Permissions:** Scoped strictly with `<rescap:Capability Name="runFullTrust" />` without unnecessary capabilities.

---

## Project Structure

```text
copilot-key-remapper/
├── CopilotLauncherMSIX/            # MSIX Staging Directory
│   ├── AppxManifest.xml            # Package definition & Copilot Key extension contract
│   ├── Assets/                     # Application icons (44x44, 150x150)
│   ├── Binary/                     # Destination for compiled launcher.exe
│   └── Public/                     # App extension metadata (CopilotProvider.json)
├── launcher/                       # Rust Application Source
│   ├── src/
│   │   └── main.rs                 # Executable resolution & UI / process launcher
│   ├── build.rs                    # Win32 resource script builder
│   ├── Cargo.toml                  # Rust dependencies (windows-sys, NWG, serde)
│   └── launcher.exe.manifest       # Side-by-side assembly manifest for high-DPI
├── BuildMSIX.ps1                   # Automated build, package, and sign pipeline
└── SetupCertificate.ps1            # Auto-elevating self-signed certificate installer