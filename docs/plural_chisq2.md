---
title: "Chi-Quadrat-Test mit Plural-Datensatz"
author: "Teodor Petrič"
date: "2021-4-20"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# Programm aufrufen

```{r}
# Install required packages
# nur wenn noch nicht installiert
# install.packages("tidyverse")
 
# Import required library
library(tidyverse)

```

# Datei laden

```{r}
plural_subj1 = read.csv2("data/plural_Subj_sum.csv")
head(plural_subj1)

```

# Ergebnisse summieren

```{r}
(p <- plural_subj1 %>% 
  group_by(WordType) %>% 
  summarise(En = sum(En), E = sum (E))
)

```

# Chi-Quadrat-Test
Falls p < 0,05: es gilt H1 (Stichproben unterscheiden sich).
Falls p > 0,05: es gilt H0 (kein Unterschied zwischen Stichproben).

```{r}
(chi <- chisq.test(p[,-1])
)

```

## Beobachtete / erwartete Werte

```{r}
(tabelle <- as_tibble(cbind(chi$observed, chi$expected)) %>%
   mutate(Wordtyp = unlist(p[,1])) %>% # Spalte wieder hinzufügen
   mutate(Wordtyp = str_replace(Wordtyp, "NoRhyme", "Nicht-Reimwort"), # auf deutsch
          Wordtyp = str_replace(Wordtyp, "Rhyme", "Reimwort")) %>% # auf deutsch
   rename(En_erwartet = V3, E_erwartet = V4) %>%  # erwartete Werte, wenn H0 richtig ist
   select(Wordtyp, En, E, En_erwartet, E_erwartet)) # Reihenfolge der Variablen verändern

```

