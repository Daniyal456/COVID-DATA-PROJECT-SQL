SELECT *
FROM [Portfolio Project _1]..['covid deaths$']



--Select data that we will be using
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM [Portfolio Project _1]..['covid deaths$']

-- Looking at Total Cases vs Total Deaths for United States

SELECT location,date,total_cases,total_deaths, (total_deaths/total_cases) * 100as death_ratio
FROM [Portfolio Project _1]..['covid deaths$']
WHERE location like '%States%'
ORDER BY 1,2 -- to order by data and location

--Looking at Total Cases vs Population for United States

SELECT location,date,total_cases, population,(total_cases/population) * 100 as infection_rate
FROM [Portfolio Project _1]..['covid deaths$']
WHERE location like '%States%'
ORDER BY 1,2

-- TO CHECK COUNTRIES WITH THE HIGHEST INFECTION COUNTS AND INFECTION RATES
SELECT location, MAX(total_cases) as highest_infection_count, population, MAX(total_cases/population) * 100 as max_infection_rate
FROM [Portfolio Project _1]..['covid deaths$']
GROUP BY location,population
ORDER BY max_infection_rate DESC

-- LOOKING AT DEATH COUNTS BY COUNTRY
SELECT location, MAX(cast(total_deaths as int)) as total_death_count--CASTING total_deaths as int, to perform function MAX on it
FROM [Portfolio Project _1]..['covid deaths$']
WHERE continent is not null-- DROPS ALL ROWS WHERE THERE IS A NULL VALUE FOR COUNTRY
GROUP BY location	
ORDER BY total_death_count DESC

-- COVID DEATHS BY CONTINENT--

SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM [Portfolio Project _1]..['covid deaths$']
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count DESC 

-- GLOBAL NUMBERS--

--TOTAL GLOBAL DEATHS AND DEATH PERCENTAGES
SELECT SUM(total_cases) as TOTAL_CASES, SUM(cast(total_deaths as BIGINT)) as TOTAL_DEATHS,(SUM(cast(total_deaths as BIGINT))/SUM(total_cases)) *100 as death_percentage-- WE USE BIGINT WHEN THE NUMBER IS LARGER THAN 4 BYTES
FROM [Portfolio Project _1]..['covid deaths$']
--GROUP BY date
ORDER BY 1,2

--JOINING ANOTHER TABLE (COVID VACCINATIONS) ON COVID DEATHS --
--CHECKING FOR COVID VACCINATIONS IN CANADA--
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rolling_new_vax-- PARTITION ALLOWS US TO APPLY SUM FUNCTION OVER SAME LOCATIONS AND RESTART WHEN THE LOCATION CHANGES, THIS WE CAN CREATE A RUNNING TOTAL OF VACCINATIONS IN CANADA
FROM [Portfolio Project _1]..['covid vaccinations$'] vac
JOIN [Portfolio Project _1]..['covid deaths$'] dea
ON vac.location =dea.location 
AND vac.date = dea.date --THE COLUMN ON WHICH THE TABLES ARE JOINED--
WHERE dea.continent IS NOT NULL AND dea.location = 'Canada'
ORDER BY 1,2,3

-- TO PERFORM QUERIES ON JOINED TABLES, WE USE A CTE--

WITH pops_vs_vac (continent, location, date, population, new_vaccinations, rolling_new_vax)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rolling_new_vax
FROM [Portfolio Project _1]..['covid vaccinations$'] vac
JOIN [Portfolio Project _1]..['covid deaths$'] dea
ON vac.location =dea.location
AND vac.date = dea.date
WHERE dea.continent IS NOT NULL AND dea.location = 'Canada'
)

SELECT *, (rolling_new_vax/population) *100 AS vaccination_rate
FROM pops_vs_vac

--CREATING VIEW FOR VISUALIZATION, THEY ARE BETTER THEN CTEs BECAUSE THEY CAN BE SAVED LIKE TABLES--

GO
CREATE VIEW view_a as

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rolling_new_vax
FROM [Portfolio Project _1]..['covid vaccinations$'] vac
JOIN [Portfolio Project _1]..['covid deaths$'] dea
ON vac.location =dea.location
AND vac.date = dea.date
WHERE dea.continent IS NOT NULL

select *
from dbo.view_a


-- QUEREY FOR TABLEAU # 1--
CREATE VIEW death_rate AS
Select continent,location,SUM(new_cases) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths, SUM(cast(new_deaths as bigint))/SUM(New_Cases)*100 as DeathPercentage
From [Portfolio Project _1]..['covid deaths$']
--Where location like '%states%'
Where location is not null and continent is not null and location not in ('World', 'European Union', 'International')
Group By continent, location
--order by 1,2
 
 -- VIEW FOR TABLEAU # 2--
 GO
 CREATE VIEW death_count AS
 Select location, continent,SUM(cast(new_deaths as bigint)) as TotalDeathCount
From [Portfolio Project _1]..['covid deaths$']
--Where location like '%states%'
Where location is not null and continent is not null and location not in ('World', 'European Union', 'International')
Group by location,continent
--order by TotalDeathCount desc

-- QUERY FOR TABLEAU # 3--
GO
CREATE VIEW infection_count_p_p_infected AS
Select Continent,Location, Population, SUM(total_cases) as InfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From [Portfolio Project _1]..['covid deaths$']
Where location is not null and continent is not null and population is not null and location not in ('World', 'European Union', 'International')
Group by Location, Continent, Population
--order by PercentPopulationInfected desc
select *
from infection_count_p_p_infected
order by continent