#!/usr/bin/env python3
# Build "Dyeing Production & QC - Operator Manual" PDF for the KGPL Scan Suite.
# Screenshots come from manual_shots.js (shots/*.png, 420px viewport @2x):
#   cd docs && node manual_shots.js && python3 build_manual_pdf.py
import os
from PIL import Image as PILImage
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph,
                                Spacer, Table, TableStyle, KeepTogether, Image,
                                PageBreak, NextPageTemplate)

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, "shots")
OUT = os.path.join(HERE, "Dyeing-Production-QC-Operator-Manual.pdf")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

BLUE   = colors.HexColor("#1857a4")
DARK   = colors.HexColor("#20262e")
GREY   = colors.HexColor("#5b6570")
LIGHT  = colors.HexColor("#eef3f9")
LINE   = colors.HexColor("#c9d4e0")
GREEN  = colors.HexColor("#1e7a34")
AMBER  = colors.HexColor("#9a6700")
RED    = colors.HexColor("#b02a2a")
PALEGREEN = colors.HexColor("#e9f6ec")
PALEAMBER = colors.HexColor("#fff6df")

S = {}
S['title'] = ParagraphStyle('title', fontName='Helvetica-Bold', fontSize=24, leading=29, textColor=DARK, spaceAfter=4)
S['subtitle'] = ParagraphStyle('subtitle', fontName='Helvetica', fontSize=11.5, leading=16, textColor=GREY, spaceAfter=14)
S['h1'] = ParagraphStyle('h1', fontName='Helvetica-Bold', fontSize=16, leading=20, textColor=BLUE, spaceBefore=4, spaceAfter=8)
S['h2'] = ParagraphStyle('h2', fontName='Helvetica-Bold', fontSize=11.5, leading=15, textColor=DARK, spaceBefore=10, spaceAfter=4)
S['body'] = ParagraphStyle('body', fontName='Helvetica', fontSize=9.6, leading=13.8, textColor=DARK, alignment=TA_LEFT, spaceAfter=5)
S['step'] = ParagraphStyle('step', parent=S['body'], leftIndent=18, bulletIndent=2, spaceAfter=3.5)
S['bullet'] = ParagraphStyle('bullet', parent=S['body'], leftIndent=14, bulletIndent=4, spaceAfter=3)
S['note'] = ParagraphStyle('note', parent=S['body'], fontSize=8.9, leading=12.6, textColor=DARK, spaceAfter=0)
S['cap'] = ParagraphStyle('cap', fontName='Helvetica-Oblique', fontSize=8.2, leading=11, textColor=GREY, alignment=TA_CENTER, spaceBefore=3, spaceAfter=8)
S['cell'] = ParagraphStyle('cell', fontName='Helvetica', fontSize=8.6, leading=11.8, textColor=DARK)
S['cellb'] = ParagraphStyle('cellb', fontName='Helvetica-Bold', fontSize=8.6, leading=11.8, textColor=colors.white)
S['cellk'] = ParagraphStyle('cellk', fontName='Helvetica-Bold', fontSize=8.6, leading=11.8, textColor=DARK)
S['toc'] = ParagraphStyle('toc', parent=S['body'], fontSize=10.2, leading=16, spaceAfter=0)
S['flow'] = ParagraphStyle('flow', fontName='Helvetica-Bold', fontSize=8.4, leading=10.5, textColor=DARK, alignment=TA_CENTER)
S['flowsub'] = ParagraphStyle('flowsub', fontName='Helvetica', fontSize=7.4, leading=9.5, textColor=GREY, alignment=TA_CENTER)

W_TEXT = 168 * mm   # frame width

def P(t, st='body'): return Paragraph(t, S[st])
def H1(t): return Paragraph(t, S['h1'])
def H2(t): return Paragraph(t, S['h2'])
def B(t): return Paragraph(t, S['bullet'], bulletText='•')
def steps(items):
    out = []
    for i, t in enumerate(items, 1):
        out.append(Paragraph(t, S['step'], bulletText='%d.' % i))
    return out

def box(txt, bg=LIGHT, border=LINE, title=None):
    body = []
    if title:
        body.append(Paragraph('<b>%s</b>' % title, S['note']))
    body.append(Paragraph(txt, S['note']))
    t = Table([[body]], colWidths=[W_TEXT])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), bg), ('BOX', (0,0), (-1,-1), 0.7, border),
        ('LEFTPADDING', (0,0), (-1,-1), 9), ('RIGHTPADDING', (0,0), (-1,-1), 9),
        ('TOPPADDING', (0,0), (-1,-1), 6), ('BOTTOMPADDING', (0,0), (-1,-1), 7),
    ]))
    return t

def tip(txt): return box(txt, LIGHT, LINE, 'Tip')
def warn(txt): return box(txt, PALEAMBER, colors.HexColor('#e2c777'), 'Take care')
def good(txt): return box(txt, PALEGREEN, colors.HexColor('#9ad0a6'))

def ref_table(header, rows, widths, key_first=True):
    data = [[Paragraph(h, S['cellb']) for h in header]]
    for r in rows:
        cells = []
        for i, c in enumerate(r):
            cells.append(Paragraph(c, S['cellk'] if (i == 0 and key_first) else S['cell']))
        data.append(cells)
    t = Table(data, colWidths=widths, repeatRows=1)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), BLUE),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, LIGHT]),
        ('GRID', (0,0), (-1,-1), 0.4, LINE), ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('LEFTPADDING', (0,0), (-1,-1), 6), ('RIGHTPADDING', (0,0), (-1,-1), 6),
        ('TOPPADDING', (0,0), (-1,-1), 4), ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ]))
    return t

