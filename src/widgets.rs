use cairo::{Context, ImageSurface, Result};
use rustix::fs::Dir;
use std::cell::{Cell, RefCell};
use std::f64::consts::PI;

// --- Core Traits and Utilities ---

#[derive(Clone, Copy)]
pub struct DirtyState {
    needs_layout: bool,
    needs_paint: bool,
}

impl DirtyState {
    pub fn clean() -> Self {
        Self {
            needs_layout: false,
            needs_paint: false,
        }
    }
    pub fn all_dirty() -> Self {
        Self {
            needs_layout: true,
            needs_paint: true,
        }
    }
}

pub trait Node {
    fn measure(&mut self, available_width: i32, available_height: i32) -> (i32, i32);
    fn layout(&mut self, x: i32, y: i32, width: i32, height: i32);
    fn mut_child(&mut self) -> &mut [Box<dyn Node>];
    fn dirty(&self) -> DirtyState;
    fn mut_dirty(&mut self) -> &mut DirtyState;
    fn draw(&self, cr: &Context) -> Result<()>;
}

#[derive(Clone, Copy)]
pub enum TextAlignH {
    Left,
    Right,
    Center,
}

#[derive(Clone, Copy)]
pub enum TextAlignV {
    Top,
    Bottom,
    Center,
}

pub struct RGBA {
    pub r: i32,
    pub g: i32,
    pub b: i32,
    pub a: f64,
}

impl RGBA {
    pub fn to_cairo(&self) -> (f64, f64, f64, f64) {
        (
            self.r as f64 / 255.0,
            self.g as f64 / 255.0,
            self.b as f64 / 255.0,
            self.a,
        )
    }
}

impl PartialEq for RGBA {
    fn eq(&self, other: &Self) -> bool {
        self.r == other.r && self.g == other.g && self.b == other.b
    }
}

// --- Rectangle Widget ---

pub struct Rectangle {
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
    pub radius: i32,
    pub margin: Option<(i32, i32, i32, i32)>,
    pub padding: Option<(i32, i32, i32, i32)>,
    pub color: RGBA,
    pub border_width: Option<i32>,
    pub border_color: Option<RGBA>,
    pub children: Vec<Box<dyn Node>>,
    dirty: DirtyState,
}

impl Rectangle {
    pub fn new(width: i32, height: i32, color: RGBA) -> Self {
        Self {
            x: 0,
            y: 0,
            width,
            height,
            radius: 0,
            margin: None,
            padding: None,
            color,
            border_width: None,
            border_color: None,
            dirty: DirtyState::all_dirty(),
            children: Vec::new(),
        }
    }

    pub fn position(mut self, x: i32, y: i32) -> Self {
        self.x = x;
        self.y = y;
        self
    }

    pub fn radius(mut self, radius: i32) -> Self {
        self.radius = radius;
        self
    }

    pub fn margin(mut self, top: i32, right: i32, bottom: i32, left: i32) -> Self {
        self.margin = Some((top, right, bottom, left));
        self
    }

    pub fn padding(mut self, top: i32, right: i32, bottom: i32, left: i32) -> Self {
        self.padding = Some((top, right, bottom, left));
        self
    }

    pub fn border(mut self, width: i32, color: RGBA) -> Self {
        self.border_width = Some(width);
        self.border_color = Some(color);
        self
    }

    pub fn child(mut self, child: Box<dyn Node>) -> Self {
        self.children.push(child);
        self
    }

    pub fn children(mut self, mut children: Vec<Box<dyn Node>>) -> Self {
        self.children.append(&mut children);
        self
    }
}

impl Node for Rectangle {
    fn measure(&mut self, _available_width: i32, _available_height: i32) -> (i32, i32) {
        for children in &mut self.children {
            children.measure(self.width, self.height);
        }
        (self.width, self.height)
    }

