---
title: "Morati vs. Treba"
author: "Teodor Petrič"
date: "2021-5-14"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# 0. Packages

```{r message=FALSE, warning=FALSE}
library(tidyverse)
library(scales)
library(janitor)
library(readxl)

```


# 1. Datei laden

Gigafida: 
Gebrauchsfrequenzen (Tokenfrequenzen) der Modalkonstruktionen 
- "morati + Infinitiv" und 
- "biti + treba + Infinitive".

```{r}
naklonska <- read_xlsx("data/morati_treba.xlsx") %>% clean_names()
naklonska

```

Die zweite Tabelle zeigt die Distribution der beiden Modalkonstruktionen in fünf Funktionalstilen.

```{r}
naklonska2 <- read_xlsx("data/morati_treba.xlsx", sheet = "List2") %>% clean_names()
naklonska2

```

Die Modalkonstruktion "morati + Infinitiv" wird ca. dreimal so häufig verwendet wie "biti + treba + Infinitiv".


# 2. Graphische Darstellung

Die graphischen Darstellungen zeigen eher geringe Distributionsunterschiede. 

```{r}
naklonska %>%
  pivot_longer(treba:morati, names_to = "konstruktion", values_to = "freq") %>% 
  ggplot(aes(konstruktion, freq, fill = vrsta_besedila)) +
  geom_col(position = "fill") +
  scale_y_continuous(labels = percent_format()) +
  labs(x = "Modalkonstruktion", y = "Gebrauchsfrequenz", fill = "Vrsta besedila")

```

Die Modalkonstruktion "morati + Infinitiv" scheint in den alltagssprachlich näherstehenden Funktionalstilen Belletristik (leposlovje), Internet und Sachtexten (stvarna besedila) etwas häufiger belegt zu sein als die Modalkonstruktion "biti + treba + Infinitiv", dafür aber in Zeitungen (Časopisi) etwas seltener. 

```{r}
naklonska2 %>%
  pivot_longer(treba:morati, names_to = "konstruktion", values_to = "freq") %>% 
  ggplot(aes(konstruktion, freq, fill = vrsta_besedila)) +
  geom_col(position = "fill") +
  scale_y_continuous(labels = percent_format()) +
  labs(x = "Modalkonstruktion", y = "Gebrauchsfrequenz", fill = "Vrsta besedila")

```


# 3. Chi-Quadrat-Test

Annahme: Die Modalkonstruktion "morati + Infinitiv" ist weniger markiert als die Modalkonstruktion "biti + treba + Infinitiv". Formael und semantische Begründungen: ...
H0: Die beiden Modalkonstruktionen kommen in denselben Funktionalstilen vor.
H1: Die beiden Modalkonstruktionen kommen nicht in denselben Funktionalstilen vor.

Der erste Chi-Quadrat-Test zeigt, dass die beiden Stichproben (morati vs. treba) unabhängig voneinander sind (p < 0,001). Damit können wir die Nullhypothese (H0) verwerfen und die alternative Hypothese (H1) akzeptieren. Die beiden Modalkonstruktionen kommen demnach nicht im gleichen Maße in denselben Funktionalstilen vor.

```{r}
chisq.test(naklonska[ , -1])

```

Der zweite Chi-Quadrat bestätigt Hypothese H1. Die Distribution der beiden Modalkonstruktionen unterscheidet sich. Die graphische Darstellung deutet an, dass dies vor allem am vergleichsweise selteneren Gebrauch der Modalkonstruktion "morati + Infinitiv" in  publizistischen Texten liegen könnte. Nach unser Annahme wird die Modalkonstruktion "biti + treba + Infinitiv" häufiger in Texten mit dem Merkmal [+Distanz] eingesetzt. 

```{r}
chisq.test(naklonska2[ , -1])

```

