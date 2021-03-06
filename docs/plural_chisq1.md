---
title: "Plural von Kunstwörtern"
author: "Teodor Petrič"
date: "2021-4-14"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# Naložimo programe

```{r}
library(tidyverse)
library(scales)

```

# Preberemo podatkovni niz z diska

```{r}
# Branje datoteke je možno na več načinov
plural_subj1 = read.csv("data/plural_Subj_sum.csv", sep = ";")
plural_subj1 = read.csv2("data/plural_Subj_sum.csv")
plural_subj1 = read_csv2("data/plural_Subj_sum.csv")

# Pokaži prvih šest vrstic
head(plural_subj1)

```

# Povzetek in Hi-kvadrat test

Podatkovni niz preoblikujemo in povzemamo (agregacija). 
Za preizkus ustvarimo tabelo 2 x 2 z opazovanimi pogostnostmi (frekvencami).
Program izračuna pričakovane pogstnosti in zatem še ocenjuje, ali je razlika med vzorcema statistično značilna.

H0: Preizkusne osebe uporabljajo množinske pripone ne glede na besedni tip (Rhyme / Non-Rhyme).
H1: Preizkusne osebe uporabljajo množinske pripone z ozirom na besedni tip (Rhyme / Non-Rhyme).

Če je p-vrednost < 0,05 (tj. 5%), potem obvelja H1: razlika med opazovanimi in pričakovanimi pogostnostmi je statistično značilna (tj. da ni naključna in dovolj velika ob upoštevanju napake). 

Če p > 0,05, potem obdržimo H0: razlika med opazovanimi pogostnostmi je naključna.

```{r}
# Povzemamo ("aggregate")
(p = plural_subj1 %>% 
  group_by(WordType) %>% 
  summarise(Sigstark = mean(Sigstark),
            En = sum(En), E = sum(E), Er = sum(Er), S = sum(S), Z = sum(Z)) 
)

# Izberemo tri stolpce
q = p %>% select(WordType, E, S)

# Razlika med deleži množinskih pripon E in S (npr. Bal-e oder Bal-s)
chisq.test(q[,-1]) # prvi stolpec naj se ne upošteva, zato [, -1]

```

## Naslednji preizkus(i)

```{r}
# Izberemo tri stolpce za naslednji preizkus
q = p %>% select(WordType, E, Er)

# Razlika med deleži množinskih pripon E in Er (npr. Bal-e oder Bal-er)
chisq.test(q[,-1]) # prvi stolpec naj se ne upošteva, zato [, -1]

```

## Tabela 2 x 3

Možno je tudi testiranje treh ali več vzorcev, vendar nam test ne pove, kateri vzorec je različen od drugega.

```{r}
# Izberemo tri stolpce za naslednji preizkus
q = p %>% select(WordType, Er, E, S)

# Razlika med deleži množinskih pripon E in Er (npr. Bal-e oder Bal-er)
chisq.test(q[,-1]) # prvi stolpec naj se ne upošteva, zato [, -1]

```

