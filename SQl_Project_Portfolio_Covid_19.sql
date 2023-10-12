SELECT * 
FROM sql_project_portfolio.coviddeaths
ORDER BY 3,5;

-- SELECT THE DATA THAT WE ARE GOING TO USE 
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM sql_project_portfolio.coviddeaths
ORDER BY location,date;

-- SIMPLE CALCULATION
-- TOTAL CASES VS TOTAL DEATHS IN PERCENTAGE 
-- THis shows liklihood of dying if you contact through covid in my country 
SELECT location,date,total_cases,total_deaths ,((total_deaths/total_cases)*100) AS Death_Percentage
FROM sql_project_portfolio.coviddeaths
-- GROUP BY location
WHERE location = "India"
ORDER BY 3 DESC;

-- Now we are looking at the Total Cases VS Population 
-- IT shows what percentage of poupulation get in contact with COVID 
SELECT location,date,total_cases,total_deaths,population,((total_cases/population)*100) AS Affect_Percentage
FROM sql_project_portfolio.coviddeaths
-- GROUP BY location
WHERE location = "India"
ORDER BY 4 asc;

-- Looking at countries with Highest Infection rate compared to population
SELECT location,population,MAX(total_cases) as Highest_Infection_Count,MAX(((total_cases/population)*100)) AS Affect_Percentage, ((Sum(total_cases))/population)*100 AS Double_Infected
FROM sql_project_portfolio.coviddeaths
GROUP BY location,population
-- WHERE location = "India"
ORDER BY  4 DESC;

-- SHowing Countries with Highest Death Counts 
-- WE ARE USING THE WHERE CLAUSE FOR THE CONTINET BECAUSE WE CAN SEE THE CONTINETS IN THE LOCATION AS WELL 

SELECT location, MAX(total_deaths) AS Total_Death_Counts
FROM sql_project_portfolio.coviddeaths
WHERE continent is not null
GROUP BY location
-- WHERE location = "India"
ORDER BY  2 DESC;

-- IF THE TOTAL_DEATH IS IN VARCHAR OR STRING WE CAN CAST THEM INTO INTO BY USING CAST FUNCTION 
/*
SELECT location, MAX(CAST(total_deaths AS INT)) AS Total_Death_Counts
FROM sql_project_portfolio.coviddeaths
GROUP BY location
-- WHERE location = "India"
ORDER BY  2 DESC;
*/

-- Lets Brake things down on the continent

SELECT distinct LOCATION,continent, MAX(total_deaths) AS Total_Death_Counts
FROM sql_project_portfolio.coviddeaths
WHERE continent is not null
GROUP BY continent,location
-- WHERE location = "India"
ORDER BY  3 DESC;


SELECT distinct LOCATION, continent,MAX(Population)
FROM sql_project_portfolio.coviddeaths
WHERE continent is not null
GROUP BY continent,location
ORDER BY  2 ;

-- GLOBAL NUMBERS 
SELECT location,population,MAX(total_cases) as Highest_Infection_Count,MAX(((total_cases/population)*100)) AS Affect_Percentage, ((Sum(total_cases))/population)*100 AS Double_Infected
FROM sql_project_portfolio.coviddeaths
WHERE continent = "World"
GROUP BY location,population
ORDER BY  4 DESC;

-- Checking the death rate and affected rate of the entire world 
SELECT location,
		SUM(total_cases) as Total_Cases_World,
		SUM(population) AS Total_Population_World,
        SUM(total_deaths) AS Total_Deaths_World,
        ((SUM(total_cases)/SUM(population)) * 100) AS Total_People_Affected_Percentage,
		((SUM(total_deaths)/SUM(population)) * 100) AS Total_People_Deaths_Percentage
FROM sql_project_portfolio.coviddeaths
WHERE location = "World"
GROUP BY location;

-- Filtering out the data by datewise 
SELECT date,SUM(total_cases) as Total_Cases_World,
		SUM(population) AS Total_Population_World,
        SUM(total_deaths) AS Total_Deaths_World,
        ((SUM(total_cases)/SUM(population)) * 100) AS Total_People_Affected_Percentage,
		((SUM(total_deaths)/SUM(population)) * 100) AS Total_People_Deaths_Percentage
