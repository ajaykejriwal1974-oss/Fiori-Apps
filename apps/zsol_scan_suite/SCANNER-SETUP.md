# Scan Suite — handheld scanner setup

The Scan Suite runs in Chrome, so the device's scan engine has to hand the
barcode to the browser **as keyboard input** (a "keyboard wedge"). Intent or
broadcast output never reaches a web page. The app (from 06.09.2026) accepts
all of the wedge variants — characters typed one by one or injected as one
block, with an Enter suffix, a Tab suffix or no suffix at all — and routes a
trigger pull into the active screen's scan field even when no field is
focused. The device settings below make that reliable.

## Zebra MC2200 (Android, DataWedge)

The MC2200 has **no camera**; its imager (SE4100) is the yellow trigger.
The app hides the camera button when the browser reports no camera.

1. Open the **DataWedge** app (App drawer → DataWedge).
2. Use **Profile0 (default)** or create a profile and associate it:
   ⋮ → *New profile* → name `KGPL Scan` → open it → **Associated apps** →
   ⋮ → *New app/activity* → `com.android.chrome` → `*`.
   If the suite is installed to the home screen (PWA), also add the entry
   that shows the app's name/icon ("KGPL Scan", package
   `org.chromium.webapk.…`).
3. **Profile enabled** ✔
4. **Barcode input** ✔ — Scanner selection: *Internal Imager* (or Auto).
   *Decoders*: keep Code 128, Code 39, EAN/UPC, Interleaved 2 of 5, QR
   Code, Data Matrix enabled. *Scan params*: Decode Audio Feedback on
   (beep), Decoding LED on. *Illumination mode*: On; *Aim type*: Trigger
   (this is the "scanning light" — if it never lights up, Barcode input
   is off or the profile is not associated with Chrome).
5. **Keystroke output** ✔ and inside it:
   - *Key event options* → **Send Characters As Events ✔**
     (without this DataWedge injects the text through the input method;
     the app copes, but the trigger then only works while a field has
     focus).
   - *Inter character delay*: 0.
   - *Basic data formatting* → **Send data ✔, Send ENTER key ✔**
     (Send TAB key off).
6. **Intent output** ✘ (off). **IP output** ✘ (off).
7. Back out; open the suite in Chrome, go to Location Scan, and pull the
   trigger on any box label with no field selected — the box field should
   fill and the scan post immediately.

## Urovo DT50S (Android, Urovo scan service)

1. Settings → **Scanner** (on some builds *Scan Settings* / the *Scanner*
   app in the drawer).
2. **Enable scanner** ✔; **Trigger**: hardware scan keys.
3. **Output / Input mode**: choose the *keyboard / key-event* mode —
   labelled **"Analog keyboard"**, **"Simulate keystrokes"** or **"Key
   events"** depending on firmware. Avoid *Broadcast / Intent* (the page
   never sees it) and *Clipboard*. *Input method* mode also works with the
   app but only while a field has focus.
4. **Suffix / Terminator**: **Enter** (`\n`). No prefix.
5. **Scan light / Illumination** ✔ and **Aim** ✔ (this is the red aiming
   light; if it does not come on the scanner service is disabled or the
   trigger keys are remapped). **Sound** ✔ for the beep.
6. **Continuous scan** ✘ (off) — the app has its own continuous camera
   mode and expects one code per trigger pull.
7. Symbologies: Code 128, Code 39, EAN/UPC, ITF-14 / Interleaved 2 of 5,
   QR Code, Data Matrix on.

## What the app now does with a scan (any device)

- A code that arrives as one block, or as fast keystrokes, is processed
  150 ms after the last character even if the device sends no Enter.
- A Tab suffix counts as Enter; a late Enter after the app already
  processed the code is ignored, so nothing is posted twice.
- A trigger pull with no field focused goes to the active screen's scan
  field (Location Scan: box, then location; HU Movement: box; Physical
  Inventory: box; Packing List: box, then order; Create Challan: order;
  Security Loading: box, then challan).
- HU Movement pads a 10-digit box number to the 20-digit handling-unit
  number SAP stores (VEKP-EXIDV), so a carton label scans straight in; a
  20-digit HU barcode is accepted unchanged.

## If the trigger still does nothing in Chrome

- Zebra: DataWedge → the profile → check *Associated apps* really lists
  Chrome; check the profile is enabled and not overridden by another
  profile associated to Chrome.
- Any device: open the Android **Settings → System → Languages & input →
  Physical keyboard** — the scanner service often appears there; "Show
  virtual keyboard" can stay on.
- Test outside the suite: open any text field (Chrome address bar), pull
  the trigger. If nothing appears, the device is not set to keyboard
  output; if the code appears without a line break, the suffix is not
  set (the app still processes it, after 150 ms).
