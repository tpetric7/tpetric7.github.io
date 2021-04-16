# Politeness data (B. Winter tutorial)

# LOAD
rm(list=ls(all=TRUE)) # clear memory
polite <- read.csv("data/politeness_data.csv", dec=".")

attach(polite)

head(polite)

polite$frequency = as.numeric(polite$frequency)
polite$scenario = as.factor(polite$scenario)
polite$subject = as.factor(polite$subject)
polite$gender = as.factor(polite$gender)
polite$attitude = as.factor(polite$attitude)

attach(polite)

# In this session we use contr. sum contrasts
options(contrasts=c('contr.sum', 'contr.poly'))
options("contrasts")

# To reset default settings run: 
options(contrasts=c('contr.treatment', 'contr.poly')) 
# (all afex functions should be unaffected by this)

# # Setting contrasts of chosen variables only
# contrasts(polite$attitude) <- contr.treatment(2, base = 1)

boxplot(frequency ~ attitude*gender, 
        col=c("red","green"), polite) 

# 1. Open jpeg file
jpeg("pictures/politeness_boxplot.jpg", 
     width = 840, height = 535)
# 2. Create the plot
boxplot(frequency ~ attitude*gender, 
        col=c("red","green"), polite) 
# 3. Close the file
dev.off()

# Open a pdf file
pdf("pictures/politeness_boxplot.pdf") 
# 2. Create a plot
boxplot(frequency ~ attitude*gender, 
        col=c("red","green"), polite) 
# Close the pdf file
dev.off() 

################
# OLS Regression
################

# model 1
m <- lm(frequency ~ gender + attitude + subject + scenario, data=polite)
summary(m)

# model 2
m <- lm(frequency ~ gender + attitude, data=polite)
summary(m)

library(effects)
allEffects(m)
plot(allEffects(m), multiline=TRUE, grid=TRUE, rug=FALSE, as.table=TRUE)

# Save plot of the effects to disk
# 1. Open jpeg file
jpeg("pictures/politeness_lineplot.jpg", 
     width = 840, height = 535)
# 2. Create the plot
plot(allEffects(m), multiline=TRUE, grid=TRUE, rug=FALSE, as.table=TRUE)
# 3. Close the file
dev.off()

# model 3 (with interaction)
m <- lm(frequency ~ gender*attitude, data=polite)
summary(m)

library(effects)
allEffects(m)
plot(allEffects(m), multiline=TRUE, grid=TRUE, rug=FALSE, as.table=TRUE)

# Save plot of the effects to disk
# 1. Open jpeg file
jpeg("pictures/politeness_effects.jpg", 
     width = 840, height = 535)
# 2. Create the plot
plot(allEffects(m), multiline=TRUE, grid=TRUE, rug=FALSE, as.table=TRUE)
# 3. Close the file
dev.off()

# Open a pdf file
pdf("pictures/politeness_effects.pdf") 
# 2. Create a plot
plot(allEffects(m), multiline=TRUE, grid=TRUE, rug=FALSE, as.table=TRUE)
# Close the pdf file
dev.off() 

# Change of estimates if one datapoint is removed from the model
(d <- dfbetas(m)
)

# plot the dfbetas (are there any outliers or data points with high influence?)
par(mfrow = c(1,3))
plot(d[,1], col = "orange")
plot(d[,2], col = "blue")
plot(d[,3], col = "purple")
par(mfrow = c(1,1))

# plot diagnostic diagrams
par(mfrow = c(3,2))
plot(m, which = 1) # variance of residuals vs. fitted values?
plot(m, which = 2) # normal distributed residuals?
plot(m, which = 3) # variance of residuals standardized
plot(m, which = 4) # Cook's distance (outliers / influencing data points?)
plot(m, which = 5) # Leverage vs. standardized variance of residuals
plot(m, which = 6) # Cook's distance vs. Leverage
par(mfrow = c(1,1))


##########################
# Mixed effects Regression
##########################

# The variables 'subject' and 'scenario' have been chosen as random effects

library(afex)

# random intercepts model
m <- lmer(frequency ~ gender + 
            (1|subject) + (1|scenario), 
          REML=F, data=polite)
m0 <- m
summary(m)

m <- lmer(frequency ~ gender + attitude + 
          (1|subject) + (1|scenario), 
          REML=F, data=polite)
m1 <- m
summary(m)

m <- lmer(frequency ~ gender*attitude + 
            (1|subject) + (1|scenario), 
          REML=F, data=polite)
m2 <- m
summary(m)

anova(m0,m1,m2)

# politeness affected pitch (χ2(1)=11.62, p=0.00065), 
# lowering it by about 19.7 Hz ± 5.6 (standard errors) 

# random slopes model
m <- lmer(frequency ~ gender + 
            (attitude + 1|subject) + (attitude + 1|scenario), 
          REML=F, data=polite)
m00 <- m
summary(m)

m <- lmer(frequency ~ gender + attitude + 
          (attitude + 1|subject) + (attitude + 1|scenario), 
          REML=F, data=polite)
m01 <- m
summary(m)

m <- lmer(frequency ~ gender + attitude + 
            (attitude + 1|subject), 
          REML=F, data=polite)

library(effects)
allEffects(m)
plot(allEffects(m), multiline=TRUE, grid=TRUE, rug=FALSE, as.table=TRUE)

m <- lmer(frequency ~ gender + attitude + 
            (attitude + 1|scenario), 
          REML=F, data=polite)

library(effects)
allEffects(m)
plot(allEffects(m), multiline=TRUE, grid=TRUE, rug=FALSE, as.table=TRUE)

m <- lmer(frequency ~ gender*attitude + 
            (attitude + 1|subject) + (attitude + 1|scenario), 
          REML=F, data=polite)
m02 <- m
summary(m)

anova(m00,m01,m02)


library(lmerTest)
s <- step(m)
s

library(LMERConvenienceFunctions)

m <- lmer(frequency ~ gender + attitude + 
            (attitude + 1|subject) + (attitude + 1|scenario), 
          REML=F, data=polite)
m01 <- m
summary(m)

# Check model asumptions
mcp.fnc(m)

fligner.test(frequency ~ attitude, polite)
fligner.test(frequency ~ gender, polite)

shapiro.test(polite$frequency)

which(is.na(polite$frequency)) 

# delete NA from data frame in row 39
polite1 <- polite[-39,]

# Remove outliers
freqout <- romr.fnc(m, polite1, trim=2.5)
freqout$n.removed
freqout$percent.removed
freqout <- freqout$data
attach(freqout)

# update model
m <- lmer(frequency ~ gender + attitude + 
            (attitude + 1|subject) + (attitude + 1|scenario), 
          REML=F, data=freqout)
m01 <- m
summary(m)

# Re-Check model asumptions
mcp.fnc(m)

fligner.test(frequency ~ attitude, freqout)
fligner.test(frequency ~ gender, freqout)

shapiro.test(freqout$frequency)