FROM sql_project_portfolio.coviddeaths
WHERE continent IS NOT NULL
GROUP BY date;


-- Merging or Joining both the tables now 

SELECT * 
FROM coviddeaths dea
JOIN covidvaccination vac
ON dea.date=vac.date 
	AND 
	dea.location=vac.location;
    
-- Merging on some selected columns 
SELECT dea.continent,dea.location,dea.population,dea.date,vac.new_vaccinations
FROM coviddeaths dea
JOIN covidvaccination vac
ON dea.date=vac.date 
	AND 
	dea.location=vac.location
WHERE dea.continent IS NOT NULL;

-- LOOKING AT TOTAL POPULATION VS VACCINATIONS 
SELECT dea.continent,dea.location,dea.population,dea.date,vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS Rolling_People_Vaccinated 
-- As we have created "Rolling_People_Vaccinated" Alias name now i want to perform action on this but it is not possible 
FROM coviddeaths dea
JOIN covidvaccination vac
ON dea.date=vac.date 
	AND 
	dea.location=vac.location
-- WHERE dea.location ="India";
WHERE dea.continent IS NOT NULL;

-- Want to convert the column into integer
/*
1. Cast as int 

SELECT dea.continent,dea.location,dea.population,dea.date,vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations) as INT ) OVER (PARTITION BY dea.location)
FROM coviddeaths dea
JOIN covidvaccination vac
ON dea.date=vac.date 
	AND 
	dea.location=vac.location
WHERE dea.location ="India";



2. Convert into INT as well 


SELECT dea.continent,dea.location,dea.population,dea.date,vac.new_vaccinations,
SUM(Convert(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location)
FROM coviddeaths dea
JOIN covidvaccination vac
ON dea.date=vac.date 
	AND 
	dea.location=vac.location
WHERE dea.location ="India";


*/

-- USING OF CTE'S 
-- Number of Columns in the CTE must be same as the number of columns in the query 

WITH PopVSVac(Continents,Locations,Total_Population,Date_DD_MM_YYYY,New_Vaccinations,Rolling_People_Vaccinated)
AS
(
SELECT dea.continent,dea.location,dea.population,dea.date,vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS Rolling_People_Vaccinated 
-- As we have created "Rolling_People_Vaccinated" Alias name now i want to perform action on this but it is not possible 
FROM coviddeaths dea
JOIN covidvaccination vac
ON dea.date=vac.date 
	AND 
	dea.location=vac.location
WHERE dea.location ="India"
-- WHERE dea.continent IS NOT NULL
)
SELECT *, ((Rolling_People_Vaccinated/Total_Population)*100) AS Percentage_of_People_Vaccinated
FROM PopVSVac;


-- DOING THE SAME EXAMPLE USING TEMP TABLES 
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Population double,
Date text,
New_Vaccination double,
Rolling_People_Vaccinated double
); 

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent,dea.location,dea.population,dea.date,vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS Rolling_People_Vaccinated 
-- As we have created "Rolling_People_Vaccinated" Alias name now i want to perform action on this but it is not possible 
FROM coviddeaths dea
JOIN covidvaccination vac
ON dea.date=vac.date 
	AND 
	dea.location=vac.location
WHERE dea.location ="India";

SELECT * 
FROM PercentPopulationVaccinated;

-- CREATING VIEWS TO STORE DATA FOR LATER VISULATIONS 
CREATE VIEW PercentPopulationVaccinated
AS 
SELECT dea.continent,dea.location,dea.population,dea.date,vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS Rolling_People_Vaccinated 
-- As we have created "Rolling_People_Vaccinated" Alias name now i want to perform action on this but it is not possible 
FROM coviddeaths dea
JOIN covidvaccination vac
ON dea.date=vac.date 
	AND 
	dea.location=vac.location
WHERE dea.location IS NOT NULL;
