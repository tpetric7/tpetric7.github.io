---
title: "Letter frequency in novels"
author: "Teodor Petrič"
date: "21 7 2021"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```


# 0. Packages

```{r}
library(tidyverse)
library(tidytext)
library(scales)
library(readtext)
# library(qdap) # syllable_count and syllable_sum
# library(quanteda) # nsyllable(tokens(txt))
```


# 1. Datensatz lesen

Die *readtext()*-Funktion erlaubt Einlesen von mehreren Dateien auf einfache Art und Weise.
Mit *docvarsfrom* erhalten wird eine neue Spalte in der Tabelle, die wir mit der Funktion *rename()* umbenennen.
Mit *encoding = "UTF-8"* teilen wir dem Programm mit, wie der Text kodiert ist (Code Page).

```{r}
novels_txt = readtext("data/books/*.txt", docvarsfrom = "filenames", encoding = "UTF-8") %>% 
  rename(title = docvar1)
novels_txt

```


# 2. Buchstaben extrahieren

## aus Liste

Der reguläre Ausdruck *[a-zA-Z]* extrahiert nur Buchstaben des englischen Alphabets, *[:alpha:]* extrahiert dagegen auch nicht-englische Buchstaben, z.B. deutsche oder slowenische Sonderzeichen. Zahlen und andere spezielle Zeichen (z.B. Interpunktion) werden auf diese Weise nicht extrahiert.

Regex *{1}* (= default) extrahiert Einzelbuchstaben. Bei Verwendung von *{2}* werden jeweils zwei aufeinander folgende Buchstaben extrahiert.

Die Funktion *tolower()* sorgt dafür, dass Großbuchstaben in Kleinbuchstaben umgewandelt werden. Falls zwischen großen und kleinen Buchstaben unterschieden werden soll, entfernen wir diese Funktion aus dem Programmkode.

```{r}
letters = tolower(novels_txt$text) %>% str_extract_all(pattern = "[:alpha:]{1}")
letters[[1]][1:10]
letters[[2]][1:9]

```


## aus Datensatz

Tabellen und Graphiken erstellen ist leichter, wenn wir die Texte in Datensätze umwandeln, und zwar mit der Funktion *as.data.frame()*.

```{r}
novels = as.data.frame(novels_txt)

```


Mit der Funktion *unnest_tokens()* können wir auch Buchstaben isolieren und anschließend auszählen.

```{r}
library(tidytext)

novels_character <- novels %>%
  unnest_tokens(character, text, token = "characters", to_lower = TRUE, drop = T)

head(novels_character)

```

# 3. Buchstaben zählen

Mit *count()* können wir die Häufigkeit einer Variable (hier: der Buchstaben) auszählen.

```{r}
novels_character %>% 
  count(character, sort = TRUE)

```

Der tidytext-Tokenizer hat nicht nur Buchstaben, sondern auch Zahlen extrahiert. Da wir nur an der Häufigkeit von Buchstaben interessiert sind, filtern wir die Zahlen und andere Zeichen heraus. Dazu verwenden wir die Funktionen *filter()* und zusätzlich *str_detect()*, da wir für diese Aufgabe einen regulären Ausdruck nutzen wollen.

```{r}
novels_character %>% 
  filter(str_detect(character, "[:alpha:]")) %>% 
  count(character, sort = T)
```


Ein paar Zeichen, die nicht zum deutschen Alphabet gehören und mit dem vorherigen Programm-Schritt nicht herausfiltern konnten, werden im nächsten Schritt ebenfalls herausgefiltert.

Wir speichern das Ergebnis als neue Tabelle mit dem Namen "char_freq".

```{r}
char_freq = novels_character %>% 
  filter(str_detect(character, "[:alpha:]")) %>% 
  filter(!str_detect(character, "é|á")) %>% 
  count(character, sort = T)

char_freq

```

Insgesamt haben wir 30 Buchstaben des deutschen Alphabets in den Romanen unterschieden.
Aus wie vielen Buchstaben des deutschen Alphabets bestehen die Romane? Die Summe erhalten wir mit der Funktion *summarise()* - fast 700 Tausend.

```{r}
char_freq %>% 
  summarise(total = sum(n))
