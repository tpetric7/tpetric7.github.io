# tpetric7.github.io

## RAJ 2021, Exercises with R/RStudio:

* [File Management](docs/download_unzip_dir.md)
- [File Management](docs/Odpiranje_in_shranjevanje.md)

* [Chi square test](docs/kommentare_chisq.md)
- [Chi square test](docs/kommentare_chisq.R)
- [Chi square test](docs/plural_chisq1.md)
- [Chi square test](docs/plural_chisq2.md)
- [Chi square test](docs/Modalkonstruktionen_chisq3.md)

* [t test](docs/t_preskus.md)

* [Ordinary least squares Regression](docs/politeness.md)
- [Ordinary least squares Regression](docs/Politeness.R)

* [Excel functions compared to R tidyverse: xlookup](docs/Excel_vs_R.md)

* [Basic NLP tasks using quanteda](docs/Sawyer_Prozess.md)
- [NLP: Using regular expressions:](docs/Regex_in_quanteda.md)

* [Vowel Formant Plots](docs/S03_Vokalformanten_Dauer.md)

### OLS Regression

``` r
m <- lm(frequency ~ gender + attitude, data=polite)
summary(m)
```

``` r
library(effects)
allEffects(m)
plot(allEffects(m), multiline=TRUE, grid=TRUE, rug=FALSE, as.table=TRUE)
```

![Plot 1](pictures/politeness_boxplot.jpg)

![Plot 2](pictures/politeness_lineplot.jpg)

### NLP

``` r
library(readtext)
library(quanteda)
library(quanteda.textplots)

txt = readtext("data/books/*.txt", encoding = "UTF-8")
romane = corpus(txt)
kwic_frau = kwic(corpus, pattern = "frau")
textplot_xray(kwic_frau)
```

![Plot 3](pictures/kwic_xray_frau.png)

### Vowel formants in L1 / L2 German

![Plot 4](pictures/messungen_tp_vokalformanten_ipa.jpg) ![Plot 5](pictures/vokalformanten_interaktiv_l1_l2_lang_kurz.png)
