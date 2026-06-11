"""Smart Scan eval harness (ADR-0005).

Runs a labeled photo set through the vision service and reports volume
estimation error against the KPIs: mean absolute error < 15%, and how the
auto-fill confidence threshold (0.85) separates good from bad estimates.

Usage:
    # 1. Fill in the labels CSV (filename, true_volume_ml)
    # 2. Run once per model:
    python scripts/eval_vision.py --images ./eval_photos --labels ./eval_photos/labels.csv
    python scripts/eval_vision.py --images ./eval_photos --labels ./eval_photos/labels.csv --model claude-sonnet-4-6

Results are written next to the labels file as eval_results_<model>.csv
so the two runs can be compared side by side.
"""

import argparse
import csv
import os
import statistics
import sys

# Make `app` importable when running from the backend root
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.core.config import settings  # noqa: E402

AUTOFILL_THRESHOLD = 0.85


def load_labels(labels_path):
    rows = []
    seen = set()
    with open(labels_path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if not row.get("filename") or not row.get("true_volume_ml"):
                continue
            filename = row["filename"].strip()
            # Windows paths are case-insensitive: IMG_002.jpg == IMG_002.JPG
            key = filename.casefold()
            if key in seen:
                print(f"WARNING: duplicate label for {filename} — skipping")
                continue
            seen.add(key)
            rows.append(
                {
                    "filename": filename,
                    "true_volume_ml": int(row["true_volume_ml"]),
                }
            )
    return rows


def pct(values):
    return f"{100 * sum(values) / len(values):.0f}%" if values else "n/a"


def main():
    parser = argparse.ArgumentParser(description="Smart Scan vision eval")
    parser.add_argument("--images", required=True, help="Folder containing photos")
    parser.add_argument("--labels", required=True, help="CSV: filename,true_volume_ml")
    parser.add_argument(
        "--model",
        default=None,
        help=f"Model override (default: {settings.VISION_MODEL})",
    )
    parser.add_argument(
        "--max-dim",
        type=int,
        default=None,
        help="Image max dimension override (default: "
        f"{settings.VISION_MAX_IMAGE_DIMENSION}px). Higher = more detail, "
        "more image tokens.",
    )
    args = parser.parse_args()

    if args.model:
        settings.VISION_MODEL = args.model
    if args.max_dim:
        settings.VISION_MAX_IMAGE_DIMENSION = args.max_dim
    model = settings.VISION_MODEL
    max_dim = settings.VISION_MAX_IMAGE_DIMENSION

    if not settings.ANTHROPIC_API_KEY:
        sys.exit("ANTHROPIC_API_KEY is not set (check aquatrack_backend/.env)")

    # Import after settings override so the service picks up the model
    from app.services.vision_service import VisionService

    service = VisionService()
    labels = load_labels(args.labels)
    if not labels:
        sys.exit(f"No labeled rows found in {args.labels}")

    print(f"Model: {model} @ {max_dim}px — {len(labels)} labeled photos\n")

    results = []
    for i, row in enumerate(labels, 1):
        path = os.path.join(args.images, row["filename"])
        if not os.path.exists(path):
            print(f"[{i}/{len(labels)}] SKIP (missing file): {row['filename']}")
            continue

        with open(path, "rb") as f:
            image_data = f.read()

        try:
            jpeg = service._preprocess_image(image_data)
            label, capacity, fill, liquid, confidence = service._run_inference(jpeg)
        except Exception as e:
            print(f"[{i}/{len(labels)}] FAIL {row['filename']}: {e}")
            continue

        estimated = round(capacity * fill)
        true_ml = row["true_volume_ml"]
        error_ml = estimated - true_ml
        if true_ml == 0:
            # chai/ly rỗng
            error_pct = 0 if estimated == 0 else 100
        else:
            error_pct = abs(error_ml) / true_ml * 100

        results.append(
            {
                "filename": row["filename"],
                "true_volume_ml": true_ml,
                "estimated_volume_ml": estimated,
                "error_ml": error_ml,
                "error_pct": round(error_pct, 1),
                "capacity_ml": capacity,
                "fill_level": round(fill, 2),
                "liquid_type": liquid,
                "confidence": round(confidence, 2),
                "container_label": label,
            }
        )
        print(
            f"[{i}/{len(labels)}] {row['filename']}: "
            f"true {true_ml}ml → est {estimated}ml "
            f"({error_pct:+.1f}% err, conf {confidence:.2f})"
        )

    if not results:
        sys.exit("No successful inferences — nothing to report")

    # Per-image results CSV next to the labels file
    out_path = os.path.join(
        os.path.dirname(os.path.abspath(args.labels)),
        f"eval_results_{model.replace(':', '_')}_{max_dim}px.csv",
    )
    with open(out_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(results[0].keys()))
        writer.writeheader()
        writer.writerows(results)

    errors = [r["error_pct"] for r in results]
    high_conf = [r for r in results if r["confidence"] >= AUTOFILL_THRESHOLD]
    low_conf = [r for r in results if r["confidence"] < AUTOFILL_THRESHOLD]

    print("\n" + "=" * 60)
    print(f"SUMMARY — {model} @ {max_dim}px ({len(results)} photos)")
    print("=" * 60)
    print(f"Mean abs error    : {statistics.mean(errors):.1f}%   (KPI: <15%)")
    print(f"Median abs error  : {statistics.median(errors):.1f}%")
    print(f"Within ±15%       : {pct([e <= 15 for e in errors])}")
    print(f"Within ±50ml      : {pct([abs(r['error_ml']) <= 50 for r in results])}")
    print(
        f"Mean confidence   : {statistics.mean(r['confidence'] for r in results):.2f}"
    )
    print(
        f"\nConfidence ≥{AUTOFILL_THRESHOLD} (auto-fill): {len(high_conf)} photos — "
        f"mean err {statistics.mean(r['error_pct'] for r in high_conf):.1f}%"
        if high_conf
        else f"\nConfidence ≥{AUTOFILL_THRESHOLD} (auto-fill): 0 photos"
    )
    if low_conf:
        print(
            f"Confidence <{AUTOFILL_THRESHOLD} (review)   : {len(low_conf)} photos — "
            f"mean err {statistics.mean(r['error_pct'] for r in low_conf):.1f}%"
        )

    worst = sorted(results, key=lambda r: r["error_pct"], reverse=True)[:5]
    print("\nWorst 5 (check these photos for patterns):")
    for r in worst:
        print(
            f"  {r['filename']}: true {r['true_volume_ml']}ml → "
            f"est {r['estimated_volume_ml']}ml ({r['error_pct']}%, "
            f"conf {r['confidence']}) — {r['container_label']}"
        )

    print(f"\nPer-image results: {out_path}")


if __name__ == "__main__":
    main()
