package com.insightr.app

/* =========================================================================
 * MODELS — mirrors schema.py + content_types.py (Vault backend)
 *
 * Field name changes vs the old schema:
 *  - CoreTakeaway(hook, summary)  -> Summary(headline, body)
 *  - the_meat                     -> keyPoints (markdown text, **bold** spans)
 *  - rabbit_hole                  -> exploreFurther
 *  - final_verdict                -> nextStep
 *  - knowledge_cards (CardType)   -> concepts (ConceptType)
 *  - collections moved out of KnowledgeEntry; managed via /api/collections
 * ====================================================================== */

data class Summary(val headline: String, val body: String)

data class ActionItem(val id: Int, val text: String, val done: Boolean = false, val entryId: Int? = null)

enum class Verifiability { FACT, OPINION, UNVERIFIED }

data class Claim(val claim: String, val verifiability: Verifiability, val note: String? = null)

data class TopicMap(val mainTopic: String, val subtopics: List<String>)

enum class ArtifactType { TOOL, BOOK, LINK, TEMPLATE, OTHER }

data class ReferencedArtifact(
    val name: String,
    val type: ArtifactType,
    val url: String? = null,
    val snippet: String? = null
)

data class Connection(val entryId: Int, val title: String, val reason: String)

enum class ConceptType { CONCEPT, FRAMEWORK, TOOL, BOOK, PERSON, METHODOLOGY, WEBSITE }

/** A reusable knowledge object — appears both inline on an entry and in the global concept index. */
data class Concept(
    val id: Int? = null,
    val conceptType: ConceptType,
    val name: String,
    val summary: String,
    val sourceEntryId: Int? = null,
    val entryCount: Int = 0
)

data class TypeSpecificField(val label: String, val value: String)

/** Minimal card for feed/list views — matches feed.entry_to_summary_card. */
data class EntrySummary(
    val id: Int,
    val title: String,
    val headline: String,
    val field: String,
    val contentType: String,
    val tags: List<String>,
    val createdAt: String
)

/** Full insight card — matches feed.entry_to_card. */
data class KnowledgeEntry(
    val id: Int,
    val title: String,
    val sourceUrl: String,
    val field: String,
    val tags: List<String>,
    val contentType: String,
    val createdAt: String,
    val summary: Summary,
    val keyPoints: String,
    val typeSpecificFields: List<TypeSpecificField>,
    val actionItems: List<ActionItem>,
    val nextStep: String,
    val referencedArtifacts: List<ReferencedArtifact> = emptyList(),
    val claims: List<Claim> = emptyList(),
    val exploreFurther: List<String> = emptyList(),
    val topicMap: TopicMap,
    val concepts: List<Concept> = emptyList(),
    val connections: List<Connection> = emptyList()
)

/* =========================================================================
 * CONTENT TYPE TEMPLATES — mirrors content_types.py exactly
 * ====================================================================== */

data class ContentTypeTemplate(val displayName: String, val fields: List<String>)

