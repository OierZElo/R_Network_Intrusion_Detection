library(tibble)
library(ggplot2)
library(readr)

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

#Eliminar columnas con varianza 0 o casi 0

#OMMIT NA's
netWorkDataset <- na.omit(netWorkDataset)

#Eliminar duplicados
netWorkDataset <- unique(netWorkDataset)

# Convertir columnas character a factor
char_cols <- sapply(netWorkDataset, is.character)
netWorkDataset[, char_cols] <- lapply(netWorkDataset[, char_cols], as.factor)

# Convertir columnas numéricas con menos de 20 niveles a factor
num_cols <- sapply(netWorkDataset, is.numeric)
for (colname in names(netWorkDataset)[num_cols]) {
  if (length(unique(netWorkDataset[[colname]])) < 20) {
    netWorkDataset[[colname]] <- as.factor(netWorkDataset[[colname]])
  }
}

int_cols <- sapply(netWorkDataset, is.integer)
netWorkDataset[int_cols] <- lapply(netWorkDataset[int_cols], as.numeric)

write_csv(netWorkDataset, "kdd_clean.csv")

str(netWorkDataset)#→ Ver tipos de datos y estructura
dim(netWorkDataset) #→ Tamaño (filas y columnas)
names(netWorkDataset) #→ Nombres de columnas

