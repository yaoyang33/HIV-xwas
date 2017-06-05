
# install.packages("foreign")
# if (!require("devtools")) install.packages("devtools")
# devtools::install_github("mkuhn/dict")


#install.packages("foreign")
#install.packages("tidyverse")

library(foreign)
# library(dict)
library(tidyr)


#Done:
#fix stata extraction
#fix year extraction
#create stats for ID uniqueness


#TODO: merge startegy
### if the character names match, merge using that
### otherwise, merge with codes
### otherwise: fix


#Output: one table, individual level. + one dict of names for the column names.

#Use cases:
# ML use case -> columnar
# Other -> mongo db? simple db?


# Class definitions ---------------------------------------------------------------------
#SPSS read wrapper - deals with multiple factor levels

#Contains a survey's data and metadata
setClass("survey_data", slots=list(start_year="numeric",survey_type="character", col_names="character", country="character", data="data.frame"))

setClassUnion("survey_data_u", c("survey_data_base", "NULL"))

#Contains all survey_data for a country and year
setClass("country_surveys", representation(ir="survey_data", mr ="survey_data", hr="survey_data"), prototype(ir = NULL, mr = NULL, hr = NULL))


# Function definitions - data load ---------------------------------------------------------------------
#SPSS read wrapper - deals with multiple factor levels

read.spss_wrapper <- function (path, verbose = FALSE){
  list_data <- read.spss(path, to.data.frame=FALSE, use.value.labels=FALSE)
  #list_data <- read.sav(path, to.data.frame=FALSE, use.value.labels=TRUE)
  l1 = length(list_data)
  indx <- sapply(list_data, is.factor)
  list_data[indx] <- lapply(list_data[indx], function(x) {
    levels(x) <- make.unique(levels(x))
    x })
  l2 = length(list_data)
  if(verbose && l1 != l2){
    print("Warning in read.spss_wrapper: unique list is not the same length as original list")
  }
  
  return(list_data)
}


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

#Takesinput a year in numerical format and outputs the yar in a 4 letter formatss
reformat_year <- function(year){
  if(year < 0){
    return(-1)
  } else if(year <17){#not very clean but there really is no safe way around this except changing the input files
    return(2000 + year)
  } else if( year <100){
    return(1900 + year)
  } else{#year is already in a 4 letter format
    return(year)
  }
}

get_start_year <- function(df, survey_type){
  if(survey_type == "HR"){
    return(reformat_year(min(df$"HV007")))
  }
  else if (survey_type == "IR"){
    return(reformat_year(min(df$"V007")))
  }
  else if (survey_type == "MR") {
    return(reformat_year(min(df$"MV007")))
  }
  else(
    return(-1)
  )
}

#Reads a spss file located at path and returns a survey_data object

load_data <- function(path, verbose=FALSE){
  print(paste("...Loading ",path))
  list_data <- read.spss_wrapper(path,verbose)
  # convert list to data frame
  survey_data <- as.data.frame(list_data)
  # copy all variable (column) labels in separated list
  names_survey <- attr(list_data, "variable.labels")
  metadata <- parse_name(path)
  out <- new("survey_data",survey_type=unlist(unname(metadata["type"])), country=unlist(unname(metadata["country"])), col_names=names_survey, data=survey_data)
  year = get_start_year(out@data, out@survey_type)
  out@start_year = year
  return(out)
}  


# Function definition - merge -------


#Takes a survey_data object and creates a new colum with a merge_id

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

#Takes a survey_data object and inserts it into a country_surveys object
insert_into_country_surveys <- function(country_surveys,survey,survey_type){
  if(survey_type == "HR"){
    country_surveys@hr = survey
  } else if(survey_type == "IR"){
    country_surveys@ir = survey
  } else if(survey_type == "MR"){
    country_surveys@mr = survey
  } else{
    stop("Undefined survey type")
  }
  return(country_surveys)
}

#Takes a survey_type object and returns whether all three surveys contain data.
#That will enable us to decide if we can proceed to the merge
is_complete <- function(country_surveys){
  return(!is.null(country_surveys@hr) && !is.null(country_surveys@mr) && !is.null(country_surveys@ir))
}


# Go through all files, read spss and attempt a merge-------

#Malo @local
working_dir = "~/Documents/Projects/HIV-xwas/shared_with_desktop"
#Malo @server
working_dir ="D:/Huwenjie/DHS_Data/DHS_live"

setwd(working_dir)



#lkf <- function(d,p) names(d)[grep(p,names(d))]
#df <- data.frame()
countries <- list.files(recursive = FALSE)

#This will be used to count the files and generate some stats
file_list <- rep(NA,10000)
year_list <- rep(NA,10000)
type_list <- rep(NA,10000)
country_list <- rep(NA,10000)
status_list <- rep(NA, 10000)
survey_folder_list <- rep(NA, 10000)

log_str = ""

