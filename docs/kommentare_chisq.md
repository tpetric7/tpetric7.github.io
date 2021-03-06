---
title: "Lange und kurze Kommentare"
author: "Teodor Petrič"
date: "2021-4-7"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

```{r}
library(tidyverse)
library(scales)
library(janitor)

```

# Datei laden

Eine Lehrerin möchte wissen, ob es effektiver ist, wenn sie am Rand der Schüleressays kurze oder ausführlichere Kommentare zu den Fehlern der Schüler_innen notiert. Sie vergleicht somit zwei Schülergruppen (Schüler_innen mit kurzen vs. langen Kommentaren) und zwei Beurteilungskategorien (korrekte vs. inkorrekte Äußerungen in den Essays).

```{r}
# von github laden
kommentare = read.delim("https://raw.githubusercontent.com/tpetric7/chi-sq/main/data/chisq_kommentare.txt",
                        sep = "\t", fileEncoding = "UTF-8")
# Variablennamen konsequent schreiben
kommentare = kommentare %>% 
  clean_names()

# Von der Festplatte laden
kommentare = read.delim("data/chisq_kommentare.txt", sep = "\t", fileEncoding = "UTF-8") %>% 
  clean_names()
head(kommentare)

```

# Chi-Quadrat-Test

Stichproben: kurzer Kommentar vs. langer Kommentar

H0: Zwischen den beiden Stichproben besteht kein signifikanter Unterschied (Unterschiede zufällig).
H1: Zwischen den beiden Stichproben besteht ein signifikanter Unterschied (Unterschiede nicht zufällig).

```{r}
chisq.test(kommentare[,-1])

```

Wir verwerfen H0 und nehmen H1 an: zwischen kurzen und langen Kommentaren besteht ein nicht zufälliger Unterschied.


# Graphische Darstellung

```{r}
(kom_lang = kommentare %>% 
  as_tibble() %>% 
  pivot_longer(kurzer_kommentar:ausfuhrlicher_kommentar, 
               names_to = "Kommentar",
               values_to = "Fehler") %>% 
  mutate(pct = Fehler/sum(Fehler))
)

kom_lang  %>%  ggplot(aes(Kommentar, pct, fill = neugeschriebener_satz)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = percent_format()) +
  labs(x = "Neugeschriebener Satz", y = "",
       title = "Wirksamkeit kurzer und langer Kommentare")

```

