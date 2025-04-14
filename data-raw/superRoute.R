library(xlsx)
read_types <- read.xlsx("data-raw/Copy of Rapidtox_hazard 1_JL edited_1.23.25_cw.xlsx", sheetIndex = 1)
library(dplyr)
oral <- read_types |> filter(Oral == 1) |> pull(toxval_type)
inhalation <- read_types |> filter(Inhalation == 1) |> pull(toxval_type)
superRoute <- list(oral = oral,inhalation = inhalation)

usethis::use_data(superRoute)
