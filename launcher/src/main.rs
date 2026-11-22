#![windows_subsystem = "windows"]

use std::path::PathBuf;
use std::process::Command;
use windows_sys::Win32::UI::WindowsAndMessaging::{
    MessageBoxW, MB_ICONERROR, MB_OK,
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
    let mut gemini_path = match std::env::var("LOCALAPPDATA") {
        Ok(val) => PathBuf::from(val),
        Err(_) => {
            message_box("Error", "Gemini Desktop not found, exiting");
            return;
        }
    };

    gemini_path.push("Google");
    gemini_path.push("Gemini");
    gemini_path.push("Gemini.exe");

    if !gemini_path.exists() {
        message_box("Error", "Gemini Desktop not found, exiting");
        return;
    }

    if Command::new(&gemini_path).spawn().is_err() {
        message_box("Error", "Gemini Desktop not found, exiting");
    }
}