object ContentTypes {
    val TEMPLATES: Map<String, ContentTypeTemplate> = mapOf(
        "coding_tutorial" to ContentTypeTemplate("Coding / Dev Tutorial", listOf("Language / Stack", "Code Snippet", "Steps", "Key Concepts")),
        "workout_routine" to ContentTypeTemplate("Workout Routine", listOf("Exercises", "Sets x Reps", "Target Muscles", "Equipment Needed")),
        "fitness_nutrition" to ContentTypeTemplate("Fitness / Nutrition", listOf("Foods / Plan", "Macros or Calories", "Foods to Avoid", "Why It Works")),
        "movie_tv_recommendation" to ContentTypeTemplate("Movie / TV Recommendation", listOf("Title", "Genre", "Why Watch It", "Where to Watch")),
        "music_recommendation" to ContentTypeTemplate("Music Recommendation", listOf("Artist / Track", "Genre / Vibe", "Why Listen", "Where to Listen")),
        "book_recommendation" to ContentTypeTemplate("Book Recommendation", listOf("Title", "Author", "Genre", "Why Read It")),
        "recipe" to ContentTypeTemplate("Recipe", listOf("Ingredients", "Steps", "Cook Time", "Servings")),
        "tool_app_recommendation" to ContentTypeTemplate("Tool / App Recommendation", listOf("Use Case", "Pricing", "Best For")),
        "tool_review" to ContentTypeTemplate("Tool / Product Review", listOf("Pros", "Cons", "Best For", "Alternatives")),
        "travel_guide" to ContentTypeTemplate("Travel Guide", listOf("Destination", "Itinerary / Spots", "Best Time to Go", "Budget Tips")),
        "finance_tip" to ContentTypeTemplate("Finance / Investing", listOf("Strategy", "Numbers / Stats", "Risk Level", "Action")),
        "career_advice" to ContentTypeTemplate("Career / Job Advice", listOf("Advice", "Who It's For", "Steps")),
        "life_hack" to ContentTypeTemplate("Life Hack", listOf("The Hack", "Materials Needed", "Time Required")),
        "fashion_outfit" to ContentTypeTemplate("Fashion / Outfit Idea", listOf("Items", "Style / Occasion", "Where to Buy")),
        "home_diy" to ContentTypeTemplate("Home / DIY", listOf("Project", "Materials", "Steps", "Time / Cost")),
        "language_learning" to ContentTypeTemplate("Language Learning", listOf("Language", "Phrases / Grammar Point", "Usage Notes")),
        "comparison" to ContentTypeTemplate("Comparison", listOf("Option A", "Option B", "Key Differences", "Winner")),
        "listicle" to ContentTypeTemplate("List / Roundup", listOf("Items")),
        "opinion" to ContentTypeTemplate("Opinion / Take", listOf("Stance", "Supporting Points", "Counterpoints")),
        "story" to ContentTypeTemplate("Story / Anecdote", listOf("What Happened", "Lesson Learned")),
        "news" to ContentTypeTemplate("News / Announcement", listOf("What Happened", "Who It Affects", "Why It Matters")),
        "research_breakdown" to ContentTypeTemplate("Research / Study Breakdown", listOf("Study Summary", "Methodology", "Key Findings", "Limitations")),
        "motivational" to ContentTypeTemplate("Motivational / Mindset", listOf("Core Message", "Mindset Shift")),
        "qna" to ContentTypeTemplate("Q&A / Interview", listOf("Question", "Answer")),
        "general" to ContentTypeTemplate("General", emptyList())
    )

    fun get(contentType: String): ContentTypeTemplate =
        TEMPLATES[contentType] ?: TEMPLATES["general"]!!

    fun displayName(contentType: String): String = get(contentType).displayName
}

/* =========================================================================
 * SAMPLE / DEMO DATA — used as offline fallback when the backend is
 * unreachable, and for Compose @Preview functions.
 * ====================================================================== */

object SampleData {

