library(dplyr)
library(tibble)
library(ggplot2)
library(readr)

csv <- read.csv("kdd_clean.csv")
netWorkDataset <- as_tibble(csv)

#CONVERT CHARACTER → FACTOR
char_cols <- sapply(netWorkDataset, is.character)
netWorkDataset[, char_cols] <- lapply(netWorkDataset[, char_cols], as.factor)

#CONVERT INTEGER → NUMERIC
int_cols <- sapply(netWorkDataset, is.integer)
netWorkDataset[int_cols] <- lapply(netWorkDataset[int_cols], as.numeric)

#SELECT ONLY IMPORTANT COLUMNS
netWorkDataset_clean <- select(netWorkDataset,
                               duration, protocol_type, service, flag,
                               src_bytes, dst_bytes, count, srv_count,
                               serror_rate, srv_serror_rate, rerror_rate, srv_rerror_rate,
                               logged_in, is_host_login, is_guest_login,
                               dst_host_count, dst_host_srv_count, dst_host_same_srv_rate,
                               dst_host_diff_srv_rate, dst_host_same_src_port_rate,
                               class
)
str(netWorkDataset_clean)

#ADD NEW COLUMNS
netWorkDataset_clean <- mutate(netWorkDataset_clean,
                               total_bytes = src_bytes + dst_bytes,
                               byte_ratio = ifelse(dst_bytes == 0, 0, src_bytes / dst_bytes)
)
str(netWorkDataset_clean)

#SHOW DURATION BY PROTOCOL
duration_by_protocol <- summarise(
  group_by(netWorkDataset_clean, protocol_type),
  mean_duration = mean(duration, na.rm = TRUE),
  median_duration = median(duration, na.rm = TRUE),
  count = n()
)

print(duration_by_protocol)

#SHOW ATTACKS BY CLASS
attack_summary <- count(netWorkDataset_clean, class)
print(attack_summary, n = 23)


