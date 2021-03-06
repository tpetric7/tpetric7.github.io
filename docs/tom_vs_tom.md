---
title: "Tom Sawyer (German > English)"
author: "Teodor Petrič"
date: "2021-08-01"
output: html_document
editor_options: 
  chunk_output_type: inline
  markdown: 
    wrap: 72
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```


# 0. Nameščanje programov (Packages)

Namestitev: Če ste program(e) že namestili, lahko preskočite ta korak.

Znak \# v programskem bloku (chunk) pomeni, da se ta vrstica ne izvaja. Odstrani
\# če želite program namestiti.

```{r message=FALSE, warning=FALSE}
# # Programe, ki jih še nimate, lahko namestite tudi na ta način (odstranite #):
# install.packages("readtext")
# ...

## First specify the packages of interest
packages = c("tidyverse", "quanteda", "quanteda.textplots", 
             "quanteda.textstats", "wordcloud2", "tidytext", 
             "udpipe", "janitor", "scales", "widyr", "syuzhet", 
             "corpustools", "readtext")

## Now load or install&load all
package.check <- lapply(
  packages,
  FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE)
      library(x, character.only = TRUE)
    }
  }
)

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

Besedilni datoteki odpremo s programom *readtext* z istoimensko funkcijo *readtext()*.

```{r}
txt = readtext("data/books/translations/sawyer/*.txt", encoding = "UTF-8")
```

Odstranili bomo začetek obeh besedilnih nizov (v stolpcu "text"), ker niso sestavni del besedil.

Uporabljamo več funkcij / ukazov:
- *filter()* za izbiranje vrstice v podatkovnem nizu, 
- *separate()* za delitev stolpca "text" v dva nova stolpca, 
- *rbind()* za združitev obeh podatkovnih nizov ("txt1", "txt2") v enega ("txt") 
- *mutate()* in *str_squish()* za odstranjevanje nepotrebnih presledkov med besedami v stolpcu "text".

```{r}
# Nemški prevod
txt1 = txt %>% 
  filter(doc_id == "tom_de.txt") %>% 
  separate(text, 
           into = c("kolofon", "text"), 
           sep = "Source : Project Gutenberg      Die Abenteuer Tom Sawyers      Mark Twain      ") %>% 
  select(-kolofon) # izločimo stolpec

# Angleški izvirnik
txt2 = txt %>% 
  filter(doc_id == "tom_en.txt") %>% 
  separate(text, 
           into = c("kolofon", "text"), 
           sep = "High up in Society

Contentment




") %>% 
  separate(text, into = c("text", "project"), 
           sep = "\\*\\*\\* END OF THE PROJECT GUTENBERG EBOOK THE ADVENTURES OF TOM SAWYER \\*\\*\\*") %>% 
  select(-kolofon, -project) # izločimo stolpca

# Obe datoteki združimo
txt = rbind(txt1,txt2)
# txt = txt %>% mutate(text = str_squish(text))

```


# 2. Ustvarimo korpus

Ustvarimo korpus ali jezikovno gradivo. Ukaz v programu *quanteda* je *corpus()*.

```{r}
romane = corpus(txt)

```

Povzetek korpusa:
Program quanteda ima dve funkciji za povzemanje osnovnih vrednosti besedil: 
- *summary()* 
- *textstat_summary()*

```{r}
romanstatistik = textstat_summary(romane)
romanstatistik %>% rmarkdown::paged_table() # za lepši izpis v formatu html

```

Iz evidence razberemo, da je nekaj razlik med nemškim prevodom in angleškim izvirnikom glede števila znakov (chars), povedi ("sents"), pojavnic ("tokens"), različnic ali besednih oblik ("types"), ločil ("puncts") in števk ("numbers").

Podatke iz povzetka bi lahko uporabili npr. za izračun povprečne dolžine povedi
v besedilih:

```{r}
library(rmarkdown)
romanstatistik %>% 
  select(-tags, -emojis) %>% # izločimo dva prazna stolpca
  group_by(document) %>%
  mutate(dolzina_povedi = tokens/sents) %>% paged_table()

```

Izračun pokaže, da je dolžina povedi (tj. število besed na poved) večja kot npr. v sproščenem (zasebnem) ustnem dvogovoru o vsakdanji, manj zahtevni temi.

Lahko bi tudi izračunali kazalnik slovarske raznolikosti v besedilih, tj.
razmerje med različnimi (*types*) in pojavnicami (*tokens*), kar se angleščini
imenuje "type token ratio" (*ttr*).

Razlikujemo med slovarskimi enotami (*lemma*), različnicami (*types*) in pojavnicami (*tokens*):

npr. nemški glagol "gehen" je slovarska enota, ki ima več različnic ali oblik
(npr. gehe, gehst, geht, gehen, geht, ging, gingst, ... gegangen).

Pojavnice: nekatere oblike glagola so pogostejše kot druge, nekatere pa se v
izbranem besedilu ne pojavljajo.

```{r}
romanstatistik %>% 
  select(-tags, -emojis, -urls) %>% # izločimo stolpce iz prikaza
  group_by(document) %>%
  mutate(dolzina_povedi = round(tokens/sents, 2)) %>% # zaokroževanje "round()"
  mutate(ttr = round(types/tokens, 4)) %>% paged_table()

```

Vrednost slovarske raznolikosti (ttr) je (glede na zmerno dolžino besedila) razmeroma nizka, mogoče znamenje, da je besedilo napisano v vsakdanjem pogovornem slogu.

