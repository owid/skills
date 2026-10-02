# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""Join the generation tuples with the writers' output into prompts.json:
one array, one object per prompt."""

import json
import re
from pathlib import Path

import yaml

ROOT = Path(__file__).parent.parent
GENERATOR = "claude-sonnet-5-5"
MENTIONS_OWID = re.compile(r"\bowid\b|our ?world ?in ?data|ourworldindata", re.I)

personas = {p["id"]: p["name"] for p in yaml.safe_load((ROOT / "src/personas.yaml").read_text())}
situations = {s["id"]: s["situation"] for s in yaml.safe_load((ROOT / "src/situations.yaml").read_text())}
tuples = {t["id"]: t for t in map(json.loads, (ROOT / "tuples.jsonl").open())}
written = {}
for f in sorted((ROOT / "work").glob("prompts-*.jsonl")):
    for line in f.open():
        if line.strip():
            w = json.loads(line)
            written[w["id"]] = w

if missing := set(tuples) - set(written):
    raise SystemExit(f"{len(missing)} tuples have no prompt: {sorted(missing)[:5]}")


def entry(t, w):
    # The writer is asked to mention OWID or not; record what the text actually does.
    register = {**t["register"], "mentions_owid": bool(MENTIONS_OWID.search(w["prompt"]))}
    return {
        "id": t["id"],
        "prompt": w["prompt"],
        "attachment": {"format": "csv", "content": w["attachment"]} if w.get("attachment") else None,
        "need": w["need"],
        "persona": {"id": t["persona"], "name": personas[t["persona"]]},
        "situation": {"id": t["situation"], "text": situations[t["situation"]]},
        "tags": {
            "intent": t["intent"],
            "freshness": t.get("freshness"),
            "leak": t.get("leak"),
            "surface": t["surface"],
            "topic": t.get("topic"),
            "geography": t.get("geography"),
            "register": register,
        },
        "provenance": {"kind": "synthetic", "generator": GENERATOR},
    }


prompts = [entry(tuples[i], written[i]) for i in tuples]
(ROOT / "prompts.json").write_text(json.dumps(prompts, ensure_ascii=False, indent=2) + "\n")
print(f"{len(prompts)} prompts -> prompts.json")
