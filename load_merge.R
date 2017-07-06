
# install.packages("foreign")
# if (!require("devtools")) install.packages("devtools")
# devtools::install_github("mkuhn/dict")

#Run this the first time
#install.packages("foreign")
#install.packages("tidyverse")
#install.packages("devtools")
#devtools::install_github('tidyverse/dplyr')

library(devtools)
library(foreign)
library(tidyr)
library(dplyr)
library(data.table)


# Class definitions ---------------------------------------------------------------------
#SPSS read wrapper - deals with multiple factor levels

#Contains a survey's data and metadata
setClass("survey_data", slots=list(start_year="numeric",survey_type="character", col_codes = "character", col_names="character", country="character", data="data.frame"))

setClassUnion("survey_data_u", c("survey_data", "NULL"))

#Contains all survey_data for a country and year
setClass("country_surveys", representation(ir="survey_data_u", mr ="survey_data_u", hr="survey_data_u"), prototype(ir = NULL, mr = NULL, hr = NULL))



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
  if (verbose){
    print(paste("...Loading ",path))
  }
  list_data <- read.spss_wrapper(path,verbose)
  # convert list to data frame
  survey_data <- as.data.frame(list_data)
  # copy all variable (column) labels in separated list
  names_survey <- attr(list_data, "variable.labels")
  metadata <- parse_name(path)
  out <- new("survey_data",survey_type=unlist(unname(metadata["type"])), country=unlist(unname(metadata["country"])), col_codes = colnames(survey_data), col_names=names_survey, data=survey_data)
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
  if(!is.null(country_surveys@hr) && !is.null(country_surveys@mr)  && !is.null(country_surveys@ir)){
    return(TRUE)
  } else{
    return(FALSE)
  }
}

# 
# is_complete <- function(country_surveys){
#   if(!is.null(country_surveys@hr) && !is.null(country_surveys@mr)  && !is.null(country_surveys@ir)){
#     return("COMPLETE")
#   } else if(!is.null(country_surveys@hr) && !is.null(country_surveys@ir)){
#     return("IR")
#   } else if(!is.null(country_surveys@hr) && !is.null(country_surveys@mr)) {
#     return("MR")
#   } else{
#     return(FALSE)
#   }
# }

#Flip names of a specific survey_data fied in a country_survey
#The column names that were not in the original data (eg: merge_id) are unchanged
flip_names<-function(country_survey,field){
  if(field == "HR"){
    df = country_survey@hr@data
    setnames(df,old = country_survey@hr@col_codes, new = country_survey@hr@col_names )
    country_survey@hr@data = df
  }else if(field == "IR"){
    df = country_survey@ir@data
    setnames(df,old = country_survey@ir@col_codes, new = country_survey@ir@col_names )
    country_survey@ir@data = df
  }else if(field == "MR"){
    df = country_survey@mr@data
    setnames(df,old = country_survey@mr@col_codes, new = country_survey@mr@col_names )
    country_survey@mr@data = df
  } else{
    stop("Invalid type")
  }
  return(country_survey)
}



# Function definition for "sliding" columns -----

name_match <-function(df,i,j){
  #whatever rule we need
  names_df = names(df)
  transf1 = function(x){return(tolower(sub("_","",sub(" ","",x))))}
  transf2 = function(x){sub("_ir","",sub("_mr","",x))}
  
  name1 = transf1(transf2(names_df[i]))
  name2 = transf1(transf2(names_df[j]))
  
  is_match = name1 == name2
  return(is_match)
}


#This function "slides" dataframe blocks based on NA values
#Takes a dataframe and two column names
#On each row, one of these columns have to be NA
#The function returns a dataframe with a new column called <newname> with the combined non NA values of the first columns
#Different factor levels in both columns are dealt with by casting to character, then back to factor after the merge
#If newname is not specified, the first columns is overriden by the new column
#Optionnal parameters allows to drop the old columns
#There is no "safety" here in the sense that if both columns are non NA, the second one will be overidden

merge_cols <- function(df,name1,name2,newname = NULL, drop = FALSE){
  require(dplyr)
  if(packageVersion("dplyr") < "0.7.0") {
    stop("Need touse dplyr 0.7.0, currently in dev_mode. Use devtools::install_github('tidyverse/dplyr') ")
  }
  if(is.null(newname)){
    newname = name1
  }
  #Factor data needs to be converted to characters first in order no to lose levels
  if(is.factor(df[,name1]) || is.factor(df[,name2])){
    df[,name1] <- as.character(df[,name1])
    df[,name2] <- as.character(df[,name2])
  }
  
  slided_df = dplyr::mutate(df, !!newname := ifelse(is.na(df[,name1]),df[,name2],df[,name1]))
  
  #If factor data, we need to cast character back to factor data
  # if(is.factor(df[,name1]) || is.factor(df[,name2])){
  #  df[,newname] <- as.factor(df[,newname])
  # }
  
  if(drop){
    if(is.null(newname)){
      slided_df[,name1] <- NULL #dropping i only if a newname was specified, otherwise it contains the result
    }
    slided_df[,name2] <- NULL #dropping name_j
  }
  return(slided_df)
}

