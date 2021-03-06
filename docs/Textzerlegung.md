---
title: "R and Py"
author: "Teodor Petrič"
date: "29 7 2021"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# 0. Packages

```{r}
library(tidyverse)
library(tidytext)

```

# 1. Text öffnen

In der R-Umgebung haben wir mehrere Möglichkeiten, Textdateien zu öffnen. Hier verwenden wir *read_lines()*, ein Programm, das mit dem Programmbündel *tidyverse* geladen wird.

Bei langen Texten vermeiden wir es, den ganzen Text in den Arbeitsspeicher (RAM) zu laden, weil das lange dauern kann. Stattdessen verwenden wir Befehle wie *substr()* oder die tidyverse-Funktion *str_sub()*, um uns einen Teil des Texte anzuschauen.

```{r}
novels_r = read_lines("data/books/tom.txt")

substr(novels_r, start = 1, stop = 300)
str_sub(novels_r, start = 1, end = 300)

```


# 2. Zerlegung des Textes

## Tabelle

Um Texteinheiten wie z.B. Wörter, Buchstaben oder Sätze / Äußerungen zählen zu können, müssen wir den Text zuerst in kleinere Teile zerlegen, in der Fachsprache als Tokenisierung bekannt (tokens extrahieren).

Für die Tokenisierung von Zeichenfolgen (Texten) gibt es in der R-Sprache viele Programme (z.B. *quanteda*, *tidytext*) und verschiedene Möglichkeiten (mit ihren Vor- und Nachteilen). Hier verwenden wir das zuletzt genannte Programm und seine Funktion *unnest_tokens()*.

Im ersten Schritt wandeln wir die Textdatei in einen Datensatz um, so dass wir mit den gut verständlichen *tidyverse*-Funktionen arbeiten können. Das machen wir mit der Funktion *as_tibble()*, die in diesem Fall eine Tabelle mit einer einzigen Spalte erzeugt. Der Default-Name der Spalte "value" wird mit *rename()* umbenannt. Der neue (bessere) Spaltenname ist "text", was wir mit *colnames()* überprüfen können. Wir geben dieser Tabelle einen neuen Namen ("novels_df").

```{r}
novels_df = as_tibble(novels_r) %>% 
  rename(text = value)
colnames(novels_df)
```

## Äußerungen

Im zweiten Schritt verwenden wir die Tabelle "novels_df" als Ausgangspunkt für die Tokenisierung. Wir zerlegen die Zeichenfolge in der Spalte "text" in Sätze (genau genommen: Äußerungen), und zwar mit Hilfe der Funktion *unnest_tokens()* des Programms *tidytext*. Wir geben dieser Tabelle einen neuen Namen, und zwar "novels_sents". 

Die Funktion unnest_tokens verlangt die folgende Reihenfolge:
zuerst muss der Datensatz angegeben werden (hier: "novels_df"), dann der Name der Tabellenspalte, die in kleinere Einheiten zerlegt werden soll (hier: "text"), gefolgt von der Angabe, in welche Einheit wir die Zeichenfolge umformen wollen (hier: "sentences").

Die neue Tabelle enthält nur eine Spalte (nur die Äußerungen), da wir die Option *drop = TRUE* beibehalten (denn sonst würde die neue Tabelle eine weitere Spalte mit dem ganzen Text enthalten, und zwar in jeder Tabellenzeile - sehr belastend für den Arbeitsspeicher!). 

Außerdem verhindern wir mit *to_lower = FALSE*, dass alle Wörter in der Spalte klein geschrieben werden. Die im Deutschen übliche Groß- und Kleinschreibung von Wörtern soll in dieser Spalte beibehalten werden.

Zuletzt entfernen wir noch die erste Zeile in der Tabelle, da sie nicht zum Text gehört. Das machen wir mit *novels_sents[-1,]*: dem Namen der Tabelle folgen eckige Klammern; die Zahl *-1* vor dem *Komma* bezieht sich auf die erste Tabellenzeile; das Minuszeichen vor der Zahl besagt, dass diese Zeile entfernt werden soll; nach dem Komma steht nichts, d.h. alle Spalten in der Tabelle bleiben unverändert.

