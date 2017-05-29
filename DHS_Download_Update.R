# analyze survey data for free (http://asdfree.com) with the r language
# demographic and health surveys
# all available years
# all approved countries

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# your.username <- "username"
# your.password <- "password"
# your.project <- "project"
# library(downloader)
# setwd( "C:/My Directory/DHS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Demographic%20and%20Health%20Surveys/download%20and%20import.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


####################################################################################
# download every file from every year of the Demographic and Health Surveys with R #
# then save every file as an R data frame (.rda) so future analyses can be rapid   #
####################################################################################


# # # # # # # # # # # # # #
# important user warning! #
# # # # # # # # # # # # # #

# you *must* visit this dhsprogram.com website and explain your research
# before receiving a username and password.

# this is to protect both yourself and the respondents of the study.  register here:
# http://dhsprogram.com/data/Access-Instructions.cfm

# once you have registered, place your username, password, and the name of your project in the script below.
# this script will not run until valid values are included in the lines below.
# oh and don't forget to uncomment these lines by removing the `#`

datatype <- "(DT|FL|SV).ZIP"
tabletype <- "Filename=..(HR|IR|MR|AR|PR|GE)"
your.project <- "Regional variation in HIV support"

# set the directory for downloaded data
setwd( "/Users/timhu/Dropbox/Stanford/career/HIV-RA/HIV-RProject/DHS_Data" )
# dir.archive <- "/Users/timhu/Dropbox/Stanford/career/HIV-RA/HIV-RProject/DHS_archive/"
dir.archive <- "/Volumes/Seagate Backup Plus Drive/DHS_Data/DHS_archive/"
# dir.live <- "/Users/timhu/Dropbox/Stanford/career/HIV-RA/HIV-RProject/DHS_live/"
dir.live <- "/Volumes/Seagate Backup Plus Drive/DHS_data/DHS_live/"

# this massive ftp download automation script will not work without the above lines filled in.
# if the three lines above are not filled in with the details you provided at registration, 
# the script is going to break.  to repeat.  register to access dhs data.


# # # # # # # # # # # # # # # # # 
# end of important user warning #
# # # # # # # # # # # # # # # # #


# set your working directory.
# all DHS data files will be stored here
# after downloading.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..

# ..in order to set your current working directory



# remove the # in order to run this install.packages line only once
# install.packages( c( "XML" , "httr" ) )

# no need to edit anything below this line #


# # # # # # # # #
# program start #
# # # # # # # # #


library(foreign) 	# load foreign package (converts data files into R)
library(httr)		# load httr package (downloads files from the web, with SSL and cookies)
library(XML)		# load XML (parses through html code to extract links)
library(readstata13) # load readstata13 package to support Stata format after 12
# library(tidyverse)


# authentication page
terms <- "https://dhsprogram.com/data/dataset_admin/login_main.cfm"

# countries page
countries.page <- "https://dhsprogram.com/data/dataset_admin/download-datasets.cfm"

# create a temporary file and temporary directory
tf <- tempfile() ; td <- tempdir()

# login to DHS with authentication
while (TRUE) {
  your.username <- readline("Please Enter your DHS username(Email): ")
  your.password <- readline("Please Enter your DHS password: ")
  values <- 
    list( 
      UserName = your.username , 
      UserPass = your.password ,
      Submitted = 1 ,
      UserType = 2
    )
  GET( terms , query = values )
  auth_post <- POST( terms , body = values )
  if (auth_post$all_headers[[2]]$status == 302) {
    print("Successfully log in to DHS!")
    break
  } else {
    print("Incorrect email address and/or password. Please try again.")
  }
}

# extract the available countries from the projects page
z <- GET( countries.page )

# write the information from the `projects` page to a local file
writeBin( z$content , tf )

# load the text 
y <- readLines( tf )

# figure out the project number
project.line <- unique( y[ grep( paste0( "option value(.*)" , your.project ) , y ) ] )

# confirm only one project
stopifnot( length( project.line ) == 1 ) 

# extract the project number from the line above
project.number <- gsub( "(.*)<option value=\"([0-9]*)\">(.*)" , "\\2" , project.line )

# log in again, but specifically with the project number
values <- 
	list( 
		UserName = your.username , 
		UserPass = your.password ,
		proj_id = project.number
	)

