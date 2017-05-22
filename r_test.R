
# install.packages("foreign")
# if (!require("devtools")) install.packages("devtools")
# devtools::install_github("mkuhn/dict")


library(foreign)
library(dict)

#-------- Load files

#BR
# load file (with category labels)
list_BR <- read.spss("NIBR22FL.SAV", to.data.frame=FALSE, use.value.labels=TRUE)
# convert list to data frame
data_BR <- as.data.frame(list_BR)
# copy all variable (column) labels in separated list
names_BR <- attr(list_BR, "variable.labels")
# names(data_BR) <- names_BR

#HR: household
list_HR <- read.spss("NIHR22FL.SAV", to.data.frame=FALSE, use.value.labels=TRUE)
# convert list to data frame
data_HR <- as.data.frame(list_HR)
# copy all variable (column) labels in separated list
names_HR <- attr(list_HR, "variable.labels")
# names(data_HR) <- names_HR

#IR: women
list_IR <- read.spss("NIIR22FL.SAV", to.data.frame=FALSE, use.value.labels=TRUE)
# convert list to data frame
data_IR <- as.data.frame(list_IR)
# copy all variable (column) labels in separated list
names_IR <- attr(list_IR, "variable.labels")
# names(data_IR) <- names_IR



class(names_IR)

#MR: men
list_MR <- read.spss("NIMR21FL.SAV", to.data.frame=FALSE, use.value.labels=TRUE)
# convert list to data frame
data_MR <- as.data.frame(list_MR)
# copy all variable (column) labels in separated list
names_MR <- attr(list_MR, "variable.labels")
# names(data_MR) <- names_MR

#--------- Store files and medata in object:


parse_name <- function(file_name){
  parsed <- list()
  filename = sub("_","",sub("-","",(sub(" ","",file_name))))
  parsed["country"] = toupper(file_name[1:2])
  parsed["type"] = toupper(file_name[1:2])
}

parse_name(" NIiresgtesraeb")


setClass("survey_data", slots=list(name="character",start_year="numeric",survey_type="numeric", col_names="character", data="data.frame"))



#Write parse_name

#Write





mr <- new("survey_data",name="MR", data=data_MR)

View(mr@data)

typeof(data_MR)








#Do we want to change the indexes?
get_start_year <- function(df, survey_type){
  if(survey_type == "HR"){
    return(min(df$"HV007"))
  }
  else if (survey_type == "IR"){
    return(min(df$"V007"))
  }
  else if (survey_type == "MR") {
    return(min(df$"MV007"))
  }
  else(
    return(NULL)
  )
}

d[["MR"]] = data_MR


create_merge_key <- function(df, survey_type){
  if(survey_type == "HR"){
    return(min(df$"HV007"))
  }
  else if (survey_type == "IR"){
    return(min(df$"V007"))
  }
  else if (survey_type == "MR") {
    return(min(df$"MV007"))
  }
  else(
    return(NULL)
  )
}


#Add a column with country

#Find key elements (for one)
#country_cluster_

#Create column



##For each object:
#Import data
# parse name
s




get_start_year(data_HR,"HR")  
get_start_year(data_IR,"IR")
get_start_year(data_MR,"MR")  




#Creating merge keys
data_BR$merge_Key = 



names_IR[1000:1020]
names_HR[1000:1020]
names(data_HR)[1:20,]







getStartYear(data_HR,"HR")



#-------- Merge

View(data_BR)
View(data_HR)
View(data_MR)
