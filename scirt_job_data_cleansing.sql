# 0. PREPARATION
# 0.1 set primary key for chch_street_address for later use
ALTER TABLE chch_street_address
MODIFY COLUMN address_id INT PRIMARY KEY;

# 0.2 set safe update mode for cleansing the data (In the end of the queries, I will undo the safe update mode)
SET SQL_SAFE_UPDATES = 0;

# 1. DATA CLEANSING PART
# 1.1 replace empty strings in chch_street_address with null values 
UPDATE chch_street_address
SET unit_value = NULL
WHERE unit_value = '';

UPDATE chch_street_address
SET address_number_suffix = NULL
WHERE address_number_suffix = '';

UPDATE chch_street_address
SET address_number_high = NULL
WHERE address_number_high = '';
# Note: I have checked other tables and did not find any other empty values, so here I did not attach other steps for further cleansing 

# 1.2 Update scirt_job table to eliminate duplication
 # 1.2.1 combine 'Fletcher Construction' with 'Fletcher' in delivery_team in scirt_job table to eliminate duplication
UPDATE scirt_job
SET delivery_team = 'Fletcher Construction'
WHERE delivery_team = 'Fletcher';
 # 1.2.2 combine 'St Albans' with 'Saint Albans' in delivery_team in scirt_job table to eliminate duplication
UPDATE scirt_job
SET locality = 'St Albans'
WHERE locality = 'Saint Albans';

# 1.3 call the function to split columns (the split data goes to temp_table)
CALL split_column(); 

# 1.4 cleanse routes having "to" or "To" between roads (total 4 rows, e.g. 'St Asaph to Fitzgerald') and remove duplication 
 # 1.4.1 separate routes having "to" or "To" between road names
  # 1.4.1.1 split roads before "to" or "To" (insert the left part of the "to" or "To")
INSERT INTO temp_table (job_id, route)  
SELECT job_id, split_string(UPPER(route), ' TO ', 1)  #(use UPPER to easily compare and avoid null values)
FROM temp_table 
WHERE UPPER(route) LIKE '% To %';
  # 1.4.1.2 split roads after "to" or "To" (insert the right part of the "to" or "To")
INSERT INTO temp_table (job_id, route) 
SELECT job_id, split_string(UPPER(route), ' TO ', 2)  #(use UPPER to easily compare and avoid null values)
FROM temp_table 
WHERE UPPER(route) LIKE '% TO %';

 # 1.4.2 Delete the original four routes with "to" or "To" 
DELETE FROM temp_table WHERE route LIKE '% TO %';

 # 1.4.3 Update routes with their complete names 
UPDATE temp_table
SET route = 'Fitzgerald Avenue'
WHERE route = 'FITZGERALD';

UPDATE temp_table
SET route = 'St Asaph Street'
WHERE route = 'ST ASAPH';

UPDATE temp_table
SET route = 'Beresford Street'
WHERE route = 'BERESFORD';

UPDATE temp_table
SET route = 'Gloucester Street'
WHERE route = 'GLOUCESTER';

UPDATE temp_table
SET route = 'Caspian Street'
WHERE route = 'CASPIAN';

UPDATE temp_table
SET route = 'Bealey Avenue'
WHERE route = 'BEALEY';

UPDATE temp_table
SET route = 'Wilsons Road'
WHERE route = 'WILSONS ROAD';

 # 1.4.4 eliminate duplications in routes (some job_ids have the same route name more than once) 
  # 1.4.4.1 set another key (id) in temp_table to find out the duplicated rows later 
ALTER TABLE temp_table 
ADD id INT KEY NOT NULL AUTO_INCREMENT;

# 1.5 correct some street names
 # 1.5.1 correct 'Durham Street' (Durham Street does not exist) to 'Durham Street South' or 'Durham Street North' according to the job_id (I checked on the map and scirt_job table)
UPDATE temp_table
SET route = 'Durham Street South' 
WHERE route = 'Durham Street' AND job_id = '11061';

UPDATE temp_table
SET route = 'Durham Street South' 
WHERE route = 'Durham Street' AND job_id = '10879';

UPDATE temp_table
SET route = 'Durham Street North' 
WHERE route = 'Durham Street' AND job_id = '10994';

UPDATE temp_table
SET route = 'Durham Street North' 
WHERE route = 'Durham Street' AND job_id = '10986';

 # 1.5.2 correct some street names (many streets have incorrect road names) 
UPDATE temp_table
SET route = 'Cranmer Square'
WHERE route = 'Cramner Square';

UPDATE temp_table
SET route = 'Snell Place'
WHERE route = 'Snells Place';

UPDATE temp_table
SET route = 'Prince Avenue'
WHERE route = 'Pince Avenue';

# 2. CREATE TABLE PART
# 2.1 create SUBURB table 
 # 2.1.1 create SUBURB table and add attributes including primary key
CREATE TABLE suburb (
  suburb_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  suburb_name VARCHAR(255) UNIQUE
);

 # 2.1.2 insert data to SUBURB table from other tables 
INSERT INTO suburb(suburb_name) 
SELECT DISTINCT suburb_locality 
FROM chch_street_address;
# (use INSERT IGNORE here for warning to avoid error)
INSERT IGNORE INTO suburb(suburb_name) 
SELECT DISTINCT locality 
FROM scirt_job;
   
