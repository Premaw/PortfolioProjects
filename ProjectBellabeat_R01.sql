
select *
from ProjectBellabeat.dbo.dailyActivity_merged
order by Id, ActivityDateConverted

select *
from ProjectBellabeat.dbo.hourlyCalories_merged

select *
from ProjectBellabeat.dbo.hourlyIntensities_merged

select *
from ProjectBellabeat.dbo.hourlySteps_merged

select * 
from ProjectBellabeat.dbo.sleepDay_merged

select *
from ProjectBellabeat.dbo.minuteSleep_merged

select * 
from ProjectBellabeat.dbo.weightLogInfo_merged


-------------------------------------------------------------------------------------------------
--Formating data type
--Using ALTER TABLE, UPDATE and CONVERT


--Converting varchar(50) to date format for ActivityDate

alter table ProjectBellabeat.dbo.dailyActivity_merged
add ActivityDateConverted date

Update ProjectBellabeat.dbo.dailyActivity_merged
set ActivityDateConverted = CONVERT(date, ActivityDate)

alter table ProjectBellabeat.dbo.dailyActivity_merged
drop column ActivityDate


--Converting varchar(50) to int format for TotalSteps

alter table ProjectBellabeat.dbo.dailyActivity_merged
add TotalStepsConverted int

Update ProjectBellabeat.dbo.dailyActivity_merged
set TotalStepsConverted = CONVERT(int, TotalSteps)

alter table ProjectBellabeat.dbo.dailyActivity_merged
drop column TotalSteps


--Converting varchar(50) to float format for TotalDistance

alter table ProjectBellabeat.dbo.dailyActivity_merged
add TotalDistanceConverted float

Update ProjectBellabeat.dbo.dailyActivity_merged
set TotalDistanceConverted = CONVERT(float, TotalDistance)

alter table ProjectBellabeat.dbo.dailyActivity_merged
drop column TotalDistance

--Converting varchar(50) to datetime format for ActivityHour

alter table ProjectBellabeat.dbo.hourlyCalories_merged
add ActivityHourConverted datetime

Update ProjectBellabeat.dbo.hourlyCalories_merged
set ActivityHourConverted = CONVERT(datetime, ActivityHour)

alter table ProjectBellabeat.dbo.hourlyCalories_merged
drop column ActivityHour


-------------------------------------------------------------------------------------------------
--Checking blank, primary key is Id.
--Using COUNT

select COUNT(Id),
	   COUNT(ActivityDateConverted),
	   COUNT(TotalStepsConverted),
	   COUNT(TotalDistanceConverted),
	   COUNT(TrackerDistanceConverted),
	   COUNT(LoggedActivitiesDistanceConverted),
	   COUNT(VeryActiveDistanceConverted),
	   COUNT(ModeratelyActiveDistanceConverted),
	   COUNT(LightActiveDistanceConverted),
	   COUNT(SedentaryActiveDistanceConverted),
	   COUNT(VeryActiveMinutesConverted),
	   COUNT(FairlyActiveMinutesConverted),
	   COUNT(LightlyActiveMinutesConverted),
	   COUNT(SedentaryMinutesConverted),
	   COUNT(CaloriesConverted)
from ProjectBellabeat.dbo.dailyActivity_merged
--There is no blank.


-------------------------------------------------------------------------------------------------
--Checking number of primary key
--Using COUNT and DISTINCT

select count (distinct Id)
from ProjectBellabeat.dbo.dailyActivity_merged
order by 1
--There are 33 unique Id for dailyActivity_merged table.

select count (distinct Id)
from ProjectBellabeat.dbo.sleepDay_merged
order by 1
--There are 24 unique Id for sleepDay_merged table.


-------------------------------------------------------------------------------------------------
--Checking duplication on dailyActivity_merged table
--Using DISTINCT and CONCAT

select distinct CONCAT(Id, ActivityDateConverted)
from ProjectBellabeat.dbo.dailyActivity_merged
order by 1
--There are 940 rows and they are all unquie, so, there is no duplication in dailyActivity_merged table.


--Checking duplication on sleepDay_merged table
--Using COUNT and HAVING

select Id
		, SleepDayConverted
		, TotalSleepRecordsConverted
		, TotalMinutesAsleepConverted
		, TotalTimeInBedConverted 
		, COUNT(*) as CNT
from ProjectBellabeat.dbo.sleepDay_merged
group by Id
		, SleepDayConverted
		, TotalSleepRecordsConverted
		, TotalMinutesAsleepConverted
		, TotalTimeInBedConverted 
having COUNT(*) > 1
--There are 3 duplicated rows in sleepDay_merged table.


