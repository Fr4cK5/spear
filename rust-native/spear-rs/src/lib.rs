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
pub extern "C" fn walk_ffi(mut dat: *mut Data, dat_len: usize, mut strs: *mut u8, strs_len: usize, mut wd_ptr: *mut u8, wd_len: isize) -> usize {

    let mut wd_str = String::new();
    unsafe {
        for _ in 0..wd_len {
            wd_str.push(wd_ptr.read() as char);
            wd_ptr = wd_ptr.add(1);
        }
    };

    let mut files = Vec::new();
    walk(&wd_str, &mut files);

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
pub extern "C" fn filter_ffi(mut dat: *mut Data, item_count: isize, mut dat_filtered: *mut Data, mut str_filtered: *mut u8) -> usize {

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

    let mut out_datas = Vec::new();
    let mut out_strs = Vec::new();
    filter(&datas, &strings, &mut out_datas, &mut out_strs);

    let match_count = out_datas.len();

    for (i, data) in out_datas.iter().enumerate() {
        unsafe {
            dat_filtered.write_unaligned(data.clone());
            dat_filtered = dat_filtered.add(1);

            out_strs.get(i).unwrap().chars()
                .for_each(|c| {
                    str_filtered.write_unaligned(c as u8);
                    str_filtered = str_filtered.add(1);
                });
        }
    }

    return match_count;
}

pub fn walk(path: &str, v: &mut Vec<FileHit>) {
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
                    v.push(FileHit { path: new_path.replace("\\", "/").replace("//", "/"), mode: FileMode::Dir });
                    walk(&new_path, v);
                }
                else if ftype.is_file() {
                    v.push(FileHit { path: new_path.replace("\\", "/").replace("//", "/"), mode: FileMode::File });
                }
            }
        });
    }
}

static mut IGNORE_CASE: bool = true;
static mut SUFFIX_FILTER: bool = true;
static mut CONTAINS_FILTER: bool = true;
static mut MATCH_PATH: bool = true;
static mut IGNORE_WHITESPACE: bool = true;
static mut USER_INPUT: String = String::new();

#[no_mangle]
pub extern "C" fn set_ignore_case(value: isize) {
    unsafe {
        IGNORE_CASE = value >= 1;
    }
}
#[no_mangle]
pub extern "C" fn set_suffix_filter(value: isize) {
    unsafe {
        SUFFIX_FILTER = value >= 1;
    }
}
#[no_mangle]
pub extern "C" fn set_contains_filter(value: isize) {
    unsafe {
        CONTAINS_FILTER = value >= 1;
    }
}
#[no_mangle]
pub extern "C" fn set_match_path(value: isize) {
    unsafe {
        MATCH_PATH = value >= 1;
    }
}
#[no_mangle]
pub extern "C" fn set_ignore_whitespace(value: isize) {
    unsafe {
        IGNORE_WHITESPACE = value >= 1;
    }
}
#[no_mangle]
pub extern "C" fn set_user_input(mut s: *mut u8, len: isize) {
    unsafe {
        let mut buf = String::new();
        for _ in 0..len {
            buf.push(s.read() as char);
            s = s.add(1);
        }

        USER_INPUT = buf;
    }
}

pub fn filter(datas: &Vec<Data>, paths: &Vec<String>, match_datas: &mut Vec<Data>, matches: &mut Vec<String>) {

    let user_input = unsafe { &USER_INPUT };

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

        if unsafe { SUFFIX_FILTER } && user_input.ends_with('$') {
            let real_user_input = &user_input.chars().take(user_input.len() - 1).collect::<String>();
            if path.ends_with(real_user_input) {
                match_datas.push(datas.get(i).unwrap().clone());
                matches.push(path);
            }
            continue;
        }

        if unsafe { CONTAINS_FILTER } && user_input.ends_with('?') {
            let real_user_input = &user_input.chars().take(user_input.len() - 1).collect::<String>();
            if path.contains(real_user_input) {
                match_datas.push(datas.get(i).unwrap().clone());
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