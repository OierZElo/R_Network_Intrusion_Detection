library(tibble)
library(ggplot2)

#CARGAR SOLO 1 VEZ
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

# Convertir columnas character a factor
char_cols <- sapply(netWorkDataset, is.character)
netWorkDataset[, char_cols] <- lapply(netWorkDataset[, char_cols], as.factor)

# Convertir columnas numéricas con menos de 30 niveles a factor
num_cols <- sapply(netWorkDataset, is.numeric)
for (colname in names(netWorkDataset)[num_cols]) {
  if (length(unique(netWorkDataset[[colname]])) < 20) {
    netWorkDataset[[colname]] <- as.factor(netWorkDataset[[colname]])
  }
}

#str(dataset) → Ver tipos de datos y estructura
#summary(dataset) → Estadísticas básicas, detecta NAs, outliers
#head(dataset) / tail(dataset) → Visualizar primeras y últimas filas
#dim(dataset) → Tamaño (filas y columnas)
#names(dataset) → Nombres de columnas