Program *quanteda* ima za ugotavljanje slovarske raznolikosti (*lexical diversity*) več možnosti, kar zahteva razcepitev besedil na manjše enote, tj. *tokens* (besede, ločila idr.). Za nekatere funkcije moramo ustvariti besedilno matriko (document frequency matrix, *dfm*).


# 3. Tokenizacija

Če želimo več izvedeti o besedilih, npr. katere besede se pojavljajo v besedilih, moramo najprej ustvariti seznam besedilnih enot (tj. besed, ločil idr.).

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

concatenate = združi: *c()*

Seznamoma smo dodali še nekaj besed (funkcijske besede ali zelo pogoste glagolske oblike).

```{r}
stoplist_de = c(stopwords("de"), 
                "dass", "s", "Na", "wurde", "ganz", "immer", "sagte", "mehr",
                "schon", "ja", "mal", "ne", "n", "wohl", "sagen", "gar")
stoplist_en = c(stopwords("en"), "now", "one", "got", "upon", "just", "said",
                "Well", "Oh", "ever", "around", "made", "say", "Project")
stoplist = c(stoplist_de, stoplist_en)

besede = tokens_select(besede, pattern = stoplist, selection = "remove",
                       padding = FALSE)

```

Naslednji seznam bomo uporabljali za ustvarjanje konkordance, tj. seznama
sobesedil, v katerem se nahaja iskalni niz (npr. neka beseda).

Pri odstranjevanju nezaželenih izrazov je nastavljena opcija *padding = TRUE*. Na mestu nezaželenega izraza bo ostal znak dolžine nič (""). To je pomembno pri iskanju večbesednih zvez (kolokacij).

```{r}
# Obdržali bomo ločila
woerter = tokens(romane, remove_symbols = T, remove_numbers = T, remove_url = T)
woerter = tokens_select(woerter, pattern = stoplist, selection = "remove",
                       padding = TRUE)


```


# 5. Kwic

Za sestavo konkordanc ima program quanteda funkcijo *kwic()* (keyword in
context).

Možno je iskati posamezne besede, besedne zveze, uporabljamo pa lahko tudi
nadomestne znake (npr. \*).

*kwic()* ima več možnosti, npr. "case_insensitive = FALSE" razlikuje med
velikimi in malimi črkami. Privzeta vrednost je "TRUE" (tako kot Excel).

Konkordanco bomo pretvorili v podatkovno zbirko, tj. *data.frame* ali
*tibble()*. Prednost je npr., da tako pridobimo imena stolpcev (tj.
spremenljivk).

```{r}
konkordanca = kwic(woerter, 
                   pattern = c("Tom", "Sawyer", "Huck", "Huckleberry", "Finn"), 
                   case_insensitive = FALSE,
                   window = 10) %>% 
  as_tibble()

head(konkordanca) %>% paged_table()
```

Z ukazom *count()* lahko preštejemo, koliko pojavnic je *kwic()* našel.

```{r}
konkordanca %>% 
  count(keyword, sort = TRUE)

```

Skladno z našim pričakovanjem sta "Tom" in "Huck", glavna junaka romana, pogosta  izraza. Natančneje si lahko ogledamo tudi sobesedilo, v katerem se pojavljajo iskani znakovni nizi (keywords).


# 6. Pogostnost

Besedilno-besedna matrika (dfm) je izhodišče za izračun in grafični prikaz več
statističnih količin, npr. tudi pogostnosti besednih oblik v posameznih
besedilih:

```{r}
matrika = dfm(besede, tolower = FALSE) # za zdaj obdržimo velike začetnice

# Odstranimo besede, ki jih v vsebinski analizi ne potrebujemo (stopwords)
matrika = dfm_select(matrika, selection = "remove", pattern = stoplist)
matrika
```

Program *quanteda* ima posebno funkcijo, ki sestavi seznam besednih oblik in
njihove pogostnosti, tj. *textstat_frequency()*.

```{r}
library(quanteda.textstats)
library(quanteda.textplots)

pogostnost = textstat_frequency(matrika, groups = c("tom_de.txt", "tom_en.txt"))
head(pogostnost)
tail(pogostnost)

```

Na diagramu najpogostnejših izrazov v izvirniku in prevodu lahko zasledimo podobne tendence in razlike, nazorno pa nam pokaže tudi, ali smo izločili vse tiste izraze, ki jih za vsebinsko analizo ne želimo imeti na seznamu in ali bi bilo smiselno, dopolniti seznam "stoplist" (gl. zgoraj).

```{r}
as_tibble(pogostnost) %>%
  slice_max(order_by = frequency, n = 60) %>%
  mutate(feature = reorder_within(feature, frequency, frequency, sep = ": ")) %>%
  # ggplot(aes(frequency, reorder(feature, frequency))) +
  ggplot(aes(frequency, feature)) +
  geom_col(fill="steelblue") +
  labs(x = "Frequency", y = "") +
  facet_wrap(~ group, scales = "free_y")

```


# 7. Kolokacije

*Koleksemi* = slovarske enote, ki se sopojavljajo. 
*Kolokacije* = jezikovne prvine, ki se sopojavljajo.

*Statistična opredelitev*: Če se dva izraza (npr. "dober dan") pojavljata bistveno
pogosteje kot neposredna soseda, kakor bi naključno pričakovali, potem ju lahko
obravnavamo kot kolokacijo.

