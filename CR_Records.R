library("RSelenium")
library("rvest")
library("tidyverse")
library("lubridate")
library("rmarkdown")
library("gridExtra")
library("xlsx")
library("tinytex")

rD <- rsDriver(browser="firefox", port=4555L, verbose=F)
remDr <- rD[["client"]]
Sys.sleep(5)

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

#Read the number of records
No_records <- read_html(html) %>% 
  html_nodes("h2.resultCount") %>%
  html_text(trim = T)

No_records = as.numeric(str_replace(No_records," Results",""))

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
Link_left[9] = "Text"

Link_right <- read_html(html) %>% # parse HTML
  html_nodes("div.docSegGrid")%>%
  html_nodes("div.docSegRow")%>%
  html_nodes("div.segColR")%>%
  html_text(trim = T)

Link_right[9] <-read_html(html) %>% # parse HTML
  html_nodes("div.segFull") %>%
  html_text(trim = T) %>%
  paste0(collapse = "\n")

Link_df = data.frame(
  Content = Link_left,
  Attribute = Link_right
)

Link_df = data.frame(rbind(Link_left,Link_right))
colnames(Link_df) = Link_df[1,]
Link_df = Link_df[-1,]
rownames(Link_df) = 1


for (index in 2:4){
  
    remDr$findElements(using = "class", "uxf-right-open-large")[[1]]$clickElement()  
    Sys.sleep(10)  
    
    html <- remDr$getPageSource()[[1]]
    
    Link_right <- read_html(html) %>% # parse HTML
      html_nodes("div.docSegGrid")%>%
      html_nodes("div.docSegRow")%>%
      html_nodes("div.segColR")%>%
      html_text(trim = T)
    
    
    Link_right[8] <-read_html(html) %>% # parse HTML
      html_nodes("div.segFull") %>%
      html_text(trim = T) %>%
      paste0(collapse = "\n")
    
    Link_df = rbind(Link_df, Link_right)
}

head(Link_df$Text)

#write.csv(Link_df,file="D:/PhD/ICON/N-EWN GRA/Web_scraping_crawling/Scrawl/CR_Records_all_text_4.csv")


my_text = "Shishir Rao"
cat(my_text, sep="  \n", file = "my_text.Rmd")
render("my_text.Rmd", pdf_document())
file.remove("my_text.Rmd") #cleanup

pdf(paste(Link_df[1,1],".pdf",sep=""))       # Export PDF
grid.table(Link_df[1,8])
dev.off()

require(rmarkdown)
my_text <- "Shishir Rao"
cat(my_text, sep="  \n", file = "my_text.Rmd")
render("my_text.Rmd", pdf_document())
file.remove("my_text.Rmd")

update.packages(ask = FALSE, checkBuilt = TRUE)
tinytex::tlmgr_update()
