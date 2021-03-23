#install.packages("RSelenium")
#install.packages("rvest")
#install.packages("tidyverse")

library("RSelenium")
library("rvest")
library("tidyverse")

rD <- rsDriver(browser="firefox", port=4545L, verbose=F)
remDr <- rD[["client"]]

remDr$navigate("https://www.fcc.gov/media/engineering/dtvmaps")

zip <- "30308"
remDr$findElement(using = "id", value = "startpoint")$sendKeysToElement(list(zip))

remDr$findElements("id", "btnSub")[[1]]$clickElement()

# required web page opened. Now use rvest to scrape the data

Sys.sleep(5) # give the page time to fully load
html <- remDr$getPageSource()[[1]]

signals <- read_html(html) %>% # parse HTML
  html_nodes("table.tbl_mapReception") %>% # extract table nodes with class = "tbl_mapReception"
  .[3] %>% # keep the third of these tables
  .[[1]] %>% # keep the first element of this list
  html_table(fill=T) # have rvest turn it into a dataframe
View(signals)

names(signals) <- c("rm", "callsign", "network", "ch_num", "band", "rm2") # rename columns

signals <- signals %>%
  slice(2:n()) %>% # drop unnecessary first row
  filter(callsign != "") %>% # drop blank rows
  select(callsign:band) # drop unnecessary columns

read_html(html) %>% 
  html_nodes(".callsign") %>% 
  html_attr("onclick")

read_html(html) %>% 
  html_nodes(".callsign") %>% 
  html_attr("onclick") %>% 
  str_extract("(?<=RX Strength: )\\s*\\-*[0-9.]+")


strength <- read_html(html) %>% 
  html_nodes(".callsign") %>% 
  html_attr("onclick") %>% 
  str_extract("(?<=RX Strength: )\\s*\\-*[0-9.]+")

signals <- cbind(signals, strength)
signals
