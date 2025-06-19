-- Preview the full datasets
SELECT * FROM Projects..CovidDeaths ORDER BY 3, 4;
SELECT * FROM Projects..CovidVaccinations ORDER BY 3, 4;

-- Focused dataset selection
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Projects..CovidDeaths
ORDER BY location, date;

-- Calculate death percentage per day per location
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    (CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)) * 100 AS Death_Percentage
FROM Projects..CovidDeaths
WHERE location LIKE 'Egypt'
ORDER BY location, date;

-- Calculate percentage of population infected with COVID
SELECT 
    location,
    date,
    population,
    total_cases,
    (CAST(total_cases AS FLOAT) / population) * 100 AS Percent_Population_Infected
FROM Projects..CovidDeaths
ORDER BY location, date;

-- Countries with highest infection rate (peak total cases relative to population)
SELECT 
    location,
    population,
    MAX(CAST(total_cases AS FLOAT)) AS Total_Infection_Cases,
    MAX((CAST(total_cases AS FLOAT) / NULLIF(population, 0)) * 100) AS Percent_Population_Infected
FROM Projects..CovidDeaths
GROUP BY location, population
ORDER BY Percent_Population_Infected DESC;

-- Countries with highest death count
SELECT 
    location,
    MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM Projects..CovidDeaths
GROUP BY location
ORDER BY Total_Death_Count DESC;

-- Death count breakdown for continents 
SELECT 
    location,
    MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM Projects..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Total_Death_Count DESC;

-- Global daily totals and death percentage
SELECT 
    date,
    SUM(CAST(new_cases AS BIGINT)) AS Total_New_Cases,
    SUM(CAST(new_deaths AS BIGINT)) AS Total_New_Deaths,
    (SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(CAST(new_cases AS FLOAT)), 0)) * 100 AS Death_Percentage
FROM Projects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Global summary stats
SELECT 
    SUM(CAST(new_cases AS BIGINT)) AS Total_New_Cases,
    SUM(CAST(new_deaths AS BIGINT)) AS Total_New_Deaths,
    (SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(CAST(new_cases AS FLOAT)), 0)) * 100 AS Death_Percentage
FROM Projects..CovidDeaths
WHERE continent IS NOT NULL;

-- Calculate percentage of vaccinated people using a CTE
WITH PopVsVac AS (
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS FLOAT)) 
            OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Total_Vaccinations
    FROM Projects..CovidDeaths dea
    JOIN Projects..CovidVaccinations vac
        ON dea.location = vac.location AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, 
       (Total_Vaccinations / NULLIF(population, 0)) * 100 AS Percentage_Vaccinated
FROM PopVsVac;

-- Temporary table approach for tracking vaccinations over time
DROP TABLE IF EXISTS #PercentPeopleVaccinated;

CREATE TABLE #PercentPeopleVaccinated (
    Continent VARCHAR(225),
    Location VARCHAR(225),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    Total_Vaccinations NUMERIC
);

INSERT INTO #PercentPeopleVaccinated
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) 
        OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Total_Vaccinations
FROM Projects..CovidDeaths dea
JOIN Projects..CovidVaccinations vac
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, 
       (Total_Vaccinations / NULLIF(population, 0)) * 100 AS Percentage_Vaccinated
FROM #PercentPeopleVaccinated;

-- Create a view for reusable vaccination analytics
DROP VIEW IF EXISTS PercentPeopleVaccinated
GO
CREATE VIEW PercentPeopleVaccinated AS
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) 
        OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Total_Vaccinations
FROM Projects..CovidDeaths dea
JOIN Projects..CovidVaccinations vac
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Preview the vaccination view
SELECT * FROM PercentPeopleVaccinated;