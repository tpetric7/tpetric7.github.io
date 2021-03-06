---
title: "Suffixe und Stemming"
author: "Teodor Petrič"
date: "25 7 2021"
output: 
  html_document:
    toc: TRUE
    toc_float: TRUE
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# 0. Packages

```{r}
library(tidyverse)
library(tidytext)
library(SnowballC)
library(readtext)
library(rmarkdown)
library(scales)
library(udpipe)
library(vecsets)

```

# 1. Dateien einlesen

```{r}
novels_txt = readtext("data/books/*.txt", docvarsfrom = "filenames", encoding = "UTF-8") %>% 
  rename(title = docvar1)
novels_txt

```

Wir wandeln die Datei in eine Tabelle um.

```{r}
novels = as.data.frame(novels_txt)

```


# 2. Lemmatisierung

Unser Ziel ist die Extrahierung von Wortbildungsmorphemen. Daher führen wir mit dem Program *udpipe* zuerst eine Analyse der Wortformen durch, die auch eine Lemmatisierung der Wortformen einschließt. Durch die Lemmatisierung können wir auf die Grundformen von Wörtern zurückgreifen und Flexionsmorpheme ausschließen.

```{r}
library(udpipe)
model = udpipe_download_model(language = "german")
demodel = udpipe_load_model(model$file_model)

```

Die Annotation der Wortformen kann mehrere Minuten dauern, falls es sich um längere Texte handelt.

```{r}
x = udpipe_annotate(demodel, novels_txt$text, trace = TRUE)
x = as.data.frame(x)

```

Wir filtern Interpunktionszeichen heraus, die für unser Ziel nicht relevant sind. Die Spalte "upos" enthält die dafür relevante Kategorie ("PUNCT").

In einem weiteren Schritt fügen wir mit *mutate* eine neue Spalte ("word") hinzu, welche die tokens der Texte enthält, aber kleingeschrieben gewerden sollen, was mit *tolower()* erreicht werden kann.

```{r}
udpipe = x %>% 
  filter(upos != "PUNCT") %>% 
  mutate(word = tolower(token))

```

Für die Entfernung von Ziffern und Symbolen aus der Tabelle verwenden wir einen regulären Ausdruck (regex). Außerdem sollen alle Lemmas mit Kleinbuchstaben beginnen.

```{r}
novels_words = udpipe %>% 
  filter(str_detect(lemma, "[:alpha:]")) %>% # keine Ziffern oder Interpunktionszeichen oder Symbole
  mutate(lemma = tolower(lemma))

```

Da wir vor allem an Wörtern interessiert sind, die aus mehr als einem Morphem bestehen, filtern wir u.a. Funktionswörter heraus, und zwar mit der Funktion *anti_join()* und einer Stoppwortliste aus dem Programm *stopwords*. 

Da die Stoppwortliste im Format einer Liste vorliegt, müssen wir sie in eine Tabelle umwandeln, und zwar mit der Funktion *as_tibble()*. Der Name der Tabellenspalte muss mit dem Namen der entsprechende Spalte in "novels_words" (also: "word") übereinstimmen, damit wir die beiden Tabellen entsprechend vereinen können. Den Namen von Tabellenspalten verändern wir mit *rename()*.

Außerdem wollen wir gleichzeitig auch einige Wörter herausfiltern, die nicht zu den Romantexten gehören: englische Wörter, die Namen der Autoren, eventuell noch nicht entfernte Ziffern, Interpunktionszeichen und Symbole. Zur Vereinigung der Wortformen in einen Vektor bzw. Tabellenspalte verwenden wir die concatenate-Funktion *c()*.

In einem weiteren Schritt sollen die Kategorien der "doc_id" bessere Namen erhalten: die allgemeineren Namen "doc1" und "doc2" ersetzen wir mit den eindeutigeren Namen "prozess" und "tom".

```{r}
stoplist_de = c(stopwords::stopwords(language = "german"), "franz","kafka","mark","twain",
                "by","aligned","Aligned","","bilingual-texts.com","fully","reviewed") %>% 
  as_tibble() %>% 
  rename(word = value)

novels_words = novels_words %>% 
  mutate(doc_id = str_replace(doc_id, "doc1", "prozess"),
         doc_id = str_replace(doc_id, "doc2", "tom")) %>% 
  anti_join(stoplist_de, novels_words, by = "word") # möglichst keine Funktionswörter
head(novels_words, 10) %>% paged_table()
tail(novels_words, 10) %>% paged_table()

```


