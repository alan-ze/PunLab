#!/usr/bin/env python
# coding: utf-8

# In[3]:


import pandas as pd
import os

def extract_columns_to_csv(file_path):
    # Load the Excel workbook
    workbook = pd.ExcelFile(file_path)
    
    # Loop through each sheet in the workbook
    for sheet_name in workbook.sheet_names:
        # Load each sheet into a DataFrame, using row 2 (index 1) for column names and starting data from row 4 (index 3)
        sheet_df = workbook.parse(sheet_name, header=1, skiprows=[2])  # Row 2 as header; skip row 3 to start data from row 4
        
        # Check if the required columns are present in the sheet
        required_columns = ['Step time', 'Strain (step)', 'Shear rate', 'Stress (step)']
        if all(column in sheet_df.columns for column in required_columns):
            # Extract the specific columns in the required order
            extracted_data = sheet_df[required_columns]
            
            # Define the output CSV filename
            workbook_name = os.path.splitext(os.path.basename(file_path))[0]
            output_filename = f"{workbook_name}_{sheet_name}.csv"
            
            # Save the extracted data to CSV without headers
            extracted_data.to_csv(output_filename, index=False, header=False)
            print(f"Data from sheet '{sheet_name}' saved to '{output_filename}'")
        else:
            print(f"Sheet '{sheet_name}' in '{file_path}' does not contain all required columns.")

# Usage example (replace with your actual file path)
extract_columns_to_csv('TJC2_20A1.xls')


# In[ ]:




