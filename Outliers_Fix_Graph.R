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

#WINSONORIZING FUNCTION (FIX GRAPH)
numeric_cols <- sapply(netWorkDataset, is.numeric)
winsorize <- function(x) {
  if (length(unique(x)) < 2) return(x)
  
  Q1 <- quantile(x, 0.25, na.rm = TRUE)
  Q3 <- quantile(x, 0.75, na.rm = TRUE)
  IQR <- Q3 - Q1
  
  if (IQR == 0) return(x)
  
  lower <- Q1 - 1.5 * IQR
  upper <- Q3 + 1.5 * IQR
  
  x[x < lower] <- lower
  x[x > upper] <- upper
  
  return(x)
}

#APPLY FUNCTION FOR ALL COLUMNS
for (colname in names(netWorkDataset)[numeric_cols]) {
  cat("Procesando outliers en:", colname, "\n")
  netWorkDataset[[colname]] <- winsorize(netWorkDataset[[colname]])
}
print(netWorkDataset)

#EXAMPLE GRAPHICS
boxplot(netWorkDataset$duration, main="Duration winsorizada")
hist(netWorkDataset$src_bytes, breaks = 50)

str(netWorkDataset)

       