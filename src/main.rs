use cairo::{Context, ImageSurface};
use memmap2::MmapMut;
use rustix::fs::{memfd_create, MemfdFlags};
use std::fs::File;
use std::os::fd::AsFd;
use wayland_client::{
    delegate_noop,
    globals::{registry_queue_init, GlobalListContents},
    protocol::{
        wl_buffer::{self, WlBuffer},
        wl_compositor::WlCompositor,
        wl_registry::WlRegistry,
        wl_shm::WlShm,
        wl_shm_pool::WlShmPool,
        wl_surface::WlSurface,
    },
    Connection, Dispatch, QueueHandle,
};
use wayland_protocols_wlr::layer_shell::v1::client::{
    zwlr_layer_shell_v1::{self, ZwlrLayerShellV1},
    zwlr_layer_surface_v1::{self, ZwlrLayerSurfaceV1},
};

mod widgets;
use widgets::Rectangle;

use crate::widgets::{Widget, RGBA};

struct RenderPool {
    width: u32,
    height: u32,
    _file: File,
    _mmap: MmapMut,
    cairo_surface: ImageSurface,
    _pool: WlShmPool,
    buffer: WlBuffer,
}

struct Neoshell {
    compositor: Option<WlCompositor>,
    shm: Option<WlShm>,
    layershell: Option<ZwlrLayerShellV1>,
    surface: Option<WlSurface>,
    layersurface: Option<ZwlrLayerSurfaceV1>,
    configured: bool,
    running: bool,
    pool: Option<RenderPool>,
    buffer_released: bool,
}

impl Neoshell {
    fn new() -> Self {
        Neoshell {
            compositor: None,
            shm: None,
            layershell: None,
            surface: None,
            layersurface: None,
            configured: false,
            running: true,
            pool: None,
            buffer_released: true,
        }
    }

    fn setup_pool(
        &mut self,
        qh: &QueueHandle<Self>,
        width: &u32,
        height: &u32,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let shm = self.shm.as_ref().ok_or("Failed to create shm")?;
        let stride = width * 4;
        let size: u64 = (stride * height) as u64;

        let fd = memfd_create("neoshell", MemfdFlags::CLOEXEC)?;
        let file = File::from(fd);
        file.set_len(size)?;
        let mut mmap = unsafe { MmapMut::map_mut(&file) }?;

        let pool = shm.create_pool(file.as_fd(), size as i32, qh, ());

        let buffer = pool.create_buffer(
            0,
            *width as i32,
            *height as i32,
            stride as i32,
            wayland_client::protocol::wl_shm::Format::Argb8888,
            qh,
            (),
        );

        // SAFETY: the slice borrows the same memory as `mmap`. We don't touch
        // `mmap` directly again after this; all writes go through cairo.
        let slice = unsafe { std::slice::from_raw_parts_mut(mmap.as_mut_ptr(), size as usize) };
        let cairo_surface = ImageSurface::create_for_data(
            slice,
            cairo::Format::ARgb32,
            *width as i32,
            *height as i32,
            stride as i32,
        )?;

        self.pool = Some(RenderPool {
            width: *width,
            height: *height,
            _file: file,
            _mmap: mmap,
            _pool: pool,
            buffer,
            cairo_surface,
        });
        Ok(())
    }

    fn draw(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        // If buffer isnt released skip the frame
        if !self.buffer_released {
            return Result::<(), Box<dyn std::error::Error>>::Ok(());
        }

        let pool = self.pool.as_mut().ok_or("Pool not initialized")?;
        let surface = self.surface.as_ref().ok_or("Surface not initialized")?;
        let cr = Context::new(&pool.cairo_surface)?;
        cr.set_source_rgba(0.1, 0.1, 0.1, 0.0);
        cr.paint()?;

        let component = Rectangle::new(
            0.0,
            0.0,
            pool.width as f64,
            (pool.height - 4) as f64,
            8.0,
            RGBA {
                r: 1.0,
                g: 1.0,
                b: 1.0,
                a: 0.9,
            },
        );

        let _ = component.draw(&cr);

        pool.cairo_surface.flush();

        // Locking buffer before commiting
        self.buffer_released = false;

        surface.attach(Some(&pool.buffer), 0, 0);
        surface.damage(
            0,
            0,
            self.pool.as_ref().unwrap().width as i32,
            self.pool.as_ref().unwrap().height as i32,
        );
        surface.commit();

        Ok(())
    }
}

// --- Dispatch impls -------------------------------------------------------

// Globals we never need events from: no-op dispatch.
delegate_noop!(Neoshell: ignore WlCompositor);
delegate_noop!(Neoshell: ignore WlShm);
delegate_noop!(Neoshell: ignore WlShmPool);
delegate_noop!(Neoshell: ignore WlSurface);
delegate_noop!(Neoshell: ignore ZwlrLayerShellV1);

impl Dispatch<WlBuffer, ()> for Neoshell {
    fn event(
        state: &mut Self,
        _: &WlBuffer,
        event: <WlBuffer as wayland_client::Proxy>::Event,
        _: &(),
        _: &Connection,
        _: &QueueHandle<Self>,
    ) {
        match event {
            wl_buffer::Event::Release => state.buffer_released = true,
            _ => (),
        }
    }
}

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
        qh: &QueueHandle<Self>,
    ) {
        match event {
            zwlr_layer_surface_v1::Event::Configure {
                serial,
                width,
                height,
                ..
            } => {
                proxy.ack_configure(serial);
                state.configured = true;
                if state.pool.is_none() {
                    state
                        .setup_pool(qh, &width, &height)
                        .expect("failed to set up shm pool");
                }
                state.draw().expect("failed to draw");
            }
            zwlr_layer_surface_v1::Event::Closed => {
                state.running = false;
            }
            _ => {}
        }
    }
}

// --- main ------------------------------------------------------------------

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let conn = Connection::connect_to_env()?;
    let (globals, mut event_queue) = registry_queue_init::<Neoshell>(&conn)?;
    let qh = event_queue.handle();

    let mut state = Neoshell::new();

    state.compositor = Some(globals.bind::<WlCompositor, _, _>(&qh, 1..=5, ())?);
    state.shm = Some(globals.bind::<WlShm, _, _>(&qh, 1..=1, ())?);
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
    state.layersurface = Some(layer_surface);

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
