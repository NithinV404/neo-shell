use khronos_egl as egl;
use wayland_client::protocol::wl_display::WlDisplay;
use wayland_client::protocol::wl_surface::WlSurface;
use wayland_client::Proxy;
use wayland_egl::WlEglSurface;

type Egl = egl::Instance<egl::Dynamic<libloading::Library, egl::EGL1_5>>;

pub struct GlContext {
    egl: Egl,
    display: egl::Display,
    surface: egl::Surface,
    context: egl::Context,
    _wl_egl_surface: WlEglSurface,
    pub gl: glow::Context,
    pub width: i32,
    pub height: i32,
}

impl GlContext {
    pub fn new(
        wl_display_ptr: *mut std::ffi::c_void,
        wl_surface: &WlSurface,
        width: i32,
        height: i32,
    ) -> Result<Self, Box<dyn std::error::Error>> {
        let lib = unsafe { libloading::Library::new("libEGL.so.1")? };

        let egl = unsafe { egl::DynamicInstance::<egl::EGL1_5>::load_required_from(lib)? };

        let display = unsafe {
            egl.get_display(wl_display_ptr)
                .ok_or("Failed to eglGetDisplay")?
        };

        egl.initialize(display)?;

        let config_attrib = [
            egl::SURFACE_TYPE,
            egl::WINDOW_BIT,
            egl::RENDERABLE_TYPE,
            egl::OPENGL_ES2_BIT,
            egl::RED_SIZE,
            8,
            egl::GREEN_SIZE,
            8,
            egl::BLUE_SIZE,
            8,
            egl::ALPHA_SIZE,
            8,
            egl::NONE,
        ];

        let count = egl.matching_config_count(display, &config_attrib)?;

        // Get the matching configurations.
        let mut configs = Vec::with_capacity(count);

        egl.choose_config(display, &config_attrib, &mut configs)?;

        let config = configs.first().ok_or("no matching config found")?;

        let wl_elg_surface = WlEglSurface::new(wl_surface.id(), width, height)?;

        let surface = unsafe {
            egl.create_window_surface(
                display,
                *config,
                wl_elg_surface.ptr() as egl::NativeWindowType,
                None,
            )?
        };

        egl.bind_api(egl::OPENGL_ES_API)?;

        let context_attrib = [egl::CONTEXT_CLIENT_VERSION, 2, egl::NONE];
        let context = egl.create_context(display, *config, None, &context_attrib)?;

        egl.make_current(display, Some(surface), Some(surface), Some(context))?;

        let gl = unsafe {
            glow::Context::from_loader_function(|name| {
                egl.get_proc_address(name)
                    .map(|f| f as *const _)
                    .unwrap_or(std::ptr::null())
            })
        };

        Ok(Self {
            egl,
            display,
            surface,
            context,
            _wl_egl_surface: wl_elg_surface,
            gl,
            width,
            height,
        })
    }

    pub fn resize(&mut self, width: i32, height: i32) {
        self._wl_egl_surface.resize(width, height, 0, 0);
        self.width = width;
        self.height = height;
    }

    pub fn make_current(&self) -> Result<(), Box<dyn std::error::Error>> {
        self.egl.make_current(
            self.display,
            Some(self.surface),
            Some(self.surface),
            Some(self.context),
        )?;
        Ok(())
    }

    pub fn swap_buffers(&self) -> Result<(), Box<dyn std::error::Error>> {
        self.egl.swap_buffers(self.display, self.surface)?;
        Ok(())
    }
}