# 2.2 create ROUTE table
 # 2.2.1 create ROUTE table and add attributes including primary key
CREATE TABLE route (
  route_id INT PRIMARY KEY AUTO_INCREMENT,
  route_name VARCHAR(255) UNIQUE
);   

 # 2.2.2 insert data to ROUTE table from other tables 
INSERT INTO route(route_name) 
SELECT DISTINCT route 
FROM temp_table;
# (use INSERT IGNORE here for warning to avoid error)
INSERT IGNORE INTO route(route_name) 
SELECT DISTINCT road_name
FROM chch_street_address;

# 2.3 create CITY table 
 # 2.3.1 create CITY table and add attributes including primary key
CREATE TABLE city(
  city_id INT PRIMARY KEY AUTO_INCREMENT,
  city_name VARCHAR(225));

 # 2.3.2 insert data to CITY table from chch_street_address
INSERT INTO city (city_name)
SELECT DISTINCT town_city from chch_street_address;

# 2.4 create ADDRESS table 
 # 2.4.1 create ADDRESS table and insert data from other tables
CREATE TABLE address 
SELECT address_id,
       unit_value,
       address_number,
       address_number_suffix,
       address_number_high,
       road_section_id,
       suburb_id,
       route_id, 
       city_id
FROM chch_street_address, suburb, route, city
WHERE chch_street_address.town_city = city.city_name
AND chch_street_address.suburb_locality = suburb.suburb_name 
AND chch_street_address.road_name = route.route_name;

 # 2.4.2 add primary key and foreign keys for ADDRESS table
ALTER TABLE address
ADD PRIMARY KEY (address_id),
ADD FOREIGN KEY (route_id) REFERENCES route (route_id) ON UPDATE CASCADE,
ADD FOREIGN KEY (suburb_id) REFERENCES Suburb (suburb_id) ON UPDATE CASCADE,
ADD FOREIGN KEY (city_id) REFERENCES city (city_id) ON UPDATE CASCADE;

# 2.5 create ROAD_SECTION table 
 # 2.5.1 create ROAD_SECTION table and insert data from other tables
CREATE TABLE road_Section 
SELECT DISTINCT road_section_id, route_id, suburb_id
FROM address;

 # 2.5.2 add primary key and foreign keys for ROAD_SECTION table
ALTER TABLE road_Section
ADD COLUMN road_sect_id INT PRIMARY KEY AUTO_INCREMENT,
ADD FOREIGN KEY (route_id) REFERENCES route(route_id) ON UPDATE CASCADE,
ADD FOREIGN KEY (suburb_id) REFERENCES suburb(suburb_id) ON UPDATE CASCADE,
DROP COLUMN road_section_id;

# 2.6 create DELIVERY_TEAM table, add primary key and insert data from scirt_job table
CREATE TABLE delivery_team (
delivery_team_id INT PRIMARY KEY AUTO_INCREMENT
)   
SELECT DISTINCT scirt_job.delivery_team
FROM scirt_job;

# 2.7 create JOB table
 # 2.7.1 create JOB table and insert data from other tables
CREATE TABLE job 
SELECT job_id,
       description,
       start_date,
       end_date,
       delivery_team_id,
       suburb_id
FROM scirt_job, delivery_team, suburb 
WHERE scirt_job.delivery_team = delivery_team.delivery_team 
AND scirt_job.locality = suburb.suburb_name;

 # 2.7.2 add primary key and foreign keys for JOB table, unsign job_id (for setting foreign key later)
ALTER TABLE job
MODIFY COLUMN job_id INT UNSIGNED PRiMARY KEY,
ADD FOREIGN KEY (delivery_team_id) REFERENCES delivery_team (delivery_team_id) ON UPDATE CASCADE,
ADD FOREIGN KEY (suburb_id) REFERENCES suburb (suburb_id) ON UPDATE CASCADE;

# 2.8 update temp_table for creating JOB_ROUTE table later
 # 2.8.1 add route_id column in temp_table
ALTER TABLE temp_table
ADD COLUMN route_id INT;

 # 2.8.2 update route_id in temp_table
UPDATE temp_table, route
SET temp_table.route_id = route.route_id
WHERE temp_table.route = route.route_name;

# 2.9 create JOB_ROUTE table
 # 2.9.1 create JOB_ROUTE table, add primary key and unsign job_id (for setting foreign key later)
CREATE TABLE job_route(
job_route_id INT PRIMARY KEY AUTO_INCREMENT,
job_id INT UNSIGNED,
route_id INT
);

 # 2.9.2 insert data to JOB_ROUTE table from temp_table
INSERT INTO job_route(job_id, route_id) 
SELECT DISTINCT job_id, route_id
FROM temp_table;

 # 2.9.3 add foreign keys for job_route table
ALTER TABLE job_route
ADD FOREIGN KEY (route_id) REFERENCES route (route_id) ON UPDATE CASCADE,
ADD FOREIGN KEY (job_id) REFERENCES job (job_id) ON UPDATE CASCADE;

# 3. FINISHING THE QUERY PART
# 3.1 drop all three old tables
DROP TABLE chch_street_address, scirt_job, temp_table; 

# 3.2 Undo the safe update mode
SET SQL_SAFE_UPDATES = 1;
