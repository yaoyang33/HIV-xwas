Assumptions:
- survey files stored in one country by folder.


Global architecture:
- country_merge.py merges and staks all the data for one country
- standardize_variables standardizes the variable names based on metadata files / tables(TBD)
- global_merge merges all the country .json? intermediary files into a final merged dataset