    val entries: List<KnowledgeEntry> = listOf(
        KnowledgeEntry(
            id = 1,
            title = "Why RAG Beats Fine-Tuning",
            sourceUrl = "https://instagram.com/reel/abc123",
            field = "AI",
            tags = listOf("rag", "llm", "embeddings", "fine-tuning"),
            contentType = "research_breakdown",
            createdAt = "2026-06-10T09:00:00",
            summary = Summary(
                headline = "Stop fine-tuning for facts — retrieval is cheaper, faster, and stays current.",
                body = "Fine-tuning bakes knowledge into model weights, so it goes stale the moment your data changes. RAG keeps a live knowledge base your model can query at inference time, so updates are instant and cheap."
            ),
            keyPoints = "**Fine-tuning** changes the model's weights — expensive, slow, and frozen in time.\n**RAG** keeps your data external in a vector DB — the model just looks it up.\nUpdating a RAG knowledge base is a database write, not a training run.\nFine-tuning is still useful for *style/tone*, not for *facts*.\nMost \"my chatbot doesn't know our docs\" problems are RAG problems, not training problems.",
            typeSpecificFields = listOf(
                TypeSpecificField("Study Summary", "Comparison of RAG vs. fine-tuning for factual QA tasks."),
                TypeSpecificField("Methodology", "Benchmarked both approaches on a 500-question dataset."),
                TypeSpecificField("Key Findings", "RAG outperformed fine-tuning on freshness and cost."),
                TypeSpecificField("Limitations", "Retrieval quality bottlenecks overall accuracy.")
            ),
            actionItems = listOf(
                ActionItem(1, "Set up a vector DB for your docs (pgvector / Pinecone)", entryId = 1),
                ActionItem(2, "Benchmark RAG vs your current fine-tuned baseline", entryId = 1),
                ActionItem(3, "Re-index your knowledge base weekly", done = true, entryId = 1)
            ),
            nextStep = "If your model needs to know things, build a RAG pipeline first — only fine-tune once retrieval alone can't fix the problem.",
            referencedArtifacts = listOf(
                ReferencedArtifact("pgvector", ArtifactType.TOOL, url = "https://github.com/pgvector/pgvector"),
                ReferencedArtifact("LangChain RAG guide", ArtifactType.LINK)
            ),
            claims = listOf(
                Claim("Fine-tuning costs roughly 10-100x more compute than indexing for a RAG pipeline.", Verifiability.UNVERIFIED, "Depends heavily on model size and dataset."),
                Claim("RAG retrieval quality is the main bottleneck for output accuracy.", Verifiability.OPINION),
                Claim("Embeddings can be updated without retraining the base model.", Verifiability.FACT)
            ),
            exploreFurther = listOf(
                "How does chunking strategy affect retrieval quality?",
                "What's the difference between dense and hybrid (BM25+vector) retrieval?",
                "When does fine-tuning actually make sense?"
            ),
            topicMap = TopicMap("Retrieval-Augmented Generation", listOf("Vector databases", "Fine-tuning", "LLM cost optimization", "Embeddings")),
            concepts = listOf(
                Concept(1, ConceptType.FRAMEWORK, "RAG (Retrieval-Augmented Generation)", "An architecture where an LLM retrieves relevant external documents at query time instead of relying solely on parameters.", sourceEntryId = 1, entryCount = 2),
                Concept(2, ConceptType.TOOL, "pgvector", "A Postgres extension for storing and querying vector embeddings.", sourceEntryId = 1, entryCount = 1)
            ),
            connections = listOf(Connection(3, "Prompt Engineering Cheat Sheet", "topics: embeddings, llm"))
        ),
        KnowledgeEntry(
            id = 2,
            title = "3 AM Routine That Fixed My Focus",
            sourceUrl = "https://instagram.com/reel/def456",
            field = "Productivity",
            tags = listOf("morning routine", "focus", "habits"),
            contentType = "life_hack",
            createdAt = "2026-06-11T07:30:00",
            summary = Summary(
                headline = "Your focus problem might just be a first-hour problem.",
                body = "Checking your phone within minutes of waking floods your brain with dopamine and context-switches before you've even started your day. Protecting the first hour resets your baseline."
            ),
            keyPoints = "**No phone for 60 minutes** after waking — biggest single change.\nGet sunlight within 30 minutes — regulates cortisol/melatonin cycle.\nWrite 3 priorities **before** opening any app.\nA short walk beats scrolling for \"waking up\" the brain.",
            typeSpecificFields = listOf(
                TypeSpecificField("The Hack", "Wake at the same time daily, no phone for the first hour, 10-min walk before any screen."),
                TypeSpecificField("Materials Needed", "An alarm clock (not your phone)"),
                TypeSpecificField("Time Required", "First hour of your day")
            ),
            actionItems = listOf(
                ActionItem(4, "Move phone charger outside the bedroom", entryId = 2),
                ActionItem(5, "Write tomorrow's top 3 priorities tonight", entryId = 2)
            ),
            nextStep = "Try protecting just the first 30 minutes after waking for one week and track how your focus feels by midday.",
            claims = listOf(
                Claim("Morning light exposure helps regulate circadian rhythm.", Verifiability.FACT),
                Claim("This routine 'fixed' the creator's focus completely.", Verifiability.OPINION)
            ),
            exploreFurther = listOf(
                "What does the research say about phone use and dopamine?",
                "How long does it take to build a new morning habit?"
            ),
            topicMap = TopicMap("Morning Routines", listOf("Focus", "Dopamine", "Habit formation")),
            concepts = listOf(
                Concept(3, ConceptType.CONCEPT, "Dopamine Detox", "The idea of reducing high-stimulation activities (phones, social media) to restore sensitivity to everyday rewards.", sourceEntryId = 2, entryCount = 1)
            )
        ),
        KnowledgeEntry(
            id = 3,
            title = "Prompt Engineering Cheat Sheet",
            sourceUrl = "https://tiktok.com/@ai_tips/video/789",
            field = "AI",
            tags = listOf("prompting", "llm", "embeddings"),
            contentType = "listicle",
            createdAt = "2026-06-09T18:00:00",
            summary = Summary(
                headline = "Most 'bad AI output' is actually a bad prompt.",
                body = "Five small prompting habits — being specific, giving examples, asking for reasoning, specifying format, and iterating — fix the vast majority of disappointing LLM outputs."
            ),
            keyPoints = "**Specificity** beats cleverness — say exactly what you want.\nFew-shot **examples** anchor the model's output format.\nAsk the model to **think step by step** for reasoning tasks.\nAlways specify **length/format** if it matters.\nTreat the first response as a **draft**, not a final answer.",
            typeSpecificFields = listOf(
                TypeSpecificField("Items", "1. Be specific. 2. Give examples. 3. Ask for step-by-step reasoning. 4. Specify format/length. 5. Iterate, don't expect perfect first try.")
            ),
            actionItems = listOf(
                ActionItem(6, "Rewrite your most-used prompt with 1-2 examples included", entryId = 3)
            ),
            nextStep = "Pick your most-used prompt and add one concrete example to it today.",
            referencedArtifacts = listOf(
                ReferencedArtifact("Anthropic prompting guide", ArtifactType.LINK, url = "https://docs.claude.com")
            ),
            claims = listOf(
                Claim("Few-shot examples improve output consistency.", Verifiability.FACT)
            ),
            exploreFurther = listOf("What's the difference between zero-shot and few-shot prompting?"),
            topicMap = TopicMap("Prompt Engineering", listOf("LLM", "Few-shot learning", "Embeddings")),
            concepts = listOf(
                Concept(1, ConceptType.FRAMEWORK, "RAG (Retrieval-Augmented Generation)", "An architecture where an LLM retrieves relevant external documents at query time instead of relying solely on parameters.", sourceEntryId = 1, entryCount = 2)
            ),
            connections = listOf(Connection(1, "Why RAG Beats Fine-Tuning", "topics: embeddings, llm"))
        )
    )

    val summaries: List<EntrySummary> = entries.map {
        EntrySummary(it.id, it.title, it.summary.headline, it.field, it.contentType, it.tags, it.createdAt)
    }

    val collectionNames: List<String> = listOf("AI Research", "Morning Routine Vault")

    val collectionMembers: Map<String, List<Int>> = mapOf(
        "AI Research" to listOf(1, 3),
        "Morning Routine Vault" to listOf(2)
    )

    /** Deduplicated concept index across all entries — mirrors GET /api/concepts. */
    val allConcepts: List<Concept> = entries
        .flatMap { it.concepts }
        .groupBy { it.id ?: it.name }
        .map { (_, occurrences) ->
            occurrences.first().copy(entryCount = occurrences.sumOf { it.entryCount }.coerceAtLeast(occurrences.size))
        }

    fun entryById(id: Int): KnowledgeEntry? = entries.find { it.id == id }

    fun allActionItems(): List<Pair<KnowledgeEntry, ActionItem>> =
        entries.flatMap { entry -> entry.actionItems.map { entry to it } }

    fun entriesForConcept(conceptId: Int): List<KnowledgeEntry> =
        entries.filter { entry -> entry.concepts.any { it.id == conceptId } }
}