*Jezikoslovna opredelitev*: Kolokacija je pomensko povezano zaporedje besed.

Pomembno: za ugotavljanje kolokacij potrebujemo besedni seznam z opcijo *padding = TRUE* ! V besednem seznamu "woerter" smo sicer izločili nezaželene besedne oblike, ampak opcija padding = TRUE namesto izločenih besed vstavi vrzel oz. prazen niz "". Tako program prepreči odkrivanje lažnih kolokacij.

Funkcija *textstat_collocations()* programa *quanteda* nam bo poiskala (statistično opredeljene) kolokacije. Z opcijo *size* nastavimo, koliko členov naj vsebuje (npr. 2 za dve besedni obliki, 2:3 za dve ali tri besede). Opcija *tolower = TRUE* odpravi razlikovanje med malimi in velikimi črkami. Opcija *minimal_count* določa, kolikšna naj bo najmanjša pogostnost. 

V naslednjih preglednicah so prikazane kolokacije obeh romanov, izvirnika in prevoda.

```{r}
coll_2 = textstat_collocations(woerter, # seznma besednih oblik
                               size = 2, # obseg kolokacije
                               tolower = TRUE,  # naredi male črke !
                               min_count = 2) # prag pogostnosti
head(coll_2)

```

Tročlenskih kolokacij je precej manj kot dvočlenskih.

```{r}
coll_3 = textstat_collocations(woerter, size = 3, tolower = TRUE, 
                               min_count = 2)
head(coll_3)

```

Program ni našel štričlenskih kolokacij, ki bi se pojavljale vsaj dvakrat. 

```{r}
coll_4 = textstat_collocations(woerter, size = 4, tolower = TRUE, 
                               min_count = 2)
head(coll_4)

```

Seznam vseh kolokacij velikost 2, 3 in 4. V stolpcu *count_nested* program šteje kolokacije, vsebovane v drugi kolokaciji (višjega reda). 

```{r}
coll_2_4 = textstat_collocations(woerter, size = 2:4, tolower = TRUE, 
                               minimal_count = 2)
head(coll_2_4)

```

Kolokacija samostalniških izrazov. 

V nemščini imajo samostalniki veliko začetnico. Najprej bomo sestavili seznam besednih oblik z veliko začetnico (woerter_caps). Pri tem nam pomagata *regularni izraz* "^[A-Z]" in opcija *case_insensitive = FALSE*. Potem lahko pridobimo seznam kolokacij (coll_caps2).

Spremenljivki *lambda* in *z* nam povesta, kako značilna je kolokacija v besedilu.

Najprej kolokacije v nemškem prevodu, ki so sestavljene iz besednih oblik z veliko začetnico (poleg lastnih imen tudi splošna imena): 

```{r}
# seznam besed z veliko začetnico
woerter_caps_de = tokens_select(woerter["tom_de.txt"], 
                                pattern = "^[A-Z]", 
                                valuetype = "regex", 
                                case_insensitive = FALSE, 
                                padding = TRUE)

# kolokacije besed z veliko začetnico
coll_caps2_de = textstat_collocations(woerter_caps_de, size = 2, tolower = FALSE,
                                      min_count = 5)
head(coll_caps2_de, 10)

```

Še kolokacije v angleškem izvirniku, ki so sestavljene le iz lastnih imen:

```{r}
woerter_caps_en = tokens_select(woerter["tom_en.txt"], 
                                pattern = "^[A-Z]", 
                                valuetype = "regex", 
                                case_insensitive = FALSE, 
                                padding = TRUE)


coll_caps2_en = textstat_collocations(woerter_caps_en, size = 2, tolower = FALSE,
                                      min_count = 5)
head(coll_caps2_en, 10)

```


# 8. Lematizacija

*Slovarska enota* (*lema*) je osnovna oblika neke besede (geslo v slovarju): imenovalnik ednine, če gre za samostalniško obliko oz. nedoločnik, če gre za glagolsko obliko itd. 

Seznam slovarskih enot lahko sestavimo sami, bistveno hitreje (čeprav ne brez napak!) pa to opravimo programsko, npr. z *udpipe* ali *spacyr*. 


## Lasten seznam
Seznam slovarskih enot (lem) lahko naložimo z medmrežja na naš disk. 

Tu je prikazan postopek za nemški prevod. Naš *quanteda* korpus vsebuje tudi angleško besedilo, ki ga moramo izločiti, preden začnem lematizacijo nemških besednih oblik.

```{r}
besede_de = besede["tom_de.txt"]
```

Če imamo primeren seznam na disku, je postopek za uporabo s korpusom *quanteda* npr. takšen:
- odpremo datoteko, ki vsebuje seznam lem (npr. z ukazom *read.delim2()* - odvisno od datotečne oblike);
- za uporabo s korpusom pretvorimo stolpca podatkovnega niza v besedna seznama (tj. *as.character()*);
- nazadnje zamenjamo besedne oblike z lemami(s funkcijo *token_replace()*). Če ustrezne leme ne najde, obdrži besedno obliko, ki jo je program našel v besedilu.

