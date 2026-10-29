"""Patch Live2D's official Hatsune Miku sample (PRO) for Open-LLM-VTuber.

- Adds the mood expressions from scripts/miku/expressions/.
- Makes body-only copies of the idle motions. The original idle motions hold a
  full smile on the face, which would hide every expression.

The model itself is not part of this repository (Live2D's terms do not allow
redistributing it); scripts/miku/setup_miku.sh downloads it from Live2D first.

Usage: python scripts/miku/patch_miku_model.py live2d-models/miku/runtime
"""

import json
import shutil
import sys
from pathlib import Path

MODEL_FILE = "miku_sample_t04.model3.json"
FACE_PARAMS = {
    "ParamCheek", "ParamEyeLOpen", "ParamEyeLSmile", "ParamEyeROpen", "ParamEyeRSmile",
    "ParamBrowLY", "ParamBrowRY", "ParamBrowLForm", "ParamBrowRForm",
    "ParamMouthOpenY", "ParamMouthForm",
}
IDLE_MOTIONS = ["motion/miku_01.motion3.json", "motion/miku_04.motion3.json", "motion/miku_07.motion3.json"]


def count_segments(segments):
    """Segment and point counts for one curve (bezier = 6 values, others = 2)."""
    i, seg_count, point_count = 2, 0, 1
    while i < len(segments):
        is_bezier = int(segments[i]) == 1
        seg_count += 1
        point_count += 3 if is_bezier else 1
        i += 1 + (6 if is_bezier else 2)
    return seg_count, point_count


def make_body_only(src: Path) -> Path:
    motion = json.loads(src.read_text())
    motion["Curves"] = [c for c in motion["Curves"] if c["Id"] not in FACE_PARAMS]
    totals = [count_segments(c["Segments"]) for c in motion["Curves"]]
    motion["Meta"]["CurveCount"] = len(motion["Curves"])
    motion["Meta"]["TotalSegmentCount"] = sum(s for s, _ in totals)
    motion["Meta"]["TotalPointCount"] = sum(p for _, p in totals)
    out = src.with_name(src.name.replace(".motion3.json", "_body.motion3.json"))
    out.write_text(json.dumps(motion, indent=1))
    return out


def main(runtime_dir: str):
    runtime = Path(runtime_dir)
    expressions_src = Path(__file__).parent / "expressions"
    (runtime / "expressions").mkdir(exist_ok=True)
    names = []
    for exp in sorted(expressions_src.glob("*.exp3.json")):
        shutil.copy(exp, runtime / "expressions" / exp.name)
        names.append(exp.name.replace(".exp3.json", ""))

    model_path = runtime / MODEL_FILE
    model = json.loads(model_path.read_text())
    refs = model["FileReferences"]
    refs["Expressions"] = [{"Name": n, "File": f"expressions/{n}.exp3.json"} for n in names]
    refs["Motions"]["Idle"] = [
        {"File": f"motion/{make_body_only(runtime / m).name}"} for m in IDLE_MOTIONS
    ]
    model_path.write_text(json.dumps(model, indent="\t", ensure_ascii=False))
    print(f"Patched {model_path}: {len(names)} expressions, body-only idle motions.")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "live2d-models/miku/runtime")
