.pragma library

const normalized = {
  216: "O", 223: "s", 248: "o", 273: "d", 295: "h", 305: "i", 320: "l", 322: "l",
  359: "t", 383: "s", 384: "b", 385: "B", 387: "b", 390: "O", 392: "c", 393: "D",
  394: "D", 396: "d", 398: "E", 400: "E", 402: "f", 403: "G", 407: "I", 409: "k",
  410: "l", 412: "M", 413: "N", 414: "n", 415: "O", 421: "p", 427: "t", 429: "t",
  430: "T", 434: "V", 436: "y", 438: "z", 477: "e", 485: "g", 544: "N", 545: "d",
  549: "z", 564: "l", 565: "n", 566: "t", 567: "j", 570: "A", 571: "C", 572: "c",
  573: "L", 574: "T", 575: "s", 576: "z", 579: "B", 580: "U", 581: "V", 582: "E",
  583: "e", 584: "J", 585: "j", 586: "Q", 587: "q", 588: "R", 589: "r", 590: "Y",
  591: "y", 592: "a", 593: "a", 595: "b", 596: "o", 597: "c", 598: "d", 599: "d",
  600: "e", 603: "e", 604: "e", 605: "e", 606: "e", 607: "j", 608: "g", 609: "g",
  610: "G", 613: "h", 614: "h", 616: "i", 618: "I", 619: "l", 620: "l", 621: "l",
  623: "m", 624: "m", 625: "m", 626: "n", 627: "n", 628: "N", 629: "o", 633: "r",
  634: "r", 635: "r", 636: "r", 637: "r", 638: "r", 639: "r", 640: "R", 641: "R",
  642: "s", 647: "t", 648: "t", 649: "u", 651: "v", 652: "v", 653: "w", 654: "y",
  655: "Y", 656: "z", 657: "z", 663: "c", 665: "B", 666: "e", 667: "G", 668: "H",
  669: "j", 670: "k", 671: "L", 672: "q", 686: "h", 867: "a", 868: "e", 869: "i",
  870: "o", 871: "u", 872: "c", 873: "d", 874: "h", 875: "m", 876: "r", 877: "t",
  878: "v", 879: "x", 7424: "A", 7427: "B", 7428: "C", 7429: "D", 7431: "E",
  7432: "e", 7433: "i", 7434: "J", 7435: "K", 7436: "L", 7437: "M", 7438: "N",
  7439: "O", 7440: "O", 7441: "o", 7442: "o", 7443: "o", 7446: "o", 7447: "o",
  7448: "P", 7449: "R", 7450: "R", 7451: "T", 7452: "U", 7453: "u", 7454: "u",
  7455: "m", 7456: "V", 7457: "W", 7458: "Z", 7522: "i", 7523: "r", 7524: "u",
  7525: "v", 7834: "a", 7835: "s", 8305: "i", 8341: "h", 8342: "k", 8343: "l",
  8344: "m", 8345: "n", 8346: "p", 8347: "s", 8348: "t", 8580: "c"
};

for (let i = "\u0300".codePointAt(0); i <= "\u036F".codePointAt(0); ++i) {
  const diacritic = String.fromCodePoint(i);
  for (const asciiChar of "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz") {
    const withDiacritic = (asciiChar + diacritic).normalize();
    const withDiacriticCodePoint = withDiacritic.codePointAt(0);
    if (withDiacriticCodePoint > 126) {
      normalized[withDiacriticCodePoint] = asciiChar;
    }
  }
}

const ranges = {
  a: [7844, 7863],
  e: [7870, 7879],
  o: [7888, 7907],
  u: [7912, 7921]
};

for (const lowerChar of Object.keys(ranges)) {
  const upperChar = lowerChar.toUpperCase();
  for (let i = ranges[lowerChar][0]; i <= ranges[lowerChar][1]; ++i) {
    normalized[i] = i % 2 === 0 ? upperChar : lowerChar;
  }
}

function normalizeRune(rune) {
  if (rune < 192 || rune > 8580) return rune;
  const normalizedChar = normalized[rune];
  if (normalizedChar !== void 0) return normalizedChar.codePointAt(0);
  return rune;
}

function toShort(number) { return number; }
function toInt(number) { return number; }
function maxInt16(num1, num2) { return num1 > num2 ? num1 : num2; }

const strToRunes = (str) => str.split("").map((s) => s.codePointAt(0));
const runesToStr = (runes) => runes.map((r) => String.fromCodePoint(r)).join("");

const whitespaceRunes = new Set(" \f\n\r\t\v\xA0\u1680\u2028\u2029\u202F\u205F\u3000\uFEFF".split("").map((v) => v.codePointAt(0)));
for (let codePoint = "\u2000".codePointAt(0); codePoint <= "\u200A".codePointAt(0); codePoint++) {
  whitespaceRunes.add(codePoint);
}
const isWhitespace = (rune) => whitespaceRunes.has(rune);