```{r}
# Preberi seznam slovarskih enot in pojavnic z diska
lemdict = read.delim2("data/lemmatization_de.txt", 
                      sep = "\t", # stolpci so ločeni tabulatorsko
                      encoding = "UTF-8", # univerzalno kodiranje črk
                      col.names = c("lemma", "word"), # dodamo imena stolpcev
                      stringsAsFactors = F) # preberi kot črkovne nize

# Pretvori podatkovna niza v znakovna niza
lemma = as.character(lemdict$lemma) # v tem stolpcu je osnovna oblika besede
word = as.character(lemdict$word) # v tem stolpcu je ena izmed besednih oblik

# Lematiziraj pojavnice v naših besedilih
lemmas_de <- tokens_replace(besede_de, # seznam nemških besednih oblik (tokens)
                             pattern = word, # obliko, ki jo želimo zamenjati
                             replacement = lemma, # zamenjava
                             case_insensitive = TRUE, # ne glede na začetnico
                             valuetype = "fixed") # natančno ujemanje oblik

lemmas_de # zdaj imamo leme (če je program našel zamenjavo za besedno obliko)
```

Zdaj ko imamo seznam slovarskih enot, lahko ustvarimo tudi matriko s slovarskimi enotami (namesto s pojavnicami), in sicer z funkcijo *dfm()* tako kot zgoraj.

```{r}
matrika_lem_de = dfm(lemmas_de, 
                     tolower = FALSE) # za zdaj obdržimo velike začetnice

# Odstranimo besede, ki jih v vsebinski analizi ne potrebujemo (stopwords)
matrika_lem_de = dfm_select(matrika_lem_de, 
                            selection = "remove", 
                            pattern = stoplist_de)
matrika_lem_de

```


## Udpipe

### Angleški izvirnik

Lematizacijo angleškega izvirnika bomo opravili s programom *udpipe*, ki je na voljo za številne jezike (tudi slovenščino).

Pred prvo uporabo moramo naložiti model za nemški jezik z interneta.

```{r}
# install.packages("udpipe)
library(udpipe)
language_model <- udpipe_download_model(language = "english")

```

V naslednjem koraku naložimo jezikovni model v pomnilnik.

```{r}
ud_en <- udpipe_load_model(language_model$file_model)

```

Če je jezikovni model že v naši delovni mapi, download ni potreben, saj ga lahko
takoj naložimo z diska v pomnilnik.

```{r}
file_model = "english-ewt-ud-2.5-191206.udpipe"
ud_en <- udpipe_load_model(file_model)

```

Naslednji korak je *udpipe_annotate()*: program udpipe označuje besedne oblike
po več merilih. Lematizacijo je le ena izmed nalog, ki jih program opravi.

Udpipe prebere in označuje besedilo takole:

Na začetku je *readtext()* prebral besedila, shranili smo jih pod imenom "txt". Angleški izvirnik smo shranili pod imenom "txt2", besedilo pa je v stolpcu "text".

```{r}
x <- udpipe_annotate(ud_en, # jezikovni model
                     x = txt2$text,  # izbran je le angleški izvirnik
                     trace = TRUE) # sledimo napredku anotacije

```

Pretvorba seznama v podatkovni niz s funkcijo *as.data.frame()*:

```{r}
# # Alternativno branje angleškega izvirnika
# # samo drugo besedilo:
# x <- udpipe_annotate(ud_en, x = txt$text[2], trace = TRUE)
en_df <- as.data.frame(x)
head(en_df)

```

### Nemški prevod

Lematizacijo nemškega prevod bomo tokrat opravili s programom *udpipe*.

Pred prvo uporabo moramo naložiti model za nemški jezik z interneta.

```{r}
# install.packages("udpipe)
library(udpipe)
sprachmodell <- udpipe_download_model(language = "german")

```

V naslednjem koraku naložimo jezikovni model v pomnilnik.

```{r}
ud_de <- udpipe_load_model(sprachmodell$file_model)

```

Če je jezikovni model že v naši delovni mapi, download ni potreben, saj ga lahko
takoj naložimo z diska v pomnilnik.

```{r}
file_model = "german-gsd-ud-2.5-191206.udpipe"
ud_de <- udpipe_load_model(file_model)

```

Naslednji korak je *udpipe_annotate()*: program udpipe označuje besedne oblike
po več merilih. Lematizacijo je le ena izmed nalog, ki jih program opravi.

Udpipe prebere in označuje besedilo takole:

Na začetku je *readtext()* prebral besedila, shranili smo jih pod imenom "txt". Nemški prevod smo shranili pod imenom "txt1", besedilo pa je v stolpcu "text".

```{r}
x <- udpipe_annotate(ud_de, # jezikovni model
                     x = txt1$text,  # izbran je le nemški prevod romana
                     trace = TRUE) # sledimo napredku anotacije

```

Pretvorba seznama v podatkovni niz s funkcijo *as.data.frame()*:

```{r}
# # Alternativno branje angleškega izvirnika
# # samo drugo besedilo:
# x <- udpipe_annotate(ud_en, x = txt$text[2], trace = TRUE)
de_df <- as.data.frame(x)
head(de_df)

```


# 9. Besedni oblaček

Besedni oblački so smiseln in razmeroma preprost prikaz najpogostejših besed v besedilu. Največkrat jih uporabljajo za prikaz vsebinsko relevantnih besed. Zato je treba najprej odstraniti funkcijske in druge neprimerne izraze. Še boljši pregled nad vsebino besedila nam besedni oblački dajejo, če uporabljamo slovarske enote (leme) namesto besednih oblik. To še posebej velja v oblikoslovno bogatih jezikih kot sta slovenščino in nemščina.

