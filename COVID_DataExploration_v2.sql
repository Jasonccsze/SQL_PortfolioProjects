--Total deaths vs Total cases
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location = 'Hong Kong'
ORDER BY 1,2

--Total cases vs Population
SELECT location, date, total_cases, population, (total_cases/population)*100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location = 'Hong Kong'
ORDER BY 1,2

--Highest Infection Rate
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

--Highest Death Count / Population
SELECT location, MAX(cast (total_deaths as int)) AS HighestDeathCount, MAX((total_deaths/population))*100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathCount DESC

--Checking location vs continent
SELECT continent, MAX(cast (total_deaths as int)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC

SELECT location, MAX(cast (total_deaths as int)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NULL
and location NOT LIKE '%income%'
GROUP BY location
ORDER BY HighestDeathCount DESC

--Showing continents with highest death count / population
SELECT continent, MAX(cast (total_deaths as int)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC


--1. Getting global numbers by SUM
SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1
--Double checking with 'World' number
SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location = 'World'
ORDER BY 1
--Double checking with 'World' and MAX
SELECT MAX(total_cases) AS TotalCases, MAX(cast(total_deaths as int)) AS TotalDeaths, MAX(cast(total_deaths as int))/MAX(total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location = 'World'
ORDER BY 1
--The difference in the numbers is less than 0.2%, the 1st set is kept for visualisation


--2. Getting regional death numbers by SUM
--EU is included in Europe, income groups are required
SELECT location, SUM(cast(new_deaths as int)) AS TotalDeaths
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NULL
and location not in ('World', 'European Union', 'International')
and location not like '%income%'
GROUP BY location
ORDER BY 2 DESC


--3. Getting infected numbers and percentages of locations
SELECT location, population, MAX(total_cases) AS InfectionCount, MAX(total_cases/population)*100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths$
GROUP BY location, population
ORDER BY 4 DESC


--4. Getting daily infected numbers and percentages of locations
SELECT location, population, date, MAX(total_cases) AS InfectionCount, MAX(total_cases/population)*100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths$
GROUP BY location, population, date
ORDER BY 1,3


--Joining Tables to get Cumulative Vaccinated Number
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CumulativeVac
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3

--Creating CTE to use Cumulative Vaccinated Number for Percentage Calculation
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, CumulativeVac)
AS
(
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CumulativeVac
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is NOT NULL
--ORDER BY 2,3
)
SELECT *, (CumulativeVac/Population)*100 AS VacPercentage
FROM PopvsVac

--Creating TEMP TABLE to use Cumulative Vaccinated Number for Calculation
--DROP TABLE if exists #VacPercentage
CREATE TABLE #VacPercentage
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
CumulativeVac numeric)

INSERT INTO #VacPercentage
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Cumulative
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is NOT NULL
--ORDER BY 2,3

SELECT *, (CumulativeVac/Population)*100 AS VacPercentage
FROM #VacPercentage
ORDER BY 2,3

--Creating View for Visualisation
CREATE VIEW VacPercentage AS
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CumulativeVac
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is NOT NULL

SELECT *
FROM VacPercentage