#returns list of names columns to slide from df
get_slide_list<-function(df){
  i = 1
  name_couples <- data.frame(i=NA,j=NA)
  df_names = names(df)
  while(i<=ncol(df)){
    j = i+1
    while(j<=ncol(df)){
      if(name_match(df,i,j)){
        name_couples <- rbind(name_couples,c(df_names[i],df_names[j]))
        j = j+1
      }
      j = j+1
    }
    i = i+1
  }
  return(tail(name_couples,-1)) #return the df but not the row that was used to initialize
}

slide_all <- function(df,slide_list){
  print(slide_list)
  for(i in 1:nrow(slide_list)){
    result = tryCatch({
      df = merge_cols(df,name1=slide_list[i,1],name2=slide_list[i,2],drop=TRUE)
    }, warning = function(w) {},
    error = function(e) {
      print(e)
    }, finally = {})
  }
  return(df)
}





# Go through all files, read spss and attempt a merge-------

main <-function(){
    
    
    #Malo @local
    working_dir = "~/Documents/Projects/HIV-xwas/shared_with_desktop"
    #Malo @server
    working_dir ="D:/Huwenjie/DHS_Data/DHS_live"
    
    setwd(working_dir)
    
    
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
        country_surveys = new("country_surveys")
        for(survey_folder in survey_folders){
          path = paste(country,survey_session,survey_folder,sep="/")
          surveys <- list.files(path = path, recursive = FALSE, pattern = "\\.sav$", ignore.case = TRUE)
          #Load
          for (survey_name in surveys){
            results <- tryCatch({
              print(paste("survey name:",survey_name))
              survey_type = unname(parse_name(survey_name)[2])
              if (survey_type %in% c("MR","IR","HR")){
                # print(paste(path,survey_name, sep="/"))
                print(paste("file_path:", paste(path,survey_name, sep="/")))
                survey = load_data(paste(path,survey_name, sep="/"), verbose = FALSE)
                print(survey@survey_type)
                survey = create_merge_id(survey)
                print("...Loaded")
                if(survey_type =="HR" && length(unique(survey@data$merge_id)) == nrow(survey@data)){
                  
                  print("...... merge ID is unique")
                  print("")
                  #Updating stats
                  file_list[i] =  survey_name
                  year_list[i] = survey@start_year
                  type_list[i] = survey@survey_type
                  country_list[i] = survey@country
                  status_list[i] = 1
                  #Insert into country surveys
                  
                  country_surveys = insert_into_country_surveys(country_surveys,survey,survey_type)
                  
                } else if(survey_type %in% c("IR","MR")){
                  print("...Inserting an MR / IR")
                  file_list[i] =  survey_name
                  year_list[i] = survey@start_year
                  type_list[i] = survey@survey_type
                  country_list[i] = survey@country
                  status_list[i] = 1
                  country_surveys = insert_into_country_surveys(country_surveys,survey,survey_type)
                  
                }else{
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
              } else{
                print(paste("...Skipped ",survey_name, " of type ", survey_type))
              }
              i = i + 1  
            }, warning = function(war) {
              print(war)
              log_str = paste(log_str,war,"\n", sep="")
            }, error = function(err) {
              print(err)
            }, finally = {
            })#end of trycatch
          } 
        }
        print(paste("Read, is it complete",is_complete(country_surveys)))
        #Check if we can merge and if so merge
        if(is_complete(country_surveys)){
          print(".........Complete")
          
          #Renaming before losing that data in merge.
          #We should store the short names, maybe in a dictionnary (see dict package)
          country_surveys = flip_names(country_surveys,"HR")
          country_surveys = flip_names(country_surveys,"IR")
          country_surveys = flip_names(country_surveys,"MR")
            
            
          #Merge 
          merged_mr = merge(country_surveys@hr@data,country_surveys@mr@data,by="merge_id",suffixes = c("","_mr") )
          merged_ir= merge(country_surveys@hr@data,country_surveys@ir@data,by="merge_id",suffixes = c("","_ir") )
          
          # merged_mr[sapply(merged_mr, is.character)] <- lapply(merged_mr[sapply(merged_mr, is.character)], as.factor)
          # merged_ir[sapply(merged_ir, is.character)] <- lapply(merged_ir[sapply(merged_ir, is.character)], as.factor)
          # 
          View(merged_mr)
          View(merged_ir)
          #Clearing memory
          rm(country_surveys)
          
          #Stack
          merged = dplyr::bind_rows(merged_mr,merged_ir)
          #merged = rbind(merged_mr,merged_ir)
          
          print(ncol(merged))
          #Slide columns with NAs
          merged = slide_all(merged,get_slide_list(merged))
          print(ncol(merged))
          #Save
          write.csv(merged, file = paste("../merged/",gsub("/","_",survey_folder)))
        }
      }
    }
}
#Here we would merge for a country (or that can be done in another step because fitting all the data of a country in memory is probably impossible)


