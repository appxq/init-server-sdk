// sdthai.typ — ตัวช่วยภาษาไทย + เอกสารราชการ สำหรับ Typst report (server วางไฟล์นี้ข้าง doc.typ ให้ทุกครั้ง)
//
//   #import "sdthai.typ": *
//   #show: gov                      // A4 + ระยะขอบระเบียบงานสารบรรณ + TH Sarabun New 16pt + จัดชิดขอบแบบไทย
//   #show: sdthai                   // เฉพาะฟอนต์/ภาษา/จัดชิดขอบ (กำหนดหน้ากระดาษเอง)
//   #show: sdthai.with(font: "Sarabun", size: 14pt)
//
//   #data.doc_no · #rows.len() · #params.x   — ข้อมูลจาก SQL provider (row แรกอยู่ที่ data.<field>)
//   #thaidate(raw.doc_date) · #money(raw.amount) · #bahttext(raw.amount) · #thainum(data.doc_no)
//   #img(data.sign, height: 2cm) · #img("garuda.png", height: 3cm)
//   #fillin(4cm)[#data.name] · #dotline(3cm)
//   #qr(data.hn, size: 2cm) · #qr(url, level: "H") · #barcode(data.hn, width: 5cm)

// QR / barcode: tiaoma (Zint wasm, MIT) — server วางไว้ใน package path (assets/typst/packages) ใช้แบบ offline
#import "@preview/tiaoma:0.3.0"
// ชุดวาดภาพ — template เรียกผ่าน sdthai ได้เลย (#cetz.canvas / #diagram) ไม่ต้องรู้เลขเวอร์ชัน
#import "@preview/cetz:0.4.0"
#import "@preview/cetz-plot:0.1.2": plot, chart
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

// ─────────── ข้อมูล ───────────
// server เขียน data.json = { ...row แรก, rows, params, raw, _images, _library } (โครงเดียวกับ LaTeX report)
#let data = json("data.json")
#let rows = data.at("rows", default: ())
#let params = data.at("params", default: (:))
#let raw = data.at("raw", default: (:))

// ─────────── หน้ากระดาษ / ฟอนต์ ───────────
// จัดชิดขอบภาษาไทย (พิสูจน์แล้ว 2026-09-22):
// - linebreaks "optimized" (ค่า default) บางบรรทัดตัดก่อนช่องว่าง → บรรทัดถัดไปขึ้นต้นเยื้อง ~1 ช่อง
// - ไทยมีช่องว่างน้อย ยืดแค่ช่องว่างจะโหว่ → เปิด tracking ให้ยืดระหว่างตัวอักษรเล็กน้อย (แบบ "กระจายแบบไทย")
#let sdthai(font: "TH Sarabun New", size: 16pt, justify: true, body) = {
  set text(font: font, size: size, lang: "th")
  set par(
    leading: 0.55em,
    spacing: 0.55em,
    justify: justify,
    linebreaks: "simple",
    justification-limits: (tracking: (min: -0.01em, max: 0.03em)),
  )
  body
}

// ระยะขอบตามระเบียบงานสารบรรณ: บน 2.5 ซม. ล่าง 2 ซม. ซ้าย 3 ซม. ขวา 2 ซม.
#let gov(font: "TH Sarabun New", size: 16pt, body) = {
  set page(paper: "a4", margin: (top: 2.5cm, bottom: 2cm, left: 3cm, right: 2cm))
  show: sdthai.with(font: font, size: size)
  body
}

// ─────────── ตัวเลข / เงิน ───────────
#let _thai-digits = ("๐", "๑", "๒", "๓", "๔", "๕", "๖", "๗", "๘", "๙")

/// เลขอารบิก → เลขไทย: thainum("123/2569") → ๑๒๓/๒๕๖๙
#let thainum(value) = {
  if value == none { return "" }
  // str() ของเลขติดลบใน Typst ได้เครื่องหมายลบ U+2212 → แปลงกลับเป็น "-" ให้ตรงกับฝั่ง LaTeX
  str(value).replace("\u{2212}", "-").replace(regex("[0-9]"), m => _thai-digits.at(int(m.text)))
}

// ค่า "1,234.5" / 1234.5 → float · ไม่ใช่ตัวเลข = none
#let _to-num(value) = {
  if type(value) == int or type(value) == float { return float(value) }
  if value == none { return none }
  let s = str(value).replace(",", "").trim()
  if s.match(regex("^-?\d+(\.\d+)?$")) == none { return none }
  float(s)
}

// ใส่คอมม่าทุก 3 หลัก (รับ string ตัวเลขล้วน)
#let _group(digits) = {
  let out = ""
  let n = digits.len()
  for (i, c) in digits.clusters().enumerate() {
    if i > 0 and calc.rem(n - i, 3) == 0 { out += "," }
    out += c
  }
  out
}