Zur Identifizierung der Reihenfolge der Äußerungen fügen wir der Tabelle noch eine Spalte hinzu: mit *mutate()* erzeugen wir die Spalte "sentence_id", und zwar indem wir die einzelnen Zeilenzahlen *row_number()* mit Hilfe der Anzahl der Tabellenzeilen *length()* festlegen.

```{r}
novels_sents = novels_df %>% 
  unnest_tokens(sentence, text, token = "sentences", drop = TRUE, to_lower = FALSE)

novels_sents = novels_sents[-1,]

novels_sents = novels_sents %>% 
  mutate(sentence_id = row_number(1:length(novels_sents$sentence)))

head(novels_sents)
tail(novels_sents)

```

## Wörter

Unser nächstes Ziel ist die Zerlegung der Äußerungen in kleinere Einheiten: Wörter. Das können wir auf ähnliche Weise bewerkstelligen wie im vorherigen Schritt.

Ausgangspunkt ist nun die Tabelle "novels_sents". Im *unnest_tokens()*-Befehl geben wir den Namen der hier gewünschten Einheit an ("word"), dann den Namen der Tabellenspalte mit den Äußerungen ("sentence") und die gewünschte Einheit, in die wir die Äußerungen umformen möchten ("words").

Außerdem wollen wir die Tabellenspalte "sentence" beibehalten, weshalb wir *drop = FALSE* auswählen. In der neuen Tabellenspalte "word" sollen alle Wörter klein geschrieben werden, was wir mit *to_lower = TRUE* erreichen.

Wir fügen der Tabelle (ähnlich wie im Fall der "sentence_id") auch eine weitere Spalte hinzu, der wir die ursprüngliche Reihenfolge der Wörter entnehmen können: "word_id".

```{r}
novels_words = novels_sents %>% 
  unnest_tokens(word, sentence, token = "words", drop = FALSE, to_lower = TRUE)

novels_words = novels_words %>% 
  mutate(word_id = row_number(1:length(novels_words$word)))

```

Bei der Durchsicht des Textes oder auch der Tabelle fallen ungewohnte Wortformen mit einem Unterstrich "-" auf. Wir entfernen den Unterstrich am Anfang und Ende der Wortformen.

```{r}
novels_words = novels_words %>% 
  mutate(word = str_replace_all(word, "_", ""))

head(novels_words)

```


## Buchstaben

Wenn wir auch Buchstaben zählen wollen, können wir die Wörter auf ähnliche Weise zerlegen und eine "char_id" (ursprüngliche Reihenfolge der Buchstaben) hinzufügen.

```{r}
novels_ch = novels_words %>% 
  unnest_tokens(char, word, token = "characters", drop = FALSE, to_lower = TRUE)

novels_ch = novels_ch %>% 
  mutate(char_id = row_number(1:length(novels_ch$char)))

head(novels_ch)

```

## Ziffern umwandeln

Unter den tokens (Vorkommnisse von Wortformen) sind auch Ziffern. Da sie im Text nicht wie Wörter geschrieben werden, zählen wir sie gewöhnlich nicht mit.

Wir könnten die Ziffern aus der Tabelle entfernen oder als unbestimmte Ziffernfolge (z.B. "0000") zusammenfassen.

Entfernen ist die einfachere Möglichkeit und oft auch die sinnvollere, wenn man davon ausgeht, dass die Zahlen keine wichtige Information zum Gesamtext beitragen. Wir erhalten 29 leere Zeilen.

```{r}
novels_ch %>% 
  mutate(word = str_remove_all(word, "[^a-zA-Z]")) %>% 
  count(word)
```

Ersetzen ist die andere Möglichkeit. 

Dazu verwenden wir einen *regulären Ausdruck*, nämlich *"[\\d]"*, in dem das "d" sich auf "digit" (Ziffer) bezieht. Die beiden Backslash-Zeichen vor dem "d" sagen dem Programm, dass nicht nach dem Buchstaben "d" gesucht wird, sondern nach Ziffern (digits). 

Als Ergebnis erhalten wir ein-, zwei- und vierstellige Zahlen in der Wortspalte. Die vierstelligen Zahlen stellen wahrscheinlich Jahreszahlen dar.

```{r}
novels_ch %>% 
  mutate(word = str_replace_all(word, "[\\d]", "0")) %>% 
  count(word)
```

