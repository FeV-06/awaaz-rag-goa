"""
Awaaz long-document augmentation.

Fetches a curated set of Wikipedia articles on retrieval / RAG / NLP topics and
writes them as long-document records consumed by the sentence-window and
semantic chunking strategies (data/processed/en_longdocs.jsonl).

This is the knowledge base that makes deeper "explain the concept" questions
answerable beyond the MSMARCO passage corpus.
"""
from __future__ import annotations

import json
import logging
import re
import time
import urllib.parse
import urllib.request
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parent.parent
OUT_RAW = ROOT / "data" / "raw" / "longdocs_en.jsonl"
OUT_PROCESSED = ROOT / "data" / "processed" / "en_longdocs.jsonl"

ARTICLES = [
    "Retrieval-augmented generation",
    "Large language model",
    "Transformer (deep learning architecture)",
    "FAISS",
    "Anns (library)",          # HNSW reference implementation
    "Hierarchical navigable small world",
    "BM25",
    "Okapi BM25",
    "TF-IDF",
    "Word2vec",
    "Sentence transformer",
    "Word embedding",
    "Vector database",
    "Search engine indexing",
    "Question answering",
    "Automatic summarization",
    "Speech recognition",
    "Machine translation",
    "Cross-lingual transfer",
    "Deep learning",
    "Neural network (machine learning)",
    "Information retrieval",
    "Web search engine",
    "Knowledge graph",
    "Named entity recognition",
    "Multilingualism",
    "Hindi",
    "Marathi language",
    "Indian English",
    "Artificial intelligence",
]

API = "https://en.wikipedia.org/w/api.php"


def fetch_article(title: str) -> dict | None:
    params = {
        "action": "query",
        "titles": title,
        "prop": "extracts",
        "explaintext": 1,
        "exintro": 1,
        "format": "json",
        "redirects": 1,
        "exsectionformat": "plain",
    }
    url = API + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": "AwaazRAG/1.0 (hackathon submission)"})
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            pages = data.get("query", {}).get("pages", {})
            for page in pages.values():
                if page.get("missing"):
                    return None
                text = (page.get("extract") or "").strip()
                if len(text) < 500:
                    return None
                return {"doc_id": page["title"].replace(" ", "_"), "title": page["title"], "text": text}
        except urllib.error.HTTPError as e:
            if e.code == 429:
                wait = 2.0 * (attempt + 1)
                logger.warning("429 for %r; retrying in %.0fs...", title, wait)
                time.sleep(wait)
                continue
            logger.warning("HTTP %s for %r: %s", e.code, title, e)
            return None
        except Exception as e:
            logger.warning("Failed to fetch %r: %s", title, e)
            return None
    return None


def main():
    docs = []
    seen = set()
    for title in ARTICLES:
        doc = fetch_article(title)
        if doc is None:
            logger.warning("Skipped (missing/too short): %s", title)
            continue
        key = re.sub(r"\s+", " ", doc["text"]).lower()
        if key in seen:
            continue
        seen.add(key)
        doc["source_lang"] = "en"
        docs.append(doc)
        logger.info("Fetched %-55s (%5d chars)", title, len(doc["text"]))
        time.sleep(0.15)

    OUT_RAW.parent.mkdir(parents=True, exist_ok=True)
    OUT_PROCESSED.parent.mkdir(parents=True, exist_ok=True)
    for path in (OUT_RAW, OUT_PROCESSED):
        with open(path, "w", encoding="utf-8") as f:
            for doc in docs:
                f.write(json.dumps(doc, ensure_ascii=False) + "\n")
    logger.info("Wrote %d long documents to %s and %s", len(docs), OUT_RAW, OUT_PROCESSED)


if __name__ == "__main__":
    main()