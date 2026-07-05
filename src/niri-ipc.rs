use serde::Deserialize;
use std::{io::Write, os::unix::net::UnixStream};

#[derive(Deserialize, Debug)]
enum NiriEvent {
    Ok(String),
    WorkspaceActivated {
        id: u64,
    },
    WorkspaceActiveWindowChanged {
        workspace_id: u64,
        active_window_id: u64,
    },
    WindowsChanged {
        windows: Vec<Window>,
    },
    WorkspacesChanged {
        workspaces: Vec<Workspace>,
    },
    WindowOpenedOrChanged {
        window: Window,
    },
    WindowClosed {
        id: u64,
    },
    WindowFocusChanged {
        id: Option<u64>,
    },

    KeyboardLayoutsChanged {
        keyboard_layouts: serde_json::Value,
    },

    OverviewOpenedOrClosed {
        is_open: bool,
    },

    ConfigLoaded {
        failed: bool,
    },

    CastsChanged {
        casts: Vec<serde_json::Value>,
    },

    WindowFocusTimestampChanged {
        id: u64,
        focus_timestamp: FocusTimestamp,
    },

    WindowLayoutsChanged {
        changes: Vec<WindowLayoutsChanged>,
    },

    #[serde(other)]
    UnknownEvent,
}

#[allow(dead_code)]
#[derive(Deserialize, Debug)]
struct Workspace {
    id: Option<u64>,
    idx: Option<u64>,
    name: Option<String>,
    output: Option<String>,
    is_urgent: Option<bool>,
    is_focused: Option<bool>,
    active_window_id: Option<u64>,
}

#[allow(dead_code)]
#[derive(Deserialize, Debug)]
struct Window {
    id: Option<u64>,
    title: String,
    app_id: String,
    pid: Option<u32>,
    workspace_id: Option<u64>,
    is_focused: bool,
    is_floating: bool,
    is_urgent: bool,
    layout: WindowLayout,
    focus_timestamp: FocusTimestamp,
}

#[allow(dead_code)]
#[derive(Deserialize, Debug)]
struct WindowLayoutsChanged {
    id: u64,
    window_layout: WindowLayout,
}

#[allow(dead_code)]
#[derive(Deserialize, Debug)]
struct WindowLayout {
    pos_in_scrolling_layout: (u64, u64),
    tile_size: (f64, f64),
    window_size: (u32, u32),
    tile_pos_in_workspace_view: Option<(i32, i32)>,
    window_offset_in_tile: (f64, f64),
}

#[allow(dead_code)]
#[derive(Deserialize, Debug)]
struct FocusTimestamp {
    secs: u64,
    nanos: u128,
}

#[allow(dead_code)]
enum NiriRequest {
    EventStream,
    ConnectEvents,
    GetStatus,
}

impl NiriRequest {
    fn as_bytes(&self) -> &'static [u8] {
        match self {
            NiriRequest::ConnectEvents => r#""ConnectEvents""#.as_bytes(),
            NiriRequest::EventStream => r#""EventStream""#.as_bytes(),
            NiriRequest::GetStatus => r#""GetStatus""#.as_bytes(),
        }
    }
}

// To format errors
fn main() {
    if let Err(e) = run() {
        eprintln!("\x1b[1;31m[niri-cli] ERROR:\x1b[0m {e}");
        let mut source = e.source();
        while let Some(cause) = source {
            eprintln!("\x1b[1;33m└── Caused by:\x1b[0m {}", cause);
            source = cause.source();
        }
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let niri_path = std::env::var("NIRI_SOCKET")?;
    let mut socket_conn = UnixStream::connect(niri_path)?;
    socket_conn.write_all(NiriRequest::EventStream.as_bytes())?;
    socket_conn.write_all(b"\n")?;
    socket_conn.flush()?;
    let deserializer = serde_json::Deserializer::from_reader(&socket_conn).into_iter::<NiriEvent>();
    for event in deserializer {
        match event? {
            NiriEvent::Ok(string) => {
                eprintln!("[niri-cli] Info: Stream initialized {string}")
            }
            NiriEvent::WindowClosed { id } => {
                eprintln!("[niri-cli] Info: {id:?}")
            }
            NiriEvent::WindowOpenedOrChanged { window } => {
                eprintln!("[niri-cli] Info: {window:?}")
            }
            NiriEvent::WindowFocusChanged { id } => {
                eprintln!("[niri-cli] Info: Window Focus Changed {id:?}")
            }
            NiriEvent::WorkspaceActivated { id } => {
                eprintln!("[niri-cli] Info: Workspace activated {id:?}")
            }
            NiriEvent::WindowsChanged { windows } => {
                eprintln!("[niri-cli] Info: Windows Changed: {windows:#?} ")
            }
            NiriEvent::WorkspaceActiveWindowChanged {
                active_window_id,
                workspace_id,
            } => {
                eprintln!("[niri-cli] Info: Workspace Changed active_window_id: {active_window_id:?}, workspace_id:{workspace_id:?}")
            }
            NiriEvent::WorkspacesChanged { workspaces } => {
                eprintln!("[niri-cli] Info: Workspaces changed: {workspaces:#?}")
            }
            NiriEvent::KeyboardLayoutsChanged { keyboard_layouts } => {
                eprintln!("[niri-cli] Info: Keyboard Layout: {keyboard_layouts:?}")
            }
            NiriEvent::CastsChanged { casts } => {
                eprintln!("[niri-cli] Info: Casts {casts:?}")
            }
            NiriEvent::ConfigLoaded { failed } => {
                eprintln!("[niri-cli] Info: Config Loaded {failed:?}");
            }
            NiriEvent::OverviewOpenedOrClosed { is_open } => {
                eprintln!("[niri-cli] Info: Window overview opened {is_open:?}")
            }
            NiriEvent::WindowFocusTimestampChanged {
                id,
                focus_timestamp,
            } => {
                eprintln!("[niri-cli] Info: Window focus timestampChanged id:{id:?}, focus_timestamp:{focus_timestamp:?}")
            }
            NiriEvent::WindowLayoutsChanged { changes } => {
                eprintln!("[niri-cli] Info: WindowLayout {changes:?}")
            }
            NiriEvent::UnknownEvent => {
                eprintln!("[niri-cli] Info: Event Unknown")
            }
        }
    }

    Ok(())
}
