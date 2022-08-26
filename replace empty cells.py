import pandas as pd 
import numpy as np

files = ['accident', 'vehicle', 'casualty']

for file in files:
    df = pd.read_csv(f'{file}.csv', low_memory=False)
    df.replace({np.NaN: '\\N'}, inplace=True)
    df.to_csv(f'{file}_prepped.csv', index=False)

