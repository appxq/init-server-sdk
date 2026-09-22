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
  let frac = "0" * (digits - frac.len()) + frac
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
  if type(value) == dictionary { value = value.at("url", default: value.at("filePath", default: none)) }
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