/// จำนวนเงินมีคอมม่า: money(3346927.9) → 3,346,927.90 · ไม่ใช่ตัวเลข = คืนค่าเดิม
#let money(value, digits: 2) = {
  let num = _to-num(value)
  if num == none { return if value == none { "" } else { str(value) } }
  let scale = calc.pow(10, digits)
  let total = int(calc.round(calc.abs(num) * scale))
  let int-part = _group(str(calc.quo(total, scale)))
  let frac = str(calc.rem(total, scale))
  let frac = "0" * calc.max(digits - frac.len(), 0) + frac  // digits: 0 → ต้องไม่ repeat ติดลบ
  (if num < 0 and total > 0 { "-" } else { "" }) + int-part + (if digits > 0 { "." + frac } else { "" })
}

// ─────────── bahttext ───────────
#let _th-num = ("", "หนึ่ง", "สอง", "สาม", "สี่", "ห้า", "หก", "เจ็ด", "แปด", "เก้า")
#let _th-unit = ("", "สิบ", "ร้อย", "พัน", "หมื่น", "แสน")

// อ่านเลขจำนวนเต็มไม่เกิน 6 หลัก (หลักล้านวนซ้ำใน _read-int)
#let _read-six(n) = {
  let digits = str(n).clusters().map(int)
  let len = digits.len()
  let out = ""
  for (i, dg) in digits.enumerate() {
    let pos = len - i - 1
    if dg == 0 { continue }
    if pos == 0 and dg == 1 and len > 1 { out += "เอ็ด" }
    else if pos == 1 and dg == 2 { out += "ยี่" }
    else if pos == 1 and dg == 1 { }
    else { out += _th-num.at(dg) }
    out += _th-unit.at(pos)
  }
  out
}

#let _read-int(n) = {
  if n == 0 { return "ศูนย์" }
  let parts = ()
  let rest = n
  while rest > 0 {
    let group = calc.rem(rest, 1000000)
    rest = calc.quo(rest, 1000000)
    // กลุ่มท้ายที่มีแค่ 1 หลังหลักล้าน อ่าน "เอ็ด" (1,000,001 = หนึ่งล้านเอ็ด)
    parts.insert(0, if group == 1 and rest > 0 { "เอ็ด" } else { _read-six(group) })
  }
  // กลุ่มที่เป็น 0 ทั้งกลุ่มยังต้องมีคำว่า "ล้าน" คั่น
  parts.enumerate().map(((i, p)) => if i < parts.len() - 1 { p + "ล้าน" } else { p }).join()
}

/// จำนวนเงินเป็นตัวอักษร: bahttext(100) → หนึ่งร้อยบาทถ้วน · bahttext(0.5) → ห้าสิบสตางค์
#let bahttext(value) = {
  let num = _to-num(value)
  if num == none { return if value == none { "" } else { str(value) } }
  let satang-total = int(calc.round(calc.abs(num) * 100))
  let baht = calc.quo(satang-total, 100)
  let satang = calc.rem(satang-total, 100)
  let out = if baht > 0 or satang == 0 { _read-int(baht) + "บาท" } else { "" }
  out += if satang == 0 { "ถ้วน" } else { _read-int(satang) + "สตางค์" }
  (if num < 0 { "ลบ" } else { "" }) + out
}

// ─────────── วันที่ไทย ───────────
#let _month-long = ("มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน", "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม")
#let _month-short = ("ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค.")
// datetime.weekday(): 1 = จันทร์ … 7 = อาทิตย์
#let _day-name = ("จันทร์", "อังคาร", "พุธ", "พฤหัสบดี", "ศุกร์", "เสาร์", "อาทิตย์")

// ค่าวันที่ → datetime · รับ "YYYY-MM-DD[THH:mm[:ss]]" และ "DD/MM/YYYY" (ปีเกิน 2400 = พ.ศ.)
// server แปลง Date จาก DB เป็นเวลาท้องถิ่นให้แล้ว (ไม่มี Z) → ตัดส่วนวันที่ได้ตรงๆ ไม่เพี้ยนข้ามวัน
#let _to-date(value) = {
  if value == none { return none }
  if type(value) == datetime { return value }
  let s = str(value).trim()
  let iso = s.match(regex("^(\d{4})-(\d{1,2})-(\d{1,2})"))
  if iso != none {
    let (y, m, d) = iso.captures.map(int)
    return datetime(year: y, month: m, day: d)
  }
  let dmy = s.match(regex("^(\d{1,2})/(\d{1,2})/(\d{4})"))
  if dmy != none {
    let (d, m, y) = dmy.captures.map(int)
    if y > 2400 { y -= 543 }
    return datetime(year: y, month: m, day: d)
  }
  none
}