-------------------------------------------------------------------------------------------------
--Delete duplicated rows on sleepDay_merged table
--Using CTE and ROW_NUMBER

with cte (
			Id
			, SleepDayConverted
			, TotalSleepRecordsConverted
			, TotalMinutesAsleepConverted
			, TotalTimeInBedConverted
			, RowNumber
		) as (select Id
					, SleepDayConverted
					, TotalSleepRecordsConverted
					, TotalMinutesAsleepConverted
					, TotalTimeInBedConverted
					, row_number() OVER(PARTITION BY Id, SleepDayConverted ORDER BY Id , SleepDayConverted) as RowNumber
			  From ProjectBellabeat.dbo.sleepDay_merged)

delete 
from cte
where RowNumber > 1


-------------------------------------------------------------------------------------------------
--Removing outliers
--Human body burns calories even when sleeping, an average of calories burned for one day of doing notheing is more than 1,000. So the calories data less than 1,000 will be removed from the data set.
--There is another outlier of Id 6117666160, the calories consumed jump from less than 3000 to 4900 which is unusual and there is no other users reaching that point.    

delete
from ProjectBellabeat.dbo.dailyActivity_merged
where CaloriesConverted < 1000
--output 12 rows was removed

delete
from ProjectBellabeat.dbo.dailyActivity_merged
where CaloriesConverted > 4600
--output 1 rows was removed


-------------------------------------------------------------------------------------------------
--Checking Min, Max, Mean
--Using MIN, MAX, AVG and Subquery 

select  MIN(ActivityDateConverted) as StartDate,
	    MAX(ActivityDateConverted) as EndDate,
		
		MIN(TotalStepsConverted) as MinTotalStep,
	    MAX(TotalStepsConverted) as MaxTotalStep,
		AVG(TotalStepsConverted) as MeanTotalStep,
		
		MIN(TotalDistanceConverted) as MinTotalDistance,
		MAX(TotalDistanceConverted) as MaxTotalDistance,
		AVG(TotalDistanceConverted) as MeanTotalDistance,
		
		MIN(TrackerDistanceConverted) as MinTrackerDistance,
		MAX(TrackerDistanceConverted) as MaxTrackerDistance,
		AVG(TrackerDistanceConverted) as MeanTrackerDistance,
		
		MIN(LoggedActivitiesDistanceConverted) as MinLoggedActivitiesDistance,
		MAX(LoggedActivitiesDistanceConverted) as MaxLoggedActivitiesDistance,
		AVG(LoggedActivitiesDistanceConverted) as MeanLoggedActivitiesDistance,
		(select COUNT (*) 
			from ProjectBellabeat.dbo.dailyActivity_merged
			where LoggedActivitiesDistanceConverted != 0) as NumOfLogged,
		
		MIN(VeryActiveDistanceConverted) as MinVeryActiveDistance,
		MAX(VeryActiveDistanceConverted) as MaxVeryActiveDistance,
		AVG(VeryActiveDistanceConverted) as MeanVeryActiveDistance,
		
		MIN(ModeratelyActiveDistanceConverted) as MinModeratelyActiveDistance,
		MAX(ModeratelyActiveDistanceConverted) as MaxModeratelyActiveDistance,
		AVG(ModeratelyActiveDistanceConverted) as MeanModeratelyActiveDistance,
		
		MIN(LightActiveDistanceConverted) as MinLightActiveDistance,
		MAX(LightActiveDistanceConverted) as MaxLightActiveDistance,
		AVG(LightActiveDistanceConverted) as MeanLightActiveDistance,

		MIN(SedentaryActiveDistanceConverted) as MinSedentaryActiveDistance,
		MAX(SedentaryActiveDistanceConverted) as MaxSedentaryActiveDistance,
		AVG(SedentaryActiveDistanceConverted) as MeanSedentaryActiveDistance,

		MIN(VeryActiveMinutesConverted) as MinVeryActiveMinutes,
		MAX(VeryActiveMinutesConverted) as MaxVeryActiveMinutes,
		AVG(VeryActiveMinutesConverted) as MeanVeryActiveMinutes,

		MIN(FairlyActiveMinutesConverted) as MinFairlyActiveMinutes,
		MAX(FairlyActiveMinutesConverted) as MaxFairlyActiveMinutes,
		AVG(FairlyActiveMinutesConverted) as MeanFairlyActiveMinutes,

		MIN(LightlyActiveMinutesConverted) as MinLightlyActiveMinutes,
		MAX(LightlyActiveMinutesConverted) as MaxLightlyActiveMinutes,
		AVG(LightlyActiveMinutesConverted) as MeanLightlyActiveMinutes,

		MIN(SedentaryMinutesConverted) as MinSedentaryMinutes,
		MAX(SedentaryMinutesConverted) as MaxSedentaryMinutes,
		AVG(SedentaryMinutesConverted) as MeanSedentaryMinutes,

		MIN(CaloriesConverted) as MinCalories,
		MAX(CaloriesConverted) as MaxCalories,
		AVG(CaloriesConverted) as MeanCalories

