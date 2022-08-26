# population distribution by age
SELECT age_of_driver, COUNT(*) AS count
FROM vehicle
WHERE age_of_driver >= 16 # exclude invalid ages
GROUP BY age_of_driver
ORDER BY age_of_driver;


# mean age of drivers
SELECT AVG(age_of_driver)
FROM vehicle;


# accident severity
SELECT 
    CASE
        WHEN accident_severity = 1 THEN 'Fatal'
        WHEN accident_severity = 2 THEN 'Serious'
        WHEN accident_severity = 3 THEN 'Slight'
    END AS severity,
    count
FROM (SELECT accident_severity, COUNT(*) AS count
      FROM accident
      GROUP BY accident_severity
      ORDER BY accident_severity DESC) t;


# average number of drivers involved in accidents
SELECT 
    AVG(count_of_drivers) AS average
FROM 
    (SELECT 
        accident_reference, 
        MAX(vehicle_reference) AS count_of_drivers
    FROM vehicle
    GROUP BY accident_reference) t;


# average age and severity for each accident
SELECT 
    a.accident_reference,
    FLOOR(AVG(age_of_driver)) AS mean_driver_age, 
    MAX(accident_severity) AS accident_severity # could have chosen MIN as well
FROM accident a
JOIN vehicle v
ON a.accident_reference = v.accident_reference
# filter out accidents where some ages ae invalid
WHERE 
    a.accident_reference IN 
    (SELECT DISTINCT accident_reference
    FROM 
        (SELECT 
            accident_reference,
            MIN(age_of_driver) OVER(partition by accident_reference) AS min_age
        FROM vehicle) t
        WHERE min_age >= 16) # only choose accidents where the minimum driver age >= 16                                                                                                              
GROUP BY a.accident_reference;


# most common manouvres in accidents
SELECT manoeuvre, SUM(count) AS count
FROM
    (SELECT 
        CASE
            WHEN vehicle_manoeuvre = 18 THEN 'Going ahead other'
            WHEN vehicle_manoeuvre = 9 THEN 'Turning right'
            WHEN vehicle_manoeuvre = 4 THEN 'Slowing or stopping'
            WHEN vehicle_manoeuvre = 5 THEN 'Moving off'
            WHEN vehicle_manoeuvre = 2 THEN 'Parked'
            WHEN vehicle_manoeuvre = 3 THEN 'Waiting to go - held up'
            WHEN vehicle_manoeuvre = 7 THEN 'Turning left'
            ELSE 'Other'
        END AS manoeuvre,
        COUNT(*) AS count
    FROM vehicle
    WHERE vehicle_manoeuvre BETWEEN 1 and 18
    GROUP BY vehicle_manoeuvre
    ORDER BY count DESC) t
GROUP BY manoeuvre;


# number of accidents per month
SELECT 
    MONTH(STR_TO_DATE(date, '%d/%m/%y')) AS month_number,
    MONTHNAME(STR_TO_DATE(date, '%d/%m/%y')) AS month,
    COUNT(*) AS count
FROM accident
GROUP BY month
ORDER BY month_number;


# accident distribution by hour
SELECT 
    hour(time) AS hour_of_day, COUNT(time) AS number_of_accidents
FROM accident
GROUP BY hour_of_day
ORDER BY hour_of_day;


# severity score for each lighting condition
SELECT 
    CASE
        WHEN light_conditions = 1 THEN 'Daylight'
        WHEN light_conditions = 4 THEN 'Darkness (lights lit)'
        WHEN light_conditions = 5 THEN 'Darkness (lights unlit)'
        WHEN light_conditions = 6 THEN 'Darkness (no lighting)'
    END as lighting,
    # compute a severity score by giving weights to each severity type
    AVG(CASE
            WHEN accident_severity = 3 THEN 1 # slight accidents
            WHEN accident_severity = 2 THEN 10 # serious accidents 
            WHEN accident_severity = 1 THEN 50 # fatal accidents
        END) AS severity,
    COUNT(*) AS number_of_accidents # make sure there are enough samples
FROM accident
WHERE light_conditions IN (1, 4, 5, 6) # choose the relevant categories
GROUP BY lighting;


# severity distribution by lighting conditions (percentage)
SELECT 
    CASE
        WHEN light_conditions = 1 THEN 'Daylight'
        WHEN light_conditions = 4 THEN 'Darkness (lights lit)'
        WHEN light_conditions = 5 THEN 'Darkness (lights unlit)'
        WHEN light_conditions = 6 THEN 'Darkness (no lighting)'
    END AS light_condition,
    100 * slight/(slight + serious + fatal) AS slight_percentage,
    100 * serious/(slight + serious + fatal) AS serious_percentage,
    100 * fatal/(slight + serious + fatal) AS fatal_percentage
FROM(SELECT 
    light_conditions, 
    COUNT(CASE
        WHEN accident_severity = 3 THEN accident_severity ELSE NULL
    END) AS slight,
    COUNT(CASE
        WHEN accident_severity = 2 THEN accident_severity ELSE NULL
    END) AS serious,
    COUNT(CASE
        WHEN accident_severity = 1 THEN accident_severity ELSE NULL
    END) AS fatal
FROM accident
WHERE light_conditions in (1, 4, 5, 6)
GROUP BY light_conditions) temp;