/// วันที่ไทย: format = long (22 กันยายน 2569) · short (22 ก.ย. 2569) · shortyear (22 ก.ย. 69)
///            full (วันจันทร์ที่ 22 กันยายน พ.ศ. 2569) · month (กันยายน 2569) · be (22 กันยายน พ.ศ. 2569)
#let thaidate(value, format: "long") = {
  let d = _to-date(value)
  if d == none { return if value == none { "" } else { str(value) } }
  let day = d.day()
  let year = d.year() + 543
  let m = d.month() - 1
  // คืน string (ไม่ใช่ content) → ส่งต่อให้ thainum ได้: thainum(thaidate(raw.doc_date))
  let (day, year) = (str(day), str(year))
  if format == "short" { day + " " + _month-short.at(m) + " " + year }
  else if format == "shortyear" { day + " " + _month-short.at(m) + " " + year.slice(-2) }
  else if format == "full" { "วัน" + _day-name.at(d.weekday() - 1) + "ที่ " + day + " " + _month-long.at(m) + " พ.ศ. " + year }
  else if format == "month" { _month-long.at(m) + " " + year }
  else if format == "be" { day + " " + _month-long.at(m) + " พ.ศ. " + year }
  else { day + " " + _month-long.at(m) + " " + year }
}

// ─────────── รูป ───────────
// server เก็บรูปที่อยู่ใน data (data URI / ไฟล์ใต้ /assets/) ไว้ข้าง doc.typ แล้วบอกชื่อไฟล์ผ่าน data._images
// ส่วนคลังรูป (assets/latex/images เช่น garuda.png) อยู่ใน data._library — เรียกด้วยชื่อไฟล์ได้เลย
#let _images = data.at("_images", default: (:))
#let _library = data.at("_library", default: ())

// ค่า field รูปอาจเป็น array / object {url} / "url1, url2" → เอารูปแรก (ล้อ firstValue ฝั่ง server)
#let _first-image(value) = {
  if type(value) == array { value = value.at(0, default: none) }
  if type(value) == dictionary {
    // drawing-input เก็บเป็น (bg, drawing, width, height) → ใช้ลายเส้นเป็นรูป (พื้นหลังใช้ #drawing() ถึงจะได้ครบ)
    if "drawing" in value { value = value.at("drawing") }
    if type(value) == dictionary { value = value.at("url", default: value.at("filePath", default: none)) }
  }
  if value == none { return "" }
  str(value).split(", ").at(0).trim()
}

/// รูปจากค่า field หรือชื่อไฟล์ในคลัง: #img(data.sign, height: 2cm) · #img("garuda.png", height: 3cm)
/// หารูปไม่เจอ = พื้นที่ว่างขนาดเท่าที่ขอ (รายงานไม่พังเพราะยังไม่อัปโหลดลายเซ็น)
#let img(value, ..args) = {
  let src = _first-image(value)
  let file = _images.at(src, default: if src in _library { src } else { none })
  if file == none { box(width: args.named().at("width", default: 0pt), height: args.named().at("height", default: 0pt)) }
  else { image(file, ..args) }
}

// ─────────── QR / barcode ───────────
#let _qr-level = (L: 1, M: 2, Q: 3, H: 4)

/// QR code แบบ vector: #qr(data.hn) · #qr(data.url, size: 3cm, level: "H") (L/M/Q/H = กู้ข้อมูลได้ 7/15/25/30%)
/// ค่าว่าง = พื้นที่ว่างขนาดเท่า QR (รายงานไม่พังเพราะยังไม่มีค่า) — ล้อ filter qr ของ LaTeX
#let qr(value, size: 2cm, level: "M") = {
  let s = if value == none { "" } else { str(value) }
  if s == "" { return box(width: size, height: size) }
  // box = วางในบรรทัดได้ (image ของ tiaoma เป็น block)
  box(tiaoma.qrcode(s, options: ("option-1": _qr-level.at(level, default: 2)), width: size))
}

/// barcode Code128 (HN / เลขเอกสาร): #barcode(data.hn, width: 5cm, height: 1.2cm)
#let barcode(value, width: 5cm, height: auto) = {
  let s = if value == none { "" } else { str(value) }
  if s == "" { return box(width: width, height: if height == auto { 1cm } else { height }) }
  box(tiaoma.code128(s, width: width, height: height))
}

// ─────────── เส้นจุดไข่ปลา (แบบฟอร์มกรอก) ───────────
/// ช่องจุดไข่ปลาความยาวคงที่: #dotline(5cm)
#let dotline(width) = box(width: width, repeat[.])

/// ค่าวางบนเส้นจุดไข่ปลา ข้อความกึ่งกลาง: #fillin(5cm)[#data.name]
#let fillin(width, body, align-to: center) = box(width: width, {
  place(bottom, dy: 0.15em, dotline(width))
  align(align-to, body)
})

