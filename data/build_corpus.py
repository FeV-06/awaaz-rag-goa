"""
Awaaz corpus builder — MSMARCO-XI → deduplicated passage corpora.

Input:  ai4bharat/MSMARCO-XI parquet (per-language translated MS MARCO).
Output: data/processed/{lang}_corpus.jsonl   (passage-native corpus records)
        data/raw/{lang}/raw_queries.json     (benchmark query sets)

Passage record schema (consumed by chunking/passage_native.py):
    text, source_lang, passage_id, source_query_ids, is_selected

Design notes:
- Streams the parquet with column pruning (pyarrow iter_batches) so a 3.7 GB
  train file only materializes the columns we actually consume.
- Hindi/Marathi passages come from their respective `Translated_passages`.
- English passages come from `English_passages` inside the Hindi parquet —
  MS MARCO's original English passages, no separate download needed.
- Passages are deduplicated by normalized text; each keeps the full list of
  source query ids, so the answer-cache and eval layers can trace provenance.
"""
from __future__ import annotations

import argparse
import json
import logging
import re
from pathlib import Path

import pyarrow.parquet as pq

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_RAW = ROOT / "data" / "raw"
DEFAULT_OUT = ROOT / "data" / "processed"

# Language -> parquet (train split). English is served from Hindi's English_passages.
TRAIN_PARQUETS = {"hi": "hintrain.parquet", "mr": "martrain.parquet"}

BENCH_QUERIES_PER_LANG = 50


def stream_records(parquet_path: Path, max_queries: int | None = None):
    """Yield per-row dicts with only the needed columns, honoring max_queries."""
    columns = ["query_id", "query", "Eng_Query", "passages", "target_lang"]
    pf = pq.ParquetFile(parquet_path)
    logger.info("Streaming %s (%d rows) with column pruning...", parquet_path.name, pf.metadata.num_rows)
    seen = 0
    for batch in pf.iter_batches(columns=columns, batch_size=8192):
        tbl = batch.to_pylist()
        for row in tbl:
            if max_queries is not None and seen >= max_queries:
                return
            seen += 1
            yield row


def build_lang(lang: str, raw_dir: Path, out_dir: Path, max_queries: int | None, max_passages: int | None):
    # English is served from Hindi's English_passages; hi/mr use their own parquet.
    parquet = raw_dir / (TRAIN_PARQUETS.get(lang) or "hintrain.parquet")
    if not parquet.exists():
        raise FileNotFoundError(f"Download {parquet.name} into {raw_dir} first.")

    out_dir.mkdir(parents=True, exist_ok=True)
    corpus_path = out_dir / f"{lang}_corpus.jsonl"

    passages: dict[str, dict] = {}          # norm_text -> record
    query_file_rows: list[dict] = []
    total_rows = 0

    def norm(text: str) -> str:
        return re.sub(r"\s+", " ", text).strip().lower()

    def add_passage(text: str, qid: int, is_selected: int, p_index: int, fallback_id: str):
        if not text or not text.strip():
            return
        key = norm(text)
        if key in passages:
            rec = passages[key]
            if qid not in rec["source_query_ids"]:
                rec["source_query_ids"].append(qid)
            rec["is_selected"] = max(rec.get("is_selected", 0), is_selected)
            return
        passages[key] = {
            "text": text.strip(),
            "source_lang": lang,
            "passage_id": fallback_id,
            "source_query_ids": [qid],
            "is_selected": is_selected,
        }

    for row in stream_records(parquet, max_queries=max_queries):
        total_rows += 1
        qid = int(row["query_id"])
        p = row.get("passages") or {}
        translated = p.get("Translated_passages") or []
        english = p.get("English_passages") or []
        is_sel = p.get("is_selected") or []

        # Benchmark query set (factoid, unique, length-gated)
        if len(query_file_rows) < BENCH_QUERIES_PER_LANG * 2:
            q = row.get("Eng_Query" if lang == "en" else "query") or ""
            q = q.lstrip(")").strip()
            existing = {r.get("Eng_Query", r.get("query", "")) for r in query_file_rows}
            if len(q) > 5 and q not in existing:
                query_file_rows.append({"Eng_Query": q} if lang == "en" else {"query": q})

        if lang == "en":
            for i, text in enumerate(english):
                if max_passages is not None and len(passages) >= max_passages:
                    break
                add_passage(text, qid, int(is_sel[i]) if i < len(is_sel) else 0, i, f"{lang}_p{qid}_{i}")
        else:
            for i, text in enumerate(translated):
                if max_passages is not None and len(passages) >= max_passages:
                    break
                add_passage(text, qid, int(is_sel[i]) if i < len(is_sel) else 0, i, f"{lang}_p{qid}_{i}")

    # Write corpus
    records = list(passages.values())
    with open(corpus_path, "w", encoding="utf-8") as f:
        for rec in records:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")

    # Write benchmark query file (first 50 unique)
    q_path = raw_dir / lang / "raw_queries.json"
    q_path.parent.mkdir(parents=True, exist_ok=True)
    with open(q_path, "w", encoding="utf-8") as f:
        json.dump(query_file_rows[:BENCH_QUERIES_PER_LANG], f, ensure_ascii=False, indent=2)

    logger.info(
        "lang=%s rows=%d passages=%d queries=%d -> %s",
        lang, total_rows, len(records), len(query_file_rows[:BENCH_QUERIES_PER_LANG]), corpus_path.name,
    )
    return len(records)


def main():
    ap = argparse.ArgumentParser(description="Build Awaaz passage corpora from MSMARCO-XI.")
    ap.add_argument("--langs", nargs="+", default=["en", "hi", "mr"])
    ap.add_argument("--raw-dir", type=Path, default=DEFAULT_RAW)
    ap.add_argument("--out-dir", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--max-queries", type=int, default=10000, help="Rows consumed per language (default 10k)")
    ap.add_argument("--max-passages", type=int, default=None, help="Optional cap on deduplicated passages")
    args = ap.parse_args()

    for lang in args.langs:
        if lang not in TRAIN_PARQUETS and lang != "en":
            raise SystemExit(f"Unsupported lang {lang!r}; supported: 'en', hi, mr")
    for lang in args.langs:
        build_lang(lang, args.raw_dir, args.out_dir, args.max_queries, args.max_passages)


if __name__ == "__main__":
    main()