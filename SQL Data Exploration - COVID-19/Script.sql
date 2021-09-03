/* 

COVID-19 Data Exploration using SQL.

Includes: Joins, Aggregate Functions, Casting Data Types, Common Table Expressions, Temporary Tables, Creating Views

Data Source:
Hannah Ritchie, Edouard Mathieu, Lucas Rodés-Guirao, Cameron Appel, Charlie Giattino, Esteban Ortiz-Ospina, Joe Hasell, Bobbie Macdonald, Diana Beltekian and Max Roser (2020) - "Coronavirus Pandemic (COVID-19)". Published online at OurWorldInData.org. Retrieved from: 'https://ourworldindata.org/coronavirus' [Online Resource]

Data downloaded on August 30th 2021

*/

-- Initial examination

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

-- Death as a percentage of the total cases

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
FROM CovidDeaths
Where continent is not null 
ORDER BY 1,2

-- Total cases as a percentage of the population

SELECT Location, date, population, total_cases, (total_cases/population) * 100 as InfectionPercentage
FROM CovidDeaths
Where continent is not null 
ORDER BY 1,2

-- Countries with highest infection rate 

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)) * 100 as PercentPopulationInfected
FROM CovidDeaths
WHERE continent is not null
GROUP BY population, location
ORDER BY PercentPopulationInfected DESC

-- Countries with highest infection rate by date

SELECT Location, population, date, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)) * 100 as PercentPopulationInfected
FROM CovidDeaths
WHERE continent is not null
GROUP BY population, location, date
ORDER BY PercentPopulationInfected DESC

-- Countries with highest death count

SELECT Location,  MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Continent with highest death count

SELECT Location,  MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Global cases, deaths, deaths as percentage of the population by date

SELECT date, SUM(new_cases) as Total_cases, SUM(cast(new_deaths as int)) as Total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage 
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- Global cases, deaths, deaths as percentage of the population total

SELECT SUM(new_cases) as Total_cases, SUM(cast(new_deaths as int)) as Total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage 
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingVaccinations
	FROM CovidDeaths dea
	Join CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Common Table Expression used to make calculations on the PARTITION BY in previous query
-- Currently shows population that received at least 1 dose of vaccine as a percentage

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingVaccinations)
as 
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingVaccinations
	FROM CovidDeaths dea
	Join CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null)
Select *, (RollingVaccinations/population) * 100 as PopulationVaccinated
FROM PopVsVac


-- Temp table used to make calculations on the PARTITION BY in previous query
-- Currently shows population that received at least 1 dose of vaccine as a percentage

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinations numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) as RollingVaccinations
	FROM CovidDeaths dea
	Join CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
SELECT *, (RollingVaccinations/population) * 100 as PopulationVaccinated
FROM #PercentPopulationVaccinated

-- Creating a View which can be used for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) as RollingVaccinations
	FROM CovidDeaths dea
	Join CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