# 3. Stemming

Beim Stemming werden die Stämme von Wortformen extrahiert. In flexionsarmen Sprachen (z.B. Englisch) sind die Ergebnisse gewöhnlich nützlicher als in morphologisch reichen Sprachen (z.B. Deutsch, Slowenisch).

Hier verwenden wir die Stemming-Funktion *wordStem()* des Programms *SnowballC*, um potentielle Suffixe und Suffixoide komplexer Wörter zu extrahieren. Das Ziel ist eine morphologische Vergleichsanalyse, und zwar von Wortbildungsmorphemen in den Romaen.

Mit *mutate()* und der *wordStem()*-Funktion fügen wir der Tabelle eine weitere Spalte hinzu, der wir den Namen "stamm" geben. 

```{r}
novels_words = novels_words %>% 
  mutate(stamm = wordStem(lemma, language = "de"))
head(novels_words) %>% paged_table()

```
Nun stehen uns die Lemma- und Stammformen zur Verfügung. Der Unterschied zwischen den jeweiligen Formen sollte (meist) Wortbildungsmorpheme (Suffixe) ergeben.

Um Unterschiede zwischen den in den Spalten "lemma" und "stamm" gespeicherten Wortformen zu bestimmen, wollen wir ein spezielles Programm verwenden: *library(vectsets)*.

Dann folgen einige Korrekturen mit *str_remove()*, *str_remove_all()*, *str_replace()* und *str_replace_all()*, damit in der Spalte "diffs" möglichst nur Wortbildungssuffixe vorkommen.

Mit *str_remove()* beseitigen wir ein Zeichen einmal, mit *str_remove_all()* so oft, wie es in einer Tabellenspalte vorkommt.
Mit *str_replace()* wandeln wir ein Zeichen einmal in ein anderes um, mit *str_replace_all()* so oft, wie es in einer Tabellenspalte vorkommt.

```{r}
library(vecsets)
novels_full_words = novels_words %>% 
  mutate(diffs = as.character(mapply(vsetdiff, strsplit(lemma, split = ""),
                            strsplit(stamm, split = "")))) %>% 
  mutate(diffs = str_remove(diffs, "c\\("),
         diffs = str_remove(diffs, "\\)"),
         diffs = str_remove_all(diffs, '\\"'),
         diffs = str_remove_all(diffs, ", "), 
         diffs = str_replace(diffs, "character\\(0", ""),
         diffs = str_replace(diffs, "ß", ""),
         diffs = str_replace_all(diffs, "ä", ""),
         diffs = str_replace_all(diffs, "ö", ""),
         diffs = str_replace_all(diffs, "ü", ""))

```

Das Ergebnis ist nicht perfekt, aber für bestimmte Wortbildungssuffixe brauchbar.

```{r}
novels_full_words %>% 
  select(doc_id, lemma, stamm, diffs) %>% 
head(10) %>% paged_table()

```

Wir speichern die Tabelle für spätere Analysen. Möglich sind verschiedene Formate, z.B. "rds"-Dateien, die man mit R/Rstudio öffnen kann, und "csv"-Dateien, die man mit beliebigen Programmen öffnen kann. 
Aber wir speichern die Tabelle hier nur als Excel-Datei ab, weil die Tabellenzeilen nicht zu lang sind.

```{r}
# write_rds(novels_full_words, "data/novels_full_words.rds")
# write_csv(novels_full_words, "data/novels_full_words.csv")
writexl::write_xlsx(novels_full_words, "data/novels_full_words.xlsx")

```


# 4. Wortbildungsanalyse

Um am nächsten Tag nicht alle vorherigen Schritte noch einmal machen zu müssen, können wir an dieser Stelle die zuvor gespeicherte Tabelle öffnen.

```{r}
novels_full_words = readxl::read_xlsx("data/novels_full_words.xlsx")
```


Wir beginnen unsere Wortbildungsanalyse mit dem Abzählen von verschiedenen Endungen, die von unserem Programm identifiziert wurden.

