use core::slice;
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
    pub path: *const String,
    pub len: usize,
    pub score: usize,
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
                let len = item.path.len();
                let ptr = strs;
                path.chars()
                    .for_each(|c| {
                        if strs as usize >= base_strs as usize + strs_len {
                            return;
                        }
                        strs.write(c as u8);
                        strs = strs.add(1);
                    });

                dat.write_unaligned(Data { path: ptr as *const String, len, score: 0 });
                dat = dat.add(1);
            }
        });

    files.sort_by(|a, b| {
        return a.path.cmp(&b.path);
    });

    return files.len();
}

#[no_mangle]
pub extern "C" fn filter_ffi(mut dat: *mut Data, item_count: isize) -> usize {

    if item_count >= 1000 {
        return 0;
    }
    
    let mut datas = Vec::new();
    let mut strings = Vec::new();

    for _ in 0..item_count {
        unsafe {
            if dat.is_null() {
                continue;
            }

            let data = dat.read();
            
            let mut buf = String::new();
            let mut byte_ptr = data.path as *mut u8;

            if byte_ptr.is_null() {
                continue;
            }

            for _ in 0..data.len {
                buf.push(byte_ptr.read() as char);
                byte_ptr = byte_ptr.add(1);
            }

            datas.push(data);
            strings.push(buf);

            dat = dat.add(1);
        }
    }

    filter(&mut datas, &mut strings);

    69_420
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

static mut IGNORE_CASE: bool = false;
static mut SUFFIX_FILTER: bool = false;
static mut CONTAINS_FILTER: bool = false;
static mut MATCH_PATH: bool = false;
static mut IGNORE_WHITESPACE: bool = true;
static mut USER_INPUT: String = String::new();

pub fn filter(datas: &mut Vec<Data>, paths: &mut Vec<String>) {

    let mut match_datas = Vec::new();
    let mut matches = Vec::new();

    for (i, real_path) in paths.iter().enumerate() {
        let path = if unsafe { IGNORE_CASE } {
            unsafe {
                USER_INPUT = USER_INPUT.to_lowercase();
            }
            real_path.to_string().to_lowercase()
        }
        else {
            real_path.to_string()
        };

        if unsafe { SUFFIX_FILTER } && path.ends_with('$') {
            if path.chars().take(path.len() - 1).collect::<String>().ends_with(unsafe { &USER_INPUT }) {
                matches.push(path);
            }
            continue;
        }

        if unsafe { CONTAINS_FILTER } && path.ends_with('?') {
            if path.chars().take(path.len() - 1).collect::<String>().contains(unsafe { &USER_INPUT }) {
                matches.push(path);
            }
            continue;
        }

        let user_input_len = unsafe { &USER_INPUT }.len();

        if user_input_len > path.len() {
            continue;
        }


        let (is_match, score) = fzf(
            if unsafe { MATCH_PATH } {
                &path
            }
            else {
                let parts = &path.split("/").collect::<Vec<_>>();
                if parts.is_empty() {
                    continue;
                }
                parts.last().unwrap()
            }
        );

        if !is_match {
            continue;
        }

        matches.push(path);
        let mut data = datas.get(i).unwrap().clone();
        data.score = score;
        match_datas.push(data);
    }
}

pub fn fzf(s: &str) -> (bool, usize) {

    let user_input = unsafe { &USER_INPUT };
    let mut input_idx = 0usize;
    let mut last_hit;
    let mut seq_len = 0usize;
    let mut score = 1usize;

    if user_input.trim() == "" {
        return (false, 1usize);
    }

    for c in s.chars() {
        if unsafe { IGNORE_WHITESPACE } && c.is_whitespace() {
            continue;
        }

        if input_idx >= user_input.len() {
            break;
        }

        if c == user_input.chars().nth(input_idx).unwrap() {
            input_idx += 1;
            last_hit = true;
            seq_len += 1;
        }
        else {
            seq_len = 0;
            last_hit = false;
        }

        if last_hit {
            score *= seq_len.max(2);
        }
    }

    return (input_idx == user_input.len(), score);
}

#[test]
pub fn test_fzf() {
    unsafe {
        USER_INPUT = "bal.rs".into();
    }
    dbg!(fzf("ballin.rs"));
}