Wir wählen die letzte Variante und speichern die Tabelle: eine oder mehrere Ziffern "[\\d]+" werden mit vier Nullen "0000" ersetzt. Diese "0000" kann als Wortform mitgezćhlt werden (oder nicht).

```{r}
novels_ch = novels_ch %>% 
  mutate(word = str_replace(word, "[\\d]+", "0000"))
```


# 3. Tabelle speichern

Diese Tabelle speichern wir als Datei, falls wir ein anderes Mal mit ihr arbeiten möchten. Wir speichern die Tabelle als Excel-Datei (Programm: *writexl*) und als Tabelle im Textformat (Endung: "csv", comma-separated-variables).

Excel hat einen Nachteil: falls die Zeilen sehr lang sind, werden sie nicht vollständig gespeichert, sondern abgekürzt. Das Dateiformat "csv" und andere Textformate sind daher besser. Außerdem kann man "csv"-Dateien, da sie nur unformatierten Text enthalten, mit jedem Programm öffnen und lesen, Excel-Dateien dagegen nicht.

```{r}
write_csv(novels_ch, "data/tom_sawyer_tabelle.csv")

# install.packages("writexl")
library(writexl)
write_xlsx(novels_ch, "data/tom_sawyer_tabelle.xlsx")

```


# 4. Tabelle öffnen

Falls wir die Arbeit an einem anderen Tag fortsetzen, können wir die gespeicherte Tabelle folgendermaßen öffnen und brauchen nicht noch einmal alle oben durchgeführten Schritte durchzuführen:

```{r}
# install.packages("readxl")
library(readxl)
novels_ch = read_xlsx("data/tom_sawyer_tabelle.xlsx")

# oder:
novels_ch = read_csv("data/tom_sawyer_tabelle.csv")

```


# 5. Zählen

Als Ausgangspunkt für die Auszählung von Äußerungen, Wörtern und Buchstaben verwenden wir die zuletzt erstellte Tabelle "novels_ch".

Zum Zählen einer Kategorie eignet sich die *tidyverse*-Funktion *count()*. 

Wie viele Äußerungen hat das Programm identifiziert? 

Hier müssen wir berücksichtigen, dass jede Äußerung in mehreren Zeilen wiederholt wird, da wir die Äußerungen auch in Wörter und Buchstaben zerlegt haben. Die Funktion *distinct()* berücksichtigt das.

```{r}
novels_ch %>% 
  distinct(sentence) %>% 
  count(sentence)

```

Als Antwort auf diese Abfrage erhalten wir 4647 Zeilen, d.h. dass 4647 Äußerungen ("number_sents") unterschieden wurden. Außerdem entsteht beim Zählen eine neue Spalte, und zwar mit dem Namen "n". Die Zahl ist in allen Tabellenzeilen dieselbe, nämlich "1". Dies zeigt uns, dass jede Äußerung nur einmal gezählt wurde (also distinkt / unterschiedlich ist), so wie wir es ja verlangt haben.

```{r}
novels_ch %>% 
  distinct(sentence) %>% 
  count(sentence) %>% 
  summarise(number_sents = sum(n))

```

Wenn wir distinct() weglassen, erhalten wir das folgende Ergebnis: Die Tabellenspalte "n" enthält nun unterschiedliche Zahlen, die sich auf die Anzahl der Buchstaben in der Spalte "sentence" bezieht, denn wir haben die Äußerungen vorher nicht nur in Wörter (Spalte "word") sondern auch in Buchstaben (Spalte "char") zerlegt.

```{r}
novels_ch %>% 
  count(sentence)

```

Auf diese Weise könnten wir die Anzahl der Buchstaben insgesamt und die Anzahl der Buchstaben pro Äußerung berechnen.


## Buchstaben

Wie lang ist der Text, gemessen in "characters"? 
Fast 333 Tausend alphanumerische Zeichen. 

Wie viele alphanumerische Zeichen (Buchstaben und Ziffern) kommen durchschnittlich pro Äußerung vor?
Beinahe 72 Zeichen. Die Standardabweichung von diesem Mittelwert ist ziemlich groß: 71,5 +/- 61,9 Zeichen. In diesem Text kommen sehr kurze Äußerungen vor, aber auch deutlich längere.