```

Es ist nun wirklich Zeit, mal ein Bild zu malen! 
Dazu verwenden wir das Programm (library) *ggplot2*, das im Programmbündel *tidyverse* enthalten ist.

Das Diagramm zeigt sehr deutlich, dass gewaltige Häufigkeitsunterschiede im deutschen Alphabet bestehen.

```{r}
char_freq %>% 
  mutate(character = fct_reorder(character, n)) %>% # Sortieren nach Frequenz
  ggplot(aes(n, character, fill = character)) +
  geom_col() +
  theme(legend.position = "none")

```

Eine bessere Vorstellung von den Zahlenverhältnissen erhalten wir, wenn wir die mehrstelligen Zahlenwerte in Prozente umwandeln.

```{r}
library(scales)
char_freq %>% 
  mutate(Prozent = n / sum(n)) %>% # Umwandlung in Prozente
  ungroup() %>% 
  mutate(character = fct_reorder(character, Prozent)) %>% # Sortieren nach Prozenten
  ggplot(aes(Prozent, character, fill = character)) +
  geom_col() +
  theme(legend.position = "none") +
  scale_x_continuous(labels = percent) # Prozent-Format

```

Getrennte tabellarische Darstellung für die Texte:

```{r}
novels_character %>% 
  group_by(doc_id) %>% 
  count(character, sort = TRUE) %>% 
  pivot_wider(names_from = doc_id, values_from = n)

```

Getrennte graphische Darstellung für die Texte:


```{r}
library(scales)
novels_character %>% 
  group_by(doc_id) %>% 
  count(character, sort = TRUE) %>% 
  mutate(Prozent = n / sum(n)) %>% # Umwandlung in Prozente
  ungroup() %>% 
  mutate(character = fct_reorder(character, Prozent)) %>% # Sortieren nach Prozenten
  filter(Prozent > 0.0001) %>% 
  ggplot(aes(Prozent, character, fill = character)) +
  geom_col() +
  theme(legend.position = "none") +
  facet_wrap(~ doc_id, scales = "free")
  scale_x_continuous(labels = percent) # Prozent-Format

```


# 4. Vokale

Betrachten wir zunächst nur die Buchstaben, die Vokale symbolisieren!
Zu diesem Zweck bilden wir eine Vokalliste. Zwischen den Vokalen setzen wir das "oder"-Zeichen ein: den *logischen Operator* "|".

```{r}
vokale = "a|e|i|o|u|ä|ö|ü|y"
```

Die Vokalliste "vokale" verwenden wir mit den Funktionen *filter()* und *str_detect()*.

```{r}
library(scales)
char_freq %>% 
  filter(str_detect(character, vokale)) %>% 
  mutate(Prozent = n / sum(n)) %>% # Umwandlung in Prozente
  ungroup() %>% 
  mutate(character = fct_reorder(character, Prozent)) %>% # Sortieren nach Prozenten
  ggplot(aes(Prozent, character, fill = character)) +
  geom_col() +
  theme(legend.position = "none") +
  labs(y = "Vokale", x = "Häufigkeit in Romanen") +
  scale_x_continuous(labels = percent, breaks = seq(0, 0.50, 0.05)) # Prozent-Format

```

Am häufigsten kommt der Buchstabe "e" in den Romanen vor (fast 45%-iger Anteil unter den Vokalen!), am seltensten "y", welches im Wesentlichen in Fremd- und Lehnwörtern auftritt.


# 5. Konsonanten

Welche Buchstaben, die Konsonanten symbolisieren, kommen am häufigsten vor?
Zum Filtern verwenden wir wiederum die Vokalliste, dieses Mal allerdings mit Negationszeichen "!".

```{r}
library(scales)
char_freq %>% 
  filter(!str_detect(character, vokale)) %>% # Negationszeichen, daher Konsonanten beibehalten
  mutate(Prozent = n / sum(n)) %>% # Umwandlung in Prozente
  ungroup() %>% 
  mutate(character = fct_reorder(character, Prozent)) %>% # Sortieren nach Prozenten
  ggplot(aes(Prozent, character, fill = character)) +
  geom_col() +
  theme(legend.position = "none") +
  labs(y = "Konsonanten", x = "Häufigkeit in Romanen") +
  scale_x_continuous(labels = percent, breaks = seq(0, 0.50, 0.02)) # Prozent-Format und Einheiten