# Stats --------

get_stats < function(){
  stats = data.frame(file = file_list, year = year_list, type = type_list, country = country_list, unique_ID = status_list)
  stats = na.omit(stats)
  View(stats)
  
  #Stats by year
  View(stats %>% dplyr::group_by(year,unique_ID) %>% dplyr::summarize(count = n()))
  
  
  #Stats by country
  View(stats %>% dplyr::group_by(country,unique_ID) %>% dplyr::summarize(count = n()))
  
  
  #Stats overall
  View(stats %>% dplyr::group_by(unique_ID) %>% dplyr::summarize(count = n()))
  
  
  #write.table(stats,"saved_stats.csv")
}


# Tests ------


go_test <-function(){
  
  #Small cosmetic help
  print_test <- function(...){
    print(paste(..., collapse=""))
  }
  
  print("testing:")
  
  #Testing classes
    print("... testing classes")
    country_surveys = new("country_surveys")
    country_surveys@ir = NULL #Should no return error
    print("... passed")
  
  #Malo @local
  working_dir = "~/Documents/Projects/HIV-xwas/shared_with_desktop"
  #Malo @server
  working_dir ="D:/Huwenjie/DHS_Data/DHS_live"
  
  setwd(working_dir)
  
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
    d = create_merge_id(d)
    country_surveys = insert_into_country_surveys(country_surveys,d,"HR")
    print(country_surveys@hr@start_year == 1994)
  
  #testing is_complete
    print("...testing is_complete")
    country_surveys = insert_into_country_surveys(country_surveys,d,"MR")
    print(is_complete(country_surveys)==FALSE)
    country_surveys = insert_into_country_surveys(country_surveys,d,"IR")
    print(is_complete(country_surveys))
    
   
  
    
  #Testing flip_names 
    print("...testing flip_names")
    n = ncol(country_surveys@mr@data)
    original_df = country_surveys@mr@data
    country_surveys = flip_names(country_surveys,"MR")
    #Flip_names should not drop any columns
    print(ncol(country_surveys@mr@data) == n)
    print(mean(country_surveys@mr@data$merge_id == original_df$merge_id))
    print_test(paste("......merged_ids match:",mean(country_surveys@mr@data$merge_id == original_df$merge_id))==1)
    
  #Testing  name_match
    print("... testing name_match")
    df <- data.frame(a=1,b=2,c=3,d=4)
    names(df) <- c("name 1_ir","NAME","name","name_1_mr")
    print(name_match(df,1,4))
    print(name_match(df,2,3))
    
  
  
  #Test merge
    # print("Testting merge...")
    # country_surveys = new("country_surveys")
    # 
    # path = "Zimbabwe/Standard DHS 1994/ZWHR31SV/ZWHR31FL.SAV"
    # d = load_data(path)
    # country_surveys = insert_into_country_surveys(country_surveys,d,"HR")
    # 
    # path = "Zimbabwe/Standard DHS 1994/ZWIR31SV/ZWIR31FL.SAV"
    # d = load_data(path)
    # country_surveys = insert_into_country_surveys(country_surveys,d,"IR")
    # 
    # path = "Zimbabwe/Standard DHS 1994/ZWMR31SV/ZWMR31FL.SAV"
    # d = load_data(path)
    # country_surveys = insert_into_country_surveys(country_surveys,d,"MR")
    # 
    # nhr = ncol(country_surveys@hr@data)
    # nir = ncol(country_surveys@ir@data)
    # nmr = ncol(country_surveys@mr@data)
    # 
    # #Output of a merge should not generate duplicate columns
    # country_surveys = flip_names(country_surveys,"HR")
    # country_surveys = flip_names(country_surveys,"IR")
    # country_surveys = flip_names(country_surveys,"MR")
    # #Merge 
    # merged_mr = c(country_surveys@hr@data,country_surveys@mr@data,by="merge_id",suffixes = c("","_mr") )
    # 
    # #Testing will have to wait that we have a unique ID
    # merged = dplyr::bind_rows(merged_mr,merged_ir)
    # 
    # print(ncol(merged) <= nhr + nir+ nmr)
}

main()
go_test()






