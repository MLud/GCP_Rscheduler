
library(rvest)
library(jsonlite)
library(magrittr)
library(readr)
library(stringr)

ymdhms<-paste0(format(Sys.Date(), "%Y%m%d"),'_',format(Sys.time(), "%H%M%S"))


base_url <- "https://www.worldometers.info/coronavirus/"
page <- read_html(base_url)



#  html_nodes('td , .sorting') %>% 



dane1 <- page %>%
  html_nodes(xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "sorting_desc", " " ))] | //td | //*[contains(concat( " ", @class, " " ), concat( " ", "sorting", " " ))]') %>%
  html_text() %>%
  str_replace_all('[+]','')%>%
  str_replace_all(',','')


#because we have two tables we have to see where their start
indexes=which(dane1=='World')


#daneYesterday<-dane1[(indexes[2]):(length(dane1)) ]  


daneTable<-function (data, dataFrom, dataTo){

  daneOut<-data[dataFrom:dataTo]  
  daneOut2<-matrix(daneOut,,15,byrow = TRUE) %>% as.data.frame(stringsAsFactors =FALSE) 
  names(daneOut2)<-c('lp','Country','TotalCases','NewCases','TotalDeaths','NewDeaths','TotalRecovered','ActiveCases','SeriousCritical','TotCases1Mpop','Deaths1Mpop','TotalTests','Tests1Mpop','Population','Continent')
  daneOut2$timestamp<-ymdhms

  daneOut2<-daneOut2 %>% dplyr::filter(lp !='')
  str(daneOut2)
  return (daneOut2)
  }


daneToday<-daneTable(dane1,indexes[1]-1,indexes[2]-2)
daneYesterday<-daneTable(dane1,indexes[2]-1,length(dane1))


write_csv(daneToday,path=paste0('outToday',ymdhms,'.csv'))
write_csv(daneYesterday,path=paste0('outYesterday',ymdhms,'.csv'))
write_csv(dane1,path=paste0('InAll',ymdhms,'.csv'))




write_csv(daneToday,path='outToday.csv')
write_csv(daneYesterday,path='outYesterday.csv')