// ─────────── ค่าจาก widget ของ low-code (map / drawing / ไฟล์แนบ) ───────────
// ค่าที่ฟอร์มเก็บเป็น object ทั้งก้อน (ไม่ใช่ string) — helper ชุดนี้แปลงให้เอง template จึงเขียนสั้นได้
// drawing-input : (bg: (type, value/url), drawing: (url), width, height)
// map-input     : (type: "Point", coordinates: (lng, lat), accuracy, source)  ← GeoJSON

/// Drawing Pad: ซ้อนพื้นหลังกับลายเส้นเป็นรูปเดียว — #drawing(data.signature, width: 6cm)
/// bg เป็นสี/กระดาษ = พื้นสี · bg เป็นรูป (template) = รูปพื้นหลัง · ลายเส้นทับด้านบนเสมอ
#let drawing(value, width: auto, height: auto, stroke-box: none) = {
  if type(value) != dictionary { return img(value, width: width, height: height) }
  let bg = value.at("bg", default: none)
  let ink = value.at("drawing", default: none)
  let w = value.at("width", default: 0)
  let h = value.at("height", default: 0)

  // ขนาดที่วาด: ระบุมาอย่างใดอย่างหนึ่งก็พอ ที่เหลือคิดจากสัดส่วนของ canvas ที่ผู้ใช้วาดไว้
  let ratio = if w != 0 and h != 0 { h / w } else { 0.5 }
  let box-w = if width == auto and height == auto { 6cm } else if width == auto { height / ratio } else { width }
  let box-h = if height == auto { box-w * ratio } else { height }

  let fill-color = none
  if type(bg) == dictionary and bg.at("type", default: "") in ("color", "paper", "pattern") {
    let v = str(bg.at("value", default: ""))
    if v.starts-with("#") { fill-color = rgb(v) }
  }

  box(width: box-w, height: box-h, fill: fill-color, stroke: stroke-box, {
    if type(bg) == dictionary and bg.at("url", default: none) != none {
      place(top + left, img(bg, width: box-w, height: box-h))
    }
    if ink != none { place(top + left, img(ink, width: box-w, height: box-h)) }
  })
}

/// พิกัดจาก map-input → (lat, lng) · รับ GeoJSON Point, "lat, lng" หรือ dictionary (lat, lng)
#let _point(value) = {
  if value == none { return none }
  if type(value) == dictionary {
    let c = value.at("coordinates", default: none)
    if type(c) == array and c.len() >= 2 { return (float(c.at(1)), float(c.at(0))) }  // GeoJSON = (lng, lat)
    let lat = value.at("lat", default: none)
    let lng = value.at("lng", default: value.at("lon", default: none))
    if lat != none and lng != none { return (float(lat), float(lng)) }
    return none
  }
  let parts = str(value).split(",")
  if parts.len() < 2 { return none }
  let lat = parts.at(0).trim()
  let lng = parts.at(1).trim()
  if lat.match(regex("^-?\d+(\.\d+)?$")) == none { return none }
  (float(lat), float(lng))
}

/// พิกัดเป็นข้อความ: #latlng(data.home_loc) → 13.756300, 100.501800
#let latlng(value, digits: 6) = {
  let p = _point(value)
  if p == none { return "" }
  let f(x) = {
    let s = str(calc.round(x, digits: digits))
    if "." not in s { s = s + "." }
    let need = digits - (s.split(".").at(1).len())
    s + "0" * calc.max(need, 0)
  }
  f(p.at(0)) + ", " + f(p.at(1))
}

/// ลิงก์เปิด Google Maps ของพิกัดนั้น (ใช้เป็นค่าใน QR)
#let gmapurl(value) = {
  let p = _point(value)
  if p == none { return "" }
  // URL ห้ามมีช่องว่าง (บางแอปตัดลิงก์ตรงช่องว่าง) → lat,lng ติดกัน
  "https://www.google.com/maps/search/?api=1&query=" + str(p.at(0)) + "," + str(p.at(1))
}

