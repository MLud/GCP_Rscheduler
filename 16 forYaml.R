

library(rvest)
library(jsonlite)
library(magrittr)
library(readr)
#library(lubridate)




ymdhms<-paste0(format(Sys.Date(), "%Y%m%d"),'_',format(Sys.time(), "%H%M%S"))



# jaką stronę wczytujemy?
base_url <- "https://www.gov.pl/web/koronawirus/wykaz-zarazen-koronawirusem-sars-cov-2"
page <- read_html(base_url)


dane1 <- page %>%
  html_nodes(xpath = "//pre[@id='registerData']") %>% 
  html_text() %>% 
  fromJSON()

dane2<-dane1$parsedData %>% 
  fromJSON()
dane2$description<-dane1$description
dane2$timestamp<-ymdhms #now()



fileout<-paste0('out',ymdhms,'.csv')


write_csv(dane2,path=fileout)
write_csv(dane2,path='out.csv')


print(system('ls -R'))
getwd()


#gcr.io/szkolachmury-kurs-gcp/dockerfile:1


