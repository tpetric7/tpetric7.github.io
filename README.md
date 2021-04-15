# tpetric7.github.io

# OLS Regression

m <- lm(frequency ~ gender + attitude + subject + scenario, data=polite)
summary(m)

m <- lm(frequency ~ gender + attitude, data=polite)
summary(m)

library(effects)
allEffects(m)
plot(allEffects(m), multiline=TRUE, grid=TRUE, rug=FALSE, as.table=TRUE)

knitr::include_graphics("pictures/politeness_boxplot.jpg")

knitr::include_graphics("pictures/politeness_lineplot.jpg")