/// ตำแหน่งจากแผนที่: QR เปิด Google Maps + พิกัดใต้ป้าย — #location(data.home_loc, label: "บ้านผู้ป่วย")
/// ไม่มีพิกัด = ไม่วาดอะไร (เหมือนรายงาน pdfmake)
#let location(value, size: 2cm, label: "", caption: "สแกนเพื่อเปิดใน Google Maps") = {
  let p = _point(value)
  if p == none { return [] }
  box(grid(columns: (auto, auto), column-gutter: 0.6em, align: horizon,
    qr(gmapurl(value), size: size),
    {
      if label != "" [#label \ ]
      [#latlng(value)]
      if caption != "" [ \ #text(size: 0.8em, caption)]
    },
  ))
}

// ─────────── จัดข้อความให้พอดีช่อง ───────────
/// ย่อขนาดตัวอักษรอัตโนมัติจนข้อความจบในความกว้าง w (ค่าจากฐานข้อมูลยาวไม่เท่ากัน ตกบรรทัดแล้วชนบล็อกอื่น)
/// #fitline(7cm)[#data.remark]
#let fitline(w, body, size: 14pt, min-size: 10pt, step: 0.25pt) = context {
  let s = size
  while measure(text(size: s, body)).width > w and s > min-size { s = s - step }
  text(size: s, body)
}

// ─────────── ระบบสี (ใช้ชุดเดียวกันทุกรายงาน) ───────────
// เรียก #sd.ok / #sd.warn ฯลฯ · สีอ่อนสำหรับพื้นหลังใช้ #tint(sd.ok)
// เลือกโทนให้พิมพ์ขาวดำแล้วยังแยกออก (ความเข้มต่างกันพอ) และอ่านบนกระดาษได้จริง
#let sd = (
  brand: rgb("#1f4e9c"),   // น้ำเงินราชการ — หัวตาราง/เส้นหลัก
  ink: rgb("#1f2328"),     // ข้อความหลัก
  muted: rgb("#6b7280"),   // ข้อความรอง/หมายเหตุ
  line: rgb("#c9ced6"),    // เส้นตาราง/ขอบกล่อง
  ok: rgb("#1e7f4f"),      // ผ่าน/อนุมัติ
  warn: rgb("#b7791f"),    // รอดำเนินการ
  danger: rgb("#b42318"),  // ยกเลิก/เกินกำหนด
  info: rgb("#0b6fa4"),    // ข้อมูลเพิ่มเติม
)

/// สีอ่อนของสีเดิม (พื้นกล่อง/แถบตาราง): #tint(sd.ok) · amount 0-100%
#let tint(color, amount: 88%) = color.lighten(amount)

/// ชุดสีสำหรับกราฟหลายชุดข้อมูล — วนใช้ตามลำดับ #palette.at(i)
#let palette = (rgb("#4c78a8"), rgb("#f58518"), rgb("#54a24b"), rgb("#e45756"), rgb("#79706e"), rgb("#b279a2"))

/// ป้ายสถานะสีพื้น: #badge("อนุมัติแล้ว", sd.ok)
#let badge(label, color: none) = {
  let c = if color == none { sd.brand } else { color }
  box(fill: tint(c), stroke: 0.5pt + c, inset: (x: 4pt, y: 1.5pt), radius: 2pt, text(fill: c, size: 0.85em, label))
}

// ─────────── สิทธิ์ผู้ใช้ในรายงาน ───────────
// ผู้ที่กดพิมพ์ — ใช้เขียนเงื่อนไขว่าจะแสดง/ปิดอะไร
//   #user.username · #user.name · #user.roles · #user.site.name · #user.unit.name
// ⚠️ ระดับความปลอดภัย: ข้อมูลถูกโหลดมาที่ server แล้วเลือก "ไม่พิมพ์ลง PDF" ⇒ ไฟล์ที่ออกไปไม่มีข้อมูลนั้นจริง
//    แต่ถ้าข้อมูลอ่อนไหวมากจนไม่ควรออกจากฐานข้อมูล ให้กรองที่ SQL provider ด้วย :xrolesx / :xuser_idx แทน
#let user = data.at("_user", default: (username: "", name: "", id: "", roles: (), site: (code: "", name: ""), unit: (code: "", name: "")))

/// มีสิทธิ์อย่างน้อยหนึ่งใน role ที่ระบุไหม — #if has-role("admin", "pharmacist") [...]
#let has-role(..roles) = {
  let mine = user.at("roles", default: ())
  roles.pos().any(r => str(r) in mine)
}

/// แสดงเฉพาะเมื่อมีสิทธิ์ · #if-role("admin", "finance")[ราคาทุน #money(raw.cost)]
/// ไม่มีสิทธิ์ = ไม่แสดงอะไรเลย (ใส่ fallback: [...] เพื่อแสดงข้อความแทนได้)
#let if-role(..args, fallback: []) = {
  let all = args.pos()
  let body = if all.len() > 0 { all.pop() } else { [] }
  if has-role(..all) { body } else { fallback }
}

/// ปิดข้อมูลบางส่วน: mask("1234567890123") → xxxxxxxxx0123 · keep = โชว์ท้ายกี่ตัว
#let mask(value, keep: 4, char: "x") = {
  if value == none { return "" }
  let s = str(value)
  if s.len() <= keep { return char * s.len() }
  char * (s.len() - keep) + s.slice(s.len() - keep)
}

/// ไม่มีสิทธิ์ = ปิดทึบ · #redact-unless("admin", data.salary)
#let redact-unless(..args, placeholder: "▮▮▮▮") = {
  let all = args.pos()
  let value = if all.len() > 0 { all.pop() } else { none }
  if has-role(..all) { if value == none { "" } else { str(value) } } else { placeholder }
}

