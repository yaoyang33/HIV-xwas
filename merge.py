"""
This scripts inplements a country by country merge of the survey files.
It outputs a <json|csv|...>? file of the merged data (one per country). Probably json as flexible.

TODO: for one country, will we have a problem of non matching variables?
If not, the standardize_variables() function will be implemented in the merge_country script
If it is, it will be implemented in another standardize_variables.py file and called both here and 
in the country merge file


TODO: if the execution of the file is long, we will need to define checkpoints (in order not to have to restart everything in case of interruption)
So the checkpoint file might look like 
- step (we arrvied at step x)
- metadata
We also need to make sure we save some intermediary steps to disk in order not to have to run them. So worst case we can start from a checkpoint.



"""



""" @Tim: After careful thinking, I would prefer either all the files to be in the same folder, or to be grouped by country.
The folder name would be the prefix of the country.
Up to you, just let me know
"""

import time
import pandas as pd
import numpy as np
import os
import json
import re
import pandas.rpy.common as com

#visited does not work if folder and subfolder have same name
#Have a path that is popped

class InvalidSurveyFileName(Exception):
	#TODO: fill that in
	pass

def print_dict(d,levels=1):
	"""Print dictionart in nice format"""
	if levels == 1:
		for k,v in d.iteritems():
			print " %s : %s " % (k, v) 
	elif levels == 2:
		for k,dic2 in d.iteritems():
			print "%s : " % k
			for k2,v in dic2.iteritems():
				print "    %s : %s " %(k2,v)

	else:
		print "Unsupported number of levels " #I was lazy on this one ;)


def explore_dir(path,extensions=None):
	"""
	Returns a list of all the files in a directory. If extension is provided, filters on extension.

	Input:
	- path_to_dir: String: path to the directory in which to look
	- [optionnal] extension: string: list of extension to select (eg: [".csv",".dat"]) 
	- [optionnal] visited: files will be added to that list
	Output:
	- List of strings: list of all the files in the folder [with given extension]. If recursive, all the files in subfolders will be prefixed by the relative path (eg:subfolder/filename)
	"""
	if os.path.isdir(path):
		out = []
		for element in os.listdir(path):
			element_path = path+"/"+element
			out = out + explore_dir(element_path,extensions=extensions)
		return out
	else:
		filename, file_extension = os.path.splitext(path)
		if(extensions == None): #No filter on extension
			return [path]
		elif(file_extension in extensions): #File is in extensions
			return [path]
		else: #File is not in target extensions
			return []

# -------- #
# def list_files(path_to_dir,extensions=None,recursive=False):
# 	
# 	Returns a list of all the files in a directory. If extension is provided, filters on extension.

# 	Input:
# 	- path_to_dir: String: path to the directory in which to look
# 	- [optionnal] extension: string: list of extension to select (eg: [".csv",".dat"]) 
# 	- [optionnal] recursive: Look recursively into subdirectories. Default False.
# 	Output:
# 	- List of strings: list of all the files in the folder [with given extension]. If recursive, all the files in subfolders will be prefixed by the relative path (eg:subfolder/filename)
# 	"""
# 	#List of list. 
# 	#List at index 0 is the singleton of the root file. List at depth 1 is all the subfolders, etc
# 	stack = [path_to_dir]
# 	stack2 = 
# 	filenames = []
# 	visited = []
# 	while stack != []:
# 		current_dir = stack.pop()
# 		all_files = listdir(current_dir)
# 		for current_file in all_files:
# 			path = stack.join("/") + current_file
# 			if os.path.isdir(current_file):
# 				if


# 	filenames = listdir(path_to_dir)
# 	if extension == None:
# 		return filenames
# 	else:
# 		return [filename for filename in filenames if filename.endswith(extension)]


# print(list_files("/Users/malo/Documents/Projects/HIV-xwas/shared_with_desktop"))


