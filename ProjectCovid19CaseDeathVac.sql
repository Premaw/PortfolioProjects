
--Data from https://ourworldindata.org/covid-deaths as of 10/08/2022

select *
from ProjectCovidDeath..CovidDeaths
order by 3,4

select *
from ProjectCovidDeath..CovidVaccination
order by 3,4


-------------------------------------------------------------------------------------------------
--Formating data type

--Converting datetime to date format

alter table ProjectCovidDeath..CovidDeaths
add date_converted date;

Update ProjectCovidDeath..CovidDeaths
set date_converted = CONVERT(date, date)

alter table ProjectCovidDeath..CovidDeaths
drop column date;

alter table ProjectCovidDeath..CovidVaccination
add date_converted date;

Update ProjectCovidDeath..CovidVaccination
set date_converted = CONVERT(date, date)

alter table ProjectCovidDeath..CovidVaccination
drop column date;

--Converting nvarchar to int for total_deaths
 
alter table ProjectCovidDeath..CovidDeaths
add total_deaths_converted float;

Update ProjectCovidDeath..CovidDeaths
set total_deaths_converted = CONVERT(float, total_deaths)

alter table ProjectCovidDeath..CovidDeaths
drop column total_deaths;

--Converting nvarchar to int for new_deaths

alter table ProjectCovidDeath..CovidDeaths
add new_deaths_converted float;

Update ProjectCovidDeath..CovidDeaths
set new_deaths_converted = CONVERT(float, new_deaths)

alter table ProjectCovidDeath..CovidDeaths
drop column new_deaths;

--Converting nvarchar to int for people_vaccinated

alter table ProjectCovidDeath..CovidVaccination
add people_vaccinated_converted float;

Update ProjectCovidDeath..CovidVaccination
set people_vaccinated_converted = CONVERT(float, people_vaccinated)

alter table ProjectCovidDeath..CovidVaccination
drop column people_vaccinated;

--Converting nvarchar to int for people_fully_vaccinated

alter table ProjectCovidDeath..CovidVaccination
add people_fully_vaccinated_converted float;

Update ProjectCovidDeath..CovidVaccination
set people_fully_vaccinated_converted = CONVERT(float, people_fully_vaccinated)

alter table ProjectCovidDeath..CovidVaccination
drop column people_fully_vaccinated;


-------------------------------------------------------------------------------------------------
--Checking duplicated data

select continent, location
from ProjectCovidDeath..CovidDeaths
group by continent, location
order by 1,2
--Output: there are duplicated data when continent is NULL and is not NULL
--Duplicated data is where continent is NULL and location are in ('World', 'Upper middle income','High income', 'Lower middle income', 'European Union', 'Low income', 'International')
--Data where continent is NULL will not be used

--Counting locations

select continent, location, count(distinct location)
from ProjectCovidDeath..CovidDeaths
where continent is not null
group by continent, location
order by 1,2
--Output: There are 231 locations where continent is not null that will be using

--Finding the different number of population where (continent is null and location = 'World') vs. (continent is not NULL)

select date_converted, continent, location, population
from ProjectCovidDeath..CovidDeaths
where location = 'World' and date_converted = 
(select max(date_converted)
from ProjectCovidDeath..CovidDeaths)
--Output: Population = 7,909,295,152 where continent is null and location = 'World'

select date_converted, sum(population)
from ProjectCovidDeath..CovidDeaths
where continent is not NULL and date_converted = 
(select max(date_converted)
from ProjectCovidDeath..CovidDeaths)
group by date_converted
--Output: Population = 7,898,275,810 where continent is not NULL
--0.14% of population are missing if continent is not NULL compare to population where location = 'World'
--Note: population is constant over time in this data set


-------------------------------------------------------------------------------------------------
--Checking rolling_new_cases vs. total_case whether there are any differences.
--Using CTE

with cte_cases (date_converted
				, continent
				, location
				, population
				, new_cases
				, rolling_new_cases
				, total_cases)
	as (select date_converted
			  , continent
		      , location
		      , population
		      , new_cases
		      , sum(new_cases) over (partition by location order by location, date_converted) as rolling_new_cases
		      , total_cases 
	   from ProjectCovidDeath..CovidDeaths
	   where continent is not null
	   )

select date_converted
	    , continent
		, location
		, population
		, new_cases
		, rolling_new_cases
		, total_cases
		, rolling_new_cases - total_cases as diff_rollingandtotal
from cte_cases
/*where date_converted = '2022-08-10' 
order by diff_rollingandtotal*/
where location in ('United Kingdom', 'Turkey', 'France', 'Spain') --Sample of location that number are different.
order by location, date_converted
--Output: sum of new_cases (rolling_new_cases) and total_cases of some location are different. 
--Some of new_cases are missing and some of total_cases are less than the day before (total_cases should be equal to or more than the day before), so they both have missing data.

--Finding number of difference of rolling_new_cases and total_cases

with cte_cases (date_converted
				, continent
				, location
				, population
				, new_cases
				, rolling_new_cases
				, total_cases)
	as (select date_converted
			  , continent
		      , location
		      , population
		      , new_cases
		      , sum(new_cases) over (partition by location order by location, date_converted) as rolling_new_cases
		      , total_cases 
	   from ProjectCovidDeath..CovidDeaths
	   where continent is not null
	   )

select date_converted
		, sum(rolling_new_cases) as sum_rolling_new_cases
		, sum(total_cases) as sum_total_cases
		, sum(rolling_new_cases - total_cases)*100/((sum(rolling_new_cases)+sum(total_cases))/2) as diff_percentage 
from cte_cases
where date_converted = '2022-08-10'
group by date_converted
--Output: the different between rolling_new_cases and total_cases is 0.2%
--Sum of total_cases is more than sum of rolling_new_cases


