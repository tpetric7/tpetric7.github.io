---
title: "Excel napredno 1. del"
author: "Teodor Petrič"
date: "2021-5-21"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# 0. Programi

```{r}
library(tidyverse)
library(scales)
library(tidymodels)
library(tidytext)
library(readxl)

```


# 1. Podatki

Podatki in posamezne naloge za delo z Excelom so iz seminarja dr. Simone Sternad Zabukovšek in mag. Zdenka Deželaka (Univerza v Mariboru, 21.5.2021).

Primerjamo z Excelom.

R: 
Oba delovna lista iz datoteke "Narocila.xlsx") shranjujemo kot samostojni tabeli z imenoma "orders" in "zaposleni".

```{r}
orders = read_xlsx("data/Narocilo.xlsx", sheet = "Orders")
zaposleni = read_xlsx("data/Narocilo.xlsx", sheet = "Zaposleni")

```

Poglejmo prve podatke:

```{r}
head(orders)
head(zaposleni)

```


# 2. Število podatkov v nizu

R:
Načinov je več.

```{r}
nrow(orders) # vrstice
ncol(orders) # stolpci
dim(orders) # vrstice x stolpci (dimenzije)

```


# 3. Lookup (Excel)

Excel (lookup): 
Na delovnem listu Zaposleni dodajte: 
- V celico P1 napišite besedilo »Vpišite številko ID«, v celici P2 vpišite besedilo »Telefonska številka«, v celico P3 pa »Datum zaposlitve«.
- Nastavite, da se bo na podlagi vpisane ID številke v celici Q1, v celico Q2 izpisala telefonska številka (namig: Lookup).
- Nastavite, da se bo na podlagi vpisane ID številke v celici Q1, v celico Q3 izpisal datum zaposlitve (namig: Lookup).

R:

```{r}
zaposleni %>% 
  select(EmployeeID, HomePhone, HireDate) %>% 
  filter(EmployeeID == 1)

```

# 4. Vlookup, &, Concat

Excel:
Na delovnem listu Orders dodajte:
o Stolpec Priimek, v katerem naj bo izpisan Priimek zaposlenega glede na ID zaposlenega (namig: Vlookup).
o Stolpec Ime, katerem naj bo izpisan Ime zaposlenega glede na ID zaposlenega 
o Stolpec Ime in priimek (združite predhodna dva). Preverite različne možnosti:
• Bliskovita zapolnitev. 
• Formula (=Stolpec1&" "&Stolpec2). 
• Funkcija (CONCAT). 

R: 
Podatkovna niza "orders" in "zaposleni" imata skupen stolpec "EmployeeID".
Ta bo osnova za združevanje obeh podatkovnih nizov.
Nadaljnje iskanje ali filtriranje bo tako enostavno.

```{r}
(zdruzena = orders %>% 
  left_join(zaposleni, by = "EmployeeID", keep = FALSE)
)

```


Novo obliko tabele (gl. spodaj) bi lahko shranil pod novim imenom (npr. "zdruzena_nova").
Prvotna tabela "zdruzena" ostane, kot jo vidite zgoraj.

```{r}
zdruzena %>% 
  unite(EmployeeName, LastName:FirstName, sep = " ")

(zdruzena_nova = zdruzena %>% 
  unite(EmployeeName, c(FirstName, LastName), sep = " ")
)

```

# 5. Transpose

Excel:
Na nov delovni list kopirajte območje A1:M10 iz delovnega lista Zaposleni tako, da zamenjate vrstice s stolpci. 
o Izbrišite prvo vrstico.
o Preimenujte delovni list v Vir.

R:
Transponiranje tabele ni potrebno, ker smo prej že ustvarili združen podatkovni niz. 
Funkcija "t()" (tj. transpose) sicer deluje podobno kot v Excelu.

```{r}
vir = as.data.frame(t(zaposleni))

(vir = vir[-1,] %>% # izbrišemo prvo vrstico
  rownames_to_column(var = "Lastnosti") # nov stolpec
)

```


# 6. Dvojniki, razdružitev

Excel:
Z delovnega lista Orders kopirajte na nov delovni list stolpec Ime in Priimek (kot vrednosti).
o Preimenujte delovni list v Kontakt.
o Odstranite dvojnike iz celotnega stolpca. 
o Razdružite ime in priimek v ločena stolpca.
o V naslednji stolpec v prvo celico napišite Rojstni datum in v stolpcu s pomočjo funkcije vstavite rojstne datume zaposlenih s tabele delovnega lista Vir (namig: Hlookup). Nastavite kratko obliko datuma.
o V naslednji stolpec v prvo celico napišite Telefon in v stolpcu s pomočjo funkcije vstavite še telefonske
številke zaposlenih.

