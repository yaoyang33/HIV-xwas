"""
This scripts inplements a country by country merge of the survey files.
It outputs a <json|csv|...>? file of the merged data (one per country). Probably json as flexible.

TODO: for one country, will we have a problem of non matching variables?
If not, the standardize_variables() function will be implemented in the merge_country script
If it is, it will be implemented in another standardize_variables.py file and called both here and 
in the country merge file
"""



""" @Tim: After careful thinking, I would prefer either all the files to be in the same folder, or to be grouped by country.
The folder name would be the prefix of the country.
Up to you, just let me know
"""


import pandas as pd
import os


#visited does not work if folder and subfolder have same name
#Have a path that is popped

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

print "\n".join(explore_dir("/Users/malo/Documents/Projects/HIV-xwas/shared_with_desktop"))

# def list_files(path_to_dir,extensions=None,recursive=False):
# 	"""
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

def parse_name(file_name):
	"""Takes a string file name in input, and parse it.
	Input: - String: name of the file
	Output: - Dictionnary of {type: <Household|Individual|Test>,country:,}
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

data = link_files("shared_with_desktop/Niger DHS 06/niar51dt/NIAR51FL.DTA")
print data.columns



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


# sanity check: pseudo code
#In the koined table: no individual has no household
#	assert join_key_individual IS NOT NULL and join_key_griup IS NOT NULL 
#   assert nb_lines == nb_individuals