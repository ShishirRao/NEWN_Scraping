library("RSelenium")
library("rvest")
library("tidyverse")
library("lubridate")

rD <- rsDriver(browser="firefox", port=4552L, verbose=F)
remDr <- rD[["client"]]
sys.sleep(5)

#open the proquest website
remDr$navigate("http://www.galileo.usg.edu/express?link=xcun-uga1&inst=uga1")
Sys.sleep(3)
#clear the username field
remDr$findElement("id", "username")$clearElement()

#load username and password
user<-"str56489"
pw<-"Bennedose@9839"

#populate the username and password fields on the proquest website
remDr$findElement(using = "id", value = "username")$sendKeysToElement(list(user))
Sys.sleep(2)
remDr$findElement(using = "id", value = "password")$sendKeysToElement(list(pw))
Sys.sleep(2)

#login
remDr$findElements(using = "name", "submit")[[1]]$clickElement()
Sys.sleep(3)

#Proquest website entered -- perform keyword search
keyword = "Nature-based"

#Populate the search field and conduct search
remDr$findElement(using = "id", value = "searchText_0")$sendKeysToElement(list(keyword))
Sys.sleep(2)
remDr$findElements(using = "name", "submitbutton")[[1]]$clickElement()
Sys.sleep(2)
#Select the "congressional record" field from the categories
remDr$findElements(using = "class", "col-md-9")[[7]]$clickElement()
Sys.sleep(3)

#load the contents of the page
html <- remDr$getPageSource()[[1]]
#write.table(html,file="D:/PhD/ICON/N-EWN GRA/Web_scraping_crawling/Scrawl/html.txt")


#Read the document names
Titles <- read_html(html) %>% # parse HTML
  html_nodes("a.itemTitle")%>%
  html_text(trim = T)

#Read the document date
Date <- read_html(html) %>% # parse HTML
  html_nodes("div.col-md-3") %>%
  html_nodes("div.rstField")%>%
  html_text(trim = T)

#Read the URL
Link <- read_html(html) %>% # parse HTML
  html_nodes("a.itemTitle")%>%
  html_attr(name="href")

#Compile a data frame with document name, date and link
CR_records <- data.frame(
  Document = Titles,
  Date = Date,
  URL = Link)

#convert the date to mm/dd/yy format
CR_records$Date = mdy(str_replace(CR_records$Date,"Date: ",""))
CR_records$URL = str_c("https://congressional-proquest-com.proxy-remote.galib.uga.edu",CR_records$URL)

#write.csv(CR_records,file="D:/PhD/ICON/N-EWN GRA/Web_scraping_crawling/Scrawl/CR_Records.csv")
#head(CR_records)

########### Go to first search result ################
remDr$findElements(using = "class", "itemTitle")[[1]]$clickElement()
#remDr$findElement(using = "id", value = "searchTerm")$sendKeysToElement(list(keyword))
html <- remDr$getPageSource()[[1]]

#write.table(html,file="D:/PhD/ICON/N-EWN GRA/Web_scraping_crawling/Scrawl/Search1.txt")

Link_left <- read_html(html) %>% # parse HTML
  html_nodes("div.docSegGrid")%>%
  html_nodes("div.docSegRow")%>%
  html_nodes("div.segColL")%>%
  html_text(trim = T)

Link_right <- read_html(html) %>% # parse HTML
  html_nodes("div.docSegGrid")%>%
  html_nodes("div.docSegRow")%>%
  html_nodes("div.segColR")%>%
  html_text(trim = T)

Link_df = data.frame(
  Content = Link_left,
  Attribute = Link_right
)

remDr$findElements(using = "class", "uxf-right-open-large")[[1]]$clickElement()


