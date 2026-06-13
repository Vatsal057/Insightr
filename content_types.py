"""
Content-type templates.

Different kinds of reels need different note structures — a coding tutorial
needs a code snippet and steps; a workout needs sets/reps; a movie
recommendation needs genre and where-to-watch. Rather than giving every entry
a fixed set of fields (most of which would be empty for any given video), we
define a hardcoded registry of templates here, one per real-world content
niche.

Each template is just a list of field labels — the LLM fills in
{"label": ..., "value": ...} pairs for whichever labels apply, using the
template for the content_type it picked. This keeps storage and the response
schema completely generic (a flat list of label/value pairs) while still
giving each content type its own structure in the prompt and in the
Markdown export.

`general` is the fallback template used for anything that doesn't fit one of
the named types — it has no required fields, since `key_points` /
`summary` / `next_step` already cover the generic case.
"""

from __future__ import annotations

CONTENT_TYPE_TEMPLATES: dict[str, dict] = {
    "coding_tutorial": {
        "display_name": "Coding / Dev Tutorial",
        "fields": ["Language / Stack", "Code Snippet", "Steps", "Key Concepts"],
    },
    "workout_routine": {
        "display_name": "Workout Routine",
        "fields": ["Exercises", "Sets x Reps", "Target Muscles", "Equipment Needed"],
    },
    "fitness_nutrition": {
        "display_name": "Fitness / Nutrition",
        "fields": ["Foods / Plan", "Macros or Calories", "Foods to Avoid", "Why It Works"],
    },
    "movie_tv_recommendation": {
        "display_name": "Movie / TV Recommendation",
        "fields": ["Title", "Genre", "Why Watch It", "Where to Watch"],
    },
    "music_recommendation": {
        "display_name": "Music Recommendation",
        "fields": ["Artist / Track", "Genre / Vibe", "Why Listen", "Where to Listen"],
    },
    "book_recommendation": {
        "display_name": "Book Recommendation",
        "fields": ["Title", "Author", "Genre", "Why Read It"],
    },
    "recipe": {
        "display_name": "Recipe",
        "fields": ["Ingredients", "Steps", "Cook Time", "Servings"],
    },
    "tool_app_recommendation": {
        "display_name": "Tool / App Recommendation",
        "fields": ["Use Case", "Pricing", "Best For"],
    },
    "tool_review": {
        "display_name": "Tool / Product Review",
        "fields": ["Pros", "Cons", "Best For", "Alternatives"],
    },
    "travel_guide": {
        "display_name": "Travel Guide",
        "fields": ["Destination", "Itinerary / Spots", "Best Time to Go", "Budget Tips"],
    },
    "finance_tip": {
        "display_name": "Finance / Investing",
        "fields": ["Strategy", "Numbers / Stats", "Risk Level", "Action"],
    },
    "career_advice": {
        "display_name": "Career / Job Advice",
        "fields": ["Advice", "Who It's For", "Steps"],
    },
    "life_hack": {
        "display_name": "Life Hack",
        "fields": ["The Hack", "Materials Needed", "Time Required"],
    },
    "fashion_outfit": {
        "display_name": "Fashion / Outfit Idea",
        "fields": ["Items", "Style / Occasion", "Where to Buy"],
    },
    "home_diy": {
        "display_name": "Home / DIY",
        "fields": ["Project", "Materials", "Steps", "Time / Cost"],
    },
    "language_learning": {
        "display_name": "Language Learning",
        "fields": ["Language", "Phrases / Grammar Point", "Usage Notes"],
    },
    "comparison": {
        "display_name": "Comparison",
        "fields": ["Option A", "Option B", "Key Differences", "Winner"],
    },
    "listicle": {
        "display_name": "List / Roundup",
        "fields": ["Items"],
    },
    "opinion": {
        "display_name": "Opinion / Take",
        "fields": ["Stance", "Supporting Points", "Counterpoints"],
    },
    "story": {
        "display_name": "Story / Anecdote",
        "fields": ["What Happened", "Lesson Learned"],
    },
    "news": {
        "display_name": "News / Announcement",
        "fields": ["What Happened", "Who It Affects", "Why It Matters"],
    },
    "research_breakdown": {
        "display_name": "Research / Study Breakdown",
        "fields": ["Study Summary", "Methodology", "Key Findings", "Limitations"],
    },
    "motivational": {
        "display_name": "Motivational / Mindset",
        "fields": ["Core Message", "Mindset Shift"],
    },
    "qna": {
        "display_name": "Q&A / Interview",
        "fields": ["Question", "Answer"],
    },
    "general": {
        "display_name": "General",
        "fields": [],
    },
}


def get_template(content_type: str) -> dict:
    """Returns the template for content_type, falling back to 'general'."""
    return CONTENT_TYPE_TEMPLATES.get(content_type, CONTENT_TYPE_TEMPLATES["general"])


def prompt_reference() -> str:
    """Renders all templates as text for inclusion in the LLM prompt."""
    lines = []
    for key, template in CONTENT_TYPE_TEMPLATES.items():
        if key == "general":
            lines.append('- "general": no fixed fields — use this when nothing else fits.')
            continue
        fields = ", ".join(template["fields"])
        lines.append(f'- "{key}" ({template["display_name"]}): {fields}')
    return "\n".join(lines)


def all_content_types() -> list[str]:
    """Returns all content_type keys, for use in the Gemini response schema and Pydantic enum."""
    return list(CONTENT_TYPE_TEMPLATES.keys())
