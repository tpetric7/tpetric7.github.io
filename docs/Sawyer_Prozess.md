---
title: "Tom Sawyer vs Der Prozess"
author: "Teodor Petrič"
date: "2021-5-19"
output: html_document
editor_options: 
  chunk_output_type: console #inline
  markdown: 
    wrap: 80
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# 0. Nameščanje programov (Packages)

Namestitev: Če ste program(e) že namestili, lahko preskočite ta korak.

Znak \# v programskem bloku (chunk) pomeni, da se ta vrstica ne izvaja. Odstrani
\# če želite program namestiti.

```{r}
# # Programe, ki jih še nimate, lahko namestite tudi na ta način (odstranite #):
# install.packages("readtext")
# ...

## First specify the packages of interest
packages = c("tidyverse", "quanteda", "quanteda.textplots", 
             "quanteda.textstats", "wordcloud2", "tidytext", 
             "udpipe", "janitor", "scales", "widyr", "syuzhet", 
             "corpustools", "readtext")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

```

# 0. Programi

Najprej moramo zagnati programe, ki jih potrebujemo za načrtovano delo.

```{r}
library(readtext)
library(quanteda)
library(quanteda.textstats)
library(quanteda.textplots)
library(tidyverse)
library(tidytext)
library(wordcloud2)
library(udpipe)
library(janitor)
library(scales)
library(widyr)
library(syuzhet)
library(corpustools)

```

# 1. Preberemo besedila

```{r}
txt = readtext("data/books/*.txt", encoding = "UTF-8")
txt

```

Alternativno lahko besedila preberemo tudi z medmrežja:

```{r}
txt1 = readtext("https://raw.githubusercontent.com/tpetric7/tpetric7.github.io/main/data/books/prozess.txt", encoding = "UTF-8")
txt2 = readtext("https://raw.githubusercontent.com/tpetric7/tpetric7.github.io/main/data/books/tom.txt", encoding = "UTF-8")

# Datoteki združimo
txt = rbind(txt1,txt2)

```

# 2. Ustvarimo korpus

Ustvarimo korpus ali jezikovno gradivo. Ukaz v programu "quanteda" je corpus().

```{r}
romane = corpus(txt)

```

Povzetek:

Program quanteda ima dve funkciji za povzemanje: - summary() -
textstat_summary()

```{r}
(romanstatistik = textstat_summary(romane)
)

```

```{r}
povzetek = summary(romane)
povzetek

```

Podatke iz povzetka bi lahko uporabili npr. za izračun povprečne dolžine povedi
v besedilih:

```{r}
povzetek %>% 
  group_by(Text) %>%
  mutate(dolzina_povedi = Tokens/Sentences)

```

Lahko bi tudi izračunali kazalnik slovarske raznolikosti v besedilih, tj.
razmerje med različnimi (types) in pojavnicami (tokens), kar se angleščini
imenuje "type token ratio" (ttr).

Razlikujemo med slovarskimi enotami (lemma), različnicami (types) in pojavnicami
(tokens):

npr. nemški glagol "gehen" je slovarska enota, ki ima več različnic ali oblik
(npr. gehe, gehst, geht, gehen, geht, ging, gingst, ... gegangen).

Pojavnice: nekatere oblike glagola so pogostejše kot druge, nekatere pa se v
izbranem besedilu ne pojavljajo.

```{r}
povzetek %>% 
  group_by(Text) %>% 
  mutate(ttr = Types/Tokens)

```

Program quanteda ima za ugotavljanje slovarske raznolikosti (lexical diversity)
več možnosti, kar zahteva razcepitev besedil na manjše enote, tj. tokens
(besede, ločila idr.). Za nekatere funkcije moramo ustvariti besedilno matriko
(document frequency matrix, dfm).

# 3. Tokenizacija

Če želimo več izvedeti o besedilih, npr. katere besede se pojavljajo v
besedilih, moramo najprej ustvariti seznam besedilnih enot (tj. besed, ločil
idr.).

Iz gradiva izvlečemo besedne oblike (npr. s pomočjo presledkov).

Za tokenizacijo ima quanteda ukaz tokens().

```{r}
besede = tokens(romane)
head(besede)

```

# 4. Čiščenje

S seznama lahko izločimo "nebesede":

```{r}
besede = tokens(romane, remove_punct = T, remove_symbols = T, remove_numbers = T, remove_url = T)
head(besede)

```

Izločimo lahko tudi besede, ki za vsebinsko analizo niso zaželene ("stopwords").

V izbranih besedilih motijo tudi angleške besede, ki niso sestavni del nemških
besedil.

concatenate = združi: c()

```{r}
stoplist_de = c(stopwords("de"), "dass", "Aligned", "by", "autoalignment", "Source", "Project", 
                "bilingual-texts.com", "fully", "reviewed")
besede = tokens_select(besede, pattern = stoplist_de, selection = "remove")

```

Naslednji seznam bomo uporabljali za ustvarjanje konkordance, tj. seznama
sobesedil, v katerem se nahaja iskalni niz (npr. neka beseda).