Wir wählen mit *select()* nur ein paar Tabellenspalten aus, damit wir die Übersicht behalten.
Die Ergebnisse sollen nach dem Romantitel gruppiert werden, was man mit *group_by()* bewerkstelligt.
Mit *filter()* werden leere Zeilen in der Tabellenspalte "diffs" herausgefiltert.
Dann zählen wir die verschiedenen Kategorien in der Tabellenspalte, und zwar mit *count()*.
Zuletzt verändern wir mit *pivot_wider()* das Tabellenformat, so dass die Romantitel als Spaltennamen erscheinen und die Endungen als Tabellenzeilen. Die Spalten "prozess" und "tom" enthalten nun die Häufigkeitswerte für die einzelnen Endungen.

```{r}
novels_full_words %>% 
  select(doc_id, lemma, stamm, diffs) %>%
  group_by(doc_id) %>% 
  filter(diffs != "") %>%
  count(diffs) %>% 
  pivot_wider(names_from = doc_id, values_from = n) %>% 
  paged_table()

```

Wir erweitern unsere Häufigkeitstabelle mit Prozentzahlen und geben ihr einen Namen ("novels_diffs").

```{r}
novels_diffs = novels_full_words %>% 
  select(doc_id, lemma, stamm, diffs) %>%
  group_by(doc_id) %>% 
  filter(diffs != "") %>%
  count(diffs) %>% 
  pivot_wider(names_from = doc_id, values_from = n) %>% 
  mutate(prozess_total = sum(prozess, na.rm = TRUE),
         tom_total = sum(tom, na.rm = TRUE)) %>% 
  mutate(prozess_pct = prozess/prozess_total,
         tom_pct = tom/tom_total,) %>% 
  select(-prozess_total, -tom_total)

head(novels_diffs) %>% paged_table()

```

Noch eine graphische Darstellung der Häufigkeitswerte, für die wir die Tabelle umformen, und zwar mit *pivot_longer()* und verkürzen (durch Filtervorgänge): wir wollen nur Endungen mit einer Häufigkeit von mehr als 0,5% (0.005) beibehalten. Mit *fct_lump()* kann man die Anzahl der Kategorien reduzieren (die Restkategorie heißt hier "Other"). Mit *fct_reorder()* sorgen wir dafür, dass die häufigeren Endungen im Diagramm oben erscheinen. Die Funktion *facet_wrap()* ermöglicht die getrennte Darstellung der Romane.

```{r}
library(scales)

novels_diffs %>% 
  pivot_longer(cols = prozess_pct:tom_pct, names_to = "title", values_to = "prozent") %>% 
  filter(!is.na(prozent)) %>% 
  filter(prozent > 0.005) %>% 
  mutate(diffs = fct_lump(diffs, 10)) %>% 
  mutate(diffs = fct_reorder(diffs, prozent)) %>% 
  ggplot(aes(prozent, diffs, fill = title)) +
  geom_col() +
  theme(legend.position = "none") +
  scale_x_continuous(labels = percent) +
  labs(x = "", y = "Endungen") +
  facet_wrap(~ title, scales = "free")

```

Vergleichen wir mal die Häufigkeit der Endung "-lich" in den Romanen! Da dieses Wortbildungssuffix mit adjektivischen Stämmen verknüpft wird, filtern die entsprechende Wortklasse heraus.

```{r}
(lich_tab = novels_full_words %>% 
  group_by(doc_id) %>% 
  filter(upos == "ADJ") %>% 
  count(diffs == "lich") %>%
  rename(lich = `diffs == "lich"`) %>% 
  filter(!is.na(lich)) %>% 
  pivot_wider(names_from = doc_id, values_from = n)
)

```

Ist der Unterschied zwischen den Romanen statistisch signifikant? Das überprüfen wir mit dem Chi-Quadrat-Test. Die erste Spalte enthält keine Zahlen, daher müssen wir sie beim Testen entfernen, und zwar mit *[, -1]*: alle Zeilen übernehmen, aber die este Tabellenspalte nicht.

```{r}
chisq.test(lich_tab[,-1])

```

Der Chi-Quadrat-Test hat lediglich einen signifikanten Unterschied zwischen den beiden Stichproben "prozess" und "tom" bestätigt, sagt uns aber nicht, in welcher Stichprobe, das Suffix "-lich" verhältnismäßig häufiger vorkommt. Bei dieser Beurteilung helfen uns Prozentzahlen.