// ─────────── ตารางรายงาน (สเปกเดียวกับคอลัมน์ของ Report Factory) ───────────
// #sdtable(rows, columns: (
//   (field: "item_name", label: "รายการ"),
//   (field: "qty",  label: "จำนวน", width: 2.2cm, align: right, format: "num2", sum: true),
//   (field: "unit", label: "หน่วย", width: 2cm, align: center),
//   (field: "cat",  group: true),                       // คอลัมน์จัดกลุ่ม → กลายเป็นแถวหัวกลุ่ม
// ))
// format: num · num1 · num2 · date · datetime · boolean · money · bahttext (ว่าง = แสดงตามค่าเดิม)
// หัวตารางซ้ำทุกหน้าอัตโนมัติ (table.header) · sum ขึ้นแถวรวมท้ายตาราง

#let _fmt(value, kind) = {
  if value == none { return "" }
  if kind == none or kind == "" { return if type(value) == str { value } else { str(value) } }
  if kind == "num" { return money(value, digits: 0) }
  if kind == "num1" { return money(value, digits: 1) }
  if kind in ("num2", "money") { return money(value) }
  if kind == "bahttext" { return bahttext(value) }
  if kind == "date" { return thaidate(value) }
  if kind == "datetime" { return thaidate(value) + " " + str(value).split(" ").at(-1).slice(0, 5) }
  if kind == "boolean" { return if value == true or value == "True" or value == 1 { "ใช่" } else { "ไม่ใช่" } }
  str(value)
}

#let _cell(row, col) = {
  let v = row.at(col.at("field", default: ""), default: none)
  if v == none and "raw-key" in col { v = row.at("_raw", default: (:)).at(col.raw-key, default: none) }
  let kind = col.at("format", default: none)
  // ช่องที่เป็นรูป/รหัส — ขนาดจาก col.size (default พอดีความสูงแถว)
  if kind == "qrcode" { return qr(v, size: col.at("size", default: 1.6cm)) }
  if kind == "barcode" { return barcode(v, width: col.at("size", default: 3.2cm), height: col.at("height", default: 0.9cm)) }
  if kind == "image" { return img(v, width: col.at("size", default: 2cm)) }
  if kind == "drawing" { return drawing(v, width: col.at("size", default: 3cm)) }
  if kind == "location" { return location(v, size: col.at("size", default: 1.4cm), caption: "") }
  _fmt(v, kind)
}

#let sdtable(
  rows,
  columns: (),
  header-fill: none,
  group-fill: none,
  stroke-color: none,
  total-label: "รวม",
  show-total: auto,
  group-pagebreak: false,
) = {
  // ในช่องตารางไม่ยืดคำ — ไม่งั้นวันที่/ข้อความในคอลัมน์แคบจะถ่างและตัดบรรทัดกลางคำ
  set par(justify: false)
  let hfill = if header-fill == none { tint(sd.brand, amount: 82%) } else { header-fill }
  let gfill = if group-fill == none { tint(sd.muted, amount: 88%) } else { group-fill }
  let scolor = if stroke-color == none { sd.line } else { stroke-color }

  // คอลัมน์ที่กำหนด roles: (...) ไว้ — ผู้ไม่มีสิทธิ์จะไม่เห็นทั้งคอลัมน์ (และไม่ถูกนำไปรวมยอด)
  let columns = columns.filter(c => {
    let need = c.at("roles", default: none)
    need == none or has-role(..need)
  })
  let shown = columns.filter(c => not c.at("group", default: false))
  let groups = columns.filter(c => c.at("group", default: false))
  let widths = shown.map(c => c.at("width", default: 1fr))
  let aligns = shown.map(c => c.at("align", default: left))
  let has-sum = shown.any(c => c.at("sum", default: false))
  let want-total = if show-total == auto { has-sum } else { show-total }

  // ค่ารวมต่อคอลัมน์ (บวกจากค่าดิบก่อน format เหมือน Report Factory)
  let totals = shown.map(c => if c.at("sum", default: false) {
    rows.map(r => {
      let v = r.at(c.at("field", default: ""), default: 0)
      if type(v) == int or type(v) == float { float(v) } else if type(v) == str and v.trim() != "" and v.replace(",", "").match(regex("^-?\d+(\.\d+)?$")) != none { float(v.replace(",", "")) } else { 0.0 }
    }).sum(default: 0.0)
  } else { none })

  let body = ()
  let last-group = none
  for r in rows {
    // แถวหัวกลุ่ม: ขึ้นใหม่เมื่อค่าเปลี่ยน (ต้อง sort มาจาก SQL แล้ว เหมือน col_group ของ pdfmake)
    if groups.len() > 0 {
      let key = groups.map(g => str(r.at(g.at("field", default: ""), default: ""))).join(" · ")
      if key != last-group {
        // ขึ้นหน้าใหม่ต่อกลุ่ม: ปิดตารางเดิมแล้วเริ่มใหม่ (ยังได้หัวตารางซ้ำเพราะ table.header)
        if group-pagebreak and last-group != none { body.push(table.cell(colspan: shown.len(), stroke: none, pagebreak(weak: true))) }
        last-group = key
        body.push(table.cell(colspan: shown.len(), fill: gfill, strong(key)))
      }
    }
    for (i, c) in shown.enumerate() {
      body.push(table.cell(align: aligns.at(i) + horizon, _cell(r, c)))
    }
  }

  if want-total {
    for (i, c) in shown.enumerate() {
      let t = totals.at(i)
      body.push(table.cell(
        fill: tint(sd.brand, amount: 92%),
        align: aligns.at(i) + horizon,
        if t != none { strong(_fmt(t, c.at("format", default: "num2"))) } else if i == 0 { strong(total-label) } else { [] },
      ))
    }
  }

  table(
    columns: widths,
    stroke: 0.5pt + scolor,
    inset: (x: 5pt, y: 3pt),
    table.header(..shown.map(c => table.cell(fill: hfill, align: center + horizon, strong(c.at("label", default: c.at("field", default: "")))))),
    ..body,
  )
}

