
# install.packages("foreign")
# if (!require("devtools")) install.packages("devtools")
# devtools::install_github("mkuhn/dict")


library(foreign)
# library(dict)
library(tidyr)


#TODO: merge startegy
### if the character names match, merge using that
### otherwise, merge with codes
### otherwise: fix





#Output: one table, individual level. + one dict of names for the column names.

#Use cases:
  # ML use case -> columnar
  # Other -> mongo db? simple db?


########- --------------- Load files


#Include AR here from cotes divoire (HIV)





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

View(data_IR)

class(names_IR)

#MR: men
list_MR <- read.spss("NIMR21FL.SAV", to.data.frame=FALSE, use.value.labels=TRUE)
# convert list to data frame
data_MR <- as.data.frame(list_MR)
# copy all variable (column) labels in separated list
names_MR <- attr(list_MR, "variable.labels")
# names(data_MR) <- names_MR

# Function definitions - data load ---------------------------------------------------------------------

setClass("survey_data", slots=list(start_year="numeric",survey_type="character", col_names="character", country="character", data="data.frame"))

setClass("country_surveys", slots=list(ir="survey_data", mr ="survey_data", hr="survey_data"))

parse_name <- function(file_path){
  #extracting name of file in case is is a path
  file_path = unlist(strsplit(file_path,split='/', fixed=TRUE))
  file_name = file_path[length(file_path)]
  parsed <- list()
  file_name = sub("_","",sub("-","",(sub(" ","",file_name))))
  parsed["country"] = toupper(substr(file_name,1,2))
  parsed["type"] = toupper(substr(file_name,3,4))
  return(parsed)
}

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
    return(-1)
  )
}


#returns a survey_data object

load_data <- function(path){
  print(paste("...Loading ",path))
  list_data <- read.spss(path, to.data.frame=FALSE, use.value.labels=TRUE)
  # convert list to data frame
  survey_data <- as.data.frame(list_data)
  # copy all variable (column) labels in separated list
  names_survey <- attr(list_data, "variable.labels")
  metadata <- parse_name(path)
  print(metadata)
  out <- new("survey_data",survey_type=unlist(unname(metadata["type"])), country=unlist(unname(metadata["country"])), col_names=names_survey, data=survey_data)
 
  year = get_start_year(out@data, out@survey_type)
  out@start_year = year
  return(out)
}  


# Function definition - merge -------


create_merge_id <- function (survey_data){
  if(survey_data@survey_type == "HR"){
    df = survey_data@data
    df = df %>% dplyr::mutate(merge_id = paste(survey_data@country, survey_data@start_year, HV001, HV002, sep="_"))
    # df = df %>% dplyr::mutate(merge_id = paste(survey_data@country, survey_data@start_year, HV001, HV002, HV003, HV004, sep="_"))
    # View(df)
    survey_data@data = df
    return(survey_data)
  }
  else if(survey_data@survey_type == "IR"){
    df = survey_data@data
    df = df %>% dplyr::mutate(merge_id = paste(survey_data@country, survey_data@start_year, V001, V002, sep="_"))
    # View(df)
    survey_data@data = df
    return(survey_data)
  }
  else if(survey_data@survey_type == "MR"){
    df = survey_data@data
    df = df %>% dplyr::mutate(merge_id = paste(survey_data@country, survey_data@start_year, MV001, MV002, sep="_"))
    # View(df)
    survey_data@data = df
    return(survey_data)
  } 
  else{
    stop(paste("Incorrect survey_type value",survey_data@survey_type))
  
  }
}


mr@col_names[1:10]
hr@col_names[1:10]
ir@col_names[1:10]


# 
# list_data <- read.spss("_92Niger/NIBR22FL.SAV", to.data.frame=FALSE, use.value.labels=TRUE)
# # convert list to data frame
# survey_data <- as.data.frame(list_data)
# # copy all variable (column) labels in separated list
# names_survey <- attr(list_data, "variable.labels")
# names_survey <- attr(list_data, "variable.labels")
# metadata <- parse_name("_92Niger/NIBR22FL.SAV")
# out <- new("survey_data",survey_type=unlist(unname(metadata["type"])), country=unlist(unname(metadata["country"])), col_names=names_survey, data=survey_data)
# 
# View(survey_data)
# year = get_start_year(out@data, out@survey_type)
# 
# load_data("_92Niger/NIBR22FL.SAV")
# ### PB: survey_type = year -> old names are used here
# 
# 


# Go through all files, read spss and attempt a merge-------


#Add exception handing
#Add stats

#like year, type, unique or not

a <- c()
a <- rep(NA, 100000)

for (i in 1:100000){
  a[i] = 1
}



working_dir = "~/Documents/Projects/HIV-xwas/shared_with_desktop"
setwd(working_dir)

lkf <- function(d,p) names(d)[grep(p,names(d))]
df <- data.frame()
countries <- list.files(recursive = FALSE)

#This will be used to count the files and generate some stats
file_list <- rep(NA,10000)
year_list <- rep(NA,10000)
type_list <- rep(NA,10000)
country_list <- rep(NA,10000)
status_list <- rep(NA, 10000)

i = 1
for (country in countries) {
  #Load data for that country
  print(country)
  surveys <- list.files(path = country, recursive = FALSE, pattern = "\\.sav$", ignore.case = TRUE)
  #Load
  country_surveys = new("country_surveys")
  for (survey_name in surveys){
    results <- tryCatch({
      print (survey_name)
      survey_type = unname(parse_name(survey_name)[2])
      if (survey_type %in% c("MR","IR","HR")){
        survey = load_data(paste(country,survey_name, sep="/"))
        print(survey@survey_type)
        survey = create_merge_id(survey)
        print("...Loaded")
        if(length(unique(survey@data$merge_id)) == nrow(survey@data)){
          print("...... merge ID is unique")
          #Updating stats
          file_list[i] =  survey_name
          year_list[i] = survey@data
          type_list[i] = survey@survey_type
          country_list[i] = survey@country
          status_list[i] = 1
          
        } else{
          print(paste("...... merge ID is NOT unique:", nrow(survey@data), "rows but", length(unique(survey@data$merge_id)), "unique IDs"))
          #Updating stats
          file_list[i] =  survey_name
          year_list[i] = survey@data
          type_list[i] = survey@survey_type
          country_list[i] = survey@country
          status_list[i] = 1
        }
      }
      else{
        print(paste("...Skipped ",survey_name, " of type ", survey_type))
      }
      i = i + 1  
      }, warning = function(war) {
        print(war)
      }, error = function(err) {
        print(err)
      }, finally = {
      })#end of trycatch
  } 
}



# if(!is.null(data)){
#   if(out@survey_type =="HR"){
#     country_survey@hr = data
#   } else if (out@survey_type =="IR"){
#     country_survey@ir = data
#   } else if (out@survey_type =="MR"){
#     country_survey@mr = data
#   } else{
#     stop(paste("Incorrect survey_type value",survey_data@survey_type))
#   }
# }

# Tests ------

test = FALSE

if(test){
  
  
}



# Old - recycle to do tests ------

