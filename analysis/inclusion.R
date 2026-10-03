# Inclusion criterion: researchers working in Europe. Shared by analysis.qmd and
# ../paper/manuscript.qmd, so that both apply the same rule to the free-text
# country of the workplace (Work_Country).
#
# Respondents naming France and another country count as France. A country that
# cannot be read (e.g., "2") is NA: it does not show that the respondent works
# outside Europe, so the respondent is kept.

library(stringr)
library(dplyr)

clean_country <- function(x) {
  x <- str_to_title(str_trim(x))
  case_when(
    !str_detect(x, "[A-Za-z]") ~ NA_character_,
    str_detect(x, "France|Feance|Frabce|Dijon|Grenoble") ~ "France",
    str_detect(x, "^Brazil") ~ "Brazil",
    str_detect(x, "^Uk|United Kingdom|England|Wales") ~ "United Kingdom",
    x %in% c("Italia", "Roma") ~ "Italy",
    str_detect(x, "^Spain") ~ "Spain",
    x %in% c("Be", "Belgique") ~ "Belgium",
    x %in% c("Nl", "The Netherlands") ~ "Netherlands",
    x == "Suisse" ~ "Switzerland",
    str_detect(x, "^Usa$|^United States") ~ "United States",
    .default = x
  )
}

# Countries (as returned by clean_country) found outside Europe in the data.
# A new export may contain others: check the list of excluded countries printed
# by the notebook (chunk `inclusion`) and the countries kept in the sample table.
non_european <- c("Australia", "Brazil", "Canada", "China", "Puerto Rico", "United States")

works_outside_europe <- function(work_country) clean_country(work_country) %in% non_european
