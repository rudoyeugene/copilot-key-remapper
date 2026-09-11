#![windows_subsystem = "windows"]

use std::process::Command;
use std::path::PathBuf;
use windows_sys::Win32::UI::WindowsAndMessaging::{
    MessageBoxW, MB_OK, MB_ICONERROR,
};

fn message_box(title: &str, text: &str) {
    unsafe {
        MessageBoxW(
            0,
            to_wide(text).as_ptr(),
            to_wide(title).as_ptr(),
            MB_OK | MB_ICONERROR,
        );
    }
}

fn to_wide(s: &str) -> Vec<u16> {
    use std::os::windows::ffi::OsStrExt;
    std::ffi::OsStr::new(s)
        .encode_wide()
        .chain(std::iter::once(0))
        .collect()
}

fn main() {
    // Resolve per-user LocalAppData path
    let local_app_data = std::env::var("LOCALAPPDATA")
        .expect("LOCALAPPDATA environment variable not found");

    // Build full path to Gemini.exe
    let mut gemini_path = PathBuf::from(local_app_data);
    gemini_path.push("Google");
    gemini_path.push("Gemini");
    gemini_path.push("Gemini.exe");

    // Check existence
    if !gemini_path.exists() {
        message_box(
            "Gemini not found",
            "Gemini.exe was not found in:\n%LOCALAPPDATA%\\Google\\Gemini\n\nPlease install Gemini or adjust your setup."
        );
        return;
    }

    // Launch Gemini
    let _ = Command::new(&gemini_path).spawn();
}
