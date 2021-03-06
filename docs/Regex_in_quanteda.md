---
title: "Regex in quanteda"
author: "Teodor Petrič"
date: "2021-6-4"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# 0. Programi

Najprej moramo zagnati programe, ki jih potrebujemo za načrtovano delo.

```{r}
library(readtext)
library(quanteda)
library(quanteda.textstats)
library(quanteda.textplots)
library(tidyverse)

```


# 1. Preberemo besedila

```{r}
txt = readtext("data/books/*.txt", encoding = "UTF-8")
txt

```

# 2. Ustvarimo korpus

Ustvarimo korpus ali jezikovno gradivo. Ukaz v programu "quanteda" je corpus().

```{r}
romane = corpus(txt)

```


# 3. Tokenizacija

```{r}
woerter = tokens(romane)

```


# 4. Kwic

Za sestavo konkordanc ima program quanteda funkcijo *kwic()* (keyword in context).

Možno je iskati posamezne besede, besedne zveze, uporabljamo pa lahko tudi nadomestne znake (npr. *).

## Frau, Mann

```{r}
kwic(woerter, pattern = c("Frau", "Herr"))

```

Konkordanco bomo pretvorili v podatkovno zbirko, tj. *data.frame* ali *tibble()*. Prednost je npr., da tako pridobimo imena stolpcev (tj. spremenljivk).

*kwic()* ima več možnosti, npr. "case_insensitive = FALSE" razlikuje med velikimi in malimi črkami. Privzeta vrednost je "TRUE", tj. da tega ne razlikuje (tako kot Excel).

```{r}
(konkordanca = kwic(woerter, pattern = c("Frau", "Herr"), case_insensitive = FALSE) %>% 
  as_tibble()
)

```

Z ukazom *count()* lahko preštejemo, koliko pojavnic je *kwic()* našel v jezikovnem gradivu.

```{r}
konkordanca %>% 
  count(keyword)

```

## Pripona -in

Poiskati želimo besede s pripono "-in" za samostalnike, ki označujejo ženska osebna imena (npr. Ärztin, Köchin, ...).

```{r}
(konkordanca2 <- kwic(woerter, pattern = c("*in"), case_insensitive = FALSE) %>% 
  as_tibble()
)

```

Med ključnimi besedami (keywords) so tudi besedne oblike, ki jih nismo želeli (npr. ein, in, ...).
Na seznamu želimo imeti samo samostalnike s pripono -in (npr. Köchin, Zimmervermieterin, ...).

Regularni izrazi (regular expressions, na kratko: regex) nam bodo pomagali izločiti nezaželene zadetke. Po navadi je to postopen proces, dokler ne najdemo najustreznejšega regularnega izraza.

\\A   na začetku črkovnega niza
\\Z   na koncu črkovnega niza
^   na začetku črkovnega niza ali na začetku vrstice v večvrstičnem vzorcu
$   na koncu vrstice

\\b   besedni rob
\\w   beseda
\\<   začetek besede
\\>   konec besede

\\s   presledek
\\d   števka
[A-Z]   samo abecedo (velike črke)
[a-z]   samo abecedo (male črke)
[^Eae]    teh znakov želimo izločiti

*   nič ali več znakov
+   en ali več znakov
.   poljuben znak (razen: nova vrstica \n)

```{r}
(konkordanca2 = as_tibble(kwic(woerter, pattern = "\\b[A-Z].+[^ae]in\\b",
                      valuetype = "regex", case_insensitive = FALSE)) %>% 
    filter(keyword != "Immerhin", 
         keyword != "Darin",
         keyword != "Termin",
         keyword != "Worin",
         keyword != "Robin",
         keyword != "Medizin",
         keyword != "Disziplin",
         keyword != "Austin",
         keyword != "Musselin",
         keyword != "Benjamin",
         keyword != "Franklin")
)

```

Od 4100 zadetkov je ostalo le 46 zadetkov, ki vsebujejo samostalnik s pripono -in, ki označuje žensko. Večino napačnih besed smo s seznama odstranili z izbranim regularnim izrazom. Okrog deset smo morali posamično izločiti s funkcijo *filter()*.


## Pripona -er

V naslednji nalogi želimo poiskati samostalnike s pripono -er, ki se pogosto nanašajo na osebe moškega spola. 

Glede na to, da se pripona -er uporablja v mnoge druge namene, bo najbolje, če 
- najprej odstranimo funkcijske in druge pogoste besede (seznam stopwords)
- in šele potem poizvedujemo s funkcijo kwic()

```{r}
wortformen = tokens_select(woerter, pattern = c(stopwords("de"), "bisher","immer"), 
                           selection = "remove")

```

Približno 500 besednih oblik manj, kot če ne bi izločili "stopwords".

```{r}
(nomen_er = as_tibble(kwic(wortformen, pattern = "\\b[A-Z].+er\\b",
                      valuetype = "regex", case_insensitive = FALSE))
)

```

462 je besednih oblik, ki se konča na -er, vendar med njimi niso samo samostalniki, ki bi se nanašali na osebe moškega spola.

```{r}
nomen_er %>% 
  count(keyword, sort = T)

```

Še vedno je potrebno posamično filtriranje: bodisi zaradi pomena bodisi zaradi besedotvornega vzorca. Zaradi prej izločenih nezaželenih besed (stopwords) je filtrirni seznam nekoliko krajši.

