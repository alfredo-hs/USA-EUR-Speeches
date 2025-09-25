# UNGA USA Speech Analysis – Europe Sentiment

This repository contains an R + Python pipeline (via [`reticulate`](https://firsa.eu/posts/ner_reticulate/ner_tutorial_r.html)) to analyze references to **Europe** in United Nations General Assembly (UNGA) speeches delivered by the United States.  
The project combines **sentence tokenization, zero-shot classification, sentiment analysis, and visualization**.

---

## Overview

1. **Data**  
   - Source: `unga_usa.rds` (pre-collected UNGA speeches by US representatives).  
   - Each speech is tokenized into sentences, cleaned of honorifics (Mr., Dr., etc.), and filtered to keep only sentences with ≥4 words.

2. **Classification**  
   - **Zero-shot classification** with [`facebook/bart-large-mnli`](https://huggingface.co/facebook/bart-large-mnli) to detect references to *Europe and European countries*.  
   - **Sentiment analysis** with [`distilbert-base-uncased-finetuned-sst-2-english`](https://huggingface.co/distilbert-base-uncased-finetuned-sst-2-english), with a configurable threshold for labeling sentences as **POSITIVE**, **NEGATIVE**, or **NEUTRAL**.

3. **Visualization**  
   - Sentences mentioning Europe are aggregated by year.  
   - Dual-axis chart shows the proportion of Europe-related sentences with positive/negative sentiment, alongside the total number of sentences per year.

---

## Dependencies

**R packages:**
- `tidyverse`
- `tidytext`
- `reticulate`
- `ggplot2`
- `dplyr`, `tibble`, `purrr`

**Python packages (via reticulate):**
- `transformers`
- `torch`

Make sure you have a working Python environment accessible from R, e.g. `use_python()`.