const whitespacesAtStart = (runes) => {
  let whitespaces = 0;
  for (const rune of runes) {
    if (isWhitespace(rune)) whitespaces++;
    else break;
  }
  return whitespaces;
};

const whitespacesAtEnd = (runes) => {
  let whitespaces = 0;
  for (let i = runes.length - 1; i >= 0; i--) {
    if (isWhitespace(runes[i])) whitespaces++;
    else break;
  }
  return whitespaces;
};

const MAX_ASCII = "\x7F".codePointAt(0);
const CAPITAL_A_RUNE = "A".codePointAt(0);
const CAPITAL_Z_RUNE = "Z".codePointAt(0);
const SMALL_A_RUNE = "a".codePointAt(0);
const SMALL_Z_RUNE = "z".codePointAt(0);
const NUMERAL_ZERO_RUNE = "0".codePointAt(0);
const NUMERAL_NINE_RUNE = "9".codePointAt(0);

const SCORE_MATCH = 16;
const SCORE_GAP_START = -3;
const SCORE_GAP_EXTENTION = -1;
const BONUS_BOUNDARY = SCORE_MATCH / 2;
const BONUS_NON_WORD = SCORE_MATCH / 2;
const BONUS_CAMEL_123 = BONUS_BOUNDARY + SCORE_GAP_EXTENTION;
const BONUS_CONSECUTIVE = -(SCORE_GAP_START + SCORE_GAP_EXTENTION);
const BONUS_FIRST_CHAR_MULTIPLIER = 2;

// --- MISSING FUNCTIONS ADDED HERE --- //
function charClassOf(rune) {
  if (rune >= SMALL_A_RUNE && rune <= SMALL_Z_RUNE) return 1;
  if (rune >= CAPITAL_A_RUNE && rune <= CAPITAL_Z_RUNE) return 2;
  if (rune >= NUMERAL_ZERO_RUNE && rune <= NUMERAL_NINE_RUNE) return 3;
  return 0; // Non-word / Boundary
}

function bonusFor(prevClass, currClass) {
  if (prevClass === 0 && currClass !== 0) return BONUS_BOUNDARY;
  if ((prevClass === 1 || prevClass === 0) && currClass === 2) return BONUS_CAMEL_123;
  if (currClass === 0) return BONUS_NON_WORD;
  return 0;
}

function bonusAt(text, index) {
  if (index === 0) return BONUS_BOUNDARY;
  return bonusFor(charClassOf(text[index - 1]), charClassOf(text[index]));
}

function asciiFuzzyIndex(text, pattern, caseSensitive) {
  let pidx = 0;
  const plen = pattern.length;
  for (let i = 0; i < text.length; i++) {
    let t = text[i];
    let p = pattern[pidx];
    if (!caseSensitive) {
      if (t >= CAPITAL_A_RUNE && t <= CAPITAL_Z_RUNE) t += 32;
      if (p >= CAPITAL_A_RUNE && p <= CAPITAL_Z_RUNE) p += 32;
    }
    if (t === p) {
      pidx++;
      if (pidx === plen) return i - plen + 1;
    }
  }
  return -1;
}

function indexAt(index, max, forward) {
  if (forward) return index;
  return max - index - 1;
}

function calculateScore(caseSensitive, normalize, text, pattern, sidx, eidx, withPos) {
  let pidx = 0, score = 0, inGap = false, consecutive = 0, firstBonus = toShort(0);
  const pos = withPos ? new Set() : null; // Fixed broken pos creator

  let prevCharClass = 0;
  if (sidx > 0) {
    prevCharClass = charClassOf(text[sidx - 1]);
  }

  for (let idx = sidx; idx < eidx; idx++) {
    let rune = text[idx];
    const charClass = charClassOf(rune);
    if (!caseSensitive) {
      if (rune >= CAPITAL_A_RUNE && rune <= CAPITAL_Z_RUNE) {
        rune += 32;
      } else if (rune > MAX_ASCII) {
        rune = String.fromCodePoint(rune).toLowerCase().codePointAt(0);
      }
    }
    if (normalize) {
      rune = normalizeRune(rune);
    }
    if (rune === pattern[pidx]) {
      if (withPos && pos !== null) {
        pos.add(idx);
      }
      score += SCORE_MATCH;
      let bonus = bonusFor(prevCharClass, charClass);
      if (consecutive === 0) {
        firstBonus = bonus;
      } else {
        if (bonus === BONUS_BOUNDARY) {
          firstBonus = bonus;
        }
        bonus = maxInt16(maxInt16(bonus, firstBonus), BONUS_CONSECUTIVE);
      }
      if (pidx === 0) {
        score += bonus * BONUS_FIRST_CHAR_MULTIPLIER;
      } else {
        score += bonus;
      }
      inGap = false;
      consecutive++;
      pidx++;
    } else {
      if (inGap) {
        score += SCORE_GAP_EXTENTION;
      } else {
        score += SCORE_GAP_START;
      }
      inGap = true;
      consecutive = 0;
      firstBonus = 0;
    }
    prevCharClass = charClass;
  }
  return [score, pos];
}