```

Der Buchstabe "n" kommt in den Romanen am häufigsten vor, gefolgt von den Buchstaben: "r, s, t, h, d".
Selten sind die Buchstaben: "x, q, p, ß, v".


# 6. Vokal-Konsonant-Verhältnis

Welches Zahlenverhältnis besteht zwischen den Vokalen und Konsonanten?

21 konsonantische Buchstaben und 9 vokalische Buchstaben. Pro Silbe sind in den deutschen Texten 1 Vokal und ungefähr 2 Konsonanten zu erwarten, also Silbenstrukturen wie z.B. KVK, KKV, VKK.

```{r}
char_freq %>% 
  mutate(buchstabe = ifelse(str_detect(character, vokale), "Vokal", "Konsonant")) %>% 
  count(buchstabe)

```

Der höhere Anteil der Konsonanten entspricht der größeren Konsonantenmenge.

```{r}
char_freq %>% 
  mutate(buchstabe = ifelse(str_detect(character, vokale), "Vokal", "Konsonant")) %>% 
  mutate(Prozent = n / sum(n)) %>% 
  group_by(buchstabe) %>% 
  summarise(Avg_Prozent = sum(Prozent))

```


```{r}
char_freq %>% 
  mutate(buchstabe = ifelse(str_detect(character, vokale), "Vokal", "Konsonant")) %>% 
  mutate(Prozent = n / sum(n)) %>% 
  group_by(buchstabe) %>% 
  summarise(Avg_Prozent = sum(Prozent)) %>% 
  ggplot(aes(Avg_Prozent, buchstabe, fill = buchstabe)) +
  geom_col() +
  theme(legend.position = "none") +
  labs(y = "Vokale / Konsonanten", x = "Häufigkeit in Romanen") +
  scale_x_continuous(labels = percent, breaks = seq(0, 0.75, 0.1)) # Prozent-Format und Einheiten

```

Diese Zahlenwerte und -verhältnisse bilden einen möglichen Ausgangspunkt für intra- oder interlinguale Vergleiche. 


# 7. Anzahl der Silben

Wie viele Silben kommen in den Romanen schätzungsweise vor und wie viele Buchstaben pro Silbe? Die genaue Bestimmung der Silbenanzahl für eine bestimmte Sprache kann aufgrund zahlreicher Besonderheiten ziemlich kompliziert sein. Die Anzahl der Silben schätzen wir daher mit einer Funktion des Programms *nsyllable* (Alternatives Programm: *qdap*). 

Da wir die Silbenzählfunktion nur ein einziges Mal bemühen, rufen wir sie in der unten sichtbaren Form auf: *nsyllable::nsyllable(buchstabenfolge)*.

```{r}
novels_words <- novels %>%
  unnest_tokens(word, text, token = "words", to_lower = TRUE, drop = T) %>% 
  mutate(syllables = nsyllable::nsyllable(as.character(word), language = "en")) %>% 
  mutate(letters = nchar(word))
  
head(novels_words)

```
Insgesamt (d.h. kumulativ gesehen) fast 139 Tausend Silben in den Romanen. Diese Zahl bietet einen möglichen Ausgangspunkt für Textvergleiche.

```{r}
novels_words %>% 
  count(syllables) %>% 
  summarise(Silben = sum(n))

```

Die meisten Wortformen in den Romanen bestehen aus einer Silbe (fast 60%) oder zwei Silben (fast 30%). Das ist typisch für deutsche Texte. Kurze Funktionswörter (meist eine Silbe) kommen wesentlich häufiger vor als andere Wortklassen (Substantive, Verben, Adjektive, Adverbien).

```{r}
novels_words %>% 
  count(syllables) %>% 
  mutate(Prozent = n / sum(n)) %>% 
  ggplot(aes(syllables, Prozent, fill = factor(syllables))) +
  geom_col() +
  theme(legend.position = "none") +
  labs(x = "Silben") +
  scale_y_continuous(labels = percent, breaks = seq(0, 0.75, 0.1)) # Prozent-Format und Einheiten

```

Berücksichtig man lediglich distinktive Wortformen (also keine Wortwiederholungen), dann ergibt sich die folgende Verteilung, in der die Zweisilber (mehr als 30%) und Dreisilber (fast 30%) den größten Anteil haben.

```{r}
novels_words %>% 
  distinct(word, .keep_all = T) %>%
  count(syllables) %>% 
  mutate(Prozent = n / sum(n)) %>% 
  ggplot(aes(syllables, Prozent, fill = factor(syllables))) +
  geom_col() +
  theme(legend.position = "none") +
  labs(x = "Silben") +
  scale_y_continuous(labels = percent, breaks = seq(0, 0.75, 0.1)) # Prozent-Format und Einheiten

```


# 8. Mittlere Wortlänge

Wir können die Wortlänge in geschriebenen Texten auf zumindest zwei grundlegende Arten messen:
- die Anzahl der Silben pro Wort(form),
- die Anzahl der Buchstaben pro Wort(form).

Die durchschnittliche Anzahl der Silben und Buchstaben pro Wort (distinkte Wortformen !) in den Romanen ist in der folgenden Tabelle zu sehen: 
- neben den Mittelwerten (Avg_Silben, Avg_Buchstaben) 
- auch die  Standardabweichungen vom entsprechenden Mittelwert (Stdev_Silben, Stdev_Buchstaben). 
Die Mittelwerte oder arithmetischen Mittel können mit der Programmfunktion *mean()* berechnet werden, die Standardabweichungen mit der Funktion *sd()*.
Die Standardabweichungen sind notwendig zur Feststellung nicht-zufälliger Unterschiede zwischen den Stichproben (d.h. den Romanen).
Bei der Berechnung der Mittelwerte und Standardabweichungen geben wir dem Programm auch die Instruktion, etwaige leere Datenzeilen (*NA*) herauszufiltern, und zwar mit Hilfe von *na.rm = TRUE*. Wird dies unterlassen, kann dies dazu führen, dass ein Mittelwert bzw. Standardabweichung nicht berechnet werden kann. 

In der folgenden Tabelle werden nur distinktive Wortformen (Types) berücksichtigt, d.h. als ob jede Wortform nur einmal pro Roman vorkommt.

```{r}
novels_words %>% 
  group_by(title) %>% 
  distinct(word, .keep_all = T) %>%
  add_count(word) %>% 
  summarise(Avg_Silben = mean(syllables, na.rm = TRUE),
            Stdev_Silben = sd(syllables, na.rm = TRUE),
            Avg_Buchstaben = mean(letters, na.rm = TRUE),
            Stdev_Buchstaben = sd(letters, na.rm = TRUE))

```

Die durchschnittliche Anzahl der Silben und Buchstaben pro Wortform (Token), bei Berücksichtigung von Wortwiederholungen in den Romanen, ist in der folgenden Tabelle zu sehen. 

```{r}
novels_words %>% 
  group_by(title) %>% 
  summarise(Avg_Silben = mean(syllables, na.rm = TRUE),
            Stdev_Silben = sd(syllables, na.rm = TRUE),
            Avg_Buchstaben = mean(letters, na.rm = TRUE),
            Stdev_Buchstaben = sd(letters, na.rm = TRUE))

```

# 9. Testen von Mittelwertunterschieden

## t-Test

Sind die berechneten Unterschiede zwischen den Mittelwerten relevant bzw. nicht-zufällig? Um diese Frage zu klären, kann man einen statistischen Test bemühen. Da wir lediglich zwei Samples (zwei Romanen) vergleichen wollen, kann uns ein parametrischer Test wie z.B. der t-Test Klarheit verschaffen. Wir verwenden die Programmfunktion *t.test()*.
Der t-Test bestätigt, dass "Der Prozess" im Durchschnitt etwas längere Wörter aufweist (2,59 Silben pro Wort gegenüber 2,44 Silben pro Wort in "Tom Sawyer") - wenn Anzahl distinktiver Wortformen verwendet.

```{r}
syls = novels_words %>% 
  group_by(title) %>% 
  distinct(word, .keep_all = T) %>%
  add_count(word) %>% 
  drop_na() %>% 
  select(title, word, syllables) %>% 
  pivot_wider(names_from = title, values_from = syllables)

t.test(syls$prozess, syls$tom) # significant

```

Wenn die Wiederholung von Wortformen berücksichtigt wird, bestätigt der t-Test ebenfalls einen signifikanten Unterschied zwischen den beiden Texten. Die durchschnittliche Anzahl der Wortsilben ist niedriger, da kürzere Wortformen (solche von Konjunktionen, Präpositionen, Artikeln und anderen Funktionswörtern) häufig vorkommen.

Schnelle Form des t-Tests:

```{r}
t.test(syllables ~ title, data = novels_words)

```

Dasselbe Ergebnis, aber aufwendiger zu programmieren, um den Datensatz in die entsprechende Form zu bringen:

```{r}
prozess_syl <- novels_words %>% 
  filter(title == "prozess") %>% 
  select(syllables) %>% 
  rename(prozess = syllables)
tom_syl <- novels_words %>% 
  filter(title == "tom") %>% 
  select(syllables) %>% 
  rename(prozess = syllables)
  
t.test(prozess_syl, tom_syl) # significant

```

Der nächste t-Test bestätigt ebenfalls, dass "Der Prozess" im Durchschnitt längere Wörter aufweist (8,79 Buchstaben pro Wort gegenüber 8.36 Buchstaben pro Wort in "Tom Sawyer".) Berücksichtigt wurden distinkte Wortformen (keine wiederholten Wortformen).

```{r}
lets = novels_words %>% 
  group_by(title) %>% 
  distinct(word, .keep_all = T) %>%
  add_count(word) %>% 
  drop_na() %>% 
  select(title, word, letters) %>% 
  pivot_wider(names_from = title, values_from = letters)

t.test(lets$prozess, lets$tom) # significant

```

Wenn die Wiederholung von Wortformen berücksichtigt wird, bestätigt der t-Test wiederum einen signifikanten Unterschied zwischen den beiden Texten. Die durchschnittliche Anzahl der Buchstaben pro Wort ist niedriger, da kürzere Wortformen (solche von Konjunktionen, Präpositionen, Artikeln und anderen Funktionswörtern) häufig vorkommen.

Schnelle Form des t-Tests:

```{r}
t.test(letters ~ title, data = novels_words)

```

Dasselbe Ergebnis, aber aufwendiger zu programmieren, um den Datensatz in die entsprechende Form zu bringen:

```{r}
prozess_let <- novels_words %>% 
  filter(title == "prozess") %>% 
  select(letters) %>% 
  rename(prozess = letters)
tom_let <- novels_words %>% 
  filter(title == "tom") %>% 
  select(letters) %>% 
  rename(prozess = letters)
  
t.test(prozess_let, tom_let) # significant

```


## Lineare Regression

Hat man mehr als zwei Stichproben zu vergleichen, kann man eine lineare Regression durchführen, die auch das Testen von mehreren Einflussgrößen (Prädiktoren) erlaubt. 

Hier folgt eine Demonstration anhand des bereits gehabten Datensatzes mit zwei Stichproben (Romanen).
Die Ordinate im Koordinatensystem (Intercept, also der y-Abschnitt mit x = 0) ist bei zwei Stichproben gleich dem Mittelwert der ersten Stichprobe (title = "prozess"), d.h. 1,613350. Der geschätzte Mittelwert (Estimate) der zweiten Stichprobe (title = "tom") ist um den Wert 0,052042 niedriger, d.h. 1,613350 - 0,052042 = 1,561308 (Dezimalkommas statt Dezimalpunkte!).

Der R-Quadrat-Wert (R-squared) ist allerdings sehr klein, d.h. dass der Prädiktor "title" (Roman) nur einen Bruchteil der festgestellten Mittelwertvarianz (Veränderungen der Mittelwerte) zu erklären vermag. Möglicherweise gibt es andere Prädiktoren, die die Mittelwertvarianz besser erklären. 

```{r}
m <- lm(syllables ~ title, data = novels_words)
summary(m)
anova(m)

```

Graphische Darstellung: der Mittelwertunterschied ist gering (nur 0,05 Silben), aber aufgrund der großen Stichproben statistisch signifikant. Der Faktor "title" erklärt nur einen verschwinded kleinen Bruchteil der Mittelwertunterschiede.

```{r}
library(effects)
allEffects(m)
plot(allEffects(m))

```

Ergebnisse in Tabellenform:

```{r}
summary(lm(syllables ~ title, data = novels_words)) %>% tidy()

```

Boxplot mit Jitterplot anhand des vollen Datensatzes: der Mittelwert ist hier der Median *median()* (d.h. ein Wert, der genau in der Mitte jeder Stichprobe liegt), das arithmetische Mittel / der Durchschnitt wird hier mit einem roten Quadrat symbolisiert. Der Median liegt in beiden Stichproben beim Wert 1, also weit unter dem jeweiligen Durchschnittswert. Dies zeigt, dass die Wortlängen nicht normalverteilt sind. Der Jitterplot veranschaulicht, dass der "Prozess" über mehr Wortformen mit 6, 7 oder 8 Silben verfügt.

```{r}
novels_words %>% 
  group_by(title) %>% 
  ggplot(aes(title, syllables, fill = title, group = title)) +
  geom_jitter(width = 0.4, alpha = 0.5, color = "gray70") +
  geom_boxplot(notch = FALSE, width = 0.8) +
  stat_summary(fun.y="mean", color = "red", shape = 15)+
  expand_limits(y = -1) +
  scale_y_continuous(breaks = seq(-1, 8, 1)) +
  theme(legend.position = "none") +
  labs(y = "Mittlere Wortlänge (in Silben)", x = "Roman")

```

Boxplot anhand der zusammengefassten Daten (Durchschnitt, Standardabweichung):

```{r}
df = novels_words %>% 
  group_by(title) %>% 
  summarise(Avg_Silben = mean(syllables, na.rm = TRUE),
            Stdev_Silben = sd(syllables, na.rm = TRUE),
            Avg_Buchstaben = mean(letters, na.rm = TRUE),
            Stdev_Buchstaben = sd(letters, na.rm = TRUE))

df %>% ggplot(aes(title, Avg_Silben, fill = title, group = title)) +
  geom_pointrange(aes(ymin = Avg_Silben - Stdev_Silben, ymax = Avg_Silben + Stdev_Silben),
               stat="identity") +
  theme(legend.position = "none") +
  labs(y = "Mittlere Wortlänge (in Silben)")

df %>% ggplot(aes(title, fill = title, group = title)) +
  geom_boxplot(aes(lower = Avg_Silben - Stdev_Silben, upper = Avg_Silben + Stdev_Silben,
                   middle = Avg_Silben,
                   ymin = Avg_Silben - 3*Stdev_Silben, ymax = Avg_Silben + 3*Stdev_Silben),
               stat="identity") +
  theme(legend.position = "none") +
  labs(y = "Mittlere Wortlänge (in Silben)")

```

# 10. Quanteda-Funktionen

Eine alternative Berechnung der Anzahl der Buchstaben pro Wort mit *quanteda* (ohne t-Test). 

Die Durchschnittswerte, die uns quanteda liefert, sind etwas höher als die tidyverse-Werte. Aber auch hier ist der Mittelwert für den "Prozess" höher als für "Tom Sawyer".

```{r}
library(quanteda)
library(quanteda.textstats)
corp = corpus(novels_txt)
stats = textstat_summary(corp)
stats

stats %>% 
  group_by(document) %>% 
  transmute(buchstaben = (chars-puncts)/tokens)

```

Die Durchschnittswerte unterscheiden sich in den Berechnungen (tidyverse vs. quanteda), was mit der verschiedenen Art der Tokenisierung und der Aussonderung von nicht relevanten Tokens und leeren Datenzeilen (NA) zu tun hat. 


# 11. Konsonantenverbindungen

Welche Konsonantenverbindungen (Buchstabenverbindungen) kommen häufiger vor in den Texten?
Wir zerlegen die Texte im Korpus in kleinere Einheiten (mittels *tokens*()), aber dieses Mal in alphanumerische Zeichen (Buchstaben). 
Anschließend wenden wir *char_ngrams()*-Funktion an, mit der man Verknüpfungen von Zeichen feststellen kann.

```{r}
tok_ch = tokens(corp, what = "character", remove_punct = TRUE, remove_symbols = T, remove_numbers = T, remove_url = T, remove_separators = T)

ngrams_ch = char_ngrams(as.character(tok_ch), n = c(2,3,4), concatenator = "")

```

Wir wandeln die ngram-Liste in einen Datensatz um (mittels *tibble()*), was das Zählen mit einer *tidyverse*-Funktion ermöglicht.

```{r}
ngrams_char = ngrams_ch %>% 
  as_tibble() %>% 
  rename(cluster = value)

ngrams_char %>% 
  count(cluster, sort = TRUE)

```


to be continued ...


# 12. Datensatz-Variante


```{r}
novels_words_char <- novels %>%
  unnest_tokens(word, text, token = "words", to_lower = TRUE, drop = T) %>% 
  mutate(Silben = nsyllable::nsyllable(as.character(word), language = "en")) %>% 
  unnest_tokens(character, word, token = "characters", to_lower = TRUE, drop = F) %>% 
  mutate(buchstabe = ifelse(str_detect(character, vokale), "Vokal", "Konsonant"))
  
head(novels_words_char)

```

