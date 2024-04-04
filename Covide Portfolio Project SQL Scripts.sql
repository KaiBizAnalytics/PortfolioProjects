-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract Covid in your country
SELECT location, date, total_cases, total_deaths
, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Canada'
ORDER BY 1,2



-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
SELECT location, date, total_cases, Population
, (total_cases  / Population ) * 100 AS InfectionPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Canada'
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, Population, MAX(total_cases) AS HighestInfectionCount 
, MAX((total_cases/ Population) * 100) AS PopulationInfectionRate
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC


-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent iS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population
SELECT location AS continent, MAX(total_deaths) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent iS NULL 
		AND location NOT LIKE '%income%' 
		AND location NOT IN ('European Union', 'World')
GROUP BY location
ORDER BY TotalDeathCount DESC



-- GLOBAL NUMBERS
-- Shows the total number of total cases and total deaths to date
SELECT location, MAX(total_cases) AS total_cases, MAX(total_deaths) AS total_deaths
, MAX(total_deaths)/MAX(total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'World' 
GROUP BY location
ORDER BY 1, 2

-- Shows the total cases and total deaths by date (weekly)
SELECT date, MAX(total_cases) AS total_cases, MAX(total_deaths) AS total_deaths
, MAX(total_deaths)/MAX(total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location = 'Canada'
WHERE location = 'World' AND new_cases <> 0 -- new_cases and new_death are reported weekly
GROUP BY date
ORDER BY 1, 2


-- JOINING WITH THE VACCINATIONS TABLE TO DO MORE ANAYSES
-- Looking at Total Population vs Vaccinations
-- Shows the rolling number of people vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed
, SUM(CAST(vac.new_people_vaccinated_smoothed AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
	dea.date) AS RollingPeopleVaccinated, total_cases, total_deaths
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date= vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- USE CTE AND WINDOW FUNCTION
-- Shows the percentage of people vaccinated over time and comparing it to the death percentage over time
WITH PopvsVac AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed
, SUM(CAST(vac.new_people_vaccinated_smoothed AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
	dea.date) AS RollingPeopleVaccinated, total_cases, total_deaths
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date= vac.date
WHERE dea.continent IS NOT NULL)
--ORDER BY 2,3)

SELECT * , (RollingPeopleVaccinated/population) * 100 AS PopulationVaccincatedPercent, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PopvsVac
ORDER BY 2, 3



-- Shows the current percentage of people vaccinated by country and give each country a rank
WITH PopvsVac AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed
, SUM(CAST(vac.new_people_vaccinated_smoothed AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
	dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date= vac.date
WHERE dea.continent IS NOT NULL)
--ORDER BY 2,3)

SELECT location, MAX((RollingPeopleVaccinated/population) * 100) AS PopulationVaccincatedPercent,
RANK() OVER (ORDER BY MAX((RollingPeopleVaccinated/population) * 100) DESC) AS VaccinationRank
FROM PopvsVac
GROUP BY location
ORDER BY PopulationVaccincatedPercent DESC




-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(64),
Location nvarchar(255),
Date datetime,
Population float,
New_people_vaccinated_smoothed float,
RollingPeopleVaccinated float
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed
, SUM(CAST(vac.new_people_vaccinated_smoothed AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
	dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date= vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT * , (RollingPeopleVaccinated/population) * 100 AS PopulationVaccincatedPercent
FROM #PercentPopulationVaccinated
ORDER BY 2, 3



-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION

CREATE VIEW View_PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed
, SUM(CAST(vac.new_people_vaccinated_smoothed AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
	dea.date) AS RollingPeopleVaccinated, total_cases, total_deaths
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date= vac.date
WHERE dea.continent IS NOT NULL

