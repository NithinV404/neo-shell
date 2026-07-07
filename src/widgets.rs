use cairo::{Context, Result};
use std::f64::consts::PI;

pub trait Widget {
    fn draw(&self, cr: &Context) -> Result<()>;
    fn get_size(&self) -> (i32, i32);
    fn set_position(&mut self, x: i32, y: i32);
}

// RGBA Struct

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

// --------------- Rectangle Widget ---------------

pub struct Rectangle {
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
    pub radius: i32,
    pub padding: Option<(i32, i32, i32, i32)>,
    pub color: RGBA,
    pub border_width: Option<i32>,
    pub border_color: Option<RGBA>,
}

impl Rectangle {
    pub fn new(
        x: i32,
        y: i32,
        width: i32,
        height: i32,
        radius: i32,
        padding: Option<(i32, i32, i32, i32)>,
        color: RGBA,
        border_width: Option<i32>,
        border_color: Option<RGBA>,
    ) -> Self {
        Self {
            x,
            y,
            width,
            height,
            radius,
            padding,
            color,
            border_color,
            border_width,
        }
    }
}

impl Widget for Rectangle {
    fn draw(&self, cr: &Context) -> Result<()> {
        let (pl, pt, pr, pb) = self.padding.unwrap_or((0, 0, 0, 0));

        let padded_x = self.x + pl;
        let padded_y = self.y + pt;
        let padded_width = self.width - pl - pr;
        let padded_height = self.height - pt - pb;

        if padded_width <= 0 || padded_height <= 0 {
            return Ok(());
        }

        let fx = padded_x as f64;
        let fy = padded_y as f64;
        let fw = padded_width as f64;
        let fh = padded_height as f64;
        let fr = self.radius as f64;

        cr.save()?;
        cr.set_source_rgba(
            self.color.to_cairo().0,
            self.color.to_cairo().1,
            self.color.to_cairo().2,
            self.color.to_cairo().3,
        );

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
            cr.set_source_rgba(
                b_color.to_cairo().0,
                b_color.to_cairo().1,
                b_color.to_cairo().2,
                b_color.to_cairo().3,
            );
            cr.set_line_width(b_width as f64);
            cr.stroke()?;
        } else {
            cr.fill()?;
        }

        cr.restore()?;
        Ok(())
    }

    fn get_size(&self) -> (i32, i32) {
        (self.width, self.height)
    }

    fn set_position(&mut self, x: i32, y: i32) {
        self.x = x;
        self.y = y;
    }
}

// --------------- Label Widget ---------------

pub struct Label {
    pub string: String,
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
    pub padding: Option<(i32, i32, i32, i32)>,
    pub color: RGBA,
    pub font: Option<FontSettings>,
}

pub struct FontSettings {
    size: i32,
    family: String,
    style: cairo::FontSlant,
    weight: cairo::FontWeight,
}

impl Label {
    pub fn new(
        string: String,
        x: i32,
        y: i32,
        width: i32,
        height: i32,
        padding: Option<(i32, i32, i32, i32)>,
        color: RGBA,
    ) -> Self {
        Self {
            string,
            x,
            y,
            width,
            height,
            padding,
            color,
            font: None,
        }
    }

    pub fn set_font_values(
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
}

impl Widget for Label {
    fn draw(&self, cr: &Context) -> Result<()> {
        let (pl, pt, pr, pb) = self.padding.unwrap_or((0, 0, 0, 0));

        let padded_x = self.x + pl;
        let padded_y = self.y + pt;
        let padded_width = self.width - pl - pr;
        let padded_height = self.height - pt - pb;

        if padded_width <= 0 || padded_height <= 0 {
            return Ok(());
        }

        let fx = padded_x as f64;
        let fy = padded_y as f64;
        let fw = padded_width as f64;
        let fh = padded_height as f64;

        cr.save()?;
        cr.set_source_rgba(
            self.color.to_cairo().0,
            self.color.to_cairo().1,
            self.color.to_cairo().2,
            self.color.to_cairo().3,
        );

        if let Some(ref font_settings) = self.font {
            cr.select_font_face(
                &font_settings.family,
                font_settings.style,
                font_settings.weight,
            );
            cr.set_font_size(font_settings.size as f64);
        } else {
            cr.select_font_face(
                "sans-serif",
                cairo::FontSlant::Normal,
                cairo::FontWeight::Normal,
            );
            cr.set_font_size((self.height * 6 / 10) as f64);
        }

        let mut font_options = cairo::FontOptions::new()?;
        font_options.set_antialias(cairo::Antialias::Subpixel);
        font_options.set_hint_style(cairo::HintStyle::Full);
        font_options.set_hint_metrics(cairo::HintMetrics::On);
        cr.set_font_options(&font_options);

        let extents = cr.text_extents(&self.string)?;

        let target_x = (fx + (fw - extents.width()) / 2.0 - extents.x_bearing()).round();
        let target_y = (fy + (fh - extents.height()) / 2.0 - extents.y_bearing()).round();

        cr.move_to(target_x, target_y);
        cr.show_text(&self.string)?;

        cr.restore()?;
        Ok(())
    }

    fn get_size(&self) -> (i32, i32) {
        (self.width, self.height)
    }

    fn set_position(&mut self, x: i32, y: i32) {
        self.x = x;
        self.y = y;
    }
}

// --------------- Component Widget ---------------

struct Component {
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
}
