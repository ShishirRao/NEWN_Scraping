library("RSelenium")
library("rvest")
library("tidyverse")
library("lubridate")
library("rmarkdown")
library("gridExtra")
library("xlsx")
library("tinytex")

rD <- rsDriver(browser="firefox", port=4558L, verbose=F)
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
Sys.sleep(10)

#Proquest website entered -- perform keyword search
keyword = "Nature-based"

#Populate the search field and conduct search
remDr$findElement(using = "id", value = "searchText_0")$sendKeysToElement(list(keyword))
Sys.sleep(2)
remDr$findElements(using = "name", "submitbutton")[[1]]$clickElement()
Sys.sleep(2)

#Select the "CRS reports" field from the categories
remDr$findElements(using = "class", "col-md-9")[[2]]$clickElement()
Sys.sleep(3)

#load the contents of the page
html <- remDr$getPageSource()[[1]]
#write.table(html,file="D:/PhD/ICON/N-EWN GRA/Web_scraping_crawling/Scrawl/html.txt")

#Read the number of records
No_records <- read_html(html) %>% 
  html_nodes("h2.resultCount") %>%
  html_text(trim = T)

No_records = as.numeric(str_replace(No_records," Results",""))

########### Go to first search result ################
remDr$findElements(using = "class", "itemTitle")[[1]]$clickElement()
Sys.sleep(5)

Link_df = NULL
Link_df_prev = NULL

for (i in 1:No_records){
  
  if(i != 1){
    remDr$findElements(using = "class", "uxf-right-open-large")[[1]]$clickElement()  
    Sys.sleep(3)  
  }
  
  html <- remDr$getPageSource()[[1]]
  
  #write.table(html,file="D:/PhD/ICON/N-EWN GRA/Web_scraping_crawling/Scrawl/Search1.txt")
  
  Link_left_title <- read_html(html) %>% # parse HTML
    html_nodes("div.docSeg-TitleText")%>%
    html_text(trim = T)
  
  #Remove unnecessary titles
  Link_left_title = Link_left_title[-c(which(Link_left_title == "Copyright"|
                                               Link_left_title == "GPO Digitally Signed"|
                                               Link_left_title == "Summary"|
                                               Link_left_title == "PDF - Full Text"))]
  
  #Load left column sub-titles
  Link_left <-  read_html(html) %>% # parse HTML
    html_nodes("div.docSegGrid")%>%
    html_nodes("div.docSegRow")%>%
    html_nodes("div.segColL")%>%
    html_text(trim = T)
  
  #Rename known fields
  Link_left[(which(Link_left == "Permalink:")+1)] = "Congress Session"
  Link_left[(which(Link_left == "Congress Session:")+1)] = "Author"
  
  #Copy titles to sub-titles
  index1 = length(Link_left)
  for(index2 in length(Link_left_title):4){
    Link_left[index1] = Link_left_title[index2]
    index1 = index1-1
  }
  
  #Read contents
  Link_right <- read_html(html) %>% # parse HTML
    html_nodes("div.docSegGrid")%>%
    html_nodes("div.docSegRow")%>%
    html_nodes("div.segColR")%>%
    html_text(trim = T)
  
  
  Link_df = data.frame(
    Content = Link_left,
    Attribute = Link_right
  )
  
  #All blank attributes must be authors
  Link_df$Content[which(Link_df$Content == "")] = "Author"
  
  #Create a single author row
  Author_length = length(which(Link_df$Content == "Author"))
  if(Author_length>1){
    for(index in 2:Author_length){
      Link_df$Attribute[which(Link_df$Content == "Author")[1]] =
        paste(Link_df$Attribute[which(Link_df$Content == "Author")[1]],
              Link_df$Attribute[which(Link_df$Content == "Author")[index]],sep='; ')
    }
    Link_df = Link_df[-which(Link_df$Content == "Author")[2:Author_length],]
  }
  colnames(Link_df)[2] = i
  
  if (i != 1){
    Link_df = merge(Link_df_prev,Link_df, by = "Content", all = TRUE)
  }
  Link_df_prev = Link_df
}
Link_df_prev = Link_df

#Mutate the dataframe
Link_df = as.data.frame(t(Link_df))
colnames(Link_df) = Link_df[1,]
Link_df = Link_df[-1,]

#Clean up the column names
names(Link_df) = str_replace(names(Link_df),pattern = ":",replacement = "")
names(Link_df) = str_replace(names(Link_df),pattern = "-",replacement = "_")
names(Link_df) = str_replace(names(Link_df),pattern = " ",replacement = "_")
names(Link_df) = str_replace(names(Link_df),pattern = " ",replacement = "_")

Link_df = select(Link_df,Title,CRDC_Id,Document_Date,Agency,Agency_Publication_Number,Length,
       Permalink,Congress_Session,Author,Subjects,Descriptors,Organization_Terms,Legislative_Terms,
       CIS_Number,Committee,Person_Term,Public_Law,Statute_At_Large,Sudoc_Number
       )

#saveRDS(Link_df, file = "D:/PhD/ICON/N-EWN GRA/Web_scraping_crawling/Scrawl/CRS_Reports_Metadata_Nature_based.rds")
#save(Link_df,file = "D:/PhD/ICON/N-EWN GRA/Web_scraping_crawling/Scrawl/CRS_Reports_Metadata_Nature_based.RData")

#write.csv(Link_df,file="D:/PhD/ICON/N-EWN GRA/Web_scraping_crawling/Scrawl/CRS_Reports_Metadata_Nature_based.csv")