```{r}
stoplist_en = c("Aligned", "by", "autoalignment", "Source", "Project", 
                "bilingual-texts.com", "fully", "reviewed")

# Obdržali bomo ločila
woerter = tokens(romane, remove_symbols = T, remove_numbers = T, remove_url = T)
# Odstranili bomo angleške besede na začetku besedil
woerter = tokens_select(woerter, pattern = stoplist_en, selection = "remove", padding = TRUE)

```

# 5. Kwic

Za sestavo konkordanc ima program quanteda funkcijo *kwic()* (keyword in
context).

Možno je iskati posamezne besede, besedne zveze, uporabljamo pa lahko tudi
nadomestne znake (npr. \*).

```{r}
kwic(woerter, pattern = c("Frau", "Herr"))

```

Konkordanco bomo pretvorili v podatkovno zbirko, tj. *data.frame* ali
*tibble()*. Prednost je npr., da tako pridobimo imena stolpcev (tj.
spremenljivk).

*kwic()* ima več možnosti, npr. "case_insensitive = FALSE" razlikuje med
velikimi in malimi črkami. Privzeta vrednost je "TRUE", tj. da tega ne razlikuje
(tako kot Excel).

```{r}
(konkordanca = kwic(woerter, pattern = c("Frau", "Herr"), case_insensitive = FALSE) %>% 
  as_tibble()
)

```

Z ukazom *count()* lahko preštejemo, koliko pojavnic je KWIC našel.

```{r}
konkordanca %>% 
  count(keyword)

```

Poiskati želimo besede s pripono "-in" za samostalnike, ki označujejo ženska
osebna imena (npr. Ärztin, Köchin, ...).

```{r}
(konkordanca2 = kwic(woerter, pattern = c("*in"), case_insensitive = FALSE) %>% 
  as_tibble()
)

```

Žal vsebuje gornji seznam sobesedil veliko besednih oblik, ki niso ženska osebna
imena (npr. ein, in, ...). Če želimo natančnejši seznam, moramo iskati na
ustreznejši način, npr. z naborom nadomestnih znakov, tako imeovanih *regularnih
izrazov* (regular expressions, "regex").

