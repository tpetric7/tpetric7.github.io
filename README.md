# tpetric7.github.io

# OLS Regression

```r
m <- lm(frequency ~ gender + attitude, data=polite)
summary(m)
```

```r
library(effects)
allEffects(m)
plot(allEffects(m), multiline=TRUE, grid=TRUE, rug=FALSE, as.table=TRUE)
```

```r
knitr::include_graphics("pictures/politeness_boxplot.jpg")
```

```r
knitr::include_graphics("pictures/politeness_lineplot.jpg")
```
