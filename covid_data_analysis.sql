-- Data checks
SELECT
	country,
	SUM(CAST(ISNULL(new_cases, 0) AS BIGINT)) AS total_cases
FROM dbo.covid_cases
WHERE continent = 'Africa'
GROUP BY country
ORDER BY total_cases DESC

SELECT * 
FROM dbo.covid_vaccinations
WHERE country = 'Mauritius'
ORDER BY 2

SELECT * 
FROM dbo.covid_tests
WHERE country LIKE '%Cape%'
ORDER BY 3

SELECT * 
FROM dbo.covid_tests
WHERE country = 'Botswana'
ORDER BY 3


-- Exploratory Data Analysis

-- Objectives: Find -
--- Number of cases, tests and vaccinations in each country in Africa
--- The contraction risk rate against the population as time went on (Case study: Kenya)
--- Number of tests per population for each country in Africa (testing rate)
--- Running totals of cases and vaccinations in each country in Africa
--- Countries in Africa that reported cases but no vaccination numbers
--- Vacinnation rate against cases recorded and per population (Case study: Africa)
--- Vaccination rates across the continents
--- Countries with the highest average positive rates of tests conducted (Case study: Africa)



-- Number of cases, tests and vaccinations in each country in Africa
SELECT 
	cases.country,
	SUM(CAST(cases.new_cases AS BIGINT)) AS total_cases,
	SUM(CAST(tests.new_tests AS BIGINT)) AS total_tests,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) AS total_vaccinations
FROM dbo.covid_cases AS cases
INNER JOIN dbo.covid_tests AS tests
	ON cases.country = tests.country
	AND cases.date = tests.date
INNER JOIN dbo.covid_vaccinations AS vac
	ON tests.country = vac.country
	AND tests.date = vac.date
WHERE cases.continent = 'Africa'
GROUP BY cases.country
ORDER BY total_cases DESC


-- The contraction risk rate against the population as time went on (Case: Kenya)
SELECT
	country,
	date,
	population,
	total_cases,
	(total_cases *1.0 / population * 100) AS contraction_risk_rate
FROM dbo.covid_cases
WHERE country = 'Kenya'


-- New cases against total cases to show spikes in the number of cases (Case: Kenya)
--SELECT
--	country,
--	date,
--	population,
--	total_cases,
--	new_cases,
--	(new_cases *1.0 / NULLIF(total_cases, 0) * 100) AS contraction_rate
--FROM dbo.covid_cases
--WHERE country = 'Kenya'
--AND total_cases IS NOT NULL
--AND new_cases IS NOT NULL


-- Number of tests per population for each country in Africa (testing rate)
WITH testsCTE AS (
SELECT
	country,
	population,
	SUM(ISNULL(tests.new_tests, 0)) AS total_tests
FROM dbo.covid_tests AS tests
WHERE tests.continent = 'Africa'
AND tests.continent IS NOT NULL
GROUP BY country, population
)

SELECT 
	country,
	population,
	total_tests,
	CAST((total_tests * 1.0 / NULLIF(population, 0) * 100) AS DECIMAL (10,2)) AS testing_rate
FROM testsCTE
ORDER BY testing_rate DESC


-- Running totals of cases and vaccinations in each country in Africa
SELECT
	cases.country,
	cases.date,
	NULLIF(cases.new_cases, 0) AS new_cases,
	SUM(NULLIF(cases.new_cases, 0)) OVER (PARTITION BY cases.country ORDER BY cases.country, cases.date) AS running_total_cases,
	NULLIF(vac.new_vaccinations, 0) AS new_vaccinations,
	SUM(CONVERT(int, NULLIF(vac.new_vaccinations, 0))) OVER (PARTITION BY vac.country ORDER BY vac.country, vac.date) AS running_total_vaccinations
FROM dbo.covid_cases AS cases
LEFT JOIN dbo.covid_vaccinations AS vac
ON cases.date = vac.date
AND cases.country = vac.country
WHERE cases.continent = 'Africa'
ORDER BY 1,2


-- Countries in Africa that reported cases but no vaccination numbers
WITH vaccineCTE AS (
SELECT 
	cases.country AS country,
	SUM(CAST(cases.new_cases AS BIGINT)) AS total_cases,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) AS total_vaccinations