```{r}
lichtab2 = novels_full_words %>% 
  group_by(doc_id) %>% 
  filter(upos == "ADJ") %>% 
  count(diffs == "lich") %>% 
  rename(lich = `diffs == "lich"`) %>% 
  filter(!is.na(lich)) %>% 
  pivot_wider(names_from = doc_id, values_from = n) %>% 
  mutate(prozess_total = sum(prozess, na.rm = TRUE),
         tom_total = sum(tom, na.rm = TRUE)) %>% 
  mutate(prozess_pct = prozess/prozess_total,
         tom_pct = tom/tom_total,) %>% 
  select(-prozess_total, -tom_total)

lichtab2 %>% paged_table()

```

Etwa 21,5% der als Adjektiv identifizierten Lemmas im Roman "prozess" enden mit dem Suffix "-lich", im Roman "tom sawyer" sind es etwa 15,2%. Der Unterschied ist auch in der graphischen Darstellung zu sehen.

```{r}
lichtab2 %>% 
  pivot_longer(prozess_pct:tom_pct, names_to = "title", values_to = "pct") %>% 
  ggplot(aes(title, pct, fill = lich)) +
  geom_col()

```

Das Suffix "-lich" gehört zu den produktiven Wortbildungsmitteln im Deutschen. Warum sind im "prozess" mehr davon zu finden als im anderen Roman? Zur Klärung dieser Frage müssten wir zuerst mehr über die semantischen Eigenschaften und Verknüpfungsmöglichkeiten (oder -einschränkungen) mit verschiedenen Wortstämmen erfahren.

```{r}
novels_full_words %>% 
  select(doc_id, lemma, word, upos, diffs) %>%
  group_by(doc_id, lemma, word) %>% 
  filter(upos == "ADJ") %>% 
  filter(diffs == "lich") %>% 
  paged_table()

```


Vergleichen wir die Häufigkeit von mehreren adjektivischen Suffixen in unserem Romankorpus!

```{r}
novels_full_words %>% 
  select(doc_id, lemma, word, upos, diffs) %>% # Auswahl von hier relevanten Spalten
  group_by(doc_id, lemma, word) %>% # Gruppierung nach diesen Merkmalen (Spalten)
  filter(upos == "ADJ") %>% # Auswahl der Wortklasse
  filter(diffs == "lich" | 
           diffs == "erlich" | 
           diffs == "isch" | 
           diffs == "ig") %>% # Suffixauswahl
  paged_table()

```

Von den insgesamt 1370 als (suffigiertes) Adjektiv identifizierten Wortformen (tokens) kommen 847 im "prozess" und 523 in "tom sawyer" vor. Der Anteil der Zustandsbeschreibungen mit Hilfe von suffigierten Adjektiven scheint im ersten Werk größer zu sein als im zuletzt genannten (was wir aber an dieser Stelle nicht mit einem Chi-Quadrat-Test überprüfen wollen).

```{r}
adj_tab = novels_full_words %>% 
  select(doc_id, lemma, upos, diffs) %>%
  group_by(doc_id) %>% 
  filter(upos == "ADJ") %>% 
  filter(diffs == "lich" | diffs == "erlich" | diffs == "isch" | diffs == "ig") %>% 
  count(diffs) %>% 
  pivot_wider(names_from = doc_id, values_from = n) %>% 
  mutate(prozess_total = sum(prozess, na.rm = TRUE),
         tom_total = sum(tom, na.rm = TRUE)) %>% 
  mutate(prozess_pct = prozess/prozess_total,
         tom_pct = tom/tom_total)

adj_tab %>% paged_table()

```


```{r}
library(scales)

adj_tab %>% 
  pivot_longer(prozess_pct:tom_pct, names_to = "title", values_to = "pct") %>% 
  mutate(diffs = fct_reorder(diffs, pct)) %>% 
  ggplot(aes(pct, diffs, fill = title)) +
  geom_col(position = "dodge") +
  scale_x_continuous(labels = percent) +
  theme(legend.position = "top")

```


# Nicht verwendete Tabelle

```{r}
novels_full_words %>% 
  select(doc_id, lemma, stamm, diffs) %>%
  group_by(doc_id) %>% 
  filter(diffs != "") %>%
  add_count(doc_id, name = "total") %>% 
  add_count(diffs) %>% 
  mutate(pct = n/total) %>%
  pivot_wider(names_from = doc_id, values_from = n, names_repair = "unique") %>% 
  unnest(c(prozess, tom)) %>% 
  paged_table()

```

