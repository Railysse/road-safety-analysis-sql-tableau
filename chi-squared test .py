import pandas as pd
import numpy as np
from scipy.stats import chi2_contingency

severity_by_age = pd.read_csv('severity by driver age.csv')

#count of slight accidents by age
filt_slight = (severity_by_age['accident_severity'] == 3)
slight = severity_by_age[filt_slight].groupby('mean_driver_age')
slight = slight['mean_driver_age'].count()
#count of serious accidents by age
filt_serious = (severity_by_age['accident_severity'] == 2)
serious = severity_by_age[filt_serious].groupby('mean_driver_age')
serious = serious['mean_driver_age'].count()
#count of fata accidents by age
filt_fatal = (severity_by_age['accident_severity'] == 1)
fatal = severity_by_age[filt_fatal].groupby('mean_driver_age')
fatal = fatal['mean_driver_age'].count()

min_age=20 
max_age=65
#check for ages between 20 and 65
list_of_proportions = list(zip(slight[min_age:max_age], serious[min_age:max_age], fatal[min_age:max_age]))
chi2_contingency(list_of_proportions)