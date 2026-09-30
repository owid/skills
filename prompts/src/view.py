"""Render prompts.json as prompts.html, a page for reading the library,
filterable by persona and intent."""

import html
import json
from pathlib import Path

ROOT = Path(__file__).parent.parent
prompts = json.loads((ROOT / "prompts.json").read_text())
e = html.escape

cards = []
for p in prompts:
    tg = p["tags"]
    geo = tg["geography"] or {}
    place = ", ".join(geo.get("countries") or []) or geo.get("region") or geo.get("scope") or ""
    pills = [p["persona"]["name"], tg["intent"], tg["leak"], tg["freshness"], tg["surface"], tg["topic"], place]
    att = f'<pre>{e(p["attachment"]["content"])}</pre>' if p["attachment"] else ""
    cards.append(
        f'<div class="card" data-persona="{e(p["persona"]["id"])}" data-intent="{e(tg["intent"])}">'
        f'<div class="meta"><b>{e(p["id"])}</b>' + "".join(f"<span>{e(str(x))}</span>" for x in pills if x) + "</div>"
        f'<div class="prompt">{e(p["prompt"])}</div>{att}'
        f'<div class="need"><span>need</span> {e(p["need"])}</div>'
        f'<div class="need"><span>situation</span> {e(p["situation"]["text"])}</div></div>'
    )


def options(pairs):
    return "".join(f'<option value="{e(k)}">{e(v)}</option>' for k, v in pairs)


persona_opts = options(sorted({(p["persona"]["id"], p["persona"]["name"]) for p in prompts}))
intent_opts = options((i, i) for i in sorted({p["tags"]["intent"] for p in prompts}))
page = f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>Prompt Library</title>
<style>
body{{margin:0;background:#fbfaf7;color:#1d2330;font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Inter,sans-serif}}
header{{position:sticky;top:0;background:#fbfaf7ee;border-bottom:1px solid #e3e0d8;padding:10px 16px}}
.wrap{{max-width:980px;margin:0 auto}} h1{{font-size:20px;margin:0 0 6px}}
select{{font:inherit;font-size:13px;padding:3px 6px;border:1px solid #e3e0d8;border-radius:6px;background:#fff}}
#count{{font-size:13px;color:#5b6475;margin-left:8px}} main{{padding:8px 16px 40px}}
.card{{background:#fff;border:1px solid #e3e0d8;border-radius:10px;padding:12px 14px;margin:10px 0}}
.meta{{display:flex;flex-wrap:wrap;gap:4px;font-size:12px;margin-bottom:6px}}
.meta span{{background:#eceae4;color:#5b6475;border-radius:99px;padding:1px 8px}}
.prompt{{font-size:16px;background:#f6f4ef;border-radius:8px;padding:10px 12px;white-space:pre-wrap}}
pre{{font:12px/1.4 ui-monospace,Menlo,monospace;background:#f6f4ef;border-radius:6px;padding:8px;overflow-x:auto}}
.need{{font-size:13.5px;margin-top:6px}} .need span{{color:#5b6475;display:inline-block;width:72px}}
</style></head><body>
<header><div class="wrap"><h1>Prompt library · {len(prompts)} prompts</h1>
<select id="p"><option value="">all personas</option>{persona_opts}</select>
<select id="i"><option value="">all intents</option>{intent_opts}</select><span id="count"></span></div></header>
<main><div class="wrap">{"".join(cards)}</div></main>
<script>
const f = () => {{ const p = document.getElementById('p').value, i = document.getElementById('i').value; let n = 0;
  document.querySelectorAll('.card').forEach(c => {{
    const show = (!p || c.dataset.persona === p) && (!i || c.dataset.intent === i);
    c.style.display = show ? '' : 'none'; n += show; }});
  document.getElementById('count').textContent = n + ' shown'; }};
document.querySelectorAll('select').forEach(s => s.addEventListener('input', f)); f();
</script></body></html>"""
(ROOT / "prompts.html").write_text(page)
print(f"{len(prompts)} prompts -> prompts.html")
