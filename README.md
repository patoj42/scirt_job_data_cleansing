# scirt_job_data_cleansing

This is a part of the course project from Data Management course at the University of Canterbury

The primary resource is what is called an SQL database dump which can be imported to create a database schema called scirt_jobs_bound. The data in this database contains the disjoint datasets listed above. In addition to those datasets there is a stored procedure and a function which split a string of comma-separated routes in the scirt_job table and store the results in a temporary table for further processing.

One dataset is an extract from Land and Information New Zealand (LINZ) database listing all addresses in Christchurch. This dataset comes in a flat table format with a hefty redundancy overhead, and other issues.

Another dataset is list of Stronger Christchurch Infrastructure Rebuild Team (SCIRT) repair jobs including the descriptions of those jobs and route/street assignments related to each job. This dataset also comes with a lot of data duplication, and other inefficiencies.

In this project, I wrote a series of SQL statements correcting the problems with the datasets, and eventually transformed the data into one integrated database where redundancy is eliminated and the route/street-to-repair-job assignment is handled in an efficient manner.

I created a suitable data model for the integrated dataset, and write the extract-transform-load (ETL) SQL statements to populate the new schema with the data from the two original datasets.
