Select * from 
Projects..CovidDeaths
order by 3,4

Select * from 
Projects..CovidVaccinations
order by 3,4

-- Select the data that i will be using
Select location,date,total_cases,new_cases,total_deaths,population
from Projects..CovidDeaths
order by 1,2

-- Calculate Death percentage
Select location,date,total_cases,total_deaths,(cast(total_deaths as float)/cast(total_cases as float))*100 as Death_Percentage
from Projects..CovidDeaths
where location like 'Egypt'
order by 1,2

-- Calculate Percentage of Population got Covid
Select location,date,population,total_cases,(cast(total_cases as float)/population)*100 as PercentPopulationInfected
from Projects..CovidDeaths
-- where location like 'Egypt'
order by 1,2

-- looking for countries with Highest infection rate
Select location,population,Max(cast(total_cases as float)) AS Total_infection_cases,Max((cast(total_cases as float)/population)*100) as Percent_Population_Infected
from Projects..CovidDeaths
Group by location,population
order by Percent_Population_Infected Desc

-- looking for countries with Highest death count
Select location , Max(cast(total_deaths AS int)) As Total_death_count
from Projects..CovidDeaths
Group by location
order by Total_death_count Desc


-- Break Down by Continent
Select location, MAX(cast(total_deaths AS int)) As Total_death_count
from Projects..CovidDeaths
Where continent is null
Group by location
order by Total_death_count Desc;

-- Globel numbers
SELECT 
    date, 
    SUM(CAST(new_cases AS BIGINT)) AS Total_New_cases, 
    SUM(CAST(new_deaths AS BIGINT)) AS Total_New_deaths, 
    (SUM(CAST(new_deaths AS FLOAT)) / SUM(CAST(new_cases AS FLOAT))) * 100 AS Death_percentage
FROM Projects..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY date,2;

SELECT  
    SUM(CAST(new_cases AS BIGINT)) AS Total_New_cases, 
    SUM(CAST(new_deaths AS BIGINT)) AS Total_New_deaths, 
    (SUM(CAST(new_deaths AS FLOAT)) / SUM(CAST(new_cases AS FLOAT))) * 100 AS Death_percentage
FROM Projects..CovidDeaths
WHERE continent is not null;

--Calculate precantage of vaccinated people

With PopvsVac (Continent,location,date,population,new_vaccinations,Total_Vaccinations)
AS (
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS Total_Vaccinations
FROM Projects..CovidDeaths dea
JOIN Projects..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT * , (Total_Vaccinations/population)* 100 AS Percentage_Vaccinated
FROM PopvsVac

-- Create TEMP Table (Another way of precantage of vaccinated people table)

DROP TABLE IF EXISTS #PercentPeopleVaccinated;

CREATE TABLE #PercentPeopleVaccinated (
    Continent VARCHAR(225),
    location VARCHAR(225),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    Total_Vaccinations NUMERIC
);

INSERT INTO #PercentPeopleVaccinated
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Total_Vaccinations
FROM Projects..CovidDeaths dea
JOIN Projects..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
order by 2,3

SELECT *, (Total_Vaccinations / population) * 100 AS Percentage_Vaccinated
FROM #PercentPeopleVaccinated;

Create view PercentPeopleVaccinated as
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Total_Vaccinations
FROM Projects..CovidDeaths dea
JOIN Projects..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

Select *
from PercentPeopleVaccinated