#TODO: consider refactroring without exception but with a None
def parse_name(file_path):
	"""Takes a string file name in input, and parse it.
	Input: - String: name of the file in the format country_surveytype_version, where survey_type is in <HR,IR,MR,AR>
	HR: Households
	IR: Women records
	MR: men records
	AR: HIV testing
	Output: - Dictionnary of {type: <Household|Individual|Test>,country:,}
	"""	
	#TODO: robustness to more string formatting problems?
	#Delete the following block	
	if True:
		file_metadata = {}
		splitted_path = file_path.split("/")
		file_name = splitted_path[-1] #Getting file name
		file_metadata["country"] = file_name[0:2]
		survey_type = file_name[2:4]
		if survey_type == "HR":
			file_metadata["survey_type"] = "households"
		elif survey_type == "IR":
			file_metadata["survey_type"] = "women"
		elif survey_type == "MR":
			file_metadata["survey_type"] = "men"
		elif survey_type == "MR":
			file_metadata["survey_type"] = "hiv_test"
		else: 
			file_metadata["survey_type"] = "other"
		return(file_metadata)
	
	# #TODO: Once all the files are imported with the new names use this block remove the previous if and keep only this block
	# else:
	# 	file_metadata = {}
	# 	reg = re.compile('[^_]+')
	# 	matches = re.findall(reg,file_name)
	# 	try:
	# 		file_metadata["country"] = matches[0]
	# 		survey_type = matches[1]
	# 		if survey_type == "HR":
	# 			file_metadata["survey_type"] = "households"
	# 		elif survey_type == "IR":
	# 			file_metadata["survey_type"] = "women"
	# 		elif survey_type == "MR":
	# 			file_metadata["survey_type"] = "men"
	# 		elif survey_type == "MR":
	# 			file_metadata["survey_type"] = "hiv_test"
	# 		else: 
	# 			file_metadata["survey_type"] = "other"

	# 		return(file_metadata)
	# 	except KeyError: #It means the file is not correctly formatted
	# 		raise InvalidSurveyFileName()
	# 	except IndexError:
	# 		pass
	# 		# raise InvalidSurveyFileName()
	# 		print("here")

def parse_names(paths):
	"""Takes a list of file path and returns a dictionnary of metadata dictionnary.
	Input: list of paths
	Output: dictionary of path:metdata_dic where metadata_dic is the output of parse_name
	"""

	metadata_dic = {}
	for path in paths:
		try:
			file_metadata = parse_name(path)
			metadata_dic[path]  = file_metadata
		except InvalidSurveyFileName:
			metadata_dic[path]  = None
	return(metadata_dic)

def get_year(path, verbose = False):
	"""Goes through a survey file and extract the start year. Returns None if there is  no such column.
	"""
	try: 
		# cacth ValueError = pb in stats file
		tic = time.time()
		data = pd.read_stata(path)
		toc = time.time()
		size = os.path.getsize(path)
		log = "Got file year for %s in %s s. File was %f Mb \n" % (path,toc-tic,size/(2.**20))
		if verbose:
			print log
		return min(data["hv007"]), log
	except KeyError:
		log = "No file year for %s. read file in %s s. File was %f Mb \n" % (path,toc-tic,size/(2.**20))
		return None, log
		if verbose:
			print log
	except ValueError as error: 
		log = "ValueError: %s in file %s" % (error, path)
		if verbose:
			print log
		return None, log
		
def get_years(paths, file_years, update = False, log_file = None):
	"""
	Get the start year of surveys by looking into the stata data file, and adds it (inplace) to the file_years dictionnary. 
	Inputs:
	- path: list of paths to survey files (.dta)
	- file_years: dictionnary of {path:year}
	- if update == True, we erase the previous values of the dic.
	Note: unfortunately python is not that good at functionnal programming, so I chose to do it inplace. I would have preferred a functionnal approach but it was looking bad.
	"""
	#Do we need to have different variables for different file types?
	#rihght now we asu
	log_string = ""
	if update: # we update all the entries
		for path in paths:
			year, log = getYear(path, verbose = True)
			log_string += log + "\n" 
			if not year == None:
				year = int(year)
				if year < 100 and year > 70: # 80's and	 90's 
					year = 1900 + year
				file_years[path] = year
	else:
		for path in paths:
			if not path in file_years:
				year, log = getYear(path, verbose = True)
				log_string += log + "\n"
				if not year == None:
					year = int(year)
					if year < 100 and year > 70: # 80's and	 90's 
						year = 1900 + year
					file_years[path] = int(year)
	#Writing log as needed
	if not log_file == None:
		with open('log_file', 'a') as f:
			f.write(log_string)

