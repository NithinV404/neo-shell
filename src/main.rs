use wayland_client::{
    delegate_noop,
    globals::{registry_queue_init, GlobalListContents},
    protocol::{wl_compositor::WlCompositor, wl_registry::WlRegistry, wl_surface::WlSurface},
    Connection, Dispatch, QueueHandle,
};
use wayland_protocols_wlr::layer_shell::v1::client::{
    zwlr_layer_shell_v1::{self, ZwlrLayerShellV1},
    zwlr_layer_surface_v1::{self, ZwlrLayerSurfaceV1},
};

use glow::HasContext;

mod glContext;
use glContext::GlContext;

struct Neoshell {
    compositor: Option<WlCompositor>,
    layershell: Option<ZwlrLayerShellV1>,
    surface: Option<WlSurface>,
    running: bool,
    gl_ctx: Option<glContext::GlContext>,
    conn: Connection,
}

impl Neoshell {
    fn draw(&mut self) {
        let Some(ctx) = self.gl_ctx.as_ref() else {
            return;
        };
        unsafe {
            ctx.gl.viewport(0, 0, ctx.width, ctx.height);
            ctx.gl.clear_color(0.12, 0.12, 0.18, 1.0);
            ctx.gl.clear(glow::COLOR_BUFFER_BIT);
        }
        ctx.swap_buffers().expect("swap_buffers failed");
    }
}

// --- Dispatch impls -------------------------------------------------------

// Globals we never need events from: no-op dispatch.
delegate_noop!(Neoshell: ignore WlCompositor);
delegate_noop!(Neoshell: ignore WlSurface);
delegate_noop!(Neoshell: ignore ZwlrLayerShellV1);

impl Dispatch<WlRegistry, GlobalListContents> for Neoshell {
    fn event(
        _state: &mut Self,
        _proxy: &WlRegistry,
        _event: wayland_client::protocol::wl_registry::Event,
        _data: &GlobalListContents,
        _conn: &Connection,
        _qh: &QueueHandle<Self>,
    ) {
        // Using registry_queue_init below, so dynamic add/remove isn't handled here.
    }
}

impl Dispatch<ZwlrLayerSurfaceV1, ()> for Neoshell {
    fn event(
        state: &mut Self,
        proxy: &ZwlrLayerSurfaceV1,
        event: zwlr_layer_surface_v1::Event,
        _data: &(),
        _conn: &Connection,
        _: &QueueHandle<Self>,
    ) {
        match event {
            zwlr_layer_surface_v1::Event::Configure {
                serial,
                width,
                height,
                ..
            } => {
                proxy.ack_configure(serial);
                let (w, h) = (width.max(1) as i32, height.max(1) as i32);

                if let Some(ctx) = state.gl_ctx.as_mut() {
                    ctx.resize(w, h);
                } else {
                    let display_ptr = state.conn.backend().display_ptr() as *mut std::ffi::c_void;
                    let wl_surface = state.surface.as_ref().unwrap();
                    match glContext::GlContext::new(display_ptr, wl_surface, w, h) {
                        Ok(ctx) => state.gl_ctx = Some(ctx),
                        Err(e) => {
                            eprintln!("failed to create GL context: {e}");
                            state.running = false;
                            return;
                        }
                    }
                }
                state.draw();
            }
            zwlr_layer_surface_v1::Event::Closed => state.running = false,
            _ => {}
        }
    }
}

// --- main ------------------------------------------------------------------

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let conn = Connection::connect_to_env()?;
    let (globals, mut event_queue) = registry_queue_init::<Neoshell>(&conn)?;
    let qh = event_queue.handle();

    let mut state = Neoshell {
        compositor: None,
        layershell: None,
        surface: None,
        running: true,
        gl_ctx: None,
        conn: conn.clone(),
    };

    state.compositor = Some(globals.bind::<WlCompositor, _, _>(&qh, 1..=5, ())?);
    state.layershell = Some(globals.bind::<ZwlrLayerShellV1, _, _>(&qh, 1..=4, ())?);

    let surface = state.compositor.as_ref().unwrap().create_surface(&qh, ());

    let layer_surface = state.layershell.as_ref().unwrap().get_layer_surface(
        &surface,
        None, // let the compositor pick the output
        zwlr_layer_shell_v1::Layer::Top,
        "neoshell".into(),
        &qh,
        (),
    );

    layer_surface.set_size(0, 30);
    layer_surface.set_anchor(
        zwlr_layer_surface_v1::Anchor::Top
            | zwlr_layer_surface_v1::Anchor::Left
            | zwlr_layer_surface_v1::Anchor::Right,
    );

    state.surface = Some(surface.clone());
    surface.commit();

    // Initial roundtrip so the server sends globals/events we just requested.
    event_queue.roundtrip(&mut state)?;

    while state.running {
        event_queue.blocking_dispatch(&mut state)?;
    }

    Ok(())
}

fn main() {
    if let Err(err) = run() {
        eprintln!("\x1b[1;31mERROR:\x1b[0m {err}");
        let mut cause = err.source();
        while let Some(source) = cause {
            eprintln!("\x1b[1;33m└── Caused by:\x1b[0m {}", source);
            cause = source.source();
        }
        std::process::exit(1)
    }
}
