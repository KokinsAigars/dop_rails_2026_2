1) SourceDoc (root, stable)

    Represents a real-world source:
    a PDF file
    a scanned image set
    a remote URL
    Table: ocr_source_doc
    Key role: identity and metadata

2) Page (stable)
    
    A document contains pages. A page is:
    source_doc_id + page_no
    plus page-level metadata (dpi, dimensions, page hash)
    Table: ocr_page
    Key role: the stable coordinate system (“page 17 of doc X”)

3) Run (produced, process-level)
    
    An OCR run is one execution of an OCR engine:
    engine + version
    config
    start/finish + status + log
    Table: ocr_run
    Key role: provenance (“how was OCR generated?”)

4) PageResult (produced output per run per page)
    
    This is the join of process + page:
    fk_run_id
    fk_page_id
    raw OCR JSON/text
    mean confidence / warnings
    Table: ocr_page_result
    Key role: “run R produced OCR output for page P”


5) Token (produced, granular)
    
    OCR text broken into ordered units:
    (page_result_id, token_no)
    text + normalized text
    bbox + confidence + kind
    Table: ocr_token
    Key role: reconstruction + layout + search at token level


6) Review (human layer)

    One review per page_result:
    status (pending/approved/...)
    approved_text (human corrected)
    reviewed_by + timestamp
    Table: ocr_review
    Key role: curated output you trust

7) Link (semantic layer)
    
    Connect OCR output to your dictionary:
    links from page_result → index/entry
    link_kind + confidence + note
    Table: ocr_link
    Key role: bridges OCR to sc_03_dictionary entities


API navigation flow (how you’ll use it)
    
    Find document
    GET /api/v1/ocr/source_docs?limit=...
    
    Get pages
    GET /api/v1/ocr/source_docs/:id/pages
    
    For a given page, see results
    GET /api/v1/ocr/pages/:id/results
    
    Get one result “full payload”
    GET /api/v1/ocr/page_results/:id/full
    → gives you tokens + review + links in one call
    
    Write data fast
    
    POST /page_results/:id/tokens/bulk_create
    
    POST/PATCH /page_results/:id/review
    
    POST /page_results/:id/links/bulk_create
    

EXAMPLE:
    POST /api/v1/ocr/page_results/:id/ingest
{
    "mode": "replace",
    "tokens": [
        {"token_no": 0, "text": "Buddha", "text_norm": "buddha", "bbox": {"x": 1, "y": 2, "w": 3, "h": 4}, "confidence": 98.7, "kind": "word"}
    ],
    "review": {
        "review_status": "pending",
        "review_note": "auto import",
        "reviewed_by": {"source": "pipeline", "run": "v1"}
    },
    "links": [
        {"fk_entry_id": "UUID-HERE", "link_kind": "candidate_entry", "link_conf": 88.2, "note": "ngram"}
    ]
}