```{r}
(char_summary = novels_ch %>% 
  count(sentence) %>% 
  summarise(char_sum = sum(n),
            char_avg = mean(n, na.rm = TRUE),
            char_sd = sd(n, na.rm = TRUE))
)

```

Kurze Äußerungen (hier: mit wenigen Buchstaben) kommen sehr häufig vor, sehr lange (hier: mit vielen Buchstaben) dagegen selten. 

```{r}
novels_ch %>% 
  count(sentence) %>% 
  ggplot(aes(n)) +
  geom_density(fill = "magenta", alpha = 0.7) +
  labs(x = "Anzahl der Buchstaben", y = "Dichte")

```

Folgt die Äußerungslänge (in Buchstaben gemessen) einer Zipf-Verteilung?

```{r}
alpha = 1
novels_ch %>% 
  count(sentence, sort = TRUE) %>% # Sortieren nicht vergessen!
  mutate(rank = row_number(),
         zipfs_freq = ifelse(rank == 1, n, dplyr::first(n) / rank^alpha)) %>% 
  ggplot(aes(rank, n)) +
  geom_point() +
  labs(y = "Anzahl der Buchstaben", x = "Rangfolge")

```

Im Vergleich dazu unten: so sähe die entsprechende Zipf-Verteilung (Power-Law-Distribution) aus, die für ausreichend lange Texte gültig ist. 

In einer Zipfverteilung käme die zweithäufigste Äußerungslänge etwa nur noch halb so häufig vor wie die häufigste Äußerungslänge, die dritthäufigste nur noch ein Drittel der ersthäufigsten, die vierthäufigste nur noch ein Viertel der ersthäufigsten usw.

```{r}
alpha = 1
novels_ch %>% 
  count(sentence, sort = TRUE) %>% # Sortieren nicht vergessen!
  # mutate(rank = row_number(),
  mutate(rank = rank(row_number(), ties.method = "average"),
         zipfs_freq = ifelse(rank == 1, n, dplyr::first(n) / rank^alpha)) %>% 
  ggplot(aes(rank, zipfs_freq)) +
  geom_point() +
  labs(y = "Anzahl der Buchstaben", x = "Rangfolge")

```

Wenn man die beiden Variablen (Rang und Häufigkeit) in einer Zipfverteilung logarithmiert, ist das Ergebnis eine Gerade. Die Äußerungslänge (hier: Buchstabenanzahl) im Roman "Tom Sawyer" scheint davon abzuweichen. Die mittellangen Äußerungen kommen häufiger vor, als nach der Zipfverteilung erwartet wird.

```{r}
library(scales)

alpha = 1
novels_ch %>% 
  count(sentence, sort = TRUE) %>% # sortieren !
  mutate(rank = rank(row_number(), ties.method = "first"),
         zipfs_freq = ifelse(rank == 1, 
                             n, 
                             dplyr::first(n) / rank^alpha)) %>% 
  ggplot(aes((n), (rank), color = "Roman")) +
  geom_point() +
  geom_point(aes(((zipfs_freq)), ((rank)), color = "theoretisch")) +
  labs(x = "Anzahl der Buchstaben", y = "Rangfolge", color = "Verteilung") +
  scale_x_log10() +
  scale_y_log10()

```

Welche Buchstaben kommen im Text häufiger / seltener vor?
Unter den auf Vokale bezogenen Buchstaben ist das "e" am häufigsten, unter den auf Konsonanten bezogenen das "n".

```{r}
alpha = 1
novels_ch %>% 
  filter(str_detect(char, "[:alpha:]")) %>% 
  count(char, sort = T)

```


```{r}
novels_ch %>% 
  filter(str_detect(char, "[:alpha:]")) %>% 
  count(char, sort = T) %>% 
  mutate(char = fct_reorder(char, n)) %>% 
  ggplot(aes(n, char, fill = char)) +
  geom_col() +
  theme(legend.position = "none")

```


