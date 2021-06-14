---
title: "Download unzip dir list"
author: "Teodor Petrič"
date: "2021-6-3"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# Download

```{r}
download.file("https://github.com/tpetric7/tpetric7.github.io/archive/refs/heads/main.zip",
              "d:/Users/teodo/Downloads/tpetric7-master.zip")
```

# Check & create directory

```{r}
pot <- "d:/Users/teodo/Downloads/tpetric7-master"
exist <- dir.exists(pot)
exist

```

```{r}
ifelse(exist == FALSE, 
       dir.create(pot, showWarnings = TRUE, recursive = TRUE), 
       "directory already exists")
```

# Unzip

```{r}
unzip("d:/Users/teodo/Downloads/tpetric7-master.zip", exdir = pot)
```


# Create subfolders

```{r}
subfolder_names <- c("a","b","c","d") 
for (i in 1:length(subfolder_names)){
  folder <- dir.create(paste0(pot, "/", subfolder_names[i]))
}

```

# List files

```{r}
seznam <- list.files(pot, pattern = "\\.txt$", recursive = TRUE, full.names = TRUE)
seznam

```

# Read files

```{r}
library(tidyverse)
alltxt <- seznam %>% map(read_lines)

head(alltxt[[5]], 12)
cat(head(alltxt[[5]], 12))

```

Base R:

```{r}
alltxt <- lapply(seznam, readLines)

head(alltxt[[5]], 12)
cat(head(alltxt[[5]], 12))

```

