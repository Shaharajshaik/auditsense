from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

W, H = 1500, 900
img = Image.new("RGB", (W, H), "white")
draw = ImageDraw.Draw(img)

COLORS = {
    "title": "#1f2937",
    "line": "#1f2937",
    "user": "#dbeafe",
    "app": "#dcfce7",
    "blob": "#fee2e2",
    "doc": "#fef3c7",
    "openai": "#f3e8ff",
    "sql": "#f3f4f6",
    "key": "#ffedd5",
    "appi": "#dbeafe",
    "entra": "#f3f4f6",
    "accent": "#2563eb",
    "dark": "#111827",
}

font_path = "C:/Windows/Fonts/arial.ttf"
try:
    title_font = ImageFont.truetype(font_path, 28)
    box_font = ImageFont.truetype(font_path, 15)
    label_font = ImageFont.truetype(font_path, 12)
    tiny_font = ImageFont.truetype(font_path, 10)
except Exception:
    title_font = ImageFont.load_default()
    box_font = ImageFont.load_default()
    label_font = ImageFont.load_default()
    tiny_font = ImageFont.load_default()


def draw_box(x, y, w, h, title, subtitle, fill, outline, radius=18):
    draw.rounded_rectangle((x, y, x + w, y + h), radius=radius, fill=fill, outline=outline, width=2)
    icon = (x + 18, y + 18, x + 42, y + 42)
    draw.rounded_rectangle(icon, radius=8, fill=outline, outline=outline)
    text_lines = title.split("\n")
    for idx, line in enumerate(text_lines):
        draw.text((x + 58, y + 16 + idx * 20), line, font=box_font, fill=COLORS["dark"])
    draw.text((x + 18, y + h - 20), subtitle, font=tiny_font, fill=COLORS["dark"])


def add_arrow(x1, y1, x2, y2, label=None):
    draw.line((x1, y1, x2, y2), fill=COLORS["line"], width=2)
    dx = x2 - x1
    dy = y2 - y1
    length = (dx ** 2 + dy ** 2) ** 0.5
    if length == 0:
        return
    ux = dx / length
    uy = dy / length
    px = x2 - ux * 18
    py = y2 - uy * 18
    left_x = px - (uy * 10)
    left_y = py + (ux * 10)
    right_x = px + (uy * 10)
    right_y = py - (ux * 10)
    draw.polygon([(x2, y2), (left_x, left_y), (right_x, right_y)], fill=COLORS["line"])
    if label:
        lx = (x1 + x2) / 2
        ly = (y1 + y2) / 2
        draw.text((lx - 30, ly - 18), label, font=label_font, fill=COLORS["dark"])

# Title
text = "AuditSense Azure MVP Architecture"
draw.text((390, 25), text, font=title_font, fill=COLORS["title"])

# User
user_x, user_y = 50, 230
user_w, user_h = 120, 90
draw.rounded_rectangle((user_x, user_y, user_x + user_w, user_y + user_h), radius=16, fill=COLORS["user"], outline="#2563eb", width=2)
draw.ellipse((user_x + 36, user_y + 14, user_x + 84, user_y + 62), fill="#93c5fd", outline="#2563eb")
draw.rounded_rectangle((user_x + 22, user_y + 58, user_x + 98, user_y + 78), radius=10, fill="#bfdbfe", outline="#2563eb")
draw.text((user_x + 18, user_y + 90), "Auditor / User", font=label_font, fill=COLORS["dark"])

# Service boxes
nodes = [
    (280, 200, 220, 160, "Azure App Service\nPython Web App + API", "App runtime", COLORS["app"], "#16a34a"),
    (590, 90, 220, 100, "Azure Blob Storage\nData + files", "Upload docs", COLORS["blob"], "#dc2626"),
    (590, 220, 220, 100, "Azure AI Document Intelligence\nOCR", "Extract text", COLORS["doc"], "#d97706"),
    (590, 350, 220, 110, "Azure OpenAI\nAnalysis + findings", "LLM", COLORS["openai"], "#7c3aed"),
    (900, 150, 250, 100, "Azure SQL Database\nAudit case data", "Store metadata", COLORS["sql"], "#6b7280"),
    (900, 285, 250, 90, "Azure Key Vault\nSecrets", "Credentials", COLORS["key"], "#f59e0b"),
    (900, 410, 250, 90, "Application Insights\nMonitoring", "Telemetry", COLORS["appi"], "#2563eb"),
    (280, 420, 220, 90, "Microsoft Entra ID\nReviewer access", "Auth", COLORS["entra"], "#4b5563"),
]

for x, y, w, h, title, subtitle, fill, outline in nodes:
    draw_box(x, y, w, h, title, subtitle, fill, outline)

# Connectors
add_arrow(170, 285, 280, 285, "Login")
add_arrow(500, 250, 590, 150, "Upload")
add_arrow(810, 150, 500, 250, "Fetch docs")
add_arrow(500, 300, 590, 270, "Extract text")
add_arrow(810, 270, 500, 320, "OCR result")
add_arrow(500, 330, 590, 410, "Prompt + context")
add_arrow(810, 410, 500, 340, "Draft findings")
add_arrow(500, 250, 900, 200, "Audit metadata")
add_arrow(500, 295, 900, 330, "Secrets")
add_arrow(500, 350, 900, 455, "Telemetry")
add_arrow(500, 380, 500, 420, "Approval")

# save generated PNG
out = Path(__file__).resolve().with_name("auditsense-azure-mvp.png")
img.save(out)
print(f"Generated PNG: {out}")