```{r}
novels_ch %>% 
  filter(str_detect(char, "[:alpha:]")) %>% 
  count(char, sort = T) %>% # sortieren !
  mutate(rank = rank(row_number(), ties.method = "first"),
         zipfs_freq = ifelse(rank == 1, 
                             n, 
                             dplyr::first(n) / rank^alpha)) %>% 
  ggplot(aes((n), (rank), color = "Roman")) +
  geom_point() +
  geom_point(aes(((zipfs_freq)), ((rank)), color = "theoretisch")) +
  labs(x = "Anzahl der Buchstaben", y = "Rangfolge", color = "Verteilung") +
  scale_x_log10() +
  scale_y_log10()

```


## Worthäufigkeiten

Da wir es gewohnt sind, mit Wörtern umzugehen, machen wir lieber mit Wörtern weiter. 

Wie viele Wortformen wurden vom Programm unterschieden? 
Die folgende Wortauszählung zeigt, dass das Programm 9639 types (Wortformen) unterschieden hat, denn die Tabelle hat so viele Zeilen ("0000" sind die oben umgewandelten Ziffern). 

Funktionswörter (z.B. und, die, nicht, sie, der, sich, er, ich, aber, ...) kommen wie in allen Texten am häufigsten vor. Für die Inhaltsanalyse spielen sie kaum oder gar keine Rolle. Daher werden sie oft entfernt.

Zu den Top-Ten gehört verständlicherweise auch der Name "Tom", da die Hauptperson im Roman fortwährend angesprochen oder erwähnt wird (die Gebrauchsfrequenz oder Anzahl der tokens n = 738).

```{r}
novels_ch %>% 
  distinct(word_id, .keep_all = TRUE) %>% 
  count(word, sort = TRUE)
```

Folgen die Worthäufigkeiten einer Zipfverteilung (Power-Law-Distribution)?
In der folgenden Tabelle sind folgende Größen zu sehen:
- die Gebrauchshäufigkeit oder Tokenfrequenz eines Wortes im Text (n)
- die Rangfolge des Wortes (rank),
- die berechnete Konstante (k = frequenz * rang),
- die berechnete theoretische Tokenfrequenz eines Wortes (zips_freq).

```{r}
novels_ch %>% 
  distinct(word_id, .keep_all = TRUE) %>% 
  count(word, sort = TRUE) %>% # sortieren !!!
  mutate(rank = rank(row_number(), ties.method = "average"),
         k = n * rank,
         zipfs_freq = ifelse(rank == 1, 
                             n, 
                             dplyr::first(n) / rank^alpha),
         zipfs_freq_k = ifelse(rank == 1, 
                             k, 
                             dplyr::first(k) / rank^alpha))

```

Die häufigeren Wörter scheinen in "Tom Sawyer" häufiger vorzukommen als nach der Zipfverteilung erwartet wird. Das spricht für einen simpleren Wortschatz, einen eher umgangssprachlich formulierten Text.

```{r}
novels_ch %>% 
  distinct(word_id, .keep_all = TRUE) %>% 
  count(word, sort = TRUE) %>% # sortieren !!!
  mutate(rank = rank(row_number(), ties.method = "average"),
         zipfs_freq = ifelse(rank == 1, 
                             n, 
                             dplyr::first(n) / rank^alpha)) %>% 
  ggplot(aes((n), (rank), color = "Roman")) +
  geom_point() +
  geom_point(aes(((zipfs_freq)), ((rank)), color = "theoretisch")) +
  labs(x = "Worthäufigkeit", y = "Rangfolge", color = "Verteilung") +
  scale_x_log10() +
  scale_y_log10()

```


## Wortschatzdichte

Die *lexikalische Diversität* oder *Wortschatzdichte*, gemessen anhand des type-token-Verhältnisses (*type-token-ratio*, ttr) beträgt 0,14 Types pro Token. Ohne mit einem anderen Text vergleichen zu können, sagt uns dieser Wert nicht viel. Dieser Wert ist ansonsnten auch von der Länge eines Textes abhängig: je länger der Text, desto kleiner wird dieser Wert.

```{r}
novels_ch %>% 
  distinct(word_id, .keep_all = TRUE) %>% 
  count(word, sort = TRUE) %>% 
  summarise(types = length(word),
            tokens = sum(n),
            ttr = length(word)/sum(n))

```

