"""
Tiny frequency-based keyword extraction. No NLP models, no dependencies
beyond the standard library. Used to power the "Connections" feature.
"""

from __future__ import annotations

import re
from collections import Counter
from typing import List

STOPWORDS = {
    "the", "a", "an", "and", "or", "but", "if", "of", "to", "in", "on", "for",
    "with", "is", "are", "was", "were", "be", "been", "being", "this", "that",
    "these", "those", "it", "its", "as", "at", "by", "from", "you", "your",
    "i", "we", "they", "he", "she", "them", "his", "her", "our", "not", "no",
    "do", "does", "did", "have", "has", "had", "will", "would", "can", "could",
    "should", "may", "might", "must", "about", "into", "than", "then", "so",
    "just", "more", "most", "out", "up", "down", "what", "when", "how", "why",
    "all", "any", "some", "one", "two", "get", "got", "use", "using", "like",
}

DEFAULT_TOP_N = 8


def extract_keywords(text: str, top_n: int = DEFAULT_TOP_N) -> List[str]:
    """Returns the top_n most frequent meaningful words in `text`."""
    # Allow alphanumeric words (like GPT-4) and hyphens
    words = re.findall(r"\b[a-z][a-z0-9\-]{2,}\b", text.lower())
    words = [w for w in words if w not in STOPWORDS]
    counts = Counter(words)
    return [word for word, _ in counts.most_common(top_n)]