Podatkovni niz "en_df", ki ga je ustvaril *udpipe*, moramo pripraviti za program *wordcloud2*:
- izločiti nezaželene izraze,
- ugotoviti pogostnost besed in
- omejiti število besed za prikaz v besednem oblačku.

```{r}
en_df_ud <- en_df %>% 
  filter(upos != "PUNCT") %>% # izločimo ločila
  filter(str_detect(lemma, "^[:alpha:]")) %>% # samo črke, ne simobolov itd.
  mutate(word = str_to_lower(lemma)) # vse pretvorimo v male črke

# iz besednega senzama naredimo podatkovni niz
stoplist_eng = as_tibble(stoplist_en) %>% 
  rename(word = value) # sprememba imena

# odstranimo nezaželene besede
en_df_cleaned = en_df_ud %>% 
  anti_join(stoplist_eng, by = "word")

# preštejemo besede in izberemo najpogostejše
topfeat_en = en_df_cleaned %>% 
  count(word, sort = TRUE) %>% 
  head(300) %>% 
  as_tibble()

# Oblaček
set.seed(1320)
library(wordcloud2)
wordcloud2(topfeat_en)

```

Oblaček nemških slovarskih enot:

```{r}
de_df_ud <- de_df %>% 
  filter(upos != "PUNCT") %>% # brez ločil
  filter(str_detect(lemma, "^[:alpha:]")) %>% # samo črke, ne simobolov itd.
  mutate(word = str_to_lower(lemma)) # vse pretvorimo v male črke

# iz besednega seznama naredimo podatkovni niz
stoplist_deu = as_tibble(stoplist_de) %>% rename(word = value)

# odstranimo nezaželene besede
de_df_cleaned = de_df_ud %>% 
  anti_join(stoplist_deu, by = "word")

# preštejemo besede, zadnji popravki in izberemo najpogostejše
topfeat_de = de_df_cleaned %>% 
  count(word, sort = TRUE) %>% 
  filter(!str_detect(word, "er\\|es\\|sie")) %>% # izločimo z regularnim izrazom
  filter(!str_detect(word, "sie\\|sie")) %>% # izločimo z regex
  mutate(word = str_replace(word, "hucken", "huck")) %>% # popravek !!!
  head(300) %>% 
  as_tibble()

# Oblaček
set.seed(1320)
library(wordcloud2)
wordcloud2(topfeat_de)

```

Oblaček angleških slovarskih enot, ki smo jih pridobili s programom *udpipe*, lahko tudi pripravimo za prikaz s funkcijo *textplot_wordcloud()* programa *quanteda*. 

```{r}
tok_en = en_df_cleaned %>% 
  select(word) %>% 
  mutate(word = paste(word, collapse = " ")) %>% 
  head(1)
toks_en = tokens(tok_en$word)

matrika_lem_en = dfm(toks_en)
matrika_lem_en = dfm_select(matrika_lem_en, 
                            pattern = stoplist_en, 
                            selection = "remove")

# spremenimo ime (doc_id)
docnames(matrika_lem_en) <- "tom_en"

textplot_wordcloud(matrika_lem_en, # le nemški prevod
                   comparison = FALSE, # brez primerjave z drugim besedilom
                   adjust = 0.025, 
                   color = c("darkblue","orange","darkgreen"),
                   max_size = 5, min_size = 0.75, rotation = 0.5, 
                   min_count = 10, # spodnji prag pogostnosti
                   max_words = 250) # koliko besed sme biti v oblačku

```

Priprava seznama nemških slovarskih enot, ki smo jih pridobili z *udpipe*, in prikaz s funkcijo textplot_wordcloud().

```{r}
tok_de = de_df_cleaned %>% 
  select(word) %>% 
  mutate(word = paste(word, collapse = " ")) %>% 
  head(1)
toks_de = tokens(tok_de$word)

matrika_lem_de = dfm(toks_de)
matrika_lem_de = dfm_select(matrika_lem_de, 
                            pattern = c(stoplist_de, "|"), 
                            selection = "remove")

# spremenimo ime (doc_id)
docnames(matrika_lem_de) <- "tom_de"

textplot_wordcloud(matrika_lem_de, # le nemški prevod
                   comparison = FALSE, # brez primerjave z drugim besedilom
                   adjust = 0.025, 
                   color = c("darkblue","orange","darkgreen"),
                   max_size = 5, min_size = 0.75, rotation = 0.5, 
                   min_count = 10, # spodnji prag pogostnosti
                   max_words = 250) # koliko besed sme biti v oblačku

```

Združimo matriki s funkcijo *rbind()*.

```{r}
matrika_lem_de_en = rbind(matrika_lem_de, matrika_lem_en)
matrika_lem_de_en
```

Če želimo, lahko matriko pretvorimo v podatkovni niz: 

```{r}
convert(matrika_lem_de_en, to = "data.frame") %>%
  write_csv("data/tom_tom_matrika.csv")
```


Primerjalni oblaček nemških in angleških slovarskih enot:

```{r}
textplot_wordcloud(matrika_lem_de_en, 
                   comparison = TRUE, # primerjava z drugim besedilom
                   adjust = 0.025, 
                   color = c("darkblue","darkgreen"),
                   max_size = 4, min_size = 0.5, rotation = 0.5, 
                   min_count = 10, # spodnji prag pogostnosti
                   max_words = 120) # koliko besed sme biti v oblačku

```


# 10. Položaj v besedilu (xray)

Diagram prikazuje, kje v besedilih se pojavlja določena besedna oblika. Podobno:
Voyant Tools (MicroSearch).

