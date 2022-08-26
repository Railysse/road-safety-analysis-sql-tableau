import pandas as pd

files = ['accident', 'vehicle', 'casualty']

output = str() #initiate empty string

for file in files:
    df = pd.read_csv(f'{file}.csv', low_memory=False)
    output += f'CREATE TABLE {file} (\n'
    for col in df.columns: #go through all columns
        #check type of column and print accordingly
        if df.dtypes[col] == 'O':
            output += f'\t{col} VARCHAR(30),\n'
        elif df.dtypes[col] == 'int64':
            output += f'\t{col} INT,\n'
        elif df.dtypes[col] == 'float64':
            output += f'\t{col} DECIMAL(16, 8),\n'
    output = output[:-2] + '\n' #delete the comma at the end
    output += ');\n\n'

print(output)

    