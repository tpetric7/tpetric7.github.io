---
title: "Branje in shranjevanje"
author: "Teodor Petrič"
date: "2021-6-9"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# 0. Programi

```{r}
library(readtext)
library(quanteda)
library(tidyverse)
library(readxl)
library(writexl)

```

Načinov za odpiranje in shranjevanje datotek je veliko. Tule bom pokazal nekaj preprostih:


# 1. Odpiranje enega besedila

Funkcija *read_lines()*: odpremo besedilo v izbrani mapi in ga shranimo v spremenljivki (npr. "besedilo").

Odpiranje besedila s spletnega naslova (url) je možen.

```{r}
library(tidyverse)
besedilo = read_lines("data/books/tom.txt")

```


# 2. Odpiranje več besedil

Funkcija *readtext()*: če namesto imena datotek navedemo samo zvezdico + pripono datotek (npr. *.txt) v izbrani mapi (npr. "data/books/"), potem bo program odprl vse besedilne datoteke s to pripono in to zbirko shranil v spremenljivki (npr. "besedila"). Program ustvari tabelo odprtih besedil.

readtext() odpira različne besedila z različnimi priponami: txt, csv, docx, pdf, xml, ...

Odpiranje besedila s spletnega naslova (url) je možen.

```{r}
library(readtext)
besedila = readtext("data/books/*.txt", encoding = "UTF-8")
besedila

```


# 3. Odpiranje tabele

Funkcija *read_csv()* ali *read_csv2()* sta le dve izmed številnih funkcij za odpiranje preglednice s pripono "csv". 

Odpiranje besedila s spletnega naslova (url) je možen.

```{r}
library(tidyverse)
tabela = read_csv2("data/plural_Subj_sum.csv")
head(tabela)

```


# 4. Odpiranje Excelove tabele

Funkcija *read_xlsx()* ali *read_excel()* omogoča odpiranje Excelove preglednice s pripono "xlsx". 

```{r}
library(readxl)
excel = read_xlsx("data/S03_Vokalformanten_Diagramme.xlsx", sheet = "A1-4_alle")
head(excel)

```


# 5. Shranjevanje

Privzeto spodnji programi shranjujejo v obliki (codepage) encoding = "UTF-8" / fileEncoding = "UTF-8".

```{r}
library(tidyverse)
# shranjevanje posamičnega besedila
write_lines(besedilo, "moje_besedilo.txt")
# shranjevanje tabele, v kateri je zbirka besedil
write_csv2(besedila, "moja_tabela_z_besedili.csv")
library(writexl)
# shranjevanje preglednice
write_xlsx(tabela, "moja_tabela.xlsx")
# shranjevanje tabele, v kateri je zibrka besedil
write_xlsx(besedila, "moja_tabela_z_besedili.xlsx")

```