/// ตารางจาก sub-form (array ของ object ในเรคคอร์ดเดียว): #subtable(data.med_items, columns: (...))
#let subtable(value, ..args) = {
  let rows = if type(value) == array { value } else { () }
  if rows.len() == 0 { return [] }
  sdtable(rows, ..args)
}

// ─────────── หน้ากระดาษรายงาน (หัว-ท้ายทุกหน้า แบบ Report Factory) ───────────
/// #show: report-page()  ← ใช้ค่าที่ตั้งในแท็บ Setting ของรายงาน (ขนาดกระดาษ ขอบ ฟอนต์ ชื่อเรื่อง ลายน้ำ พื้นหลัง เลขหน้า วันที่พิมพ์)
/// ระบุ argument ตัวไหน = ทับค่าจากบิลเดอร์เฉพาะตัวนั้น · numbering-style: "thai" = หน้า ๑/๓ · "arabic" · "en" · none
#let report-page(
  title: auto,
  subtitle: "",
  print-date: auto,
  print-date-label: "พิมพ์วันที่",
  numbering-style: auto,
  every-page: auto,
  size: auto,
  flipped: auto,
  margin: auto,
  font: "TH Sarabun New",
  font-size: auto,
  watermark: auto,
  background: auto,
) = body => {
  let cfg = data.at("_report", default: (:))
  let pick(given, key, fallback) = if given != auto { given } else { cfg.at(key, default: fallback) }

  let title = pick(title, "title", "")
  let size = pick(size, "page_size", "a4")
  let flipped = if flipped != auto { flipped } else { cfg.at("orientation", default: "portrait") == "landscape" }
  let font-size = pick(font-size, "font_size", 14) * 1pt
  let print-date = pick(print-date, "page_date", true)
  let show-num = pick(numbering-style, "page_num", true)
  let numbering-style = if type(show-num) == str { show-num } else if show-num == true { "thai" } else { none }
  let every-page = if every-page != auto { every-page } else { cfg.at("show_header", default: "firstPage") == "everyPage" }
  let watermark = pick(watermark, "watermark", "")
  let background = pick(background, "background", "")
  // มีหัวกระดาษ (ชื่อเรื่อง/วันที่พิมพ์) ต้องเผื่อขอบบนให้พอ ไม่งั้นหัวทับเนื้อหา — ล้อ pdfmake ที่ดัน top เป็น 45pt
  let need-top = if title != "" or subtitle != "" or print-date { 48 } else { 20 }
  let margin = if margin != auto { margin } else {
    (left: cfg.at("margin_left", default: 20) * 1pt, top: calc.max(cfg.at("margin_top", default: 20), need-top) * 1pt,
     right: cfg.at("margin_right", default: 20) * 1pt, bottom: calc.max(cfg.at("margin_bottom", default: 20), 28) * 1pt)
  }
  // ขนาดกระดาษกำหนดเอง (Custom ในบิลเดอร์ = หน่วย pt)
  let cw = cfg.at("custom_width", default: none)
  let ch = cfg.at("custom_height", default: none)
  let custom = size == "custom" and cw != none and ch != none

  let foot = context {
    let n = counter(page).get().first()
    let total = counter(page).final().first()
    let label = if numbering-style == "thai" { "หน้า " + thainum(n) + "/" + thainum(total) } else if numbering-style == "arabic" { "หน้า " + str(n) + "/" + str(total) } else if numbering-style == "en" { "Page " + str(n) + " of " + str(total) } else { "" }
    if label != "" { align(right, text(size: 0.8em, fill: sd.muted, label)) }
  }
  let head = context {
    let first = counter(page).get().first() == 1
    if every-page or first {
      block(width: 100%, {
        if print-date {
          place(right, text(size: 0.78em, fill: sd.muted, print-date-label + " " + thaidate(datetime.today().display("[year]-[month]-[day]"))))
        }
        if title != "" { align(center, text(size: 1.3em, weight: "bold", title)) }
        if subtitle != "" { align(center, text(size: 0.95em, fill: sd.muted, subtitle)) }
        if title != "" or subtitle != "" { v(-0.3em); line(length: 100%, stroke: 0.6pt + sd.line) }
      })
    }
  }
  // ลายน้ำ + ภาพพื้นหลังจากบิลเดอร์ (ลายน้ำเอียง 45° จาง ๆ เหมือนรายงาน pdfmake)
  let back = {
    if background != "" { place(top + left, img(background, width: 100%, height: 100%)) }
    if watermark != "" {
      place(center + horizon, rotate(-45deg, text(size: 60pt, weight: "bold", fill: luma(50).transparentize(88%), watermark)))
    }
  }

  // set page ต้องเรียกนอก if — set rule ที่อยู่ใน block มีผลแค่ใน block นั้น (เจอจริง: ตั้ง A5 แล้วยังได้ A4)
  let page-size = if custom { (width: cw * 1pt, height: ch * 1pt) } else { (paper: size, flipped: flipped) }
  set page(..page-size, margin: margin, header: head, footer: foot, background: back)

  show: sdthai.with(font: font, size: font-size)
  body
}

