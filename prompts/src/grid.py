# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""Build generation tuples: every situation x leak level, other grid values cycled
per situation, then seeded
sampling of topic, geography and register. Deterministic mechanics only —
which values make sense for a situation is decided in situations.yaml."""

import csv
import json
import random
from pathlib import Path

import yaml

HERE = Path(__file__).parent
SEED = 20260929
rng = random.Random(SEED)

personas = {p["id"]: p for p in yaml.safe_load((HERE / "personas.yaml").read_text())}
situations = yaml.safe_load((HERE / "situations.yaml").read_text())
topics = [t["name"] for t in json.loads((HERE / "topics.json").read_text())]
countries = list(csv.DictReader((HERE / "countries.csv").open()))
by_region: dict[str, list[str]] = {}
for c in countries:
    by_region.setdefault(c["region"], []).append(c["country"])
regions = sorted(by_region)

main = [s for s in situations if s["persona"] != "X"]
controls = [s for s in situations if s["persona"] == "X"]
sit_by_id = {s["id"]: s for s in situations}

LEAK = ["L0", "L1", "L2", "L3"]
SURFACE = ["chat", "agent"]


class Cycle:
    """Shuffled round-robin so values spread evenly before repeating."""

    def __init__(self, values):
        self.values, self.queue = list(values), []

    def next(self):
        if not self.queue:
            self.queue = rng.sample(self.values, len(self.values))
        return self.queue.pop()


topic_cycle = Cycle(topics)
region_cycle = Cycle(regions)


def pick_geography(kind):
    if kind == "world":
        return {"scope": "world"}
    region = region_cycle.next()
    if kind == "region":
        return {"scope": "region", "region": region}
    pool = by_region[region]
    if kind == "country":
        return {"scope": "country", "countries": [rng.choice(pool)]}
    n = rng.choice([2, 3, 4])
    return {"scope": "comparison", "countries": rng.sample(pool, min(n, len(pool)))}


def pick_register():
    return {
        "tone": "formal" if rng.random() < 0.15 else "casual",
        "typo": rng.random() < 0.35,
        "pasted_material": rng.random() < 0.2,
        "length": rng.choices(["one line", "a few sentences", "long, with context"], [0.5, 0.35, 0.15])[0],
        "mentions_owid": rng.random() < 0.3,
    }


rows = []
n = 0
for s in main:
    # Every situation gets every leak level; the situation's other allowed
    # values are cycled (in shuffled order) so each appears before any repeats.
    cyc = {k: Cycle(s[k]) for k in ("intents", "freshness", "geography")}
    surf = Cycle(personas[s["persona"]]["surfaces"])
    for leak in LEAK:
        n += 1
        rows.append({
            "id": f"{s['id']}-{n:03d}",
            "persona": s["persona"],
            "situation": s["id"],
            "intent": cyc["intents"].next(),
            "freshness": cyc["freshness"].next(),
            "geography": pick_geography(cyc["geography"].next()),
            "topic": topic_cycle.next(),
            "leak": leak,
            "surface": surf.next(),
            "register": pick_register(),
        })

for s in controls:
    for k in range(2):
        rows.append({
            "id": f"{s['id']}-{k + 1:03d}",
            "persona": "X",
            "situation": s["id"],
            "intent": "out-of-scope",
            "surface": rng.choice(SURFACE),
            "register": pick_register(),
        })

out = HERE.parent / "tuples.jsonl"
out.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows))
print(f"{len(rows)} tuples -> {out}")
