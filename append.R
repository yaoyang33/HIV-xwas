# append country surveys
## test on ALPR50SV and TDPR41SV

##uncomment this when first run
#install.packages("dplyr")
library(dplyr)
setwd("D:/Huwenjie/DHS_Data/merged")
a<-read.csv("ALPR50SV.csv", header = T)
b<-read.csv("TDPR41sv.csv", header = T)
a_var <- names(a)
b_var <- names(b)
dim(a)
dim(b)
#variables that are the same
length(intersect(a_var,b_var))
a_remain <- a_var[!a_var %in% intersect(a_var, b_var)]
b_remain <- b_var[!b_var %in% intersect(a_var, b_var)]

# fuzzy match a_remain and b_remain 
## creates a matrix with standard levensthtein of both sources
dist.name<-adist(a_remain, b_remain, partial = TRUE, ignore.case = TRUE)
#take pairs with the minimum distance
min.name<-apply(dist.name, 1, min)

match.s1.s2<-NULL
for (i in 1:nrow(dist.name))
{
  s2.i<-match(min.name[i],dist.name[i,])
  s1.i<-i
  match.s1.s2 <- rbind(data.frame(s2.i=s2.i,s1.i=s1.i, 
                                  s2name=b_remain[s2.i], 
                                  s1name=a_remain[s1.i], 
                                  adist=min.name[i]), 
                       match.s1.s2)
}
View(match.s1.s2)

#second method is to use LCS
#install.packages("astringdist")
library(astringdist) # we need to update Rstudio 


#append the two datasets according to the same variables
rbind.fill(a,b)

#all files in the folder
file_list = list.files()
data_list = lapply(file_list, read.csv)
data_combined = do.call("rbind.fill", data_list)
 

#Another way we can do is using reshape library 
datalist<-list(a,b)
merge_recurse(datalist)


