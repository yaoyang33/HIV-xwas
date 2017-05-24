 
# ###############################################################

rm(list=ls())
library(foreign)
library(readstata13)

# start in the DHS file

setwd("~/Google Drive/HIV Big Data")

lkf <- function(d,p) names(d)[grep(p,names(d))]
df <- data.frame()
countries <- list.files(recursive = FALSE)

# Check depth 1 - name of country 
#for (country in countries) {
 # print(country)
	# starting from the root directory, go to the next country
	#setwd(paste("C:/Users/Tara/Documents/Projects/DHS/",country,"/", sep=""))
	# get the list of survey names 
	#surveys<- list.files(recursive = FALSE)
	# Check depth 2 - survey names -> want Standard DHS and > 1 year
	#for (survey in surveys) {
	 # print(survey)
	  #path = paste("C:/Users/Tara/Documents/Projects/DHS/",country,"/",survey, sep="")
		#setwd(path)
		# Check depth 3 - pick up the individual recode RDA file
		#rdas<- list.files(pattern = c("kr[0-9A-Za-z][0-9A-Za-z]sv.rda$"), recursive = FALSE)
	#	for (rda in rdas) {
	#	  load(rda)
	#	  path = paste("C:/Users/Tara/Documents/Projects/DHS/",
	#	               country,
	#	               "/",
	#	               survey,
	#	               "/",
	#	               rda,
	#	               sep="")
	#	  f <- names(x)
	#	  # get the metadata info
	#	  keep <- cbind(rep(as.character(country),length(f)),
	#	                rep(as.character(survey),length(f)), 
	#	                f,
	#	                attributes(x)$variable.labels,
	#	                rep(as.character(path),length(f)))
	#	  df <- rbind(df, keep)
	#	}
	#}
#}

          
#write.csv(df, "C:/Users/Tara/Documents/Projects/meta_DHSes_kr.csv")
#write.csv(df)

data<-read.spss("ZZBR62FL.SAV")
labels <- attr(data, "variable.labels")
labels <- as.data.frame(labels)
labels
