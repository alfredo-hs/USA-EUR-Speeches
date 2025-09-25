# ------------------------------------------------------------------------------
# Setup Libraries
# ------------------------------------------------------------------------------

library(tidyverse)
library(tidytext)
library(reticulate)
set.seed(344)

# ------------------------------------------------------------------------------
# Tokenize Sentences
# ------------------------------------------------------------------------------
unga_usa <- readRDS("unga_usa.rds")

usa_sentences <- unga_usa %>%
  mutate(
    text = str_replace_all(text, "Mr.", "Mr"),
    text = str_replace_all(text, "Mrs.", "Mrs"),
    text = str_replace_all(text, "Ms.", "Ms"),
    text = str_replace_all(text, "Dr.", "Dr"),
  ) %>% 
  unnest_tokens(sentence,
                text,
                drop = T,
                to_lower = F,
                token = "sentences") %>% 
  filter(str_count(sentence, "\\w+") >= 4) %>% 
  group_by(doc_id) %>%
  mutate(rank = row_number(),
         sentence_id = paste(doc_id, rank, sep = "_")) %>%
  select(-rank) %>%
  ungroup()

# ------------------------------------------------------------------------------
# Python Setup
# ------------------------------------------------------------------------------

transformers <- import("transformers")

pipeline <- transformers$pipeline

zeroshot <- transformers$pipeline(
  task = "zero-shot-classification",
  model = "facebook/bart-large-mnli"
)

classify_sentences_adaptive <- function(df, 
                                        classifier, 
                                        labels) {
  required_packages <- c("dplyr", "tibble", "purrr", "reticulate")
  installed <- installed.packages()
  missing <- setdiff(required_packages, rownames(installed))
  if (length(missing) > 0) install.packages(missing)
  lapply(required_packages, require, character.only = TRUE)
  unique_labels <- unique(unlist(labels))
  label_colnames <- make.names(unique_labels, unique = TRUE)
  classify_single <- function(sentence) {
    result <- classifier(sentence, unique_labels)
    scores_r <- unlist(reticulate::py_to_r(result$scores))
    labels_r <- unlist(reticulate::py_to_r(result$labels))
    scores_named <- setNames(as.numeric(scores_r), labels_r)
    score_row <- setNames(
      lapply(unique_labels, function(lbl) scores_named[[lbl]] %||% NA_real_),
      paste0(label_colnames, "_score")
    )
    tibble::as_tibble(score_row)
  }
  results <- purrr::map_dfr(df$sentence, classify_single)
  dplyr::bind_cols(df, results)
}

sentiment <- pipeline(
  task ="sentiment-analysis",
  model = "distilbert-base-uncased-finetuned-sst-2-english")

classify_sentiment_adaptive <- function(df,
                                        classifier,
                                        threshold = 0.5,
                                        neutral_label = "NEUTRAL") {
  required_packages <- c("dplyr", "tibble", "purrr", "reticulate")
  installed <- installed.packages()
  missing <- setdiff(required_packages, rownames(installed))
  if (length(missing) > 0) install.packages(missing)
  lapply(required_packages, require, character.only = TRUE)
  classify_single <- function(sentence) {
    raw <- classifier(sentence, return_all_scores = TRUE)[[1]]
    labs  <- vapply(raw, function(x) reticulate::py_to_r(x$label),   character(1))
    probs <- vapply(raw, function(x) reticulate::py_to_r(x$score),   numeric(1))
    names(probs) <- toupper(labs)
    pos <- probs[["POSITIVE"]]
    neg <- probs[["NEGATIVE"]]
    if (is.null(pos)) pos <- 1 - neg
    if (is.null(neg)) neg <- 1 - pos
    chosen_label <-
      if (!is.na(pos) && pos >= threshold && pos >= neg) "POSITIVE"
    else if (!is.na(neg) && neg >= threshold && neg >  pos) "NEGATIVE"
    else neutral_label
    tibble::tibble(
      sentiment_label = chosen_label,
      positive_score  = as.numeric(pos),
      negative_score  = as.numeric(neg)
    )
  }
  results <- purrr::map_dfr(df$sentence, classify_single)
  dplyr::bind_cols(df, results)
}

# ------------------------------------------------------------------------------
# Classification Tasks
# ------------------------------------------------------------------------------

label = "Europe and European countries"

system.time({
  classified_df <- classify_sentences_adaptive(
    df = usa_sentences,
    classifier = zeroshot,
    labels = label
  )
})

europe_df <- classified_df %>% 
  filter(Europe.and.European.countries_score >= .8)

system.time({
  europe_df <- classify_sentiment_adaptive(
    df = europe_df,
    threshold = .8,
    classifier = sentiment
  )
})

main <- europe_df %>% 
  filter(sentiment_label != "NEUTRAL") %>%
  group_by(year, sentiment_label) %>% 
  tally() %>% 
  ungroup() %>% 
  left_join(
    usa_sentences %>% 
      group_by(year) %>%
      summarise(total_s = n()) 
  ) %>% 
  mutate(
    perc = (n/total_s)*100
  )

# ------------------------------------------------------------------------------
# Visualization
# ------------------------------------------------------------------------------

main %>% 
  ggplot() +
  geom_area(
    aes(x = year, 
        y = total_s/100),
    alpha = .2
  ) +
  geom_col(
    aes(x = year, 
        y = perc, 
        fill = sentiment_label)
    , position = position_dodge()
  ) +
  scale_y_continuous(
    name = "Sentences about Europe (%)",
    sec.axis = sec_axis(~.*100, name = "All Speech Sentences (N)")
  ) +
  scale_x_continuous(
    breaks = seq(min(1950, na.rm = TRUE),
                 max(2025, na.rm = TRUE),
                 by = 5)
  ) +
  scale_fill_manual(values = c("red", "blue")) +
  annotate("text", 
           x = 2010, 
           y = 5, 
           label = "Trump's 2025 Speech", 
           hjust = 0.5, 
           size = 5, 
           fontface = "bold") +
  annotate("segment", 
           x = 2010, xend = 2025, 
           y = 4.5, 
           yend = max(main$perc[main$year == 2025], na.rm = TRUE) + .1, 
           arrow = arrow(length = unit(0.2, "cm"))) +
  labs(
    x = NULL,
    fill = "Sentiment:",
    caption = "Visualization by: @alfredo-hs"
  ) +
  theme_classic() +
  theme(legend.position = "top",
        plot.caption = element_text(
          hjust = 0,            
          vjust = 0,            
          size = 8,
          face = "italic",
          colour = "grey40"
        ),
        plot.caption.position = "plot")

ggsave("usa_europe.png",
       width = 20,
       height = 10,
       unit = "cm")

