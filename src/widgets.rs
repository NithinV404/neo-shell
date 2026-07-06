use std::f64::consts::PI;

use cairo::{Context, Result};

pub trait Widget {
    fn draw(&self, cr: &Context) -> Result<()>;
}

pub struct RGBA {
    pub r: f64,
    pub g: f64,
    pub b: f64,
    pub a: f64,
}

pub struct Rectangle {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
    pub radius: f64,
    pub color: RGBA,
    pub border_width: Option<f64>,
    pub border_color: Option<RGBA>,
}

impl Rectangle {
    pub fn new(
        x: f64,
        y: f64,
        width: f64,
        height: f64,
        radius: f64,
        color: RGBA,
        border_width: Option<f64>,
        border_color: Option<RGBA>,
    ) -> Self {
        Self {
            x,
            y,
            width,
            height,
            radius,
            color,
            border_color,
            border_width,
        }
    }
}

impl Widget for Rectangle {
    fn draw(&self, cr: &Context) -> Result<()> {
        cr.save()?;
        cr.set_source_rgba(self.color.r, self.color.g, self.color.b, self.color.a);
        cr.arc_negative(
            self.x + self.radius,
            self.y + self.radius,
            self.radius,
            -0.5 * PI,
            1.0 * PI,
        );
        cr.line_to(self.x, self.y - self.radius + self.height);
        cr.arc_negative(
            self.x + self.radius,
            self.y + self.height - self.radius,
            self.radius,
            1.0 * PI,
            0.5 * PI,
        );
        cr.line_to(self.x - self.radius + self.width, self.y + self.height);
        cr.arc_negative(
            self.x + self.width - self.radius,
            self.y + self.height - self.radius,
            self.radius,
            0.5 * PI,
            0.0 * PI,
        );
        cr.line_to(self.x + self.width, self.y + self.radius);
        cr.arc_negative(
            self.x + self.width - self.radius,
            self.y + self.radius,
            self.radius,
            0.0 * PI,
            -0.5 * PI,
        );
        cr.close_path();
        if let (Some(b_color), Some(b_width)) = (&self.border_color, self.border_width) {
            cr.fill_preserve()?;
            cr.set_source_rgba(b_color.r, b_color.g, b_color.b, b_color.a);
            cr.set_line_width(b_width);
            cr.stroke()?;
        } else {
            cr.fill()?;
        }
        cr.restore()?;
        Ok(())
    }
}

pub struct Label {
    pub string: String,
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
    pub color: RGBA,
    pub font: Option<FontSettings>,
}

pub struct FontSettings {
    size: f64,
    family: String,
    style: cairo::FontSlant,
    weight: cairo::FontWeight,
}

impl Label {
    pub fn new(string: String, x: f64, y: f64, width: f64, height: f64, color: RGBA) -> Self {
        Self {
            string,
            x,
            y,
            width,
            height,
            color,
            font: None,
        }
    }

    pub fn set_font_values(
        mut self,
        size: f64,
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
        cr.save()?;
        cr.set_source_rgba(self.color.r, self.color.g, self.color.b, self.color.a);
        if let Some(ref font_settings) = self.font {
            cr.select_font_face(
                &font_settings.family,
                font_settings.style,
                font_settings.weight,
            );
            cr.set_font_size(font_settings.size);
        } else {
            cr.select_font_face(
                "sans-serif",
                cairo::FontSlant::Normal,
                cairo::FontWeight::Normal,
            );
            cr.set_font_size(self.height * 0.6);
        }
        cr.set_antialias(cairo::Antialias::Best);
        let extents = cr.text_extents(&self.string)?;
        let target_x = self.x + (self.width - extents.width()) / 2.0 - extents.x_bearing();
        let target_y = self.y + (self.height - extents.height()) / 2.0 - extents.y_bearing();

        cr.move_to(target_x, target_y);
        cr.show_text(&self.string)?;

        cr.restore()?;
        Ok(())
    }
}