Auch die lexikalische Diversität (Wortschatzdichte) ist relativ gering, da die Anzahl der verschiedenen Wortformen (types) im Vergleich zu ihrer Gebrauchsfrequenz (tokens) verhältnismäßig klein ist. Dies spricht wiederum für die These, dass der Roman einen recht einfachen Wortschatz aufweist, was einem eher umgangssprachlichen Stil entspricht.


## Äußerungslänge

Wie viele Wörter kommen durchschnittlich in einer Äußerung vor?
Da wir bei der Auszählung auch einige der als "0000" kodierten Ziffern berücksichtigen, beträgt die durchschnittliche Länge der Äußerungen im Text 14,44 Wortformen (tokens), die Standardabweichung vom Mittelwert ist fast so groß wie der Mittelwert: 14,44 +/- 11,95 Wortformen.

```{r}
novels_ch %>% 
  distinct(word_id, .keep_all = T) %>%
  count(sentence) %>% 
  summarise(leng_sents = mean(n),
            sd_sents = sd(n))
  
```

Die Häufigkeitsverteilung der Äußerungslänge im Roman:

```{r}
novels_ch %>% 
  distinct(word_id, .keep_all = TRUE) %>% 
  count(sentence, sort = TRUE) %>% # sortieren !!!
  mutate(rank = as.integer(length(sentence) - rank(n, ties.method = "average") + 1),
         rank2 = rank(row_number(), ties.method = "average"),
         zipfs_freq = ifelse(rank == 1, 
                             n, 
                             dplyr::first(n) / rank^alpha)) %>% 
  ggplot(aes(n)) +
  geom_histogram(fill = "darkgreen", alpha = 0.7, binwidth = 2) +
  labs(x = "Anzahl der Wörter", y = "Anzahl der Äußerungen")

```

Logarithmiert:

```{r}
novels_ch %>% 
  distinct(word_id, .keep_all = TRUE) %>% 
  count(sentence, sort = TRUE) %>% # sortieren !!!
  mutate(rank = as.integer(length(sentence) - rank(n, ties.method = "average") + 1),
         rank2 = rank(row_number(), ties.method = "average"),
         zipfs_freq = ifelse(rank == 1, 
                             n, 
                             dplyr::first(n) / rank^alpha)) %>% 
  ggplot(aes(n)) +
  geom_histogram(fill = "darkgreen", alpha = 0.7, binwidth = 0.05) +
  scale_x_log10() +
  labs(x = "Anzahl der Wörter", y = "Anzahl der Äußerungen")


```


Tabelle mit Anzahl der Wörter pro Äußerung (n), Rangfolge (rank) und die theoretische Frequenz gemäß Zipfverteilung (zipfs_freq). 

```{r}
novels_ch %>% 
  distinct(word_id, .keep_all = TRUE) %>% 
  count(sentence, sort = TRUE) %>% # sortieren !!!
  mutate(rank = as.integer(length(sentence) - rank(n, ties.method = "average") + 1),
         rank2 = rank(row_number(), ties.method = "average"),
         zipfs_freq = ifelse(rank == 1, 
                             n, 
                             dplyr::first(n) / rank^alpha)) %>% 
  arrange(rank)

```

Die Verteilung der Äußerungslängen unterscheidet sich von der Zipfverteilung.

```{r}
alpha = 1
novels_ch %>% 
  distinct(word_id, .keep_all = TRUE) %>% 
  count(sentence, sort = F) %>% # sortieren !!!
  mutate(rank = as.integer(length(sentence) - rank(n, ties.method = "average") + 1),
         zipfs_freq = ifelse(rank == 1, 
                             n, 
                             dplyr::first(n) / rank^alpha)) %>% 
  ggplot(aes((n), (rank), color = "Roman")) +
  geom_point() +
  geom_point(aes(((zipfs_freq)), ((rank)), color = "theoretisch")) +
  geom_jitter() +
  labs(x = "WAnzahl der Wörter", y = "Rangfolge", color = "Verteilung") +
  scale_x_log10() +
  scale_y_log10()

```


## Vergleich mit quanteda

```{r}
library(quanteda)
library(quanteda.textstats)

```

Die Zahlenwerte, die wir mit dem Program *quanteda* (ohne genauere Bearbeitung) erhalten, sind höher. Das liegt daran, dass Interpunktionszeichen, Symbole und Ziffern noch nicht herausgefiltert sind.

```{r}
# ohne Filterung
corp = corpus(novels_r)
textstat_summary(corp)

```
Gefiltert sind die Werte mit den Werten vergleichbar, die wir mit den tidyverse-Funktionen berechnet haben.

```{r}

# gefiltert
tok = tokens(corp, remove_punct = T, remove_symbols = T, remove_numbers = T, remove_url = T, remove_separators = T)
textstat_summary(tok)

```

Zahlenwerte für die einzelnen Äußerungen:

```{r}
# ungefiltert
corps = corpus_reshape(corp, to = "sentences")
textstat_summary(corps)

# gefiltert
toks = tokens(corps, remove_punct = T, remove_symbols = T, remove_numbers = T, remove_url = T, remove_separators = T)
textstat_summary(toks)

```

Die von quanteda berechnete durchschnittliche Äußerungslänge und ihre Standardabweichung weisen ähnliche Werte auf (Mittelwert = 14,41, Standardabweichung = 11,998) wie die zuvor berechneten mit den tidyverse-Funktionen.

```{r}
textstat_summary(toks) %>% 
  summarise(len_sents_q = mean(tokens),
            len_sents_q_sd = sd(tokens))

```


Lexikalische Diversität (Wortschatzdichte) des gesamten Texts liegt bei 0,1467 (ähnlich wie mit den tidyverse-Funktionen).

```{r}
textstat_lexdiv(tok)

```

Wortschatzdichte in einzelnen Äußerungen:

```{r}
textstat_lexdiv(toks)

```


```{r}
corp_dfm <- dfm(tok, verbose = FALSE)

```


```{r}
term_count <- tidy(corp_dfm) %>%
  group_by(document) %>%
  arrange(desc(count)) # sortieren !!!

term_count

```


```{r}
term_count_rank <- tidy(corp_dfm) %>%
  group_by(document) %>%
  arrange(desc(count)) %>%
  mutate(rank = row_number(),
         total = sum(count),
         `term frequency` = count / total)

term_count_rank

```


```{r}
term_count_rank %>%
  ggplot(aes(rank, `term frequency`, color = document)) +
  geom_line(alpha = 0.8, show.legend = FALSE) + 
  scale_x_log10() +
  scale_y_log10()

```

```{r}
alpha = 1
term_count_rank %>%
    mutate(rank = as.integer(rank(length(term) - `term frequency` + 1, ties.method = "average")), 
           zipfs_freq = ifelse(rank == 1, `term frequency`, 
                               dplyr::first(`term frequency`) / rank^alpha)) %>% 
  ggplot(aes(rank, `term frequency`, color = document)) +
  geom_line(alpha = 0.8, show.legend = FALSE) + 
  geom_point(aes((rank), (zipfs_freq), color = "theoretisch")) +
  geom_jitter() +
  labs(y = "Termfrequenz", x = "Rangfolge", color = "Verteilung") +
  scale_x_log10() +
  scale_y_log10()

```



## Vergleich mit Voyant Tools

Ein empfehlenwertes Werkzeug, schnell und einfach, um einen Überblick und verständliche graphische Darstellungen zu erhalten - solange man es nur mit einem Text oder wenigen zu tun hat.

Die deutsche Übersetzung des Tools ist stellenweise ungenau: z.B. wird in der deutschen Übersetzung nicht zwischen types (einzigartigen Wortformen / unique word forms) und tokens (total words) unterschieden. 
https://voyant-tools.org/

Falsch: Dieser Korpus hat 1 Dokument mit 67,137 einzigartige Wortformen. 
Richtig ist: Dieses Korpus hat 67,137 tokens (Vorkommnisse von Wortformen) und 9828 types (unique word forms).
Wortschatzdichte: 0.146
Durchschnittliche Wörter pro Satz: 15.5 (höher als mit tidyverse und quanteda berechnet)
Die häufigsten Begriffe im Korpustom (739); s (296); huck (237); na (175); joe (150)

This corpus has 1 document with 67,137 total words and 9,828 unique word forms. Created about 8 hours ago.
Vocabulary Density: 0.146
Average Words Per Sentence: 15.5
Most frequent words in the corpus: tom (739); s (296); huck (237); na (175); joe (150)

