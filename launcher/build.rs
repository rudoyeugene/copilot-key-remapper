fn main() {
    if std::env::var("CARGO_CFG_TARGET_OS").unwrap() == "windows" {
        let mut res = winres::WindowsResource::new();
        res.set_manifest_file("launcher.exe.manifest");
        res.compile().unwrap();
    }
    println!("cargo:rerun-if-changed=launcher.exe.manifest");
}