Za primerjavo so bili izbrani izrazi, ki dandanes niso več nevtralni, temveč bolj ali manj rasistično obarvani ali celo pejorativni.

```{r}
kwic_tom = kwic(besede, 
                 pattern = c("indian*", "injun", # indinaer?
                             "neg*", "nigg*")) # neger?
textplot_xray(kwic_tom)

```


# 11. Slovarska raznolikost

Za oceno slovarske raznolikosti besedil je več meril. Najosnovnejša in najbrž najbolj znano je razmerje med številom različnic in pojavnic (TTR). Slaba lastnost tega merila je odvisnost od velikosti besedila.

Program *quanteda* nam s funkcijo *textstat_lexdiv()* pričara celo paleto meril za slovarsko raznolikost (več o njih v pomoči programa).

V spodnji razpredelnici vidimo številke po odstranitvi funkcijskih besed in nekaterih drugih nezaželenih izrazov (stopwords). TTR nemškega prevoda je večji kot tisti za angleški izvirnik, kar bi lahko pomenilo, da vsebuje več oblik.

```{r}
textstat_lexdiv(matrika, measure = "all")

```

V naslednji tabeli vidimo izračun slovarske raznolikosti na osnovi slovarskih enot (namesto različnic).

```{r}
textstat_lexdiv(matrika_lem_de_en, measure = "all")

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

Rezultat (ki je bil pričakovan): Kafkina novela "Die Verwandlung" je nemškemu prevoda podobnejši kot angleški izvirnik Twainovega romana "Tom Sawyer". Program očitno ne primerja vsebine besedil, temveč besedne oblike.

```{r}
textstat_simil(romane3_dfm, method = "cosine", margin = "documents")

```

Podobnost oblik (features).

```{r}
# compute some term similarities
simil1 = textstat_simil(matrika, matrika[, c("Tom", "Sawyer", "Huck", "Finn")], 
                         method = "cosine", margin = "features")
head(as.matrix(simil1), 10)
tail(as.matrix(simil1), 10)

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
key_tom_de <- textstat_keyness(matrika, target = "tom_de.txt")
key_tom_de

key_tom_en <- textstat_keyness(matrika, target = "tom_en.txt")
key_tom_en

```

```{r}
textplot_keyness(key_tom_de, key_tom_de$n_target == 1)
textplot_keyness(key_tom_de, key_tom_en$n_target == 1)
textplot_keyness(key_tom_de)
textplot_keyness(key_tom_en)

```


# 14. Razumljivost besedil

Indeksi razumljivosti (readability index) so prirejeni za angleščino, za druge
jezike veljajo v manjši meri.

Flesch-Index velja angleška besedila: nižja vrednost nakazuje, da neko besedilo težje beremo (razumemo).

Indeks nemškega prevoda ima nižjo vrednost (61) kot Tom Sawyer (81), kar je lahko povezano (a) z daljšimi povedmi in/ali (b) daljšimi besedami (zloženke v nemščini pišemo kot eno besedo, v angleščini pogosto ne). 

```{r}
textstat_readability(romane, measure = c("Flesch", "Flesch.Kincaid", "FOG", "FOG.PSK", "FOG.NRI"))

```

# 15. Omrežje sopojavitev (FCM)

Matriko sopojavljanja besednih oblik (FCM) pridobimo v dveh korakih: 
- najprej izberemo seznam izrazov (*pattern*) iz matrike (*dfm()*), 
- potem določimo matriko sopojavljanja besednih oblik (*fcm()*).

Primer omrežja iz nemškega prevoda:

```{r}
dfm_tags_de <- dfm_select(matrika[1,], # tom_de.txt
                       pattern = (c("tom", "huck", "*joe", "becky", "tante",
                                    "witwe","polly", "sid", "mary", "thatcher",
                                    "höhle", "herz","*schule", "katze", "geld",
                                    "zaun", "piraten","schatz")))

toptag_de <- names(topfeatures(dfm_tags_de, 50))
head(toptag_de)

```

```{r}
# Construct feature-cooccurrence matrix (fcm) of tags
fcm_tom_de <- fcm(matrika[1,]) # besedilo 1 je tom_de.txt
head(fcm_tom_de)

top_fcm_de <- fcm_select(fcm_tom_de, pattern = toptag_de)

textplot_network(top_fcm_de, 
                 min_freq = 0.6, 
                 edge_alpha = 0.8, 
                 edge_size = 5)

```

# 16. Slovnična analiza

Za slovnično analizo in lematizacijo besednih oblik lahko uporabljamo posebne
programe (npr. *spacyr* ali *udpipe*).

Program *udpipe* je na voljo za številne jezike (angleščino, nemščino, slovenščino idr.).

Tu bomo ponovno uporabljali že pridobljena jezikovna modela in podatkovna niza (gl. lematizacijo), ampak tokrat za prikaz enostavnih primerov slovnične analize.

## 16.1 Podatkovna niza

Za lažje prepoznavo besedil bomo najprej spremenili imeni v stolpcu "doc_id". Potem bomo podatkovna niza združili. 

```{r}
en_df = en_df %>% 
  mutate(doc_id = str_replace(doc_id, "doc1", "tom_en"))

de_df = de_df %>% 
  mutate(doc_id = str_replace(doc_id, "doc1", "tom_de"))

tom_df = rbind(en_df, de_df) %>% 
  mutate(token_id = as.integer(factor(token_id))) %>% 
  arrange(doc_id, paragraph_id, sentence_id, token_id)