    fn layout(&mut self, x: i32, y: i32, width: i32, height: i32) {
        let (pt, pr, pb, pl) = self.padding.unwrap_or((0, 0, 0, 0));
        let (mt, mr, mb, ml) = self.margin.unwrap_or((0, 0, 0, 0));

        self.x = x + ml;
        self.y = y + mt;
        self.width = (width - mr - ml).max(0);
        self.height = (height - mb - mt).max(0);

        let inner_x = x + pl;
        let inner_y = y + pt;
        let inner_w = (width - pr - pl).max(0);
        let inner_h = (height - pb - pt).max(0);

        for child in &mut self.children {
            let (cw, ch) = child.measure(inner_w, inner_h);
            child.layout(inner_x, inner_y, cw, ch);
        }
    }

    fn draw(&self, cr: &Context) -> Result<()> {
        let fx = self.x as f64;
        let fy = self.y as f64;
        let fw = self.width as f64;
        let fh = self.height as f64;

        let max_radius = fw.min(fh) / 2.0;
        let fr = (self.radius as f64).min(max_radius);

        cr.save()?;
        let (r, g, b, a) = self.color.to_cairo();
        cr.set_source_rgba(r, g, b, a);

        cr.arc_negative(fx + fr, fy + fr, fr, -0.5 * PI, 1.0 * PI);
        cr.line_to(fx, fy - fr + fh);
        cr.arc_negative(fx + fr, fy + fh - fr, fr, 1.0 * PI, 0.5 * PI);
        cr.line_to(fx - fr + fw, fy + fh);
        cr.arc_negative(fx + fw - fr, fy + fh - fr, fr, 0.5 * PI, 0.0 * PI);
        cr.line_to(fx + fw, fy + fr);
        cr.arc_negative(fx + fw - fr, fy + fr, fr, 0.0 * PI, -0.5 * PI);
        cr.close_path();

        if let (Some(b_color), Some(b_width)) = (&self.border_color, self.border_width) {
            cr.fill_preserve()?;
            let (br, bg, bb, ba) = b_color.to_cairo();
            cr.set_source_rgba(br, bg, bb, ba);
            cr.set_line_width(b_width as f64);
            cr.stroke()?;
        } else {
            cr.fill()?;
        }

        for children in &self.children {
            children.draw(cr)?;
        }

        cr.restore()?;
        Ok(())
    }

    fn mut_child(&mut self) -> &mut [Box<dyn Node>] {
        &mut self.children
    }

    fn dirty(&self) -> DirtyState {
        self.dirty
    }

    fn mut_dirty(&mut self) -> &mut DirtyState {
        {
            &mut self.dirty
        }
    }
}

// --- Label Widget ---

pub struct FontSettings {
    pub size: i32,
    pub family: String,
    pub style: cairo::FontSlant,
    pub weight: cairo::FontWeight,
}

pub struct Label {
    pub string: String,
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
    pub margin: Option<(i32, i32, i32, i32)>,
    pub padding: Option<(i32, i32, i32, i32)>,
    pub color: RGBA,
    pub font: Option<FontSettings>,
    pub align_h: Option<TextAlignH>,
    pub align_v: Option<TextAlignV>,
    dirty: DirtyState,
    auto_width: bool,
    auto_height: bool,
}

impl Label {
    pub fn new(string: String, width: i32, height: i32, color: RGBA) -> Self {
        Self {
            string,
            x: 0,
            y: 0,
            width,
            height,
            margin: None,
            padding: None,
            color,
            font: None,
            align_h: None,
            align_v: None,
            dirty: DirtyState::all_dirty(),
            auto_height: height == 0,
            auto_width: width == 0,
        }
    }

    pub fn position(mut self, x: i32, y: i32) -> Self {
        self.x = x;
        self.y = y;
        self
    }

    pub fn margin(mut self, top: i32, right: i32, bottom: i32, left: i32) -> Self {
        self.margin = Some((top, right, bottom, left));
        self
    }

    pub fn padding(mut self, top: i32, right: i32, bottom: i32, left: i32) -> Self {
        self.padding = Some((top, right, bottom, left));
        self
    }

    pub fn align_h(mut self, alignment: TextAlignH) -> Self {
        self.align_h = Some(alignment);
        self
    }

    pub fn align_v(mut self, alignment: TextAlignV) -> Self {
        self.align_v = Some(alignment);
        self
    }

    pub fn font(
        mut self,
        size: i32,
        family: String,
        style: cairo::FontSlant,
        weight: cairo::FontWeight,
    ) -> Self {
        self.font = Some(FontSettings {
            size,
            family,
            style,
            weight,
        });
        self
    }

