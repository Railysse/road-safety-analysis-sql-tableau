# creating the tables
CREATE TABLE accident (
        accident_index VARCHAR(30),
        accident_year INT,
        accident_reference VARCHAR(30),
        location_easting_osgr DECIMAL(16, 8),    
        location_northing_osgr DECIMAL(16, 8),   
        longitude DECIMAL(16, 8),
        latitude DECIMAL(16, 8),
        police_force INT,
        accident_severity INT,
        number_of_vehicles INT,
        number_of_casualties INT,
        date VARCHAR(30),
        day_of_week INT,
        time VARCHAR(30),
        local_authority_district INT,
        local_authority_ons_district VARCHAR(30),
        local_authority_highway VARCHAR(30),
        first_road_class INT,
        first_road_number INT,
        road_type INT,
        speed_limit INT,
        junction_detail INT,
        junction_control INT,
        second_road_class INT,
        second_road_number INT,
        pedestrian_crossing_human_control INT,
        pedestrian_crossing_physical_facilities INT,
        light_conditions INT,
        weather_conditions INT,
        road_surface_conditions INT,
        special_conditions_at_site INT,
        carriageway_hazards INT,
        urban_or_rural_area INT,
        did_police_officer_attend_scene_of_accident INT,
        trunk_road_flag INT,
        lsoa_of_accident_location VARCHAR(30)
);
CREATE TABLE vehicle (
        accident_index VARCHAR(30),
        accident_year INT,
        accident_reference VARCHAR(30),
        vehicle_reference INT,
        vehicle_type INT,
        towing_and_articulation INT,
        vehicle_manoeuvre INT,
        vehicle_direction_from INT,
        vehicle_direction_to INT,
        vehicle_location_restricted_lane INT,
        junction_location INT,
        skidding_and_overturning INT,
        hit_object_in_carriageway INT,
        vehicle_leaving_carriageway INT,
        hit_object_off_carriageway INT,
        first_point_of_impact INT,
        vehicle_left_hand_drive INT,
        journey_purpose_of_driver INT,
        sex_of_driver INT,
        age_of_driver INT,
        age_band_of_driver INT,
        engine_capacity_cc INT,
        propulsion_code INT,
        age_of_vehicle INT,
        generic_make_model VARCHAR(30),
        driver_imd_decile INT,
        driver_home_area_type INT
);
CREATE TABLE casualty (
        accident_index VARCHAR(30),
        accident_year INT,
        accident_reference VARCHAR(30),
        vehicle_reference INT,
        casualty_reference INT,
        casualty_class INT,
        sex_of_casualty INT,
        age_of_casualty INT,
        age_band_of_casualty INT,
        casualty_severity INT,
        pedestrian_location INT,
        pedestrian_movement INT,
        car_passenger INT,
        bus_or_coach_passenger INT,
        pedestrian_road_maintenance_worker INT,
        casualty_type INT,
        casualty_home_area_type INT,
        casualty_imd_decile INT
); 


# loading the data
LOAD DATA INFILE 'E:/road_safety/accident_prepped.csv'
INTO TABLE accident
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;		

LOAD DATA INFILE 'E:/road_safety/vehicle_prepped.csv'
INTO TABLE vehicle	
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;
	
LOAD DATA INFILE 'E:/road_safety/casualty_prepped.csv'
INTO TABLE casualty
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;


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