from ProjectBellabeat.dbo.dailyActivity_merged
--Outcome (per day)

--Start Date:					2016-04-12
--End Date:						2016-05-12

--Total steps:					mean = 7637,	max = 36019

--Total distance:				mean = 5.49,	max = 28.03
--Logged activities distance:	mean = 0.12,	max = 4.94	, note: sample group logged activities distance only 32 times from 940

--Very active distance:			mean = 1.5,		max = 21.92
--Moderately active distance:	mean = 0.57,	max = 6.48
--Light active distance:		mean = 3.34,	max = 10.71
--Sedentary active distance:	mean = 0.002,	max = 0.11

--Very active minute:			mean = 21,		max = 210
--Fairly active minute:			mean = 13,		max = 143
--Lightly active minute:		mean = 192,		max = 518
--Sedentary minute:				mean = 991,		max = 1440

--Calories:						mean = 2327,	max = 4552

-- => Sample group spent majority of active time sedentary 


-------------------------------------------------------------------------------------------------
--Joining table for further visualisation to find correlation between Calorie, Intensity and Step
--Using INNER JOIN

Select  hi.Id
		, hi.ActivityHourConverted
		, hc.CaloriesConverted
		, hi.TotalIntensityConverted
		, hs.StepTotalConverted
from ProjectBellabeat.dbo.hourlyCalories_merged hc
	join ProjectBellabeat.dbo.hourlyIntensities_merged hi
		on hc.Id = hi.Id 
			and hc.ActivityHourConverted = hi.ActivityHourConverted
	join ProjectBellabeat.dbo.hourlySteps_merged hs
		on hi.Id = hs.Id 
			and hi.ActivityHourConverted = hs.ActivityHourConverted


-------------------------------------------------------------------------------------------------
--Finding sleep details 

select *
from ProjectBellabeat.dbo.minuteSleep_merged

select logId
	   , MIN(Id) as ID
	   , MIN(dateConverted) as SleepStart
	   , MAX(dateConverted) as SleepEnd
	   , DATEDIFF(MINUTE, MIN(dateConverted), MAX(dateConverted)) as SleepMinutes
from ProjectBellabeat.dbo.minuteSleep_merged
group by logId
order by 2, 3


-------------------------------------------------------------------------------------------------
--Joining table for further visualisation to find correlation between Level of Activity and Sleep
--Using LEFT JOIN

Select  da.Id
		, da.ActivityDateConverted
		, DATENAME(DW, da.ActivityDateConverted) as DayOfTheWeek
		, da.TotalStepsConverted
		, da.TotalDistanceConverted
		, da.TrackerDistanceConverted
		, da.LoggedActivitiesDistanceConverted
		, da.VeryActiveDistanceConverted
		, da.ModeratelyActiveDistanceConverted
		, da.LightActiveDistanceConverted
		, da.SedentaryActiveDistanceConverted
		, da.VeryActiveMinutesConverted
		, da.FairlyActiveMinutesConverted
		, da.LightlyActiveMinutesConverted
		, da.SedentaryMinutesConverted
		, da.CaloriesConverted
		, sa.TotalSleepRecordsConverted
		, sa.TotalMinutesAsleepConverted
		, sa.TotalTimeInBedConverted
		, sa.TotalSleepRecordsConverted
from ProjectBellabeat.dbo.dailyActivity_merged da
	left join ProjectBellabeat.dbo.sleepDay_merged sa
		on da.Id = sa.Id 
			and da.ActivityDateConverted = sa.SleepDayConverted
--stored in ProjectBellaBeatdaily.csv

-------------------------------------------------------------------------------------------------
--Checking weight log info 

select CONVERT(datetime, Date)
		, *
from ProjectBellabeat.dbo.weightLogInfo_merged
order by 2, 1

select count(distinct Id) 
from ProjectBellabeat.dbo.weightLogInfo_merged
--Only 8 accounts had weight log info

select COUNT(IsManualReport)
from ProjectBellabeat.dbo.weightLogInfo_merged
where IsManualReport = 'True'
--Only 8 out of 33 accounts had their weight log info and those info are not consistency. Seem like the sample group did not use smart device to monitor their weight.
--Only 2 out of 33 accounts have logged the weight info consistently (one account logged info manually)