function fuzzyMatchV1(caseSensitive, normalize, forward, text, pattern, withPos, slab2) {
  if (pattern.length === 0) {
    return [{ start: 0, end: 0, score: 0 }, null];
  }
  if (asciiFuzzyIndex(text, pattern, caseSensitive) < 0) {
    return [{ start: -1, end: -1, score: 0 }, null];
  }
  let pidx = 0, sidx = -1, eidx = -1;
  const lenRunes = text.length;
  const lenPattern = pattern.length;
  for (let index = 0; index < lenRunes; index++) {
    let rune = text[indexAt(index, lenRunes, forward)];
    if (!caseSensitive) {
      if (rune >= CAPITAL_A_RUNE && rune <= CAPITAL_Z_RUNE) {
        rune += 32;
      } else if (rune > MAX_ASCII) {
        rune = String.fromCodePoint(rune).toLowerCase().codePointAt(0);
      }
    }
    if (normalize) {
      rune = normalizeRune(rune);
    }
    const pchar = pattern[indexAt(pidx, lenPattern, forward)];
    if (rune === pchar) {
      if (sidx < 0) {
        sidx = index;
      }
      pidx++;
      if (pidx === lenPattern) {
        eidx = index + 1;
        break;
      }
    }
  }
  if (sidx >= 0 && eidx >= 0) {
    pidx--;
    for (let index = eidx - 1; index >= sidx; index--) {
      const tidx = indexAt(index, lenRunes, forward);
      let rune = text[tidx];
      if (!caseSensitive) {
        if (rune >= CAPITAL_A_RUNE && rune <= CAPITAL_Z_RUNE) {
          rune += 32;
        } else if (rune > MAX_ASCII) {
          rune = String.fromCodePoint(rune).toLowerCase().codePointAt(0);
        }
      }
      const pidx_ = indexAt(pidx, lenPattern, forward);
      const pchar = pattern[pidx_];
      if (rune === pchar) {
        pidx--;
        if (pidx < 0) {
          sidx = index;
          break;
        }
      }
    }
    if (!forward) {
      const sidxTemp = sidx;
      sidx = lenRunes - eidx;
      eidx = lenRunes - sidxTemp;
    }
    const [score, pos] = calculateScore(caseSensitive, normalize, text, pattern, sidx, eidx, withPos);
    return [{ start: sidx, end: eidx, score }, pos];
  }
  return [{ start: -1, end: -1, score: 0 }, null];
};

// Map V2 to V1 to prevent the library from crashing when called
const fuzzyMatchV2 = fuzzyMatchV1;

function Finder(items, opts) {
  this.items = items || []
  this.opts = opts || {}
  this.opts.selector = this.opts.selector || (item => item)
  this.opts.casing = this.opts.casing || "case-insensitive"
  this.opts.fuzzy = this.opts.fuzzy || "v2"
  this.opts.limit = this.opts.limit || 50
  this.opts.sort = this.opts.sort !== undefined ? this.opts.sort : true
  this.opts.tiebreakers = this.opts.tiebreakers || []

  this.find = function(query) {
    if (!query || query.length === 0) {
      return this.items.map((item, idx) => ({ item: item, score: 0, index: idx }))
    }
    const results = []
    const selector = this.opts.selector
    const caseSensitive = this.opts.casing === "case-sensitive"
    const normalize = !caseSensitive
    const fuzzyAlgo = this.opts.fuzzy === "v2" ? fuzzyMatchV2 : fuzzyMatchV1

    for (let idx = 0; idx < this.items.length; idx++) {
      const item = this.items[idx]
      const text = selector(item)
      if (!text) continue
      const runes = strToRunes(text)
      const pattern = strToRunes(query)
      const res = fuzzyAlgo(caseSensitive, normalize, true, runes, pattern, false, null)
      if (res[0].start >= 0) {
        results.push({
          item: item,
          score: res[0].score,
          index: idx,
          start: res[0].start,
          end: res[0].end
        })
      }
    }
    if (this.opts.sort) {
      results.sort((a, b) => {
        if (b.score !== a.score) {
          return b.score - a.score
        }
        for (const tiebreaker of this.opts.tiebreakers) {
          const diff = tiebreaker(a, b, selector)
          if (diff !== 0) {
            return diff
          }
        }
        return 0
      })
    }
    if (Number.isFinite(this.opts.limit)) {
      return results.slice(0, this.opts.limit)
    }
    return results
  }
}
