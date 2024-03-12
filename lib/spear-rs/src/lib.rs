use std::{fmt::Display, fs};

#[derive(Clone, Debug)]
pub enum FileMode {
    File,
    Dir,
    Link,
}

impl Display for FileMode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let _ = f.write_str(match &self {
            Self::Dir => "Dir",
            Self::File => "File",
            Self::Link => "Link",
        });

        Ok(())
    }
}

#[derive(Clone, Debug)]
pub struct FileHit {
    pub path: String,
    pub mode: FileMode,
}

#[derive(Clone, Debug)]
pub struct Data {
    pub pathptr: *const String,
    pub pathlen: usize,
}

#[no_mangle]
pub extern "C" fn explore_ffi(mut dat: *mut Data, dat_len: usize, mut strs: *mut u8, strs_len: usize) -> usize {

    let mut files = Vec::new();
    explore(".", &mut files);

    let base_dat = dat;
    let base_strs = strs;

    files.iter()
        .for_each(|item| {
            if dat as usize > base_dat as usize + dat_len {
                return;
            }
            unsafe {
                let path = item.path.to_string();
                let pathlen = item.path.len();
                let ptr = strs;
                path.chars()
                    .for_each(|c| {
                        if strs as usize >= base_strs as usize + strs_len {
                            return;
                        }
                        strs.write(c as u8);
                        strs = strs.add(1);
                    });

                dat.write_unaligned(Data { pathptr: ptr as *const String, pathlen });
                dat = dat.add(1);
            }
        });

    return files.len();
}

pub fn explore(path: &str, v: &mut Vec<FileHit>) {
    if let Ok(dir) = fs::read_dir(path) {
        dir.for_each(|item| {
            if item.is_err() {
                return;
            }

            let file = item.unwrap();
            let file_name = file.file_name().to_string_lossy().to_string();

            let mut new_path: String = path.to_string();
            new_path.push_str("/");
            new_path.push_str(&file_name);

            if let Ok(ftype) = file.file_type() {
                if ftype.is_dir() {
                    v.push(FileHit { path: new_path.clone(), mode: FileMode::Dir });
                    explore(&new_path, v);
                }
                else if ftype.is_file() {
                    v.push(FileHit { path: new_path, mode: FileMode::File });
                }
            }
        });
    }
}
