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

	elif country == "other edge cases"

	#Standard case: all other
	else:

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