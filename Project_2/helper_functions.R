library(tidyverse)
library(dplyr)
library(stringr)


#Create dataset-----------------------------------------
#load data file
UMD_df = read_tsv("https://raw.githubusercontent.com/biodatascience/datasci611/gh-pages/data/project1_2019/UMD_Services_Provided_20190719.tsv", na = '**')
#visuals

#Replace spaces in field names with underscores
spaceless <- function(x) {colnames(x) <- gsub(" ", "_", colnames(x));x}
rename_UMD_df <- spaceless(UMD_df)

#Convert date field to date data type; Remove unrelated fields; limit date range to 2007 to 2016 to match open dataset; limit food_provided_for to 1 to 10
final_UMD_df = rename_UMD_df %>%
  mutate(Date_of_service = as.Date(UMD_df$Date, "%m/%d/%Y")) %>%
  select(-'Date', -'Client_File_Merge', -'Bus_Tickets_(Number_of)', -'Notes_of_Service', -'Referrals', -'Financial_Support', -`Type_of_Bill_Paid`, -`Payer_of_Support`, -'Field1', -'Field2', -'Field3') %>%
  subset(Date_of_service > "2006-12-31" & Date_of_service < "2017-01-01") 
#select distinct clientfilenum and  max family size determined by food provided for

group_UMD_df = final_UMD_df %>%
  group_by(Client_File_Number) %>%
  filter(Food_Provided_for > 0, Food_Provided_for <= 10)  %>%
  summarise(max_Food_Provided_for = max(Food_Provided_for)) %>%
  drop_na(max_Food_Provided_for)

#Create groups
group_UMD_df$Family_Size <- cut(group_UMD_df$max_Food_Provided_for, breaks = c(0,1,2,3,4,5,6,7,10), labels=c("Individual","2","3","4","5","6","7","8+"))

group_UMD_df$Indv_Family <- cut(group_UMD_df$max_Food_Provided_for, breaks = c(0,1,10), labels=c("Individual","Family"))


#view(group_UMD_df)

#Counts by Family Size (2007-2016)
ggplot(group_UMD_df, aes(x=Family_Size)) +
  geom_bar(aes(fill=Family_Size)) +
  xlab("Family Size") + 
  ggtitle('Counts by Family Size (2007-2016)')

#Individuals Versus Families (2007-2016)
ggplot(group_UMD_df, aes(x=Indv_Family), group = Indv_Family) +
  geom_bar(aes(fill=Indv_Family)) +
  xlab("Family Size") + 
  ggtitle('Individuals Versus Families (2007-2016)')

#view(group_UMD_df)

#join to original data set to append Date_of_Service

#view by each family size
family_size_group_UMD_df = inner_join(group_UMD_df, final_UMD_df, by = c("Client_File_Number" = "Client_File_Number"), suffix = c(".x", ".y")) %>%
  mutate(Year_of_Service = format(Date_of_service, "%Y")) %>%
  group_by(Family_Size, Year_of_Service) %>%
  summarise(n=n_distinct(Client_File_Number))

  
#view(family_size_group_UMD_df)

#Total Number Services by Family Size by Year
ggplot(family_size_group_UMD_df, aes(x=Year_of_Service, y=n, group=Family_Size)) +
  geom_line(aes(color=Family_Size)) +
  scale_x_discrete() +
  xlab("Year_of_Service") + 
  ylab("Number Serviced") + 
  ggtitle('Total Number Serviced by Family Size by Year')


#view by individual vs family
Indv_Family_group_UMD_df = inner_join(group_UMD_df, final_UMD_df, by = c("Client_File_Number" = "Client_File_Number"), suffix = c(".x", ".y")) %>%
  mutate(Year_of_Service = format(Date_of_service, "%Y")) %>%
  group_by(Indv_Family, Year_of_Service) %>%
  summarise(n=n_distinct(Client_File_Number))

#view(Indv_Family_group_UMD_df)

#Individual vs Family by Year
ggplot(Indv_Family_group_UMD_df, aes(x=Year_of_Service, y=n, group=Indv_Family)) +
  geom_line(aes(color=Indv_Family)) +
  scale_x_discrete() +
  xlab("Year_of_Service") +
  ylab("Number Serviced") +
  ggtitle('Individual vs Family by Year')

#----------------------------------------------------------------------------------------------

#Create dataset-----------------------------------------
#load data file in Durham Count Point in Time Data
Durham_PIT_df = read_csv("https://raw.githubusercontent.com/datasci611/bios611-projects-fall-2019-mlfoste1/master/Project1/data/external/Durham%20County_Homeless_Point%20In%20Time.csv", na = '**')

#view(Durham_PIT_df)


#Convert date field to date data type; Remove unrelated fields; limit date range to 2006 to 2016 to match open dataset; limit food_provided_for to 1 to 10
final_PIT_df = Durham_PIT_df %>%
  select('year','measures','count_') %>%
  filter(measures=="Homeless Individuals" | measures=="Homeless People in Families")

#view(final_PIT_df)

#group
final_PIT_df$Indv_Family<-NA
final_PIT_df$Indv_Family[final_PIT_df$measures=="Homeless Individuals"] <- "Individual"
final_PIT_df$Indv_Family[final_PIT_df$measures=="Homeless People in Families"] <- "Family"
final_PIT_df$Year_of_service <- cut(final_PIT_df$year, breaks = c(2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016), labels=c("2007","2008","2009","2010","2011","2012","2013","2014","2015","2016"))
final_PIT_df$n <- as.numeric(final_PIT_df$count_)

#Individuals Versus Families (2007-2016)
indv_fam_plot = ggplot(final_PIT_df, aes(x=Indv_Family, y=n)) +
  geom_bar(stat="identity", aes(fill=Indv_Family)) +
  xlab("Family Size") + 
  ggtitle('Durham PIT - Individuals Versus Families (2007-2016)')


#Total Number Services by Family Size by Year
fam_size_plot = ggplot(final_PIT_df, aes(x=Year_of_service, y=n, group=Indv_Family)) +
  geom_line(aes(color=Indv_Family)) +
  scale_x_discrete() +
  xlab("Year_of_Service") + 
  ggtitle('Durham PIT - Total Number Services by Family Size by Year')


#---------------------------------------------------------------------------------
#Overlap data

#Number serviced vs number reported
serv_reprt_plot = function(yearinput){
  final_PIT_df_plot = final_PIT_df %>%
    filter(year==yearinput)
  
#view(final_PIT_df_plot)

Indv_Family_group_UMD_df_plot = Indv_Family_group_UMD_df %>%
  filter(Year_of_Service==yearinput)

#view(Indv_Family_group_UMD_df_plot)

  ggplot(Indv_Family_group_UMD_df_plot, aes(x=Indv_Family, y=n, group = Indv_Family)) +
    geom_bar(aes(fill=Indv_Family), stat="Identity") +
    geom_bar(data=final_PIT_df_plot, aes(x=measures, y=n, fill=measures), stat="Identity") +
    xlab("") +
    ylab("Number of People Serviced or Reported") +
    theme(axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank())
}