Na portalu [**https://regex101.com/**](https://regex101.com/){.uri} lahko
preizkušate in se učite regularnih izrazov.

Poizvedovanje s pomočjo regularnih izrazov: \*in.

```{r}
(konkordanca2 = kwic(woerter, pattern = "\\A[A-Z][a-z]+[^Eae]in\\b",
                      valuetype = "regex", case_insensitive = FALSE) %>% 
  as_tibble() %>% 
  filter(keyword != "Immerhin", 
         keyword != "Darin",
         keyword != "Termin",
         keyword != "Worin",
         keyword != "Robin",
         keyword != "Medizin",
         keyword != "Austin",
         keyword != "Musselin",
         keyword != "Benjamin",
         keyword != "Franklin")
)

```

Še drug primer uporabe regularnih izrazov Poizvedovanje s pomočjo regex:
Manjšalnice / Diminutive (-chen, -lein). Katera manjšalna pripona prevladuje:
-lein ali -chen ?

```{r}
(konkordanca3a = kwic(woerter, "*lein",
                      valuetype = "glob", case_insensitive = FALSE) %>% 
  as_tibble() %>% 
   count(keyword, sort = TRUE)
)

(konkordanca3b <- kwic(woerter, "*chen",
                      valuetype = "glob", case_insensitive = FALSE) %>% 
  as_tibble() %>% 
   count(keyword, sort = T)
)

(konkordanca3 <- kwic(woerter, 
                      pattern = c("\\A[A-Z][a-z]*[^aäeiouürs]chen\\b",
                                  "[A-Z]*[^kl]lein\\b"),
                      valuetype = "regex", case_insensitive = FALSE) %>% 
  as_tibble() %>% 
  filter(keyword != "Welchen", 
         keyword != "Manchen",
         keyword != "Solchen",
         keyword != "Fräulein")
)

```

Poizvedovanje s pomočjo "regex": Frau + Priimek / Ime

Obvezno nastavimo case_insensitive = FALSE, saj naj program razlikuje med
velikimi in malimi začetnicami.

```{r}
(konkordanca4 <- kwic(woerter, pattern = phrase("\\bFrau\\b ^[A-Z][^[:punct:]]"), 
                      valuetype = "regex", case_insensitive = FALSE) %>% 
  as_tibble()
)

```

# 6. Pogostnost

Besedilno-besedna matrika (dfm) je izhodišče za izračun in grafični prikaz več
statističnih količin, npr. tudi pogostnosti besednih oblik v posameznih
besedilih:

```{r}
matrika = dfm(besede, tolower = FALSE) # za zdaj obdržimo velike začetnice

# Odstranimo besede, ki jih v vsebinski analizi ne potrebujemo (stopwords)
matrika = dfm_select(matrika, selection = "remove", pattern = stoplist_de)
matrika
```

Program quanteda ima posebno funkcijo, ki sestavi seznam besednih oblik in
njihove pogostnosti, tj. textstat_frequency().

```{r}
library(quanteda.textstats)
library(quanteda.textplots)

(pogostnost = textstat_frequency(matrika, groups = c("prozess.txt", "tom.txt"))
)

```

Diagram najpogostnejših izrazov:

```{r}
pogostnost %>% 
  slice_max(order_by = frequency, n = 20) %>% 
  mutate(feature = reorder_within(feature, frequency, frequency, sep = ": ")) %>%
  # ggplot(aes(frequency, reorder(feature, frequency))) +
  ggplot(aes(frequency, feature)) +
  geom_col(fill="steelblue") +
  labs(x = "Frequency", y = "") +
  facet_wrap(~ group, scales = "free")

```

Po potrebi lahko seznam besednih pogostnosti oblik razdelimo na dva posebna
seznama, in sicer s funkcijo filter().

```{r}
(pogost_tom = textstat_frequency(matrika, groups = c("prozess.txt", "tom.txt")) %>% 
  filter(group == "tom.txt")
)

(pogost_prozess = textstat_frequency(matrika, groups = c("prozess.txt", "tom.txt")) %>% 
  filter(group == "prozess.txt")
)

```

Glagoli rekanja in mišljenja: kateri so v izbranih besedilih pogostnejši?

```{r}
(sagen = pogostnost %>%
   filter(str_detect(feature, "^(ge)?sag*"))
)

(reden = pogostnost %>% 
    filter(str_detect(feature, "^(ge)?rede*"))
)

(fragen = pogostnost %>% 
    filter(str_detect(feature, "^(ge)?frag*"))
)

(antworten = pogostnost %>% 
    filter(str_detect(feature, "^(ge)?antwort*"))
)

(rufen = pogostnost %>% 
    filter(str_detect(feature, pattern = "^(ge)?ruf*", negate = FALSE)) %>% 
    filter(!str_detect(feature, "ruh|run|rum|rui|ruch"))
)

```

```{r}
verb1 = sagen %>% 
  group_by(group) %>% 
  summarise(freq = sum(frequency)) %>% 
  mutate(verb = "sagen")

verb2 = reden %>% 
  group_by(group) %>% 
  summarise(freq = sum(frequency)) %>% 
  mutate(verb = "reden")

verb3 = fragen %>% 
  group_by(group) %>% 
  summarise(freq = sum(frequency)) %>% 
  mutate(verb = "fragen")

verb4 = antworten %>% 
  group_by(group) %>% 
  summarise(freq = sum(frequency)) %>% 
  mutate(verb = "antworten")

verb5 = rufen %>% 
  group_by(group) %>% 
  summarise(freq = sum(frequency)) %>% 
  mutate(verb = "rufen")

```

Pet majhnih tabel lahko združimo v večjo tabelo, tj. s funkcijo rbind().

```{r}
glagoli = rbind(verb1, verb2, verb3, verb4, verb5)
glagoli

```

Še diagram:

```{r}
glagoli %>% 
  ggplot(aes(freq, verb, fill = verb)) +
  geom_col() +
  facet_wrap(~ group) +
  theme(legend.position = "none")

```

Tabelo lahko tudi prerazporedimo, npr. zaradi lažje primerjave besedil takole:

```{r}
glagoli %>% 
  pivot_wider(id_cols = verb, names_from = group, values_from = freq)

```

# 7. Kolokacije

Koleksemi = slovarske enote, ki se sopojavljajo. Kolokacije = jezikovne prvine,
ki se sopojavljajo.

Statistična opredelitev: Če se dva izraza (npr. "dober dan") pojavljata bistveno
pogosteje kot neposredna soseda, kakor bi naključno pričakovali, potem ju lahko
obravnavamo kot kolokacijo.

Jezikoslovna opredelitev: Kolokacija je pomensko povezano zaporedje besed.

Funkcija textstat_collocations() v programu quanteda.

"woerter" je seznam besednih oblik (padding = TRUE !), ki smo ga ustvarili
zgoraj.

```{r}
(coll_2 = textstat_collocations(woerter, size = 2, tolower = TRUE) # naredi male črke !
)

```

Kolokacije s tremi členi.

```{r}
(coll_3 = textstat_collocations(woerter, size = 3, tolower = FALSE)
)

```

```{r}
(coll_4 = textstat_collocations(woerter, size = 4, tolower = FALSE)
)

```

Sopomenski vprašalnici "warum" in "wieso: s katerimi besednimi oblikami se
sopojavljata?

```{r}
(warum <- coll_2 %>% 
  filter(str_detect(collocation, "^warum"))
)

(wieso <- coll_2 %>% 
  filter(str_detect(collocation, "^wieso"))
)

```

Kolokacija samostalniških izrazov. V nemščini imajo veliko začetnico. Najprej
bomo sestavili seznam besednih oblik z veliko začetnico (woerter_caps). Potem
lahko pridobimo seznam kolokacij (coll_caps2).

```{r}
woerter_caps = tokens_select(woerter, pattern = "^[A-Z]", 
                                valuetype = "regex", 
                                case_insensitive = FALSE, 
                                padding = TRUE)

coll_caps2 = textstat_collocations(woerter_caps, size = 2, tolower = FALSE, min_count = 5)
head(coll_caps2, 100)

```

Ni smiselno upoštevati "Der + samostalnik" kot kolokacijo, saj se v nemščini
velika večina samostalnikov pojavlja s členom.

Zato bomo člene "Der, Die, Das" in še nekaj besednih oblik na začetku stavka
spremenili v "der, die , das", ....

```{r}
woerter_small = tokens_replace(woerter, 
                               pattern = c("Der","Die","Das","Des","Wollen","Im","Zum",
                                           "Kein","Jeden","Wenn","Als","Da","Aber","Und","Sehen"), 
                               replacement = c("der","die","das","des","wollen","im","zum",
                                               "kein","jeden","wenn","als","da","aber","und","sehen"))

woerter_caps = tokens_select(woerter_small, pattern = "^[A-Z]", 
                                valuetype = "regex", 
                                case_insensitive = FALSE, 
                                padding = TRUE)

coll_caps2 = textstat_collocations(woerter_caps, size = 2, tolower = FALSE, min_count = 5)
head(coll_caps2, 100)

```

# 8. Lematizacija

Seznam slovarskih enot (lem) lahko naložimo z medmrežja na naš disk.

```{r}
# Preberi seznam slovarskih enot in pojavnic z diska
lemdict = read.delim2("data/lemmatization_de.txt", sep = "\t", encoding = "UTF-8", 
                      col.names = c("lemma", "word"), stringsAsFactors = F)

# Pretvori podatkovna niza v znakovna niza
lemma = as.character(lemdict$lemma) 
word = as.character(lemdict$word)

# Lematiziraj pojavnice v naših besedilih
lemmas <- tokens_replace(besede,
                             pattern = word,
                             replacement = lemma,
                             case_insensitive = TRUE, 
                             valuetype = "fixed")


```

Ustvarimo matriko s slovarskimi enotami (namesto pojavnic).

```{r}
matrika_lem = dfm(lemmas, tolower = FALSE) # za zdaj obdržimo velike začetnice

# Odstranimo besede, ki jih v vsebinski analizi ne potrebujemo (stopwords)
matrika_lem = dfm_select(matrika_lem, selection = "remove", pattern = stoplist_de)
matrika_lem

```

# 9. Besedni oblaček

```{r}
textplot_wordcloud(matrika_lem, comparison = TRUE, adjust = 0.3, color = c("darkblue","darkgreen"),
                   max_size = 4, min_size = 0.75, rotation = 0.5, min_count = 30, max_words = 250)

```

Lepši oblaček (za obe besedili skupaj).

```{r}
# install.packages("wordcloud2)
matrika_lem_prozess = matrika_lem[1,]

set.seed(1320)
library(wordcloud2)
topfeat <- as.data.frame(topfeatures(matrika_lem_prozess, 100))
topfeat <- rownames_to_column(topfeat, var = "word")
wordcloud2(topfeat)

```

```{r}
matrika_lem_tom = matrika_lem[2,]

set.seed(1320)
library(wordcloud2)
topfeat <- as.data.frame(topfeatures(matrika_lem_tom, 100))
topfeat <- rownames_to_column(topfeat, var = "word")
wordcloud2(topfeat)

```

# 10. Položaj v besedilu (xray)

Diagram prikazuje, kje v besedilih se pojavlja besedna oblika "frau". Podobno:
Voyant Tools (MicroSearch).

```{r}
kwic_frau = kwic(lemmas, pattern = "frau")
textplot_xray(kwic_frau)

```

# 11. Slovarska raznolikost

```{r}
textstat_lexdiv(matrika, measure = "all")

```

# 12. Podobnost besedil

Ta postopek je bolj zanimiv, če želimo primerjati več besedil. Zato bomo dodali
še Kafkino novelo.

```{r}
# odpremo datoteko
verwandl = readtext("data/books/verwandlung/verwandlung.txt", encoding = "UTF-8")
# ustvarimo nov korpus
verw_corp = corpus(verwandl)
# združimo novi korpus s prrejšnjim
romane3 = romane + verw_corp
# tokenizacija
romane3_toks = tokens(romane3)
# ustvarimo matriko (dfm)
romane3_dfm = dfm(romane3_toks)

```

Rezultat: Kafkina novela "Die Verwandlung" je Kafkinemu romanu "Der Prozess"
nekoliko podobnejša kot Twainov roman "Tom Sawyer".

```{r}
textstat_simil(romane3_dfm, method = "cosine", margin = "documents")

```

Podobnost oblik (features).

```{r}
# compute some term similarities
simil1 = textstat_simil(matrika, matrika[, c("Josef", "Tom", "Sawyer", "Huck", "Finn")], 
                         method = "cosine", margin = "features")
head(as.matrix(simil1), 10)

```

Različnost besedil (Kaj je ta metoda upoštevala? Razliko v dolžini?):

```{r}
# plot a dendrogram after converting the object into distances
dist1 = textstat_dist(romane3_dfm, method = "euclidean", margin = "documents")
plot(hclust(as.dist(dist1)))

```

# 13. Ključne besede

Katere besedne oblike lahko uvrstimo med ključne besede, tj. take izraze, ki so
najbolj značilni za neko besedilo? Program quanteda ima funkcijo
*textstat_keyness()*: ciljno besedilo (target) primerjamo z referenčnim
besedilom (reference).

```{r}
key_tom <- textstat_keyness(matrika, target = "tom.txt")
key_tom

key_prozess <- textstat_keyness(matrika, target = "prozess.txt")
key_prozess

```

```{r}
textplot_keyness(key_tom, key_tom$n_target == 1)
textplot_keyness(key_tom, key_prozess$n_target == 1)
textplot_keyness(key_tom)
textplot_keyness(key_prozess)

```

# 14. Razumljivost besedil

Indeksi razumljivosti (readability index) so prirejeni za angleščino, za druge
jezike veljajo v manjši meri.

Flesch-Indeks: Prozess ima nekoliko nižjo vrednost (52) kot Tom Sawyer (61), kar
pomeni, da Prozess (zaradi daljših povedi in besed) težje beremo (razumemo), Tom
Sawyer pa z večjo lahkoto.

```{r}
textstat_readability(romane, measure = c("Flesch", "Flesch.Kincaid", "FOG", "FOG.PSK", "FOG.NRI"))

```

# 15. Omrežje sopojavitev (FCM)

Matriko sopojavljanja besednih oblik (FCM) pridobimo v dveh korakih: - najprej
izberemo seznam izrazov (pattern) iz matrike (dfm), - potem določimo matriko
sopojavljanja besednih oblik (fcm).

```{r}
dfm_tags <- dfm_select(matrika[2,], pattern = (c("tom", "huck", "*joe", "becky", "tante", "witwe",
                                                 "polly", "sid", "mary", "thatcher", "höhle", "herz",
                                                 "*schule", "katze", "geld", "zaun", "piraten",
                                                 "schatz")))
toptag <- names(topfeatures(dfm_tags, 50))
head(toptag)

```

```{r}
# Construct feature-cooccurrence matrix (fcm) of tags
fcm_tom <- fcm(matrika[2,]) # besedilo 2 je tom.txt
head(fcm_tom)
top_fcm <- fcm_select(fcm_tom, pattern = toptag)
textplot_network(top_fcm, min_freq = 0.6, edge_alpha = 0.8, edge_size = 5)

```

# 16. Slovnična analiza

Za slovnično analizo in lematizacijo besednih oblik lahko uporabljamo posebne
programe (npr. spacyr ali udpipe).

Program udpipe je na voljo za številne jezike, tudi za nemščino in slovenščino.

## 16.1 Priprava

Pred prvo uporabo moramo naložiti model za nemški jezik z interneta.

```{r}
library(udpipe)
sprachmodell <- udpipe_download_model(language = "german")

```

V naslednjem koraku naložimo jezikovni model v pomnilnik.

```{r}
udmodel_de <- udpipe_load_model(sprachmodell$file_model)

```

Če je jezikovni model že v naši delovni mapi, download ni potreben, saj ga lahko
takoj naložimo z diska v pomnilnik.

```{r}
file_model = "german-gsd-ud-2.5-191206.udpipe"
udmodel_de <- udpipe_load_model(file_model)

```

Naslednji korak je *udpipe_annotate()*: program udpipe označuje besedne oblike
po več merilih.

Udpipe prebere in označuje besedilo takole:

```{r}
# Na začetku je readtext prebral besedila, shranili smo jih v spremenljivki "txt".
x <- udpipe_annotate(udmodel_de, x = txt$text, trace = TRUE)

# # samo prvo besedilo:
# x <- udpipe_annotate(udmodel_de, x = txt$text[1], trace = TRUE)

x <- as.data.frame(x)

```

Zgradba podatkovnega niza (structure of data frame):

```{r}
str(x)
```

Podatkovni niz ima tako obliko:

```{r}
x

```

## 16.2 Primerjava Noun : Pron

Zdaj lahko začnemo poizvedovati po besednih oblikah, slovarskih enotah in
slovničnih kategorijah.

```{r}
(tabela = x %>% 
  group_by(doc_id) %>% 
  count(upos) %>% 
  filter(!is.na(upos),
         upos != "PUNCT")
)

tabela %>% 
  mutate(upos = reorder_within(upos, n, n, sep = ": ")) %>% 
  ggplot(aes(n, upos, fill = upos)) +
  geom_col() +
  facet_wrap(~ doc_id, scales = "free") +
  theme(legend.position = "none") +
  labs(x = "Število pojavnic", y = "")

```

Izračun deležev v odstotkih:

```{r}
(delezi = tabela %>% 
  mutate(prozent = n/sum(n)) %>% 
  pivot_wider(id_cols = upos, names_from = doc_id, values_from = n:prozent)
)

```

```{r}
delezi %>% 
  filter(upos %in% c("NOUN", "PRON"))

```

Ali se besedili razlikujeta glede na razmerje med samostalniki in zaimki?

```{r}
# za hi kvadrat test potrebujemo le drugi in tretji stolpec
nominal = delezi %>% 
  filter(upos %in% c("NOUN", "PRON")) %>% 
  select(n_doc1, n_doc2) 

chisq.test(nominal)

```

Besedili se razlikujeta glede razmerja med samostalniki in zaimki: X\^2 (1) =
147,38; p \< 0,001. Iz gornje tabele pogostnosti je razvidno, da je delež
zaimkov v romanu "Prozess" sorazmerno večji kot v romanu "Tom Sawyer". Da bi
ugotovili, kaj to pomeni, bi si morali podrobneje ogledati, kateri zaimki in
kateri samostalniki bistveno vplivajo na to številčno razmerje. Na splošno
velja, da so zaimki manj zanesljiva jezikovna sredstva kot samostalniki,
samostalniki pa so bolj zapleteni.

Če želimo primerjati eno besedno vrsto z vsemi drugimi v podatkovnem nizu, je
pretvorba bolj zapletena, saj moramo podobno kot v Excelu - najprej izračunati
vsoto za vse besedne vrste, - potem odšteti število zaimkov oz. samostalnikov od
vsote, - razliko pa upoštevati za tabelo 2x2 za hi kvadrat test.

```{r}
(zaimki = x %>% 
  group_by(doc_id) %>% 
  count(upos) %>% 
  filter(!is.na(upos),
         upos != "PUNCT") %>% 
  mutate(vsota = sum(n),
         no_noun = vsota - n[upos == "NOUN"],
         no_pron = vsota - n[upos == "PRON"]) %>% 
  filter(upos == "PRON") %>% 
  select(doc_id, n, no_pron) %>% 
  pivot_longer(-doc_id, 'kategorija', 'vrednost') %>%
  pivot_wider(kategorija, doc_id)
)

(samostalniki = x %>% 
  group_by(doc_id) %>% 
  count(upos) %>% 
  filter(!is.na(upos),
         upos != "PUNCT") %>% 
  mutate(vsota = sum(n),
         no_noun = vsota - n[upos == "NOUN"],
         no_pron = vsota - n[upos == "PRON"]) %>% 
  filter(upos == "NOUN") %>% 
  select(doc_id, n, no_noun) %>% 
  pivot_longer(-doc_id, 'kategorija', 'vrednost') %>%
  pivot_wider(kategorija, doc_id)
)

```

Hi kvadrat testa: - primerjava števila zaimkov nasproti ostalim besednim vrstam,
- primerjava števila samostalnikov nasproti ostalim besednim vrstam.

```{r}
# izločimo prvi stolpec [, -1], za hi kvadrat test potrebujemo le drugi in tretji stolpec
chisq.test(zaimki[,-1])
chisq.test(samostalniki[,-1])

```

Besedili se razlikujeta glede deleža zaimkov in samostalnikov.

## 16.3 Primerjava veznikov

Primerjati želimo število stavkov s prirednim in podrednim veznikom.

Osnovna domneva je, da priredno zložene povedi (vsebujejo stavek, uveden s
prirednim veznikom) lažje razumemo kot podredno zložene povedi (vsebujejo
stavek, uveden s podrednim veznikom).

```{r}
(vezniki = tabela %>% 
  filter(upos %in% c("CCONJ", "SCONJ")) %>% 
  mutate(prozent = n/sum(n)) %>% 
  pivot_wider(id_cols = upos, names_from = doc_id, values_from = n:prozent)
)

```

Odstotki nakazujejo, da je v romanu Prozess delež prirednih veznikov manjši kot
v romanu Tom Sawyer.

Hi kvadrat test (upoštevane so le povedi, ki vsebujejo veznik) za preverjanje,
ali je razlika dovolj velika, da bi bila nenaključna.

```{r}
chisq.test(vezniki[,c(2:3)])

```

Razlika med romanoma je statistično značilna.

Če upoštevamo tudi vsote drugih besednih vrst (kot zgoraj):

```{r}
(koord = tabela %>% 
  mutate(vsota = sum(n),
         no_cconj = vsota - n[upos == "CCONJ"],
         no_sconj = vsota - n[upos == "SCONJ"]) %>% 
  filter(upos == "CCONJ") %>% 
  select(doc_id, n, no_cconj) %>% 
  pivot_longer(-doc_id, 'kategorija', 'vrednost') %>%
  pivot_wider(kategorija, doc_id)
)

(subord = tabela %>% 
  mutate(vsota = sum(n),
         no_cconj = vsota - n[upos == "CCONJ"],
         no_sconj = vsota - n[upos == "SCONJ"]) %>% 
  filter(upos == "SCONJ") %>% 
  select(doc_id, n, no_sconj) %>% 
  pivot_longer(-doc_id, 'kategorija', 'vrednost') %>%
  pivot_wider(kategorija, doc_id)
)

```

Hi kvadrat preizkus izkazuje razliko med romanoma

```{r}
chisq.test(koord[,-1])
chisq.test(subord[,-1])

```

Besedili se razlikujeta glede števila veznikov.

## 16.4 Slovarske enote

Program udpipe je vsako besedno obliko dodelil slovarski enoti (lemma). Koliko
koliko slovarskih enot je v besedilih? Katerim besednim vrstam najpogosteje
pripadajo?

```{r}
(tabela2 = x %>% 
  group_by(doc_id, upos) %>% 
    filter(!is.na(upos),
           upos != "PUNCT",
           upos != "X") %>% 
  distinct(lemma) %>% 
  count(lemma) %>% 
  summarise(lemmas = sum(n)) %>% 
  mutate(prozent = round(lemmas/sum(lemmas), 4)) %>% 
  arrange(-prozent)
)

tabela2 %>% 
  # slice_max(order_by = prozent, n=6) %>% 
  mutate(upos = reorder_within(upos, lemmas, paste("(",100*prozent,"%)"), sep = " ")) %>%
  ggplot(aes(prozent, upos, fill = upos)) +
  geom_col() +
  facet_wrap(~ doc_id, scales = "free") +
  theme(legend.position = "none") +
  scale_x_continuous(labels = percent_format()) +
  labs(x = "Anteil", y = "Wortklasse")

```

## 16.5 Korelacija besed

Katere besedne pogostnosti se vzporedno povečujejo ali zmanjšujejo (pairwise
correlation) ? Podobno analizno orodje: Voyant Tools.

```{r}
library(widyr)

# pairwise correlation
(correlations = x %>% 
  filter(dep_rel != "punct", dep_rel != "nummod") %>%
  mutate(lemma = tolower(lemma), token = tolower(token),
         lemma = str_trim(lemma), token = str_trim(token)) %>% 
  janitor::clean_names() %>%
  group_by(doc_id, lemma, token, sentence_id) %>% 
  # add_count(token) %>% 
  summarize(Freq = n()) %>% 
  arrange(-Freq) %>% 
  filter(Freq > 2) %>% 
  pairwise_cor(lemma, sentence_id, sort = TRUE) %>% 
  filter(correlation < 1 & correlation > 0.3)
)

```

Tom Sawyer: Zaun.

```{r}
correlations %>%
  filter(item1 == "zaun") %>%
  mutate(item2 = fct_reorder(item2, correlation)) %>%
  ggplot(aes(item2, correlation, fill = item2)) +
  geom_col(show.legend = F) +
  coord_flip() +
  labs(title = "What tends to appear with 'Zaun'?",
       subtitle = "Among elements that appeared in at least 2 sentences")

```

Prozess: Gericht.

```{r}
correlations %>%
  filter(item1 == "gericht") %>%
  mutate(item2 = fct_reorder(item2, correlation)) %>%
  ggplot(aes(item2, correlation, fill = item2)) +
  geom_col(show.legend = F) +
  coord_flip() +
  labs(title = "What tends to appear with 'Gericht'?",
       subtitle = "Among elements that appeared in at least 2 sentences")

```

# 17. Sentiment

Stopnjo čustvenosti ali emocionalnosti besedila je mogoče določiti s
sentimentnim slovarjem.

## 17.1 Različica 1

Uporaba nrc leksikona za nemščino (priložen programu syuzhet).

Najprej besedilo s funkcijo *get_sentences()* razcepimo na povedi.

```{r}
library(syuzhet)

tom_v = get_sentences(txt$text[2]) # izberemo drugo besedilo: tom.txt
tom_v = (tom_v[-1]) # tako lahko izločimo prvo vrstico (uredniško pripombo)
head(tom_v[-1])

```

Funkcija *get_sentiment()* dodeli besedam v povedih pozitivno (+1), negativno
(-1) ali nevtralno (0) čustveno vrednost. Program te vrednosti sešteje.

```{r}
tom_values <- get_sentiment(tom_v, method = "nrc", language = "german")
length(tom_values)
tom_values[100:110]

```

Povedi, čustvene vrednosti in dolžino povedi povežemo v podatkovni niz. To nam
olajšuje oceno, kako uspešna je bila uporaba sentimentnega slovarja v našem
besedilu. Preimenovali bomo tudi nekaj stolpcev.

```{r}
sentiment1 = cbind(tom_v, tom_values, ntoken(tom_v)) %>% 
  as.data.frame() %>% 
  rename(words = V3,
         text = tom_v,
         values = tom_values) %>% 
  mutate(doc_id = "tom.txt") %>% 
  rowid_to_column(var = "sentence")
head(sentiment1)
View(sentiment1)

```

Gornje postopke ponovimo za besedilo, ki ga želimo primerjati s prvim.

```{r}
prozess_v = get_sentences(txt$text[1]) # izberemo prvo besedilo: prozess.txt
prozess_v = (prozess_v[-1]) # tako lahko izločimo prvo vrstico (uredniško pripombo)
prozess_values <- get_sentiment(prozess_v, method = "nrc", language = "german")
sentiment2 = cbind(prozess_v, prozess_values, ntoken(prozess_v)) %>% 
  as.data.frame() %>% 
  rename(words = V3,
         text = prozess_v,
         values = prozess_values) %>% 
  mutate(doc_id = "prozess.txt") %>% 
  rowid_to_column(var = "sentence")
head(sentiment2)
View(sentiment2)

```

S seštevanjem čustvenih vrednosti je mogoče oceniti, katero besedilo ima več
pozitivno ocenjenih besed. V ta namen bomo združili podatkovna niza in uredili
obliko stolpcev "words" in "values".

```{r}
sentiment = rbind(sentiment1, sentiment2) %>% as_tibble() %>% 
  mutate(values = parse_number(values),
         words = parse_number(words)) %>%
  select(doc_id, sentence, words, values, text)
head(sentiment)

```

Rezultat: po gornji metodi je povprečje čustvenih vrednosti v romanu "Prozess"
nekoliko večje kot v romanu "Tom Sawyer". To je v nasprotju z našim
pričakovanjem, saj Tom Sawyer vsebuje kar nekaj vedrih zgodb, je pa res, da so
njegove pustolovščine pogosto tudi nevarne ali strašljive.

```{r}
sentiment %>% 
  group_by(doc_id) %>% 
  summarise(polarnost = mean(values))

```

Poskusimo drugače: pozitivne, nevtralne in negativne vrednosti obravnajmo ločeno
in upoštevajmo tudi dolžino povedi.

```{r}
sentiment1 = sentiment %>% 
  group_by(doc_id) %>% 
  mutate(positive = ifelse(values > 0, abs(values), 0),
         neutral = ifelse(values == 0, 1, 0),
         negative = ifelse(values < 0, abs(values), 0))
sentiment1 %>% 
  summarise(pos = mean(100*positive/words),
            neut = mean(100*neutral/words),
            neg = mean(100*negative/words))

```

Ta rezultat je skladnejši z našim pričakovanjem.

Poglejmo še nekaj povedi, ki so bile ocenjene negativno:

```{r}
sentiment1 %>% 
  filter(negative > 0)
```

## 17.2 Različica 2

```{r}
tom_v = get_sentences(txt$text[2])
tom_nrc_values = get_nrc_sentiment(tom_v)
tom_joy_items = which(tom_nrc_values$joy > 0)
head(tom_v[tom_joy_items], 4)

```

```{r}
nrc_sentiment = as.data.frame(cbind(tom_v, tom_nrc_values))
head(nrc_sentiment)

```

## 17.3 Različica 3

Drugi sentimentni slovarji z medmrežja: npr. BAWLR lahko uporabljamo kot
sentimentni slovar.

```{r}
# This lexicons contains values of Emotional valence and arousal ranging from 1 to 5.
# But this extended version contains also binary Emo_Val values (1, -1).
bawlr <- read.delim2("data/BAWLR_utf8.txt", sep = "\t", dec = ",", fileEncoding = "UTF-8", 
                     header = T, stringsAsFactors = T)
# # bawlr$EmoVal <- as.character(bawlr$EmoVal)
# # str(EmoVal)
# bawlr$EmoVal <- gsub('NEG', '-1', bawlr$EmoVal)
# bawlr$EmoVal <- gsub('POS', '1', bawlr$EmoVal)
# bawlr$EmoVal <- as.numeric(bawlr$EmoVal)
head(bawlr)

```

Sestavimo dva seznama:

```{r}
positive.words = bawlr %>% 
  mutate(WORD_LOWER = as.character(WORD_LOWER)) %>% 
  select(EmoVal, WORD_LOWER) %>% 
  filter(EmoVal == "POS") %>% 
  select(WORD_LOWER) %>% 
  filter(str_detect(WORD_LOWER, "[a-zA-Z]"))

negative.words = bawlr %>% 
  mutate(WORD_LOWER = as.character(WORD_LOWER)) %>% 
  select(EmoVal, WORD_LOWER) %>% 
  filter(EmoVal == "NEG") %>% 
  select(WORD_LOWER) %>% 
  filter(str_detect(WORD_LOWER, "[a-zA-Z]"))

```

Ustvarimo quanteda slovar *dictionary()*:

```{r}
bawlr_dict = dictionary(list(positive = list(positive.words), negative = list(negative.words)))

```

Uporabljamo matriko (dfm) s slovarskimi enotami (lemma), saj slovar bawlr_dict
vsebujejo le osnovno obliko slovarskih enot.

```{r}
matrika_lemmas = dfm(matrika_lem, tolower = TRUE)

result = matrika_lemmas %>% 
  dfm_lookup(bawlr_dict) %>% 
  convert(to = "data.frame") %>% 
  as_tibble
result

```

Dodamo lahko skupno dolžino besed, če želimo normalizirati rezultat z ozirom na
dolžino besedil.

```{r}
result = result %>% mutate(length=ntoken(matrika_lemmas))
result

```

Po navadi želimo izračunati skupni sentimentno vrednost. Možnosti je več: npr. -
odšteti negativne vrednosti od pozitivnih in nato razliko deliti z vsoto obeh
vrednosti, - odšteti negativne vrednosti od pozitivnih in nato razliko deliti z
dolžino besedil,

Izračunamo lahko tudi stopnjo subjektivnosti, tj. koliko čustvenih vrednosti je
skupno izraženih:

```{r}
result = result %>% mutate(sentiment1=(positive - negative) / (positive + negative))
result = result %>% mutate(sentiment2=(positive - negative) / length)
result = result %>% mutate(subjektivnost=(positive + negative) / length)
result

```

### Barvno označevanje

Program corpustools barvno označuje besede v besedilih z ozirom na čustvene
vrednosti besed v sentimentnem slovarju.

Prvi korak je ustvarjanje tcorpusa.

```{r}
library(corpustools)
t = create_tcorpus(txt, doc_column="doc_id")

```

V drugem koraku sledi iskanje po slovarju (tcorpus):

```{r}
t$code_dictionary(bawlr_dict, column = 'bawlr')
t$set('sentiment', 1, subset = bawlr %in% c('positive','neg_negative'))
t$set('sentiment', -1, subset = bawlr %in% c('negative','neg_positive'))

```

Prikaz barvno označenih besedil v oknu "Viewer":

```{r}
browse_texts(t, scale='sentiment')

```

Prikaz barvno označenih besedil v spletnem brskalniku in shranjevanje v obliki
html datoteke:

```{r}
browse_texts(t, scale='sentiment', filename = "sentiment_prozess_tom.html", 
             header = "Sentiment in Kafkas Prozess und Twains Tom Sawyer")

```
