use std::{cell::RefCell, pin::Pin, sync::mpsc, thread};

use niri_ipc::{self, socket::Socket, Request};
use qmetaobject::*;

#[derive(QObject, Default)]
struct NiriProvider {
    base: qt_base_class!(trait QObject),

    // Property for window_title
    window_title: qt_property!(QString; NOTIFY title_changed),
    title_changed: qt_signal!(),

    // Property for current_active workspace list
    current_workspace: qt_property!(QString; NOTIFY current_workspace_switched),
    current_workspace_switched: qt_signal!(),

    //Property for workspaces
    workspaces: qt_property!(QStringList; NOTIFY workspaces_changed),
    workspaces_changed: qt_signal!(),
}

fn main() {
    qml_register_type::<NiriProvider>(c"Niri", 1, 0, c"NiriProvider");

    let mut qmlEngine = QmlEngine::new();
    let niri_provider = NiriProvider::default();

    let niri_provider_pointer = QPointer::from(&niri_provider);

    // Wrap in RefCell - this is required for QObjectPinned
    let niri_provider = RefCell::new(NiriProvider::default());

    // Set as object property using QObjectPinned
    // This also initializes the C++ side of the QObject
    qmlEngine.set_object_property("niri".into(), unsafe { QObjectPinned::new(&niri_provider) });

    // Now get QPointer for thread-safe callbacks
    // We borrow from RefCell after C++ object is initialized
    let niri_ptr = QPointer::from(&*niri_provider.borrow());

    // Create channel for IPC communication
    let (tx, rx) = mpsc::channel();

    //Spawned thread for listening on niri
    thread::spawn(move || {
        let mut socket = match Socket::connect() {
            Ok(s) => s,
            Err(e) => {
                dbg!("Failed to connect to Niri Socket {}", e);
                return;
            }
        };

        if let Err(e) = socket.send(Request::EventStream) {
            eprintln!("Failed to request Event Stream {}", e);
            return;
        }

        let mut read_event = socket.read_events();

        match read_event() {
            Ok(event) => {
                println!("{:?}", Request::Outputs)
            }
            Err(e) => {
                eprintln!("Failed to read event {}", e)
            }
        }
    });
    qmlEngine.exec();
}