    fn apply_font(&self, cr: &Context) {
        if let Some(ref f) = self.font {
            cr.select_font_face(&f.family, f.style, f.weight);
            cr.set_font_size(f.size as f64);
        } else {
            cr.select_font_face(
                "sans-serif",
                cairo::FontSlant::Normal,
                cairo::FontWeight::Normal,
            );

            let basis = if self.auto_height {
                16
            } else {
                self.height.max(1)
            };
            cr.set_font_size((basis * 6 / 10).max(1) as f64);
        }
    }

    fn natural_size(&self) -> Result<(i32, i32)> {
        let cr_surface = ImageSurface::create(cairo::Format::ARgb32, 1, 1)?;
        let cr = Context::new(cr_surface)?;
        self.apply_font(&cr);
        let extends = cr.text_extents(&self.string)?;
        let (pt, pr, pb, pl) = self.padding.unwrap_or((0, 0, 0, 0));
        Ok((
            extends.width().ceil() as i32 + (pr + pl),
            extends.height().ceil() as i32 + (pt + pb),
        ))
    }
}

impl Node for Label {
    fn measure(&mut self, _available_width: i32, _available_height: i32) -> (i32, i32) {
        if self.auto_height || self.auto_width {
            if let Ok((n_width, n_height)) = self.natural_size() {
                if self.auto_width {
                    self.width = n_width
                }
                if self.auto_height {
                    self.height = n_height
                }
            }
        }
        (self.width, self.height)
    }

    fn layout(&mut self, x: i32, y: i32, width: i32, height: i32) {
        let (mt, mr, mb, ml) = self.margin.unwrap_or((0, 0, 0, 0));
        self.x = x + ml;
        self.y = y + mt;
        if !self.auto_width {
            self.width = (width - ml - mr).max(0);
        }
        if !self.auto_height {
            self.height = (height - mt - mb).max(0);
        }
    }

    fn draw(&self, cr: &Context) -> Result<()> {
        self.apply_font(cr);

        let mut font_options = cairo::FontOptions::new()?;
        font_options.set_antialias(cairo::Antialias::Subpixel);
        font_options.set_hint_style(cairo::HintStyle::Full);
        font_options.set_hint_metrics(cairo::HintMetrics::On);
        cr.set_font_options(&font_options);

        let extents = cr.text_extents(&self.string)?;
        let (pt, pr, pb, pl) = self.padding.unwrap_or((0, 0, 0, 0));

        let content_x = self.x as f64 + pl as f64;
        let content_y = self.y as f64 + pt as f64;
        let content_fw = (self.width - pl - pr) as f64;
        let content_fh = (self.height - pt - pb) as f64;

        if content_fw <= 0.0 || content_fh <= 0.0 {
            return Ok(());
        }

        cr.save()?;
        let (r, g, b, a) = self.color.to_cairo();
        cr.set_source_rgba(r, g, b, a);

        let target_x = match self.align_h.unwrap_or(TextAlignH::Center) {
            TextAlignH::Left => content_x - extents.x_bearing(),
            TextAlignH::Center => {
                content_x + (content_fw - extents.width()) / 2.0 - extents.x_bearing()
            }
            TextAlignH::Right => content_x + content_fw - extents.width() - extents.x_bearing(),
        };
        let target_y = match self.align_v.unwrap_or(TextAlignV::Center) {
            TextAlignV::Top => content_y - extents.y_bearing(),
            TextAlignV::Center => {
                content_y + (content_fh - extents.height()) / 2.0 - extents.y_bearing()
            }
            TextAlignV::Bottom => content_y + content_fh - (extents.height() + extents.y_bearing()),
        };

        cr.move_to(target_x, target_y);
        cr.show_text(&self.string)?;
        cr.restore()?;
        Ok(())
    }

    fn mut_child(&mut self) -> &mut [Box<dyn Node>] {
        &mut []
    }

    fn dirty(&self) -> DirtyState {
        self.dirty
    }

    fn mut_dirty(&mut self) -> &mut DirtyState {
        &mut self.dirty
    }
}
