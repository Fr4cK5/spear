use std::{fmt::Display, fs};

#[derive(Clone, Debug, PartialEq)]
pub enum FileMode {
    File,
    Dir,
    Link,
    Any,
}

impl Display for FileMode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let _ = f.write_str(match &self {
            Self::Dir => "Dir",
            Self::File => "File",
            Self::Link => "Link",
            Self::Any => "Any",
        });
        Ok(())
    }
}

impl FileMode {
    pub fn as_usize(&self) -> usize {
        return match self {
            Self::Dir => 0,
            Self::File => 1,
            Self::Link => 2,
            Self::Any => 4,
        }
    }

    pub fn from_usize(value: usize) -> Self {
        return match value {
            0 => Self::Dir,
            1 => Self::File,
            2 => Self::Link,
            4 => Self::Any,
            _ => panic!("Invalid file mode as integer {}", value),
        }
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
    pub file_type: usize,
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

                dat.write_unaligned(Data { path: ptr as *const String, len, score: 0, file_type: item.mode.as_usize() });
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
static mut MATCH_PATH: bool = false;
static mut IGNORE_WHITESPACE: bool = false;
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

    let user_input: String = unsafe {
        let new_ui = if IGNORE_CASE {
            USER_INPUT.clone().to_lowercase()
        }
        else {
            USER_INPUT.clone()
        };

        if new_ui.starts_with(":f") || new_ui.starts_with(":l") || new_ui.starts_with(":d") {
            new_ui.chars().skip(2).collect::<String>()
        }
        else {
            new_ui
        }
    };

    let mode = if unsafe { &USER_INPUT }.starts_with(":f") {
        FileMode::File
    }
    else if unsafe { &USER_INPUT }.starts_with(":l") {
        FileMode::Link
    }
    else if unsafe { &USER_INPUT }.starts_with(":d") {
        FileMode::Dir
    }
    else {
        FileMode::Any
    };

    for (i, real_path) in paths.iter().enumerate() {

        if let Some(dat) = datas.get(i) {
            if mode != FileMode::Any && FileMode::from_usize(dat.file_type) != mode {
                continue;
            }
        }
        else {
            continue;
        }

        let path = if unsafe { IGNORE_CASE } {
            real_path.to_string().to_lowercase()
        }
        else {
            real_path.to_string()
        };

        let match_path = if unsafe { MATCH_PATH } {
            &path
        }
        else {
            let parts = &path.split("/").collect::<Vec<_>>();
            if parts.is_empty() {
                continue;
            }
            *parts.last().unwrap()
        };

        if unsafe { SUFFIX_FILTER } && user_input.ends_with('$') {
            let real_user_input = &user_input.chars().take(user_input.len() - 1).collect::<String>();
            if match_path.ends_with(real_user_input) {
                match_datas.push(datas.get(i).unwrap().clone());
                matches.push(real_path.to_string());
            }
            continue;
        }

        if unsafe { CONTAINS_FILTER } && user_input.ends_with('?') {
            let real_user_input = &user_input.chars().take(user_input.len() - 1).collect::<String>();
            if match_path.contains(real_user_input) {
                match_datas.push(datas.get(i).unwrap().clone());
                matches.push(real_path.to_string());
            }
            continue;
        }

        let user_input_len = user_input.len();

        if user_input_len > match_path.len() {
            continue;
        }

        let (is_match, score) = fzf(match_path, &user_input);

        if !is_match {
            continue;
        }

        matches.push(real_path.to_string());
        let mut data = datas.get(i).unwrap().clone();
        data.score = score;
        match_datas.push(data);
    }

    match_datas.sort_by(|a, b| {
        b.score.cmp(&a.score)
    });
}


pub fn fzf(path: &str, user_input: &str) -> (bool, usize) {

    let input = user_input;
    let mut input_idx = 0usize;
    let mut seq_len = 0usize;
    let mut score = 1usize;

    if input.len() == 0 || input.trim() == "" {
        return (false, 1usize);
    }

    let input = input.chars()
        .map(|c| c as u8)
        .collect::<Vec<_>>();

    for c in path.chars() {
        if input_idx >= input.len() {
            break;
        }
        
        if c == input[input_idx] as char {
            input_idx += 1;

            while unsafe { IGNORE_WHITESPACE } && input_idx < input.len() && input[input_idx].is_ascii_whitespace() {
                input_idx += 1;
            }

            seq_len += 1;
            score *= seq_len.max(2);
        }
        else {
            seq_len = 0;
        }
    }

    return (input_idx == input.len(), score);
}

#[test]
pub fn test_fzf() {
    let ui = "main.rs";
    let path = "C:/.dev/mc-modding/YarrakObama's MC-EasyMode/build/classes/java/main/net/yarrak/Main.class";

    set_ignore_whitespace(1);
    let (ok, score) = fzf(path, ui);

    if ok {
        println!("Input '{}' matches '{}' with a score of {}", ui, path, score);
    }
    else {
        println!("Input '{}' doesn't match '{}'", ui, path);
    }
}