R:

```{r}
(kontakt = zdruzena_nova %>% 
  distinct(EmployeeName, .keep_all = T) %>% 
  separate(EmployeeName, into = c("Ime", "Priimek")) %>% 
  select(Ime, Priimek, Title, BirthDate, HomePhone)
)

```


# 7. Xlookup

Excel:
Postavite se na delovni list Zaposleni.
o V celico S1 napišite besedilo »Vpišite ime«, v celici S2 vpišite besedilo »Telefonska številka«, v celico S3 pa »Naslov«.
o Nastavite, da se bo na podlagi vpisanega imena v celici T1, v celico T2 izpisala telefonska številka (namig: Xlookup).
o Nastavite, da se bo na podlagi vpisanega imena v celici T1, v celico T3 izpisal celotni naslov – Adress, City, Region, PostalCode, Country) (namig: Xlookup). 

R:

```{r}
zdruzena_nova %>% 
  filter(EmployeeName == "Steven Buchanan") %>% 
  select(EmployeeName, HomePhone, Address:Country) %>% 
  distinct() %>% 
  unite(Naslov, Address:Country, sep = ", ") %>% 
  rename(Telefon = HomePhone,
         Zaposleni = EmployeeName)

```

# 8. Index, Match

Excel:
Postavite se na delovni list Zaposleni v celico P6 in izpišite, kaj se vam nahaja v vrstici 5 in stolpcu 8 (namig: index). 
• V celico P7 izpišite številko vrstice, v kateri se nahaja priimek Fuller (namig: match). 
• Postavite se na delovni list Orders, v naslednji stolpec v prvo celico napišite Št. vrstice, ter na podlagi priimka poiščite v kateri vrstici se priimek nahaja v stolpcu Priimek v tabeli Zaposleni (namig: match). 
• Postavite se na delovni list Orders, v naslednji stolpec v prvo celico napišite Title, ter na podlagi stolpca Št. vrstice poiščite naziv zaposlenega iz tabele Zaposleni (stolpec Title; namig: index). 
• Postavite se na delovni list Orders, v naslednji stolpec v prvo celico napišite Title, ter na podlagi priimka s pomočjo funkcij Index in Match vstavite naziv zaposlenega s tabele delovnega lista Zaposleni.
• V naslednji stolpec v prvo celico napišite Naslavljanje, ter na podlagi priimka s pomočjo funkcij Index in Match vstavite obliko naslavljanja zaposlenega s tabele delovnega lista Zaposleni. 


```{r}
zaposleni[5,8] # vrstica 5, stolpec 8

zaposleni %>% 
  # add_rownames() %>% # opcionalen korak
  filter(str_detect(LastName, "Fuller")) %>% 
  select(EmployeeID)

zdruzena_nova %>% 
  filter(str_detect(EmployeeName, "Fuller"))

kontakt %>% 
  filter(str_detect(Priimek, "Fuller"))

```

# 9. Filtriranje

Excel:
Funkcionalnost Napredno filtriranje.
• Dodajte nov list z imenom Napredno filtriranje.
• V celico A1 napišite besedilo ID zaposlenega in v celico B1 zapiši številko ID zaposlenega (poljubna številka od 1 - 9).
• V celico A2 napišite besedilo Število naročil in v celico B2 izpišite število naročil za ID zaposlenega iz celice B1 (namig: Countif). 
• Na delovnem listu Orders s filtriranjem preverite naročila zaposlenega, ki ste jih prešteli (osnovno filtriranje). 
• Izpisati želimo seznam naročil na podlagi ID zaposlenega (namig: napredno filtriranje). Seznam naj se izpiše v celico A10 na delovnem listu Napredno filtriranje.
• Namesto naprednega filtriranja uporabite funkcionalnost tabele in razčlenjevalnike. 

R:

```{r}
(seznam = zdruzena_nova %>% 
  count(EmployeeID, OrderID) %>% 
  filter(EmployeeID == 9)
)

(napredno_filtriranje = seznam %>% 
  summarise(Narocila = sum(n))
)

```


```{r}
zdruzena_nova %>%
  count(EmployeeName) %>%
  mutate(Procent = n / sum(n)) %>% 
  ungroup() %>% 
  mutate(EmployeeName = fct_reorder(EmployeeName, Procent)) %>% 
  ggplot(aes(Procent, EmployeeName, fill = EmployeeName)) +
  geom_col(color = "black") +
  scale_x_continuous(labels = percent_format()) +
  theme(legend.position = "none") +
  labs(x="", y="", title = "Percentage of orders by employee")

```