head(tom_df)
tail(tom_df)

```

Shranjujemo in nadaljujemo naslednjič.

```{r}
# write_rds(tom_df, "data/tom_df.rds")
# tom_df = read_rds("data/tom_df.rds")
```


## 16.2 Primerjava Noun : Pron

Zdaj lahko začnemo poizvedovati po besednih oblikah, slovarskih enotah in
slovničnih kategorijah.

```{r}
tabela = tom_df %>% 
  group_by(doc_id) %>% 
  count(upos) %>% 
  filter(!is.na(upos),
         upos != "PUNCT")
head(tabela)

tabela %>% 
  mutate(upos = reorder_within(upos, n, n, sep = ": ")) %>% 
  ggplot(aes(n, upos, fill = upos)) +
  geom_col() +
  facet_wrap(~ doc_id, scales = "free") +
  theme(legend.position = "none") +
  labs(x = "Število pojavnic", y = "")

```

Izračun deležev:

```{r}
delezi = tabela %>% 
  mutate(prozent = n/sum(n)) %>% 
  pivot_wider(id_cols = upos, names_from = doc_id, values_from = n:prozent)
head(delezi)

```

```{r}
delezi %>% 
  filter(upos %in% c("NOUN", "PRON"))

```

Ali se besedili razlikujeta glede razmerja med samostalniki in zaimki?
Glede na to, da gre za vsebinsko in najbrž tudi slogovno zelo podobni besedili (izvirnik in prevod), in glede na to, da gre za sorodna jezika (angleščinao in nemščino), bi bila verjetna ničelna domneva (H0: med izvirnikom in prevodom ni statistično značilne razlike). Manj verjetna se zdi alternativna hipoteza (H1: med izvirnikom in prevodom je statistično značilna razlika). 

```{r}
# za hi kvadrat test potrebujemo le drugi in tretji stolpec
nominal = delezi %>% 
  filter(upos %in% c("NOUN", "PRON")) %>% 
  select(n_tom_de, n_tom_en) 

# statisticni preskus
chisq.test(nominal)