TRIMMED = os.path.join(HERE, "shots", "_trim"); os.makedirs(TRIMMED, exist_ok=True)
def trimmed(name):
    """Full-page shots end in a long empty page background; cut it off (keep 24px)."""
    src = os.path.join(SHOTS, name + '.png'); dst = os.path.join(TRIMMED, name + '.png')
    im = PILImage.open(src).convert('RGB'); w, h = im.size
    bg = im.getpixel((w - 3, h - 3))
    px = im.load(); last = h - 1
    while last > 0:
        row_blank = all(abs(px[x, last][0]-bg[0]) < 6 and abs(px[x, last][1]-bg[1]) < 6 and abs(px[x, last][2]-bg[2]) < 6 for x in range(0, w, 7))
        if not row_blank: break
        last -= 1
    im.crop((0, 0, w, min(h, last + 26))).save(dst)
    return dst

def shot(name, width_mm, max_h_mm=None):
    """Image scaled to width, capped at max height (keeps aspect)."""
    p = trimmed(name)
    im = PILImage.open(p); w, h = im.size
    tw = width_mm * mm; th = tw * h / w
    if max_h_mm and th > max_h_mm * mm:
        th = max_h_mm * mm; tw = th * w / h
    img = Image(p, width=tw, height=th)
    return img

def framed(flowable, w):
    t = Table([[flowable]], colWidths=[w])
    t.setStyle(TableStyle([('BOX', (0,0), (-1,-1), 0.6, LINE), ('BACKGROUND', (0,0), (-1,-1), colors.white),
                           ('LEFTPADDING', (0,0), (-1,-1), 0), ('RIGHTPADDING', (0,0), (-1,-1), 0),
                           ('TOPPADDING', (0,0), (-1,-1), 0), ('BOTTOMPADDING', (0,0), (-1,-1), 0),
                           ('ALIGN', (0,0), (-1,-1), 'CENTER')]))
    return t

def fig(name, caption, width_mm=70, max_h_mm=120):
    img = shot(name, width_mm, max_h_mm)
    return KeepTogether([framed(img, img.drawWidth), Paragraph(caption, S['cap'])])

def fig_row(items, gap=4):
    """items: list of (name, caption, width_mm, max_h_mm). Side by side, centred."""
    cells = []; widths = []
    for name, cap, w_mm, mh in items:
        img = shot(name, w_mm, mh)
        cells.append([framed(img, img.drawWidth), Paragraph(cap, S['cap'])])
        widths.append(img.drawWidth + gap * mm)
    t = Table([cells], colWidths=widths)
    t.setStyle(TableStyle([('VALIGN', (0,0), (-1,-1), 'TOP'), ('ALIGN', (0,0), (-1,-1), 'CENTER'),
                           ('LEFTPADDING', (0,0), (-1,-1), gap*mm/2), ('RIGHTPADDING', (0,0), (-1,-1), gap*mm/2),
                           ('TOPPADDING', (0,0), (-1,-1), 0), ('BOTTOMPADDING', (0,0), (-1,-1), 0)]))
    return t

def text_beside_fig(paras, name, width_mm=62, max_h_mm=110):
    img = shot(name, width_mm, max_h_mm)
    left = W_TEXT - img.drawWidth - 6*mm
    t = Table([[paras, [framed(img, img.drawWidth)]]], colWidths=[left, img.drawWidth + 6*mm])
    t.setStyle(TableStyle([('VALIGN', (0,0), (-1,-1), 'TOP'),
                           ('LEFTPADDING', (0,0), (0,0), 0), ('RIGHTPADDING', (0,0), (0,0), 6),
                           ('LEFTPADDING', (1,0), (1,0), 6*mm), ('RIGHTPADDING', (1,0), (1,0), 0),
                           ('TOPPADDING', (0,0), (-1,-1), 0), ('BOTTOMPADDING', (0,0), (-1,-1), 0)]))
    return t