-------------------------------------------------------------------------------------------------
--Checking rolling_new_deaths vs. total_deaths to see if there are any differences
--Using temporary table

drop table if exists #RollingNewDeathVsTotalDeaths

create table #RollingNewDeathVsTotalDeaths
(continent nvarchar(255),
 location nvarchar(255),
 date date, 
 population numeric,
 new_deaths numeric,
 rolling_new_deaths numeric,
 total_deaths numeric
)

insert into #RollingNewDeathVsTotalDeaths
select 
	continent
	, location
	, date_converted
	, population
	, new_deaths_converted 
	, sum(new_deaths_converted) over (partition by location order by location, date_converted) as rolling_new_deaths
	, total_deaths_converted
from ProjectCovidDeath..CovidDeaths
where continent is not null 

select *, rolling_new_deaths - total_deaths as diff_rollingandtotal
from #RollingNewDeathVsTotalDeaths
/*where date = '2022-08-10'
order by diff_rollingandtotal*/ 
where location in ('Ecuador', 'India', 'Spain') --Sample of location that number are different.
order by location, date
--Output: sum of new_deaths (rolling_new_deaths) and total_deaths of some location are different. 
--Some of new_deaths are missing and some of total_deaths are less than the day before (total_deaths should be equal to or more than the day before), so they both have missing data.

--Finding number of difference of rolling_new_cases and total_cases

select date
		, sum(rolling_new_deaths) as sum_rolling_new_death
		, sum(total_deaths) as sum_total_death
		, sum(rolling_new_deaths - total_deaths)*100/((sum(rolling_new_deaths)+sum(total_deaths))/2) as diff_percentage 
from #RollingNewDeathVsTotalDeaths
where date = '2022-08-10'
group by date
--Output: the different between rolling_new_cases and total_cases is 0.6%
--Sum of total_deaths_converted is more than sum of rolling_new_deathed


-------------------------------------------------------------------------------------------------
--Replacing NULL on people_vaccinated and people_fully_vaccinated with a number from a previous day.
--Number of vaccinated people only show on the reported day, if it was not reported on the next day, it shows NULL on that next day instead of showing the same number of the previous day.  
--Using CTE, OVER, FIRST_VALUE

with cte_grouped_vaccinated as
	(select 
		date_converted
		, location
		, people_vaccinated_converted
		, count(people_vaccinated_converted) over (partition by location order by location, date_converted) as grouped_people_vaccinated
		, people_fully_vaccinated_converted
		, count(people_fully_vaccinated_converted) over (partition by location order by location, date_converted) as grouped_people_fully_vaccinated 
	 from ProjectCovidDeath..CovidVaccination
	 where continent is not null
	)
, cte_filled_vaccinated as
	(
	 select 
		date_converted
		, location
		, people_vaccinated_converted
		, grouped_people_vaccinated
		, first_value(people_vaccinated_converted) over (partition by grouped_people_vaccinated, location order by location, date_converted) as filled_people_vaccinated
		, people_fully_vaccinated_converted
		, grouped_people_fully_vaccinated
		, first_value(people_fully_vaccinated_converted) over (partition by grouped_people_fully_vaccinated, location order by location, date_converted) as filled_people_fully_vaccinated
	 from cte_grouped_vaccinated
	)
select date_converted, location, people_vaccinated_converted, filled_people_vaccinated, people_fully_vaccinated_converted, filled_people_fully_vaccinated
from cte_filled_vaccinated
order by location, date_converted


-------------------------------------------------------------------------------------------------
--Joining table CovidDeaths and cte_filled_vaccinated 
--Replacing NULL by 0 for later visualisation

with cte_grouped_vaccinated as
	(
	 select 
		date_converted
		, location
		, people_vaccinated_converted
		, count(people_vaccinated_converted) over (partition by location order by location, date_converted) as grouped_people_vaccinated
		, people_fully_vaccinated_converted
		, count(people_fully_vaccinated_converted) over (partition by location order by location, date_converted) as grouped_people_fully_vaccinated 
	 from ProjectCovidDeath..CovidVaccination
	 where continent is not null
	)
, cte_filled_vaccinated as
	(
	 select 
		date_converted
		, location
		, people_vaccinated_converted
		, grouped_people_vaccinated
		, first_value(people_vaccinated_converted) over (partition by grouped_people_vaccinated, location order by location, date_converted) as filled_people_vaccinated
		, people_fully_vaccinated_converted
		, grouped_people_fully_vaccinated
		, first_value(people_fully_vaccinated_converted) over (partition by grouped_people_fully_vaccinated, location order by location, date_converted) as filled_people_fully_vaccinated
	 from cte_grouped_vaccinated
	)

select dea.date_converted
	   , dea.continent
	   , dea.location
	   , dea.population
	   , isnull(dea.total_cases,0) as totol_cases
	   , isnull(dea.new_cases,0) as new_cases
	   , isnull(dea.total_deaths_converted,0) as total_deaths
	   , isnull(dea.new_deaths_converted,0) as new_deaths
	   , isnull(vac.filled_people_vaccinated,0) as people_vaccinated
	   , isnull(vac.filled_people_fully_vaccinated,0) as people_fully_vaccinated
	   , isnull(dea.total_cases/dea.population*100,0) as case_percentage 
	   , isnull(dea.total_deaths_converted/dea.population*100,0) as death_percentage
	   , isnull(vac.filled_people_vaccinated/dea.population*100,0) as vaccinated_percentage
	   , isnull(vac.filled_people_fully_vaccinated/dea.population*100,0) as fully_vaccinated_percentage
from ProjectCovidDeath..CovidDeaths dea
join cte_filled_vaccinated vac
	on dea.location = vac.location
	and dea.date_converted = vac.date_converted
where dea.continent is not null