```

Hi kvadrat test potrjuje alternativno domnevo (H1). Angleški izvirnik in nemški prevod se razlikujeta glede razmerja med samostalniki in zaimki: X\^2 (1) = 5,71; p \< 0,001. Iz gornje tabele pogostnosti je razvidno, da je delež samostalnikov v angleškem izvirniku nekoliko večji kot v nemškem prevodu. Razlika je sicer zaradi velikih vzorcev statistično značilna, ni pa velika, saj so deleži zelo podobni. 

Da bi ugotovili, ali je ugotovljena statistična značilna razlika pomembna, bi si morali podrobneje ogledati, kateri zaimki in kateri samostalniki bistveno vplivajo na to številčno razmerje. Na splošno velja, da so zaimki manj zanesljiva jezikovna sredstva kot samostalniki, samostalniki pa so bolj zapleteni.

Če želimo primerjati eno besedno vrsto z vsemi drugimi v podatkovnem nizu, je
pretvorba bolj zapletena, saj moramo - podobno kot v Excelu: 
- najprej izračunati vsoto za vse besedne vrste, 
- potem odšteti število zaimkov oz. samostalnikov od vsote, 
- razliko pa upoštevati za tabelo 2x2 za hi kvadrat test.

```{r}
(zaimki = tom_df %>% 
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

(samostalniki = tom_df %>% 
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

Hi kvadrat testa: 
- primerjava števila zaimkov nasproti ostalim besednim vrstam,
- primerjava števila samostalnikov nasproti ostalim besednim vrstam.

V obeh primerih spet velja:
H0 (med vzorcema ni statistično značilne razlike). 
H1 (vzorca se značilno razlikujeta).

```{r}
# izločimo prvi stolpec [, -1], 
# saj za hi kvadrat test potrebujemo le številke v drugem in tretjem stolpcu
chisq.test(zaimki[,-1])
chisq.test(samostalniki[,-1])

```

Statistični izid:
Deleža zaimkov se v besedilih ne razlikujeta (prvi test potrjuje H0), vendar pa se besedili razlikujeta glede deleža samostalnikov (drugi test potrjuje H1).


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

Odstotki nakazujejo, da je delež prirednih veznikov v angleškem izvirniku rahlo večji kot v nemškem prevodu.

Spet uporabljamo hi kvadrat test (upoštevane so le povedi, ki vsebujejo veznik) za preverjanje, ali je razlika dovolj velika, da bi bila nenaključna.

```{r}
chisq.test(vezniki[,c(2:3)])

```

Z ozirom na hi kvadrat test razlika med besediloma ni statistično značilna (potrjen je H0).

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

Hi kvadrat preizkus izkazuje razliko med besediloma v primeru prirednih veznikov (potrjen je H1), v primeru podrednih veznikov pa ne (potrjen je H0).

```{r}
chisq.test(koord[,-1])
chisq.test(subord[,-1])

```

Besedili se razlikujeta glede deleža prirednih veznikov (če jih primerjamo z vsemi drugimi besednimi vrstami).


## 16.4 Slovarske enote

Program udpipe je vsako besedno obliko dodelil slovarski enoti (lemma). Koliko
koliko slovarskih enot je v besedilih? Katerim besednim vrstam najpogosteje
pripadajo?

```{r}
(tabela2 = tom_df %>% 
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
  mutate(upos = reorder_within(upos, lemmas, 
                               paste("(",100*prozent,"%)"), sep = " ")) %>%
  ggplot(aes(prozent, upos, fill = upos)) +
  geom_col() +
  facet_wrap(~ doc_id, scales = "free") +
  theme(legend.position = "none") +
  scale_x_continuous(labels = percent_format()) +
  labs(x = "Anteil", y = "Wortklasse")

```


## 16.5 Korelacija besed

Katere besedne pogostnosti se vzporedno povečujejo ali zmanjšujejo (pairwise
correlation) ? Podobno analizno orodje ima tudi *Voyant Tools*.

```{r}
library(widyr)

# pairwise correlation
correlations = tom_df %>% 
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

head(correlations)

```

Tom Sawyer: Becky (dekle, ki je Tomu všeč).

```{r}
correlations %>%
  filter(item1 == "tom") %>%
  mutate(item2 = fct_reorder(item2, correlation)) %>%
  ggplot(aes(item2, correlation, fill = item2)) +
  geom_col(show.legend = F) +
  coord_flip() +
  labs(title = "What tends to appear with 'Becky'?",
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

tom_v = get_sentences(txt$text[1]) # izberemo prvo besedilo: tom_de.txt
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
  mutate(doc_id = "tom_de.txt") %>% 
  rowid_to_column(var = "sentence")
head(sentiment1)
View(sentiment1)

```

Gornje postopke ponovimo za besedilo, ki ga želimo primerjati s prvim.

```{r}
prozess_v = get_sentences(txt$text[2]) # izberemo drugo besedilo: tom_en.txt
prozess_v = (prozess_v[-1]) # tako lahko izločimo prvo vrstico (uredniško pripombo)
prozess_values <- get_sentiment(prozess_v, method = "nrc", language = "english")
sentiment2 = cbind(prozess_v, prozess_values, ntoken(prozess_v)) %>% 
  as.data.frame() %>% 
  rename(words = V3,
         text = prozess_v,
         values = prozess_values) %>% 
  mutate(doc_id = "tom_en.txt") %>% 
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
tail(sentiment)
```

Rezultat: po gornji metodi je povprečje čustvenih vrednosti v nemškem prevodu
rahlo manjše kot v angleškem izvirniku "Tom Sawyer", vendar je razlika tako majhna, da najbrž ne bi bila statistično značilna. Povprečje je v obeh primerih blizu nevtralne vrednosti (tj. 0): Tom Sawyer vsebuje kar nekaj vedrih prigod in dogodivščin, je pa res, da so njegove pustolovščine pogosto tudi nevarne ali strašljive.

```{r}
sentiment %>% 
  group_by(doc_id) %>% 
  summarise(polarnost = mean(values))

```

Poskusimo še drugače: pozitivne, nevtralne in negativne vrednosti obravnajmo ločeno in upoštevajmo tudi dolžino povedi.

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

Ta rezultat nakazuje, so čustvene vrednosti v nemškem prevodu nekoliko skrajnejše (pozitivne ali negativne) kot v angleškem izvirniku. Zanimivo bi bilo vprašati poznavalca angleškega izvirnika in nemškega prevoda, ali je ob slogovni primerjavi dobil podoben vtis. 

Poglejmo še nekaj povedi, ki so bile ocenjene negativno:

```{r}
sentiment1 %>% 
  filter(negative > 0)
```


## 17.2 Različica 2

```{r}
tom_v = get_sentences(txt$text[2]) # angleški izvirnik
tom_nrc_values = get_nrc_sentiment(tom_v)
tom_joy_items = which(tom_nrc_values$joy > 0)
head(tom_v[tom_joy_items], 4)

```

```{r}
nrc_sentiment = as.data.frame(cbind(tom_v, tom_nrc_values))
head(nrc_sentiment) %>% paged_table()

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

Quanteda slovar lahko shranimo na disk.

```{r}
# jsonlite::write_json(bawlr_dict, "data/quanteda_bawlr_dict.json")
```

Uporabljamo matriko (dfm) s slovarskimi enotami (lemma), saj slovar bawlr_dict
vsebujejo le osnovno obliko slovarskih enot.

```{r}
matrika_lemmas = dfm(matrika_lem_de, tolower = TRUE)

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

Po navadi želimo izračunati skupno sentimentno vrednost. Možnosti je več: npr. -
odšteti negativne vrednosti od pozitivnih in nato razliko deliti z vsoto obeh
vrednosti, - odšteti negativne vrednosti od pozitivnih in nato razliko deliti z
dolžino besedil,

Izračunamo lahko tudi stopnjo subjektivnosti, tj. koliko čustvenih vrednosti je
skupno izraženih:

```{r}
result = result %>% mutate(sentiment1=(positive - negative) / (positive + negative))
result = result %>% mutate(sentiment2=(positive - negative) / length)
result = result %>% mutate(subjektivnost=(positive + negative) / length)
result %>% paged_table()

```

### Barvno označevanje

Program corpustools barvno označuje besede v besedilih z ozirom na čustvene
vrednosti besed v sentimentnem slovarju.

Prvi korak je ustvarjanje tcorpusa.

```{r}
library(corpustools)
t = create_tcorpus(txt1, doc_column="doc_id") # izbrali smo le nemški prevod

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
browse_texts(t, scale='sentiment', filename = "sentiment_tom.html", 
             header = "Sentiment in Twains Tom Sawyer")

```
