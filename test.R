library(tibble)

#CARGAR SOLO 1 VEZ
csv <- read.csv("kddcup.csv")
netWorkDataset <- as_tibble(csv)

print(netWorkDataset)

#test