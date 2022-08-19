--SELECT * FROM PortfolioProject..CovidDeaths ORDER BY 3,4
--SELECT * FROM PortfolioProject..CovidVaccinations ORDER BY 3,4

-- Selecting Data that we're going to use
-- Ordering off of location and date

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2 

-- Total Cases vs Total Deaths (Percentage of people who died who had it)
-- Shows the likelihood of dying if you contract Covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%' and continent IS NOT NULL
ORDER BY 1,2



-- Total Cases vs Population (Shows what percentage of population actually got Covid)

SELECT location, date, total_cases, population, (total_cases/population)*100 as percent_population_infected
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%' and continent IS NOT NULL
ORDER BY 1,2



-- Countries with highest infection rate compared to population

SELECT location, MAX(total_cases) as highest_infection_count, population, (MAX(total_cases)/population)*100 as percent_population_infected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY ((MAX(total_cases)/population)*100) DESC



-- Countries with highest death count per population

SELECT location, MAX(total_deaths) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY MAX(total_deaths) DESC

-- Group by continent
-----------------------------------------------------------
-- "Correct" way to do this query
SELECT location, MAX(total_deaths) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY MAX(total_deaths) DESC
-----------------------------------------------------------

-- Using for Tableau / Drill Down
SELECT continent, MAX(total_deaths) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY MAX(total_deaths) DESC



-- Global numbers

SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2




-- Total Population vs Vaccinations using Self Join

SELECT vac2.continent, vac2.location, vac2.date, dea.population, vac2.new_vaccinations,
(
SELECT SUM(vac.new_vaccinations)
FROM PortfolioProject..CovidVaccinations vac
WHERE vac.date <= vac2.date
AND vac.location = vac2.location
AND vac.continent IS NOT NULL
) AS rolling_people_vaccinated
FROM PortfolioProject..CovidVaccinations vac2
JOIN PortfolioProject..CovidDeaths dea
	ON dea.location = vac2.location
	AND dea.date = vac2.date
WHERE vac2.continent IS NOT NULL
ORDER BY vac2.location, vac2.date ASC



-- Using a CTE

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT vac2.continent, vac2.location, vac2.date, dea.population, vac2.new_vaccinations,
(
SELECT SUM(vac.new_vaccinations)
FROM PortfolioProject..CovidVaccinations vac
WHERE vac.date <= vac2.date
AND vac.location = vac2.location
AND vac.continent IS NOT NULL
) AS rolling_people_vaccinated
FROM PortfolioProject..CovidVaccinations vac2
JOIN PortfolioProject..CovidDeaths dea
	ON dea.location = vac2.location
	AND dea.date = vac2.date
WHERE vac2.continent IS NOT NULL
)

SELECT *, (rolling_people_vaccinated/population)*100 AS rolling_vaccinated_percent
FROM pop_vs_vac



-- Using a temp table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population NUMERIC,
New_Vaccinations NUMERIC,
Rolling_People_Vaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT vac2.continent, vac2.location, vac2.date, dea.population, vac2.new_vaccinations,
(
SELECT SUM(vac.new_vaccinations)
FROM PortfolioProject..CovidVaccinations vac
WHERE vac.date <= vac2.date
AND vac.location = vac2.location
AND vac.continent IS NOT NULL
) AS rolling_people_vaccinated
FROM PortfolioProject..CovidVaccinations vac2
JOIN PortfolioProject..CovidDeaths dea
	ON dea.location = vac2.location
	AND dea.date = vac2.date
WHERE vac2.continent IS NOT NULL

SELECT *, (rolling_people_vaccinated/population)*100 AS rolling_vaccinated_percent
FROM #PercentPopulationVaccinated



-- Creating View to store for later total_vaccinations_per_hundred

CREATE VIEW PercentPopulationVaccinated as 
SELECT vac2.continent, vac2.location, vac2.date, dea.population, vac2.new_vaccinations,
(
SELECT SUM(vac.new_vaccinations)
FROM PortfolioProject..CovidVaccinations vac
WHERE vac.date <= vac2.date
AND vac.location = vac2.location
AND vac.continent IS NOT NULL
) AS rolling_people_vaccinated
FROM PortfolioProject..CovidVaccinations vac2
JOIN PortfolioProject..CovidDeaths dea
	ON dea.location = vac2.location
	AND dea.date = vac2.date
WHERE vac2.continent IS NOT NULL
--ORDER BY 2,3