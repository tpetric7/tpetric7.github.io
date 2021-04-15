library(tidyverse)
library(janitor)

# Datei laden

kommentare = read.delim("data/chisq_kommentare.txt", sep = "\t") %>% 
  clean_names()
head(kommentare)

# Chi-Quadrat-Test

chisq.test(kommentare[,-1])

# Wir verwerfen H0 und nehmen H1 an: 
# zwischen kurzen und langen Kommentaren besteht ein nicht zufälliger Unterschied.
