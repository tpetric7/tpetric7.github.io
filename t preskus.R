# t test

metode <- read.csv("d:/Users/teodo/Documents/R/RPDJG/data/ttest2a.csv", dec=",")
attach(metode)

head(metode)

tapply(Resultat, list(Methode), mean)
tapply(Resultat, list(Methode), sd)
barplot(tapply(Resultat, list(Methode), mean), col=c(3:2))

t.test(Resultat ~ Methode, data=metode, paired = F, var.equal = T)

m <- lm(Resultat ~ Methode, data=metode)
summary(m)

library(effects)
allEffects(m)
plot(allEffects(m), multiline=TRUE, grid=TRUE, rug=FALSE, as.table=TRUE)