def get_paths_by_country(parsed_dict):
	"""Takes the output of parse_names and transforms it in a country:{type:[paths_lists dictionnary]}
	Input: dictionary of path:metdata_dic where metadata_dic is the output of parse_name
	Output: dictionnary of dict of {country: {type: [paths _list]}}
	"""

	out = {}

	for path, dic in parsed_dict.iteritems():
		print path
		country = dic["country"]
		survey_type = dic["survey_type"]
		if country in out.keys():
			inside_dic = out[country]
			if survey_type in inside_dic.keys():
				inside_dic[survey_type] = inside_dic[survey_type] + [path]
				out[country] = inside_dic
			else:
				inside_dic[survey_type] = [path]
				out[country] = inside_dic
		else:
			out[country] = {survey_type:[path]}
	return out

def merge_two_files(file1,file2,file_types):
	""" file1, file 2: paths
		file_types: dictionnary of {path:type} as output by parse_name
	"""

def link_files(path, verbose = False):
	""" 
	Input: path of directory containing files (or folders by country). If none, looking in working directory.
	Crawls all the folders to look for files.
		For each file:
		- read into df 
		- call generate_join_key() to create a new key column
		- repeat until read all files
		- join
		- stack
		- outputs to json via export_file()
		- print status
		- writes into a log file if everything went well
	"""

	data = pd.read_stata(path)
	return data

# data = link_files("shared_with_desktop/Niger DHS 06/niar51dt/NIAR51FL.DTA")
# print data.columns

def jenerate_join_key(data,country,dataType):
	"""
	Creates join keys in survey data. Implements country specific rules

	Input:
		- data: pandas dataframe
		- country we are looking at
		- dataType individual, household, test survey

	Output:
		- dataframe with a new join_key column. The join_key in indiviual survey will match uniquely with the corresponding key in household surveys and testing survey.
	"""

	data_key = None

	#First deal with edge cases
	if country == "Ethiopia":
		pass
	elif country == "Afghanistan":
		pass
	elif country == "other edge cases":
		pass
	#Standard case: all other
	else:
		pass

	return data_key

def export_file(data,country,path):
	"""
	Exports a country level merged data frame into json.
	Inputs:

	Output:
	- log_string: string of operation that was completed, status, nb of rows 
	"""

	data.to_json(path)

	return log_string

def write_log(path,string):
	""" Writes data -- logString in a new log file 
	name of file will be log_date_country.txt
	"""




def add_labels(df,dic_labels):
	""" Takes a dataframe imported from stata and add back its categorical labels
	Input: - df, as read by pd.io.stata.StataReader
		   - json_names: category names file 

	"""
	new = pd.DataFrame.from_dict({col: series.apply(lambda x: dic_labels[col][x] if x in dic_labels[col].keys() else np.nan)
                             if col in dic_labels.keys() else series
                             for col, series in df.iteritems()})
	
	reurn(new)



def read_stata(path):
	#Create reader
	try:
		#Trying to read labels
		stata_reader = pd.io.stata.StataReader(path)
		households_data = stata_reader.read(convert_categoricals=True)
		stata_reader.close()
	except (AttributeError, ValueError):#If catsgorical variables are not properly structured, reading separately then merging
		stata_reader = pd.io.stata.StataReader(path)
		households_data = stata_reader.read(convert_categoricals=False)
		value_labels = stata_reader.value_labels() #returns dict of {var_name: {value:label}}
		households_data = add_labels(households_data,value_labels)
		stata_reader.close()
		# households_data = add_labels(households_data,value_labels)
	return households_data


p = "/Users/malo/Documents/Projects/HIV-xwas/shared_with_desktop/08Nigeria/NGIR52FL.dta"
print read_stata(p)



def test():
	paths = explore_dir("/Users/malo/Documents/Projects/HIV-xwas/shared_with_desktop/_98Niger", extensions=[".DTA",".dta"])
	parsed_names = parse_names(paths)
	l = []
	for path in paths:
		w = com.robj.r('foreign::read.spss("%s", to.data.frame=TRUE)' % path)
		w = com.convert_robj(w)
		l.append(w)
	for f in l:
		print f.head()



def test2():
	paths = explore_dir("/Users/malo/Documents/Projects/HIV-xwas/shared_with_desktop", extensions=[".DTA",".dta"])
	parsed_names = parse_names(paths)
	by_country = get_paths_by_country(parsed_names)
	print_dict(by_country,levels=2)
	for country in by_country.keys():
		households_paths = by_country[country]["households"]
		print "Merging %s, %s file to merge ..." % (country, len(households_paths))
		i = 1
		households_merged = pd.DataFrame()
		all_labels = {}
		for households_path in households_paths:
			print("...reading file %s") % i
			# households_data = pd.read_stata(households_path,convert_categoricals=False) #losing categorical value. Files are not clean.
			try:
				stata_reader = pd.io.stata.StataReader(households_path)
				households_data = stata_reader.read(convert_categoricals=False)
				value_labels = stata_reader.value_labels() #returns dict of {var_name: {value:label}}
				stata_reader.close()
				all_labels[country + str(i)] = value_labels
				households_data = add_labels(df,dic_labels)
				# value_labels.to_json("temp/vlabels_"+str(country)+"_"+str(i))
			except AttributeError:
				print "no labels extracted"
			print("...merging file %s") % i
			households_merged = pd.concat([households_merged,households_data], axis=0, ignore_index=True)
			i += 1
		# print households_merged.columns
	return(all_labels)


# all_labels = test()

def test3():
	paths = explore_dir("/Users/malo/Documents/Projects/HIV-xwas/shared_with_desktop", extensions=[".DTA",".dta"])


	dic = {}
	get_years(paths, dic, update = False, log_file="Log.txt")


	print dic

	for k,v in dic.iteritems():
		print k
		print type(k)
		print(v)
		print(type(v))

	with open('survey_years.json', 'w') as fp:
	    json.dump(dic, fp, indent=4)

	print dic

def main():
	for country in country_dict.keys():
		pass
		# stack all households surveys in a country (not smart as increasing the number of rows. Find heuristic to reduce the number of maxes? eg: extract min and max year?)
		# create keys
		# open pne by one all the individuals and stack them
		# join
		# open tests and stack them
		# add tests to joined
		# output to json
		# next country
		# -> needed = dict of {country: {type: [paths _list]}

	# pd.concat([df,df1], axis=0, ignore_index=True)

def code_checks():
	#TODO: remove (temporary)
	parsed = parse_name("NGHR21FL.DTA") 
	assert parsed["country"] == "NG"
	assert parsed["survey_type"] == "households"
	# Test parse_name
	# parsed = parse_name("NG_HR_21FL.DTA") 
	# assert parsed["country"] == "NG"
	# assert parsed["survey_type"] == "households"


code_checks()

def sanity_checks():
	pass







# TODO: each survey (i.e. each folder) contains a unique set of individual. In other words there is no overlap of the data. So we can merge Country/Survey by survey.
# TODO: Stats transfer -> we have it
# Labels -> trim spaces and put everything in lower cases
# start with women and men
# rows = individuals
#Merge one block without the labels and column names/. Spss format

#Men years are MV007 -> careful
#When stacking men and women -> remove the "M"










# sanity check: pseudo code
#In the koined table: no individual has no household
#	assert join_key_individual IS NOT NULL and join_key_griup IS NOT NULL 
#   assert nb_lines == nb_individuals