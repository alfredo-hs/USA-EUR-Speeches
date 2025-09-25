{\rtf1\ansi\ansicpg1252\cocoartf2759
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 # UNGA USA Speech Analysis \'96 Europe Sentiment\
\
This repository contains an R + Python pipeline (via [`reticulate`](https://firsa.eu/posts/ner_reticulate/ner_tutorial_r.html)) to analyze references to **Europe and European Countries** in United Nations General Assembly (UNGA) speeches delivered by the United States.  \
The project combines **sentence tokenization, zero-shot classification, sentiment analysis, and visualization**.\
\
---\
\
## Overview\
\
1. **Data**  \
   - Source: `unga_usa.rds` (pre-collected UNGA speeches by US representatives).  \
   - Each speech is tokenized into sentences, cleaned of honorifics (Mr., Dr., etc.), and filtered to keep only sentences with \uc0\u8805 4 words.\
\
2. **Classification**  \
   - **Zero-shot classification** with [`facebook/bart-large-mnli`](https://huggingface.co/facebook/bart-large-mnli) to detect references to *Europe and European countries*.  \
   - **Sentiment analysis** with [`distilbert-base-uncased-finetuned-sst-2-english`](https://huggingface.co/distilbert-base-uncased-finetuned-sst-2-english), with a configurable threshold for labeling sentences as **POSITIVE**, **NEGATIVE**, or **NEUTRAL**.\
\
3. **Visualization**  \
   - Sentences mentioning Europe are aggregated by year.  \
   - Dual-axis chart shows the proportion of Europe-related sentences with positive/negative sentiment, alongside the total number of sentences per year.\
\
---\
\
## Dependencies\
\
**R packages:**\
- `tidyverse`\
- `tidytext`\
- `reticulate`\
- `ggplot2`\
- `dplyr`, `tibble`, `purrr`\
\
**Python packages (via reticulate):**\
- `transformers`\
- `torch`\
\
Make sure you have a working Python environment accessible from R. In the script, `use_python()` points to:\
\
}