FROM dbo.covid_cases AS cases
LEFT JOIN dbo.covid_vaccinations AS vac
	ON cases.country = vac.country
	AND cases.date = vac.date
WHERE cases.continent = 'Africa'
GROUP BY cases.country
)

SELECT 
	country,
	total_cases,
	total_vaccinations
FROM vaccineCTE
WHERE (total_vaccinations = 0 OR total_vaccinations IS NULL)
AND total_cases > 0
ORDER BY total_cases DESC;


-- Drop View if it already exists
GO
DROP VIEW IF EXISTS dbo.v_AfricanCountriesNoVaccination;
GO

-- Create view to show countries that had cases but no vaccination numbers
GO
CREATE VIEW dbo.v_AfricanCountriesNoVaccination AS
WITH vaccineCTE AS (
SELECT 
	cases.country AS country,
	SUM(CAST(cases.new_cases AS BIGINT)) AS total_cases,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) AS total_vaccinations
FROM dbo.covid_cases AS cases
LEFT JOIN dbo.covid_vaccinations AS vac
	ON cases.country = vac.country
	AND cases.date = vac.date
WHERE cases.continent = 'Africa'
GROUP BY cases.country
)

SELECT 
	country,
	total_cases,
	total_vaccinations
FROM vaccineCTE
WHERE (total_vaccinations = 0 OR total_vaccinations IS NULL)
AND total_cases > 0
GO


-- Utilize saved view
SELECT *
FROM dbo.v_AfricanCountriesNoVaccination
ORDER BY total_cases DESC


-- Vacinnation rate against cases recorded and per population (Case study: Africa)
WITH casesVaccinesCTE AS (
SELECT 
	cases.country AS country,
	cases.population AS population,
	SUM(CAST(cases.new_cases AS BIGINT)) AS total_cases,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) AS total_vaccinations,
	MAX(CONVERT(BIGINT, ISNULL(vac.people_vaccinated, 0))) AS max_people_vaccinated
FROM dbo.covid_cases AS cases
LEFT JOIN dbo.covid_vaccinations AS vac
	ON cases.country = vac.country
	AND cases.date = vac.date
WHERE cases.continent = 'Africa'
GROUP BY cases.country, cases.population
)

SELECT 
	country,
	population,
	total_cases,
	total_vaccinations,
	max_people_vaccinated,
	CAST((ISNULL(total_vaccinations, 0) * 1.0 / NULLIF(total_cases, 0) * 100) AS DECIMAL(10,2)) AS vaccinations_rate_per_case,
	CAST((max_people_vaccinated * 1.0 / NULLIF(population, 0) * 100) AS DECIMAL (10,2)) AS vaccinatedPopulationPercentage
FROM casesVaccinesCTE
ORDER BY vaccinatedPopulationPercentage DESC

-- Vaccination rates across the continents
WITH countryPopulationCTE AS (
SELECT
	continent,
	country,
	MAX(population) AS unique_country_population,
	MAX(people_vaccinated) AS country_total_vaccinated
	FROM dbo.covid_vaccinations
	WHERE continent IS NOT NULL
	GROUP BY continent, country
)

SELECT
	continent,
	SUM(unique_country_population) AS total_Continental_Population,
	SUM(country_total_vaccinated) AS total_Continental_Vaccinated,
	ROUND((SUM(country_total_vaccinated) / NULLIF(SUM(unique_country_population), 0) * 100.0), 2) AS vaccinatedPopulationPercentage
FROM countryPopulationCTE
GROUP BY continent
ORDER BY vaccinatedPopulationPercentage DESC

-- Countries with the highest average positive rates of tests conducted (Case study: Africa)
SELECT
	country,
	CAST(ISNULL(AVG(positive_rate), 0.00) AS DECIMAL (10,2)) AS average_positive_rate_of_tests
	--CAST(AVG(positive_rate) AS DECIMAL (10,2)) AS average_positive_rate_of_tests
FROM dbo.covid_tests
WHERE continent = 'Africa'
GROUP BY country
ORDER BY average_positive_rate_of_tests DESC