/// ลายน้ำเฉพาะจุด (เมื่อไม่อยากใช้ค่าจากบิลเดอร์): #watermark-text("สำเนา")
#let watermark-text(label, size: 60pt, opacity: 88%, angle: -45deg) = place(
  center + horizon, rotate(angle, text(size: size, weight: "bold", fill: luma(50).transparentize(opacity), label)),
)

// ─────────── ข้อความ HTML (จาก html-input / col_html) ───────────
// server แปลง HTML เป็น markup ให้แล้ว (data._html) — ที่นี่แค่หยิบมาแสดง
// ไม่เจอ = แสดงเป็นข้อความธรรมดา (ไม่โชว์แท็กดิบ)
#let _html-map = data.at("_html", default: (:))
#let _strip-tags(s) = s.replace(regex("<[^>]*>"), "").replace("&nbsp;", " ").replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")

/// #html(data.note) · #html(data.header_html)
#let html(value) = {
  if value == none { return [] }
  let key = str(value)
  let markup = _html-map.at(key, default: none)
  if markup == none { _strip-tags(key) } else { eval(markup, mode: "markup") }
}

/// รูปทั้งหมดใน field (field รูปเก็บได้หลายไฟล์ — #img เอารูปแรกอย่างเดียว)
/// #imgs(data.photos, width: 4cm, columns: 3)
#let imgs(value, width: 4cm, columns: 3, gutter: 4pt, ..args) = {
  let items = if type(value) == array { value } else if type(value) == str { str(value).split(", ") } else { (value,) }
  let cells = items.filter(v => v != none and v != "").map(v => img(v, width: width, ..args))
  if cells.len() == 0 { return [] }
  grid(columns: calc.min(columns, cells.len()), column-gutter: gutter, row-gutter: gutter, ..cells)
}

// ─────────── ชุดข้อมูลเสริม (หลาย provider ในรายงานเดียว) ───────────
// รายงานผูก provider หลักได้ตัวเดียว — ชุดอื่นประกาศในโค้ดตรงนี้ แล้ว server โหลดให้ก่อน compile
// อ้างด้วย "ชื่อ provider" (sql_name) หรือ "_id ของ provider" ก็ได้ · ต้องเป็นข้อความตรง ๆ ในวงเล็บ (ไม่ใช่ตัวแปร)
// สิทธิ์ถูกตรวจทุกชุดเหมือน provider หลัก · ไม่มีสิทธิ์/ไม่พบ = ได้ชุดว่าง รายงานไม่พัง
//
//   #let ยา = dataset("stock_balance")          // → array ของแถว
//   #let หัวบิล = dataset-first("6ab29b61...")  // → แถวแรก (ใช้กับ provider ที่คืนแถวเดียว)
//   #sdtable(ยา, columns: (...))
#let _sets = data.at("_sets", default: (:))

/// ทุกแถวของชุดข้อมูลที่ระบุ
#let dataset(name) = _sets.at(name, default: ())

/// แถวแรกของชุดข้อมูล (ไม่มีข้อมูล = dictionary ว่าง — อ่าน field ด้วย .at(key, default: "") ได้)
#let dataset-first(name) = {
  let rows = dataset(name)
  if rows.len() > 0 { rows.at(0) } else { (:) }
}