i = 1
for (country in countries) {
  #Load data for that country
  print(country)
  survey_sessions = list.dirs(path = country, recursive = FALSE,full.names = FALSE)
  for(survey_session in survey_sessions){
    print(paste("survey_session",survey_sessions,sep=":"))
    survey_folders = list.dirs(path = paste(country,survey_session,sep="/"), recursive = FALSE,full.names = FALSE)
    for(survey_folder in survey_folders){
      path = paste(country,survey_session,survey_folder,sep="/")
      surveys <- list.files(path = path, recursive = FALSE, pattern = "\\.sav$", ignore.case = TRUE)
      #Load
      country_surveys = new("country_surveys")
      for (survey_name in surveys){
        results <- tryCatch({
          print (survey_name)
          survey_type = unname(parse_name(survey_name)[2])
          if (survey_type %in% c("MR","IR","HR")){
            print(paste(path,survey_name, sep="/"))
            print(paste("file_path:", paste(path,survey_name, sep="/")))
            survey = load_data(paste(path,survey_name, sep="/"), verbose = TRUE)
            print(survey@survey_type)
            survey = create_merge_id(survey)
            print("...Loaded")
            if(length(unique(survey@data$merge_id)) == nrow(survey@data)){
              
              print("...... merge ID is unique")
              print("")
              #Updating stats
              file_list[i] =  survey_name
              year_list[i] = survey@start_year
              type_list[i] = survey@survey_type
              country_list[i] = survey@country
              status_list[i] = 1
              #Insert into country surveyss
              country_surveys = insert_into_country_surveys(country_surveys,survey,survey_type)
              
            } else{
              print(paste("...... merge ID is NOT unique:", nrow(survey@data), "rows but", length(unique(survey@data$merge_id)), "unique IDs"))
              print("")
              #Updating stats
              file_list[i] =  survey_name
              year_list[i] = survey@start_year
              type_list[i] = survey@survey_type
              country_list[i] = survey@country
              status_list[i] = 0
              survey_folder_list[i] = gsub("/","_",survey_folder)
            }
          }
          else{
            print(paste("...Skipped ",survey_name, " of type ", survey_type))
          }
          i = i + 1  
        }, warning = function(war) {
          log_str = paste(log_str,war,"\n", sep="")
        }, error = function(err) {
          print(err)
        }, finally = {
        })#end of trycatch
      } 
      #Check if we can merge and if so merge
      if(is_complete(country_surveys)){
        #Merge
        merged_mr = merge(country_surveys@hr@data,country_surveys@mr@data,by="merge_id")
        merged_ir= merge(country_surveys@hr@data,country_surveys@ir@data,by="merge_id")
        
        rm(country_surveys)
        #Stack
        merged = bind_rows(merged_mr,merged_ir)
        #Save
        write.csv(merged, file = paste("../merged/",gsub("/","_",survey_folder)))
      }
    }
  }
}
#Here we would merge for a country (or that can be done in another step because fitting all the data of a country in memory is probably impossible)



stats = data.frame(file = file_list, year = year_list, type = type_list, country = country_list, unique_ID = status_list)
stats = na.omit(stats)
View(stats)

#Stats by year
View(stats %>% dplyr::group_by(year,unique_ID) %>% dplyr::summarize(count = n()))


#Stats by country
View(stats %>% dplyr::group_by(country,unique_ID) %>% dplyr::summarize(count = n()))


#Stats overall
View(stats %>% dplyr::group_by(unique_ID) %>% dplyr::summarize(count = n()))




# Tests ------

test = TRUE

if(test){
  print("testing:")
  
  #Malo @local
  working_dir = "~/Documents/Projects/HIV-xwas/shared_with_desktop"
  #Malo @server
  working_dir ="D:/Huwenjie/DHS_Data/DHS_live"
  
  setwd(working_dir)
  
  print("...testing classes")
  
  
  #testing reformat_year
  print("...testing reformat_year")
  print(reformat_year(1992) == 1992)
  print(reformat_year(2005) == 2005)
  print(reformat_year(20) == 1920)
  print(reformat_year(00) == 2000)
  print(reformat_year(96) == 1996)
  
  
  path = "Zimbabwe/Standard DHS 1994/ZWHR31SV/ZWHR31FL.SAV"
  demoDf = read.spss_wrapper(path, verbose = TRUE)
  
  
  #testing get_start_year
  print("...testing get_start_year")
  print(reformat_year(get_start_year(demoDf,"HR")) == 1994)
  
  #testing insert_into_country_surveys
  print("...testing insert_into_country_surveys")
  country_surveys = new("country_surveys")
  path = "Zimbabwe/Standard DHS 1994/ZWHR31SV/ZWHR31FL.SAV"
  d = load_data(path)
  country_surveys = insert_into_country_surveys(country_surveys,d,"HR")
  print(country_surveys@hr@start_year == 1994)
  
  #testing is_complete
  country_surveys = insert_into_country_surveys(country_surveys,d,"MR")
  print(!is_complete(country_surveys))#should be TRUE
  country_surveys = insert_into_country_surveys(country_surveys,d,"IR")
  print(is_complete(country_surveys))#should be TRUE
  
}






