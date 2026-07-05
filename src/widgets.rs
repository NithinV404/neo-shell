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
}

impl Rectangle {
    pub fn new(x: f64, y: f64, width: f64, height: f64, radius: f64, color: RGBA) -> Self {
        Self {
            x,
            y,
            width,
            height,
            radius,
            color,
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
        cr.fill()?;
        Ok(())
    }
}