# re-access the download-datasets page
z <- 
	POST( 
		"https://dhsprogram.com/data/dataset_admin/download-datasets.cfm" , 
		body = list( proj_id = project.number ) 
	)
print(paste0("Log in with project: ", your.project))

# write the information from the `countries` page to a local file
writeBin( z$content , tf )

# load the text 
y <- readLines( tf )

# figure out the country lines
country_lines <- unique( grep( 'notranslate' , y , value = TRUE ) )

# figure out which countries are available for download
country.names <- gsub( "(.*)>(.*)<(.*)" , "\\2" , country_lines )
country.numbers <- gsub( '(.*)value = \"(.*)\"(.*)' , "\\2" , country_lines )


# loop through each available country #
for ( j in seq( length( country.numbers ) ) ){

	# extract the current country number..
	this.number <- country.numbers[ j ]
	# ..and current country name
	this.name <- country.names[ j ] 
	
	print(paste0("Fetching data for country: ", this.name, "..."))

	# create the country directory on the local disk
	if (!dir.exists(paste0( dir.archive, this.name ))) {
	  dir.create( paste0( dir.archive, this.name ) )
	}
	if (!dir.exists(paste0( dir.live, this.name ))) {
	  dir.create( paste0( dir.live, this.name ) )
  }
	# create a website key pointing the specific country
	values <- 
		list( 
			proj_id = project.number ,
			Apr_Ctry_list_id = this.number ,
			submitted = 2 ,
			action = "View Surveys" ,
			submit = "View Surveys"
		)

	# re-access the download data page
	# using the new country-specific key
	z <- 
		POST( 
			"https://dhsprogram.com/data/dataset_admin/download-datasets.cfm" , 
			body = values 
		)
		
	# pull all links
	link.urls <- xpathSApply( htmlParse(z) , "//a" , xmlGetAttr , "href" )

	# extract all links containing the current country's name
	valid.surveys <- grep( "?flag=1" , link.urls )
	link.urls <- unlist( link.urls [ valid.surveys ] )
	
	# loop through each available data set within the country #
	for ( this.link in link.urls ){

		# access each dataset's link
		z <- GET( paste0( "https://dhsprogram.com" , this.link ) )

		writeBin( z$content , tf )
		
		# read the table from each country page, remove the country name, and remove extraneous characters
		this.title <- gsub( ": |," , "" , gsub( this.name , "" , gsub( '(.*)surveyTitle\">(.*)<(.*)' , "\\2" , grep( 'surveyTitle\">' , readLines( tf ) , value = TRUE ) ) ) )


		# store all dataset-specific links
		all.links <- xpathSApply( htmlParse( z ) , "//div//a" , xmlGetAttr , "href" )

		# keep only /data/dataset/ links
		data.link <- unique( all.links[ grepl( "customcf/legacy/data/download_dataset" , all.links ) ] )
    
		# select data type to download. "datatype" was specified at the beginning.
		select.datatype <- grep( datatype , data.link, ignore.case = TRUE) 
		archive.links <- unlist( data.link[ select.datatype ] )
		this_dir_archive <- paste0( dir.archive , this.name , "/" , this.title )
		if (!dir.exists(this_dir_archive)) {
		  dir.create(this_dir_archive)
		}
		# check whether the zips in url already exist in the folder, only download additional ones.
		this_archive_zips <-  list.files(this_dir_archive, pattern = ".(zip|ZIP)")
		url_archive_zips <- gsub( "(.*)Filename=(.*)\\.(ZIP|zip)(.*)" , "\\2.zip" , archive.links)
		archive.links <- archive.links[!url_archive_zips %in% this_archive_zips]
		if (length(archive.links) == 0) {next}
		
		# select table type to download for live directory. "tabletype" was specified at the beginning.
		select.tabletype <- grep( tabletype , archive.links, ignore.case = TRUE)
		live.links <-  unlist(archive.links[ select.tabletype ] )
		
		if (length(live.links) != 0) {
		  this_dir_live <- paste0( dir.live , this.name , "/" , this.title )
		  if (!dir.exists(this_dir_live)) {
		    dir.create(this_dir_live)
		  }
		  this_live_zips <- list.files(this_dir_live, pattern = ".(zip|ZIP)")
		  url_live_zips <- gsub( "(.*)Filename=(.*)\\.(ZIP|zip)(.*)" , "\\2.zip" , live.links)
		  
		  # check whether the new version exists in url, if so, remove old files
		  this_zips_check <- gsub("(\\d)(\\d)" , "\\1" , this_live_zips)
		  url_zips_check <- gsub("(\\d)(\\d)" , "\\1" , url_live_zips)
		  
		  # determine the zips and directory to remove for update
		  this_zips_remove <- this_live_zips[this_zips_check %in% url_zips_check]
		  directory_remove <- gsub( "\\.zip" , "" , this_zips_remove)
		  
		  # remove zip and directory to be updated
		  file.remove(paste0(this_dir_live, "/", this_zips_remove))
		  unlink(paste0(this_dir_live, "/", directory_remove), recursive = TRUE, force = FALSE) 
		}
		
		

		for( file.url in archive.links ){
			
			# maintain the zipped filename
		  zipname <- gsub( "(.*)Filename=(.*)\\.(ZIP|zip)(.*)" , "\\2.zip" , file.url )
			zfn <- paste0( this_dir_archive , "/" ,  zipname)
			print(paste0("Downloading ", zipname, "in ", this.title, "..."))
			
			# download the actual microdata file directly to disk
			# don't read it into memory.  save it as `tf` immediately (RAM-free)
			attempt <- try( { current.file <- GET( paste0( "https://dhsprogram.com" , file.url ) , write_disk( zfn , overwrite = TRUE ) , progress() ) } , silent = TRUE )
			
			# if first download didn't work, try again.
			if( class( attempt ) == 'try-error' ){
				Sys.sleep( 60 )
				current.file <- GET( paste0( "https://dhsprogram.com" , file.url ) , write_disk( zfn , overwrite = TRUE ) , progress() )
			}
			
			# make sure the file-specific folder exists
			dir.create( gsub( "\\.zip" , "" , zfn ) , showWarnings = FALSE )
			
			# unzip the contents of the zipped file
			z <- unzip( zfn , exdir = gsub( "\\.zip" , "" , zfn ) )
			
			# if the file is also in live url list, copy and unzip in live folder.
			if (file.url %in% live.links) {
			  file.copy(zfn, this_dir_live)
			  zfn_live <- paste0(this_dir_live, "/", zipname)
			  dir.create( gsub( "\\.zip" , "" , zfn_live ) , showWarnings = FALSE )
			  unzip( zfn_live , exdir = gsub( "\\.zip" , "" , zfn_live ) )
			}
		}
		
		

			# # figure out the correct location for the csv (the original version use rda output format)
			# csv_name <- tolower( paste0( gsub( "\\.zip" , ".csv" , zfn ) ) )
			# 
			# # and now, if there's a stata file, import it!
			# if ( any( st <- grepl( "\\.dta$" , tolower( z ) ) ) ){
			# 	
			# 	# remove any prior `x` tables ; clear up RAM
			# 	rm( x ) ; gc()
			# 	
			# 	# load the current stata file into working memory
			# 	x <- read.dta13( z[ which( st ) ], convert.factors = TRUE, generate.factors = TRUE)
			# 
			# 	# save the file on the local disk, within the appropriate country-survey filepath
			# 	    # save( x , file = rda_name )
			# 	write_csv(x, path = csv_name)
			# 	
			# }

			# # if a file has not been saved as an rda yet,
			# # look for an spss file as well.  this way, stata always takes priority.
			# if ( !file.exists( rda_name ) ){
			# 
			# 	# if there's any spss file, import it!
			# 	if ( any( st <- grepl( "\\.sav$" , tolower( z ) ) ) ){
			# 		
			# 		# remove any prior `x` tables ; clear up RAM
			# 		rm( x ) ; gc()
			# 	
			# 		# load the current stata file into working memory
			# 		x <- read.spss( z[ which( st ) ] , to.data.frame = TRUE , use.value.labels = FALSE )
			# 	
			# 		# save the file on the local disk, within the appropriate country-survey filepath
			# 		save( x , file = rda_name )
			# 		
			# 	}
			# }
			
		
	}
}


# delete the temporary file..
file.remove( tf )

# ..and temporary directory on the local disk
unlink( td , recursive = TRUE )

# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done. you should set the folder " , getwd() , " read-only so you don't accidentally alter these tables." ) )

