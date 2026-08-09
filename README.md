# COVID-19 Exploratory Data Analysis on official dataset
SQL analysis of the official COVID-19 dataset using SQL Server Management Studio for trends on the cases, testing and vaccination sections of the dataset


## Objectives: 
Find:
  * Number of cases, tests and vaccinations in each country in Africa
  * The contraction risk rate against the population as time went on (Case study: Kenya)
  * Number of tests per population for each country in Africa (testing rate)
  * Running totals of cases and vaccinations in each country in Africa
  * Countries in Africa that reported cases but no vaccination numbers
  * Vaccination rate against cases recorded and per population (Case study: Africa)
  * Vaccination rates across the continents
  * Countries with the highest average positive rates of tests conducted (Case study: Africa)

## Key SQL Skills Demonstrated
* Common Table Expressions (CTEs)
* Database Views creation
* Advanced joins handles (`LEFT JOIN` / `INNER JOIN`)
* Aggregate calculations (`SUM`, `MAX`, `AVG`) & Divide-by-zero safeguards (`NULLIF`)
* Datatype formatting

## Key Insights From the Analysis
  * Identified Egypt and Tunisia to have had the highest positive rates per test conducted
  * Africa had the least percentage of its population (36%) vaccinated against COVID-19
  * South Africa was the most affected country in Africa with the highest number of cases (4073188)
  * Mauritius extensively vaccinated its population with the highest coverage rate of 88.06%
