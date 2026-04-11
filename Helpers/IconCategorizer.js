.pragma library

const config = {
    "earbuds_2": ["earbud", "bud", "airpod", "pixel bud", "galaxy bud", "wf-", "tws", "in ear"],
    "headphones": ["headphone", "headset", "wh-", "mdr-", "over ear", "on ear", "studio"],
    "speaker": ["speaker", "soundbar", "homepod", "echo", "google home", "nest audio", "sonos", "boombox"],
    "mic": ["microphone", "mic", "recording"],
    "keyboard": ["keyboard", "keypad", "numpad"],
    "mouse": ["mouse", "mice", "trackball"],
    "touchpad_mouse": ["trackpad", "touchpad"],
    "stylus": ["stylus", "pen", "pencil", "s pen", "apple pencil", "surface pen"],
    "sports_esports": ["controller", "gamepad", "joystick", "xbox", "playstation", "dualsense", "dualshock", "nintendo"],
    "remote_gen": ["remote", "tv remote", "clicker"],
    "tv_gen": ["tv", "television", "smart tv", "android tv", "google tv", "bravia", "fire tv"],
    "monitor": ["monitor", "display", "screen"],
    "watch": ["watch", "smartwatch", "apple watch", "galaxy watch", "fitbit", "garmin"],
    "watch_screentime": ["band", "fitness band", "mi band", "smart band", "fitness tracker"],
    "eyeglasses": ["glasses", "smartglass", "spectacles", "vision pro", "hololens"],
    "laptop": ["laptop", "notebook", "macbook", "thinkpad", "xps", "surface laptop"],
    "tablet": ["tablet", "ipad", "galaxy tab", "surface pro", "pixel tablet"],
    "smartphone": ["phone", "smartphone", "iphone", "galaxy", "pixel", "mobile"],
    "computer": ["desktop", "workstation", "pc", "built-in", "internal", "builtin", "system", "host"],
    "print": ["printer", "scanner", "copier", "mfp"],
    "photo_camera": ["webcam", "camera", "cam", "gopro"],
    "hub": ["hub", "dock", "docking station", "usb hub"],
    "settings_input_hdmi": ["dongle", "adapter", "receiver", "transmitter"],
    "lock": ["lock", "smart lock", "door lock", "deadbolt"],
    "lightbulb": ["light", "bulb", "lamp", "hue", "lifx", "nanoleaf"],
    "thermostat": ["thermostat", "temperature", "climate", "nest", "ecobee"],
    "videocam": ["security cam", "doorbell", "ring", "nest cam", "wyze", "arlo"],
    "pin_drop": ["tag", "tracker", "airtag", "tile", "smarttag", "chipolo"],
    "directions_car": ["car", "vehicle", "auto", "automotive", "tesla", "bmw", "mercedes", "handsfree", "car kit"],
    "monitor_heart": ["scale", "weight", "health", "medical", "thermometer", "glucose", "blood pressure"],
    "audio_file": ["dac", "amp", "amplifier", "audio interface", "sound card"]
};


class DeviceIconMapper {
  constructor(config) {
    this.keyWordMap = new Map();
    this.tokenCache = new Map();

    for (const [icon, keywords] of Object.entries(config)) {
      for (const keyword of keywords) {
        const firstChar = keyword[0];
        if (!this.keyWordMap.has(firstChar)) {
          this.keyWordMap.set(firstChar, []);
        }
        this.keyWordMap.get(firstChar).push({ keyword: keyword, icon });
      }
    }
  }

  tokenize(text) {
    if (this.tokenCache.has(text))
    {
      return this.tokenCache.get(text);
    }

    const tokens = [];
    const lower = text.toLowerCase();
    let i = 0;
    while (i < lower.length) {
      // To remove skip seperators (doesnt match alphanumeric chars)
      while (i < lower.length && !/[a-z0-9]/.test(lower[i])) i++;
      if (i >= lower.length) break;

      // To find the boundary(end) of a word
      let start = i;
      while (i < lower.length && /[a-z0-9]/.test(lower[i])) i++;

      const word = lower.slice(start, i);
      tokens.push({ word, start, end: i });

      for (let len = 3; len < word.length; len++) {
        tokens.push({ word: word.slice(0, len), start, partial: true });
      }

    }
      this.tokenCache.set(text, tokens);
      return tokens;
  }
  findIcon(name) {
    if (!name) return "bluetooth";

    const words = this.tokenize(name);
    const lowerName = name.toLowerCase();
    const checked = new Set();

    for (const token of words) {
                const firstChar = token.word[0];
                if (checked.has(firstChar)) continue;
                checked.add(firstChar);

                const candidates = this.keyWordMap.get(firstChar) || [];

                for (const { keyword, icon } of candidates) {
                    if (lowerName.includes(keyword)) {
                        return icon;
                    }
                }
            }

    return "bluetooth";
  }

}

const map =  new DeviceIconMapper(config)

function getDeviceIcon(name) {
    return map.findIcon(name);
}
