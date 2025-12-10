library(tibble)
library(ggplot2)
library(readr)
library(dplyr)

csv <- read.csv("kdd_clean.csv")
netWorkDataset <- as_tibble(csv)

#CONVERT CHARACTER → FACTOR
char_cols <- sapply(netWorkDataset, is.character)
netWorkDataset[, char_cols] <- lapply(netWorkDataset[, char_cols], as.factor)

#CONVERT INTEGER → NUMERIC
int_cols <- sapply(netWorkDataset, is.integer)
netWorkDataset[int_cols] <- lapply(netWorkDataset[int_cols], as.numeric)

#EXAMPLE GRAPHICS
boxplot(netWorkDataset$duration, main="Duration winsorizada")
hist(netWorkDataset$src_bytes, breaks = 50)

str(netWorkDataset)

       