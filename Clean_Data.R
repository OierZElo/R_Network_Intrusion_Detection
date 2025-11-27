library(tibble)
library(ggplot2)
library(readr)

#LOAD THE ORIGINAL DATASET
csv <- read.csv("kddcup.csv")
netWorkDataset <- as_tibble(csv)

col_names <- readLines("kddcup.names")

#EDIT THE STRING OF COLNAMES
col_names <- col_names[-1]
col_names <- sapply(col_names, function(x) strsplit(x, ":")[[1]][1])
col_names <- trimws(col_names)
colnames(netWorkDataset) <- col_names
colnames(netWorkDataset)[ncol(netWorkDataset)] <- "class"

print(netWorkDataset)

#OMMIT NA's
netWorkDataset <- na.omit(netWorkDataset)

#DELETE DUPLICATES
netWorkDataset <- unique(netWorkDataset)

#CONVERT CHARACTER → FACTOR
char_cols <- sapply(netWorkDataset, is.character)
netWorkDataset[, char_cols] <- lapply(netWorkDataset[, char_cols], as.factor)

#CONVERT INTEGER → NUMERIC
int_cols <- sapply(netWorkDataset, is.integer)
netWorkDataset[int_cols] <- lapply(netWorkDataset[int_cols], as.numeric)

#SAVE THE CLEAN CSV TO A CSV
write_csv(netWorkDataset, "kdd_clean.csv")

str(netWorkDataset)
dim(netWorkDataset)
names(netWorkDataset)