# ---------------------------------------------------------------- page furniture
FOOT = "KGPL Scan Suite — Dyeing Production & QC Operator Manual · plant 2002 · September 2026"
def on_page(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(LINE); canvas.setLineWidth(0.5)
    canvas.line(21*mm, 14*mm, 189*mm, 14*mm)
    canvas.setFont('Helvetica', 8); canvas.setFillColor(GREY)
    canvas.drawString(21*mm, 9.5*mm, FOOT)
    canvas.drawRightString(189*mm, 9.5*mm, "Page %d" % doc.page)
    canvas.restoreState()

def on_cover(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(BLUE); canvas.rect(0, 250*mm, 210*mm, 47*mm, stroke=0, fill=1)
    canvas.setFillColor(colors.white); canvas.setFont('Helvetica-Bold', 26)
    canvas.drawString(21*mm, 276*mm, "KGPL Scan Suite")
    canvas.setFont('Helvetica', 12.5)
    canvas.drawString(21*mm, 266*mm, "Operator Manual · Dyeing Production & Quality Control · Plant 2002")
    canvas.setFont('Helvetica', 8); canvas.setFillColor(GREY)
    canvas.drawString(21*mm, 9.5*mm, FOOT)
    canvas.restoreState()

doc = BaseDocTemplate(OUT, pagesize=A4, leftMargin=21*mm, rightMargin=21*mm, topMargin=18*mm, bottomMargin=20*mm,
                      title="Dyeing Production & QC - Operator Manual", author="KGPL Scan Suite",
                      subject="WIP Batch, Job Card, QC Raw Material, QC Post Dyeing, QC Post Winding")
frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id='f', leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
cover_frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, 222*mm, id='c', leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
doc.addPageTemplates([PageTemplate(id='cover', frames=[cover_frame], onPage=on_cover),
                      PageTemplate(id='body', frames=[frame], onPage=on_page)])

story = []

# ================================================================ COVER
story += [NextPageTemplate('body')]
story.append(Spacer(1, 6*mm))
story.append(P("This manual is for the people who run dyeing production in plant 2002 and record its quality checks "
               "on the phone or tablet: the dyeing supervisor, the winding supervisor and the QC lab. It covers the five "
               "screens of the KGPL Scan Suite that carry a greige lot from the store to a finished, inspected dyed batch:"))
story.append(Spacer(1, 2*mm))
story.append(ref_table(["Screen", "Who uses it", "What it does in SAP"], [
    ["QC Raw Material", "QC lab", "Records results and the usage decision on the greige inspection lot (type 01) and releases the greige from the raw store DRM1 to the production floor DPR1 (movement 301)."],
    ["WIP Batch", "Dyeing supervisor", "Draws a dyeing batch (plant batch) from a released production order, using the greige lot released by QC."],
    ["Job Card", "Dyeing supervisor / planning", "Ties the batch to a customer schedule and the machines, creates the job card and prints it with its barcode and dyeing recipe."],
    ["QC Post Dyeing", "QC lab", "Inspects the dyed batch (lot type 03), posts the usage decision and confirms the dyeing operation 0010 of the production order."],
    ["QC Post Winding", "QC lab", "Inspects the wound batch (lot type 04), posts the usage decision and confirms the winding operation 0020. The batch is then ready for packing."],
], [34*mm, 36*mm, 98*mm]))
story.append(Spacer(1, 6*mm))
toc = [P("Contents", 'h2')]
for n, t in [("1", "How the screens fit together"), ("2", "Signing in, scanning and reading the screen"),
             ("3", "QC Raw Material — release greige to production"), ("4", "WIP Batch — draw a dyeing batch from an order"),
             ("5", "Job Card — schedule, machines, print"), ("6", "QC Post Dyeing — inspect and confirm operation 0010"),
             ("7", "QC Post Winding — inspect and confirm operation 0020"), ("8", "Messages you may see and what to do"),
             ("9", "Quick reference by role")]:
    toc.append(Paragraph("<b>%s</b>&nbsp;&nbsp;%s" % (n, t), S['toc']))
toc.append(Spacer(1, 4*mm))
toc.append(Paragraph("The home screen. Only the tiles your user has been granted are shown.", S['note']))
story.append(text_beside_fig(toc, '01_home', 56, 95))
story.append(PageBreak())

# ================================================================ 1. PROCESS
story.append(H1("1. How the screens fit together"))
story.append(P("A dyed batch passes through the same stations every time. Each station has its own screen, and each screen "
               "only offers what is waiting for it: QC Raw Material lists the open greige lots, WIP Batch lists the orders "
               "that can still take a batch, Job Card lists the batches without a card, and the two production QC screens "
               "open with the job cards that are waiting for their inspection. If a screen shows nothing to do, the step "
               "before it has not been completed yet."))

def flow_cell(title, sub, bg):
    t = Table([[Paragraph(title, S['flow'])], [Paragraph(sub, S['flowsub'])]], colWidths=[26*mm])
    t.setStyle(TableStyle([('BACKGROUND', (0,0), (-1,-1), bg), ('BOX', (0,0), (-1,-1), 0.6, LINE),
                           ('LEFTPADDING', (0,0), (-1,-1), 3), ('RIGHTPADDING', (0,0), (-1,-1), 3),
                           ('TOPPADDING', (0,0), (0,0), 5), ('BOTTOMPADDING', (0,0), (0,0), 1),
                           ('TOPPADDING', (0,1), (0,1), 0), ('BOTTOMPADDING', (0,1), (0,1), 5)]))
    return t
arrow = Paragraph("→", ParagraphStyle('arr', fontName='Helvetica-Bold', fontSize=14, textColor=GREY, alignment=TA_CENTER))
row1 = [flow_cell("Greige receipt", "store DRM1 · SAP creates lot type 01", LIGHT), arrow,
        flow_cell("QC Raw Material", "results · UD · release 301 to DPR1", PALEGREEN), arrow,
        flow_cell("WIP Batch", "batch drawn from the production order", PALEGREEN), arrow,
        flow_cell("Job Card", "schedule + machines · print barcode", PALEGREEN)]
row2 = [flow_cell("Dyeing", "on the dyeing machine of the card", LIGHT), arrow,
        flow_cell("QC Post Dyeing", "lot type 03 · UD · confirm op 0010", PALEGREEN), arrow,
        flow_cell("Winding", "on the winding machine of the card", LIGHT), arrow,
        flow_cell("QC Post Winding", "lot type 04 · UD · confirm op 0020", PALEGREEN)]
row3 = [flow_cell("Packing", "cartons · Packing List screen", LIGHT), arrow,
        flow_cell("Security Loading", "cartons scanned at the gate", LIGHT), arrow,
        flow_cell("Create Challan", "delivery + goods issue", LIGHT), Spacer(1,1), Spacer(1,1)]
ft = Table([row1, row2, row3], colWidths=[26*mm, 8*mm, 26*mm, 8*mm, 26*mm, 8*mm, 26*mm] , rowHeights=None)
ft.setStyle(TableStyle([('VALIGN', (0,0), (-1,-1), 'MIDDLE'), ('ALIGN', (0,0), (-1,-1), 'CENTER'),
                        ('TOPPADDING', (0,0), (-1,-1), 5), ('BOTTOMPADDING', (0,0), (-1,-1), 5),
                        ('LEFTPADDING', (0,0), (-1,-1), 0), ('RIGHTPADDING', (0,0), (-1,-1), 0)]))
story.append(ft)
story.append(Paragraph("Green boxes are the screens in this manual; grey boxes are steps done on the floor or on other screens of the suite.", S['cap']))

story.append(H2("Who does what, in order"))
story.append(ref_table(["Step", "Who", "Screen", "Result"], [
    ["1", "Store", "SAP goods receipt (outside the app)", "Greige arrives in DRM1. SAP opens an inspection lot of type 01 for the supplier batch."],
    ["2", "QC lab", "QC Raw Material", "Results recorded, usage decision posted, greige released 301 DRM1 → DPR1. Only now is the lot 'free' for a batch."],
    ["3", "Dyeing supervisor", "WIP Batch", "Batch created against the production order; quantity, cheeses and the greige lot recorded."],
    ["4", "Dyeing supervisor", "Job Card", "Schedule and machines chosen, job card created and printed. The barcode is the batch number."],
    ["5", "Dyeing floor", "—", "The batch is dyed on the machine named on the card."],
    ["6", "QC lab", "QC Post Dyeing", "Shade / moisture / denier recorded, usage decision posted, operation 0010 confirmed. The card moves to the winding list."],
    ["7", "Winding floor", "—", "The batch is wound."],
    ["8", "QC lab", "QC Post Winding", "Results recorded, usage decision posted, operation 0020 confirmed. The batch leaves both QC lists and can be packed."],
], [12*mm, 30*mm, 44*mm, 82*mm]))
story.append(Spacer(1, 3*mm))
story.append(tip("Do QC Raw Material <b>before</b> WIP Batch, not after. The WIP Batch screen proposes the greige lot from what is "
                 "free in DPR1 / JWPR; a lot still sitting in DRM1 under inspection is not offered, and the batch cannot be created "
                 "from it."))
story.append(PageBreak())

# ================================================================ 2. BASICS
story.append(H1("2. Signing in, scanning and reading the screen"))
story.append(P("Open the Scan Suite on the phone or tablet and sign in with your own user name and password. Your name "
               "appears at the top right of every screen and every posting is recorded under it. The home screen shows only "
               "the tiles you have been granted — the features are called WIPBATCH, JOBCARD, QCRAW, QCDYE and QCWIND "
               "in the user administration. If a tile you need is missing, ask the administrator to grant it; you do not need "
               "a new SAP user."))
story.append(H2("Things that work the same on every screen"))
story += [
    B("<b>Back arrow</b> (top left) returns to the home screen. <b>Sign out</b> is at the bottom of the home screen."),
    B("<b>Camera button</b> next to an input field opens the barcode scanner. Point it at the job card barcode, the batch "
      "label or the supplier lot; the number is filled in and looked up straight away. Tap X to close the camera. You can "
      "always type the number instead and press Enter."),
    B("<b>Plant</b> is pre-filled with 2002 when your user has that plant; the screens remember the last plant you used."),
    B("<b>Tap a row</b> in any list to select it. The row you tapped gets a blue border and the screen scrolls on to the next step."),
    B("<b>Green card</b> = the thing you selected is in order; <b>amber card</b> = selected, but with a warning to read; "
      "<b>green text</b> under a button = the posting succeeded; <b>red text</b> = it was refused, and the text is SAP's own reason."),
    B("<b>Change &hellip;</b> links inside a green card undo the selection and bring the list back."),
    B("The <b>log</b> at the bottom of a screen keeps the last postings of this session, newest first, so you can see what you have done."),
]
story.append(Spacer(1, 2*mm))
story.append(warn("Every green message means SAP has already posted the document. There is no undo button in the app: a "
                  "wrong usage decision, release or confirmation has to be reversed in SAP by the QC or production office. "
                  "Read the card before you press the blue button."))
story.append(PageBreak())

# ================================================================ 3. QC RAW
story.append(H1("3. QC Raw Material — release greige to production"))
story.append(P("<b>When:</b> as soon as greige has been received into the raw store (DRM1) and before the dyeing supervisor "
               "wants to draw a batch from it. <b>Who:</b> the QC lab. <b>What SAP does:</b> the results and usage decision "
               "are posted on the type-01 inspection lot, and the release posts a stock transfer, movement 301, from DRM1 to "
               "the production floor DPR1 under the same (or a new) batch."))
story.append(H2("Step by step"))
story += steps([
    "Tap <b>QC Raw Material</b> on the home screen.",
    "The screen opens with <b>Greige Batches Waiting for QC</b>: every greige lot of the plant still waiting for a decision, "
    "batch number on the left and the <b>quantity to test</b> on the right, with the totals (batches, kg to test) above the list. "
    "Tap the batch you are inspecting — or scan the supplier lot / batch label with the camera, or type it and tap <b>Find Lot</b>. "
    "<b>Refresh</b> (or <b>Open Lots</b>) re-reads the list.",
    "Check the green <b>lot card</b>: material, batch (with the supplier's batch in brackets), quantity and the date the lot was "
    "created. If it is the wrong lot, tap <b>Change lot</b>.",
    "Under <b>Characteristics</b>, enter the measured value of each characteristic (target and limits are printed under its "
    "name) and tap <b>Save</b>. A saved row turns green and says <i>Saved</i>. Enter a defect count only if there were defects. "
    "A characteristic with a code instead of a value takes the code and code group (for example OK / ZSHADE).",
    "Optionally type an <b>operation remark</b>, then tap <b>Record Operation</b> to close the results recording on the lot.",
    "Under <b>Usage Decision</b>, tap the decision code (see the table below), add a reason if you want, and tap <b>Post Usage Decision</b>.",
    "Under <b>Release Greige to Production</b>, check the quantity (pre-filled with the lot quantity) and posting date. Leave "
    "<b>To batch</b> blank to keep the same batch name on the floor, or type a new batch name. Tap <b>Release to Production</b>.",
    "The message <i>Greige released to the production floor: &hellip; DRM1 -&gt; DPR1</i> confirms the posting. The lot "
    "disappears from Open Lots and the greige is now offered by WIP Batch.",
])
story.append(Spacer(1, 2*mm))
story.append(fig_row([('12a_qr_pendcard', 'The screen opens with the greige batches waiting and the kg to test.', 52, 105),
                      ('13a_qr_lotbox', 'The lot card after a tap or a scan.', 52, 105),
                      ('13b_qr_charcard', 'Enter each value and Save; saved rows turn green.', 52, 105)]))
story.append(fig_row([('13c_qr_udcard', 'Pick the decision code and post it.', 52, 105),
                      ('14a_qr_finalcard', 'Release: movement 301, DRM1 to DPR1, quantity pre-filled.', 52, 105),
                      ('14b_qr_log', 'The log keeps what you posted.', 52, 105)]))
story.append(H2("Usage decision codes"))
story.append(ref_table(["Code", "Meaning", "Use it when"], [
    ["A", "Accept", "All results within limits."],
    ["A1", "Accept with deviation", "A result is outside the limit but the lot is usable; say why in the reason."],
    ["SP", "Special", "Special release agreed with production or the customer."],
    ["CLQ", "Claim / lab query", "The lot is held for a supplier claim or a lab query. It is not released."],
    ["DG", "Downgrade", "Usable, but in a lower grade."],
    ["JL", "Job lot", "To be sold or used as a job lot."],
    ["PQ", "Poor quality", "Rejected."],
    ["RD / ST", "Re-dye / Strip &amp; re-dye", "Post-dyeing and post-winding only: the batch goes back to dyeing. Not offered on raw material."],
], [18*mm, 42*mm, 108*mm]))
story.append(Spacer(1, 2*mm))
story.append(tip("The order results → Record Operation → Usage Decision → Release is the order SAP expects. If a "
                 "step is refused (red text), the reason is SAP's: most often a characteristic still has no result, or the "
                 "usage decision has not been posted yet. Fix that step and try again."))
story.append(PageBreak())

# ================================================================ 4. WIP BATCH
story.append(H1("4. WIP Batch — draw a dyeing batch from an order"))
story.append(P("<b>When:</b> the greige has been released by QC and a released production order exists for the dyed "
               "material. <b>Who:</b> the dyeing supervisor. <b>What it does:</b> creates the plant batch (the number that "
               "follows the yarn through dyeing, winding and packing) against the production order, with its quantity, "
               "number of cheeses and the greige lot it was drawn from."))
story.append(H2("New Batch"))
story += steps([
    "Tap <b>WIP Batch</b>. The <b>New Batch</b> tab is open. Plant is pre-filled.",
    "Scan or type the <b>production order</b> and tap <b>Load Order</b> — or tap <b>Open Orders</b> to list every released "
    "order in the plant that can still take a batch, with the open quantity on the right, and tap one.",
    "Read the green <b>order card</b>: dyed material, order quantity, how much is already batched and how much is still open, "
    "the grey yarn, and the <b>lot proposed</b> — the greige lot that is free in DPR1 / JWPR, with its free quantity. "
    "An amber card means the order cannot take a batch; the card says why (not released, fully batched, no free greige).",
    "The form below is pre-filled from the order: batch date (today), lot number, grey code and dyed code. Enter the "
    "<b>quantity</b> of greige going into the dye bath and the number of <b>cheeses</b>. The quantity may not exceed what is "
    "still open on the order.",
    "Tap <b>Create Batch</b>. The green box <i>Batch 2120017074 created</i> shows the new batch number, and the "
    "<b>Create Job Card</b> button takes you straight to the Job Card screen with this batch loaded.",
])
story.append(Spacer(1, 2*mm))
story.append(fig_row([('02_wb_orders', 'Open Orders: released orders with quantity still to batch.', 54, 110),
                      ('03b_wb_formcard', 'The form, pre-filled from the order; only quantity and cheeses are typed.', 54, 110),
                      ('04a_wb_donebox', 'The new batch number, and the shortcut to its job card.', 54, 110)]))
story.append(KeepTogether([H2("Batches tab"), text_beside_fig([
    P("The <b>Batches</b> tab lists the batches of the plant for the last 30 days (change the days, or filter to one order "
      "or one batch number). <b>Open batches only</b> is ticked by default. The four counters give the number of batches, "
      "how many are open, how many have <b>no job card</b> yet, and the total kilograms."),
    P("Each row has buttons for the next thing to do with that batch: <b>Job Card</b> when it has none yet, <b>Print Card</b> "
      "when it has one, and <b>Close</b> to close a batch that will not be processed further (closed batches leave every list, "
      "including the QC lists)."),
    tip("The <b>No job card</b> badge is the dyeing supervisor's to-do list: every batch there still has to be tied to a "
        "schedule and a machine before it can be dyed."),
], '05_wb_list', 60, 125)]))
story.append(PageBreak())

# ================================================================ 5. JOB CARD
story.append(H1("5. Job Card — schedule, machines, print"))
story.append(P("<b>When:</b> a batch exists and is about to go to the dye house. <b>Who:</b> the dyeing supervisor or "
               "planning. <b>What it does:</b> ties the batch to one customer <b>schedule</b> (sales order item, shade, dyeing "
               "date) and to the dyeing machine (and optionally the winding machine), then prints the job card with the "
               "batch barcode and the dyeing recipe. The job card number is the batch number, so the same barcode is "
               "scanned at every later station."))
story.append(H2("New Job Card"))
story += steps([
    "Tap <b>Job Card</b> (or <b>Create Job Card</b> right after creating the batch). Plant is pre-filled.",
    "Scan the batch label or type the batch number and tap <b>Load Batch</b> — or tap <b>Free Batches</b> to list the "
    "batches of the plant that have no job card yet, and tap one.",
    "The green <b>batch card</b> shows the dyed material, quantity, cheeses, grey yarn and order. Tap <b>Change batch</b> if it is the wrong one.",
    "<b>Schedule:</b> the list shows the open schedules for this dyed material with the kilograms still to batch on the right "
    "(customer, card, shade, scheduled quantity, quantity already batched and dyeing date underneath). Schedules that are "
    "already fully batched are hidden — tick <b>Show completed schedules too</b> to see them. Tap the schedule, or scan / "
    "type its number. The list folds away behind a green <b>schedule box</b> and the screen scrolls on to the machines. "
    "<b>Change schedule</b> brings the list back.",
    "<b>Dyeing machine</b> (required): tap the machine's chip, or type its work-centre code. Chips show the code and the machine name.",
    "<b>Winding machine</b> (optional): tap a chip if the winding machine is already known; it can be left blank.",
    "Tap <b>Create Job Card</b>. The batch card turns into <i>Job card &hellip; created</i> and the <b>print preview</b> opens below.",
    "Check the preview, then tap <b>Print Job Card</b>. The phone's print dialog opens; choose the office printer. The card "
    "carries the barcode, the batch and order facts, the customer and sales order, the machines and the <b>dyeing recipe</b> "
    "with the components, ratios and remarks, plus signature lines for dyeing, winding and packing.",
])
story.append(Spacer(1, 2*mm))
story.append(fig_row([('06_jc_free', 'Free Batches: batches with no job card yet.', 54, 110),
                      ('07b_jc_schedcard', 'Open schedules for this material, with the KG left to batch.', 54, 110),
                      ('08b_jc_machcard', 'Pick the dyeing machine; the winding machine is optional.', 54, 110)]))
story.append(fig_row([('08a_jc_schedbox', 'After the tap the schedule sits in a green box.', 62, 90),
                      ('11a_jc_printcard', 'The printed job card: barcode, facts, recipe, signatures.', 92, 150)]))
story.append(H2("Warnings on the schedule"))
story += [
    B("<b>Amber schedule box</b> — the schedule you typed or scanned is already batched beyond its quantity (for example "
      "<i>77.4 KG over the scheduled quantity</i>). You can still use it, but planning should know."),
    B("<b>Schedule &hellip; is for D999&hellip; - this batch dyes D300072&hellip;</b> — the schedule is for another dyed material and is refused."),
    B("<b>N fully batched schedule(s) not shown</b> — the note under the list; nothing is wrong, these schedules are simply complete."),
]
story.append(H2("Job Cards tab"))
story.append(P("The <b>Job Cards</b> tab lists the cards of the plant for the last 30 days, optionally filtered to one job card "
               "or batch number (scan it). Each row carries its stage badge: <b>Open</b> (not dyed yet), <b>Dyed</b> (dyeing "
               "confirmed, not wound), <b>Wound</b> (both confirmed) or <b>Closed</b>. Tap a row to open its preview and "
               "reprint it — a reprint is marked with the print date."))
story.append(PageBreak())

# ================================================================ 6. QC POST DYEING
story.append(H1("6. QC Post Dyeing — inspect and confirm operation 0010"))
story.append(P("<b>When:</b> the batch has come off the dyeing machine and the lab has its sample. <b>Who:</b> the QC lab. "
               "<b>What SAP does:</b> results and usage decision on the type-03 inspection lot of the batch; then the "
               "<b>production confirmation of operation 0010</b> (dyeing) on the production order, with yield, scrap, "
               "cheeses and the dyeing work centre. That confirmation is what moves the job card from <i>Open</i> to "
               "<i>Dyed</i> everywhere in the suite."))
story.append(H2("Step by step"))
story += steps([
    "Tap <b>QC Post Dyeing</b>. The screen opens with <b>Batches Waiting for Dyeing QC</b>: every batch of plant 2002 "
    "from the last 45 days that has no dyeing confirmation yet (closed batches are left out). Each row shows the batch number and, "
    "on the right, the <b>quantity to test</b> (kg and cheeses); the strip above totals the batches, kg and cheeses waiting. Change "
    "the plant or the days and the list re-reads; <b>Refresh</b> re-reads it as it is.",
    "<b>Tap the job card</b> you are inspecting. Its open dyeing lot is found exactly as if you had scanned the card's "
    "barcode — you can also scan the barcode with the camera, or type the job card / batch number and tap <b>Find Lot</b>.",
    "Check the green <b>lot card</b>: material, batch, order and greige lot, job card and schedule, quantity and cheeses, the "
    "dyeing and winding work centres.",
    "Under <b>Characteristics</b>, enter each result and tap <b>Save</b> (shade is a code: OK with code group ZSHADE, or the "
    "fault code). Type an operation remark if needed and tap <b>Record Operation</b>.",
    "Under <b>Usage Decision</b>, tap the code and tap <b>Post Usage Decision</b>. <b>RD</b> (re-dye) and <b>ST</b> (strip "
    "and re-dye) send the batch back to dyeing instead of on to winding.",
    "Under <b>Confirm Post-Dyeing Production</b> (badge <i>OP 0010</i>), check the <b>yield quantity</b> (pre-filled with the "
    "batch quantity), enter <b>scrap</b> if any, check the <b>cheeses</b> and the <b>work centre</b> (pre-filled with the "
    "dyeing machine of the job card) and the posting date. Leave <b>Final confirmation</b> ticked unless the operation is "
    "deliberately only part-confirmed. Add a confirmation text if you like.",
    "Tap <b>Confirm Production</b>. On <i>Production confirmed for batch &hellip;</i> the waiting list is re-read and the card "
    "is gone from it: it now waits on the QC Post Winding screen.",
])
story.append(Spacer(1, 2*mm))
story.append(fig_row([('15a_qd_pendcard', 'The batches waiting for dyeing QC, with the kg and cheeses to test. Tap one.', 54, 110),
                      ('16a_qd_lotbox', 'The tap finds the card\'s open dyeing lot.', 54, 110),
                      ('16b_qd_charcard', 'Results: value or code, Save each, then Record Operation.', 54, 110)]))
story.append(fig_row([('16c_qd_udcard', 'Usage decision; RD / ST mean re-dye.', 54, 110),
                      ('16d_qd_finalcard', 'Confirm operation 0010: yield, scrap, cheeses, work centre.', 54, 110),
                      ('17b_qd_pendcard', 'After the confirmation the card has left the list.', 54, 110)]))
story.append(Spacer(1, 2*mm))
story.append(tip("A card in the waiting list whose lot is not found (<i>No open lot for 2120017073</i>) has no type-03 inspection "
                 "lot yet, or the lot is already closed. Check the batch in QA03 / the production office; the card stays on the "
                 "list until operation 0010 is confirmed."))
story.append(PageBreak())

# ================================================================ 7. QC POST WINDING
story.append(H1("7. QC Post Winding — inspect and confirm operation 0020"))
story.append(P("<b>When:</b> the dyed batch has been wound. <b>Who:</b> the QC lab. <b>What SAP does:</b> results and usage "
               "decision on the type-04 inspection lot; then the <b>production confirmation of operation 0020</b> (winding) "
               "with the winding work centre. After it the job card shows <i>Wound</i>, leaves both QC lists and the batch "
               "is ready for the packing screens."))
story.append(H2("Step by step"))
story += steps([
    "Tap <b>QC Post Winding</b>. It opens with <b>Batches Waiting for Winding QC</b>: the batches of the plant whose dyeing "
    "is confirmed but whose winding is not, each with the quantity to test on the right and its <b>Dyed</b> date underneath; "
    "the strip above totals what is waiting. Same plant / days / Refresh controls as on the dyeing screen.",
    "Tap the card, or scan its barcode. The open winding lot is shown in the green card.",
    "Enter and <b>Save</b> the results, <b>Record Operation</b>, pick and <b>Post</b> the usage decision.",
    "Under <b>Confirm Post-Winding Production</b> (badge <i>OP 0020</i>) check yield, scrap, cheeses, the <b>winding work "
    "centre</b> (pre-filled from the job card when the card names one — type it if the card was created without a winding "
    "machine) and the date, then tap <b>Confirm Production</b>.",
    "The card leaves the list. In the Job Cards tab it now reads <b>Wound</b>.",
])
story.append(Spacer(1, 2*mm))
story.append(fig_row([('18a_qw_pendcard', 'Batches dyed but not yet wound, with the quantity to test and the dyeing date.', 54, 110),
                      ('19a_qw_lotbox', 'The winding lot (type 04) of the tapped card.', 54, 110),
                      ('19b_qw_finalcard', 'Confirm operation 0020 with the winding work centre.', 54, 110)]))
story.append(Spacer(1, 2*mm))
story.append(good("<b>Order of the two QC screens.</b> A card appears on Post Winding only after Post Dyeing has confirmed "
                  "operation 0010. If the lab is asked to inspect a wound batch that is not on the winding list, the dyeing "
                  "confirmation was skipped: do QC Post Dyeing first, then the card shows up here."))
story.append(PageBreak())

# ================================================================ 8. MESSAGES
story.append(H1("8. Messages you may see and what to do"))
story.append(ref_table(["Message on the screen", "Meaning", "What to do"], [
    ["No open lot for 2120017073", "QC screens: no open inspection lot of this type for the job card / batch.", "Check the stage: a dyeing lot (03) exists only after the batch was created and the order released; a winding lot (04) only after dyeing. Ask the production office if the lot was closed by hand."],
    ["No batch of the last 45 days is waiting for dyeing QC", "Nothing pending in the window you chose.", "Widen <b>Cards of the last days</b> or check the plant. Otherwise there is nothing to inspect."],
    ["Quantity 320 KG is more than the 301.2 KG still open on the order", "WIP Batch: the batch would exceed the production order.", "Reduce the quantity, or have the order quantity increased (CO02) first."],
    ["This order cannot take a batch (amber card)", "Order not released, fully batched or no free greige.", "The card gives the reason. Release the order, or run QC Raw Material for the greige."],
    ["Schedule &hellip; is for D999&hellip; - this batch dyes D300072&hellip;", "Job Card: schedule belongs to another dyed material.", "Pick a schedule of this material from the list."],
    ["77.4 KG over the scheduled quantity (amber box)", "Job Card: the schedule is already over-batched.", "Allowed; tell planning, or choose a schedule with quantity left."],
    ["N fully batched schedule(s) not shown", "Job Card: complete schedules are hidden.", "Nothing to do. Tick <b>Show completed schedules too</b> if you really need one of them."],
    ["Pick a decision code.", "QC: Post Usage Decision pressed without a code.", "Tap one of the code chips first."],
    ["&hellip; refused / SAP text in red", "SAP rejected the posting; the text is SAP's own message.", "Typical causes: a characteristic without a result, usage decision missing before release / confirmation, quantity larger than the order, a locked order. Fix and retry; if the message is about authorisation, tell the administrator."],
    ["The barcode camera library did not load", "No network when the page first opened.", "Type the number instead, or reload the page once you are online."],
    ["Session expired / sign in again", "The app session timed out.", "Sign in again; nothing half-posted is lost — every green message was already saved in SAP."],
], [50*mm, 52*mm, 66*mm]))
story.append(PageBreak())

# ================================================================ 9. QUICK REFERENCE
story.append(H1("9. Quick reference by role"))
story.append(H2("QC lab"))
story.append(ref_table(["Screen", "Open with", "Then", "Finish with"], [
    ["QC Raw Material", "Tap a batch in <i>Greige Batches Waiting for QC</i>, or scan the supplier lot", "Save each result → Record Operation → UD code → Post", "Release to Production (301, DRM1 → DPR1)"],
    ["QC Post Dyeing", "Tap a batch in <i>Batches Waiting for Dyeing QC</i>, or scan the job card", "Save each result → Record Operation → UD code (RD/ST = re-dye) → Post", "Confirm Production, op 0010, dyeing work centre"],
    ["QC Post Winding", "Tap a batch in <i>Batches Waiting for Winding QC</i>, or scan the job card", "Save each result → Record Operation → UD code → Post", "Confirm Production, op 0020, winding work centre"],
], [30*mm, 46*mm, 54*mm, 38*mm]))
story.append(H2("Dyeing supervisor"))
story.append(ref_table(["Screen", "Open with", "Then", "Finish with"], [
    ["WIP Batch", "Open Orders, or scan the production order", "Check the order card and the proposed lot; type quantity and cheeses", "Create Batch → Create Job Card"],
    ["Job Card", "Free Batches, or scan the batch", "Tap the schedule → tap the dyeing machine (winding optional)", "Create Job Card → Print Job Card"],
    ["Job Card · Job Cards tab", "Load (plant, last days)", "Read the stage badge: Open / Dyed / Wound / Closed", "Tap a row to reprint"],
], [30*mm, 46*mm, 54*mm, 38*mm]))
story.append(Spacer(1, 4*mm))
story.append(H2("Numbers to recognise"))
story.append(ref_table(["Number", "Looks like", "Where it comes from"], [
    ["Production order", "1039729", "SAP (CO01); typed or scanned on WIP Batch."],
    ["Batch / job card / plant batch", "2120017074", "Created by WIP Batch. The job card has the same number; the barcode on the card is this number."],
    ["Schedule", "2610008998", "Planning; one customer sales-order item, shade and dyeing date."],
    ["Inspection lot", "010000045871 · 030000012207 · 040000009318", "SAP QM. The first two digits are the type: 01 greige, 03 post-dyeing, 04 post-winding."],
    ["Work centre", "DYG00012 · WIN00003", "Dyeing and winding machines of plant 2002."],
    ["Storage locations", "DRM1 → DPR1 (JWPR)", "Raw store under inspection → production floor. QC Raw Material's release moves the greige between them."],
], [40*mm, 58*mm, 70*mm]))
story.append(Spacer(1, 6*mm))
story.append(P("Version: Scan Suite of 07.09.2026 (QC screens open with the batches waiting and the quantity to test; Job Card hides fully batched schedules). "
               "Screens shown are from a test system with sample data; numbers on your device will differ.", 'note'))

doc.build(story)
print("wrote", OUT)
