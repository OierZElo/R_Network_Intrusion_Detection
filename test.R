library(tibble)

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