```{r}
(nomina_er = nomen_er %>%
  filter(!str_detect(keyword, 
                     c("[Z|z]immer|[P|p]apier|[F|f]inger|[W|w]asser|[H|h]äuser|[B|b]ücher|spritzer|[G|g]itter|[K|k]ammer|[W|w]etter")),
         !keyword %in% c("Kinder","Messer","Blätter","Kleider","Bilder","Nummer","Koffer","Fenster",
                         "Feuer","Körper","Gesichter","Kummer","Abenteuer","Schulter","Tier",
                         "Theater","Fehler","Gelächter","Mutter","Seufzer","Vater","Wunder","Atelier",
                         "Geister","Mauer","Ufer","Bruder","Hunger","Lichter","Eimer","Lager",
                         "Meter","Trauer","Polster","Manier"))
)

```


```{r}
nomina_er %>% 
  group_by(docname) %>% 
  count(keyword, sort = T)

```

Za grafični prikaz obdržimo samo po 20 najpogostnejših izrazov iz vsakega besedila.

```{r}
nomina_er %>% 
  group_by(docname) %>% 
  count(keyword, sort = T) %>% 
  slice_head(n=20)

```

V romanu Tom Sawyer so priimki na -er na vrhu lestvice, roman Prozess vsebuje bistvenih več splošnih samostalnikov, ki se končajo s pripono -er in se nanašajo na moške osebe. Edini Priimek je Bürstner.

```{r}
library(tidytext)
nomina_er %>% 
  group_by(docname) %>% 
  count(keyword, sort = T) %>% 
  slice_head(n=20) %>% 
  mutate(keyword = reorder_within(keyword, n, n, sep = ": ")) %>% 
  ggplot(aes(n, keyword, fill = keyword)) +
  geom_col() +
  theme(legend.position = "none") +
  facet_wrap(~ docname, scales = "free") +
  labs(x = "Frequenz", y = "")

```


## Pripona -ung

```{r}
(nomen_ung = as_tibble(kwic(woerter, pattern = "\\b[A-Z].+ung\\b",
                      valuetype = "regex", case_insensitive = FALSE))
)

```

V romanu Prozess je število pojavnic samostalnikov na -ung skoraj enkrat večje kot v Tomu.
Mnogi samostalniki s pripono -ung so abstraktni in težje razumljivi kot konkretni samostalniki.

```{r}
nomen_ung %>% 
  group_by(docname) %>%
  count(keyword, sort = T) %>% 
  summarise(Freq = sum(n))

```

```{r}
kwic_ung = kwic(woerter, pattern = "\\b[A-Z].+ung\\b",
                      valuetype = "regex", case_insensitive = FALSE)
textplot_xray(kwic_ung)
```


Najpogostnejši samostalniki s pripono -ung odražajo osrednjo tematiko obeh besedil. V romanu Prozess se pogosteje pojavljajo samostalniki s pripono -ung, ki spadajo v pomensko polje "(kriminalno) pravo", v romanu Tom Sawyer pa je na vrhu lestvice več takih samostalnikov, ki se nanašajo na geografski prostor in razpoloženje.

```{r}
library(tidytext)
(nomina_ung = nomen_ung %>% 
  group_by(docname) %>% 
  count(keyword, sort = T) %>% 
  slice_head(n=20) %>% 
  mutate(keyword = reorder_within(keyword, n, n, sep = ": "))
)

nomina_ung %>% 
  ggplot(aes(n, keyword, fill = keyword)) +
  geom_col() +
  theme(legend.position = "none") +
  facet_wrap(~ docname, scales = "free") +
  labs(x = "Frequenz", y = "")

```

Iskanje besednih zvez s funkcijo *kwic()* in *phrase()* - funkcijske glagolske zveze (Funktionsverbgefüge) in frazemi:

```{r}
(fvg1 =  as_tibble(kwic(woerter, pattern = phrase(
  c("zur|in .+ung (ge)komm.+|(ge)brach.+|bring.+")),
                 valuetype = "regex", case_insensitive = FALSE))
)

```

Če so med sestavnimi deli besedne zveze drugi izrazi, lahko tudi postopoma filtriramo:

```{r}
phrase1 = "\\bstand.*|\\bsteh.*"

(fvg2 = as_tibble(kwic(woerter, pattern = phrase(phrase1), window = 10,
                 valuetype = "regex", case_insensitive = FALSE)) %>% 
  filter(str_detect(post, "zur")) %>% 
  filter(str_detect(post, ".+ung\\b"))
)

```


# 5. tidytext

Pretvorba besedil v povedi s programom tidytext, funkcija *unnest_tokens()*:

```{r}
romantexte = txt %>% 
  as_tibble() %>% 
  unnest_tokens(sentence, text, token = "sentences")

```


Izvleci samostalniške zveze:

```{r}
np = "(der|die|das|des|dem|den) ([^ ]+)"

romantexte %>%
  str_extract_all(np)

# romantexte %>%
#   str_match_all(np)

```


Izvleci FVG:

```{r}
nomphrase = "stand.*\\W(\\w+){1,3}\\szur\\s.+ung"
nomphrase = "stand.* (zur .+ung)"

romantexte %>%
  select(sentence) %>% 
  str_extract_all(nomphrase) %>% 
  head(10)

```

