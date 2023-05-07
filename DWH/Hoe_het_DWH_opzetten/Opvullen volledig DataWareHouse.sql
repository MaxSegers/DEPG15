USE AirFaresDWH;

-- Enables DELETE FROM
SET SQL_SAFE_UPDATES = 0;

-- Temporarily remove constraints
SET FOREIGN_KEY_CHECKS=0;

-- Empty and recreate dim_date
DELETE FROM DimDate;

-- Recreates the fill_dim_date procedure which fills the dim_date table
DROP PROCEDURE IF EXISTS fill_dim_date;

DELIMITER //
CREATE PROCEDURE fill_dim_date()
BEGIN
    DECLARE start_date DATE DEFAULT '2023-01-01';
    DECLARE end_date DATE DEFAULT '2023-12-31';
    DECLARE curr_date DATE DEFAULT start_date;

    -- Fill up the Dim_Date table
    WHILE curr_date <= end_date DO
        INSERT INTO DimDate (DateKey, FullDate, DayNumberOfWeek, DayNumberOfMonth, NameWeekday, NumMonth, NameMonth, NumQuarter, IsHoliday, NameHoliday, IsWeekend)
        VALUES (
            CONCAT(YEAR(curr_date), LPAD(MONTH(curr_date), 2, '0'), LPAD(DAY(curr_date), 2, '0')), -- DateKey
            curr_date, -- FullDate
            WEEKDAY(curr_date) + 1, -- DayNumberOfWeek
            DAY(curr_date), -- DayNumberOfMonth
            CASE WEEKDAY(curr_date) -- NameWeekday
				WHEN 0 THEN 'Monday'
				WHEN 1 THEN 'Tuesday'
				WHEN 2 THEN 'Wednesday'
				WHEN 3 THEN 'Thursday'
				WHEN 4 THEN 'Friday'
				WHEN 5 THEN 'Saturday'
				WHEN 6 THEN 'Sunday'
			END,
            -- DAY(curr_date), -- dayNumber
            -- WEEK(curr_date), -- weekNumber
            MONTH(curr_date) , -- NumMonth
            MONTHNAME(curr_date) , -- NameMonth
            QUARTER(curr_date), -- NumQuarter
            CASE -- isHoliday
                WHEN MONTH(curr_date) = 1 AND DAY(curr_date) = 1 THEN TRUE
                WHEN MONTH(curr_date) = 4 AND DAY(curr_date) = 10 THEN TRUE
                WHEN MONTH(curr_date) = 5 AND DAY(curr_date) = 1 THEN TRUE
                WHEN MONTH(curr_date) = 5 AND DAY(curr_date) = 18 THEN TRUE
                WHEN MONTH(curr_date) = 5 AND DAY(curr_date) = 29 THEN TRUE
                WHEN MONTH(curr_date) = 7 AND DAY(curr_date) = 21 THEN TRUE
                WHEN MONTH(curr_date) = 8 AND DAY(curr_date) = 15 THEN TRUE
                WHEN MONTH(curr_date) = 11 AND DAY(curr_date) = 1 THEN TRUE
                WHEN MONTH(curr_date) = 11 AND DAY(curr_date) = 11 THEN TRUE
                WHEN MONTH(curr_date) = 12 AND DAY(curr_date) = 25 THEN TRUE
                ELSE FALSE
            END,
            CASE -- nameHoliday
                WHEN MONTH(curr_date) = 1 AND DAY(curr_date) = 1 THEN 'New Year\'s Day'
                WHEN MONTH(curr_date) = 4 AND DAY(curr_date) = 1 THEN 'Easter Monday'
                WHEN MONTH(curr_date) = 5 AND DAY(curr_date) = 1 THEN 'Labour Day'
                WHEN MONTH(curr_date) = 5 AND DAY(curr_date) = 1 THEN 'Our Lord\'s Ascension'
                WHEN MONTH(curr_date) = 5 AND DAY(curr_date) = 29 THEN 'Whit Monday'
                WHEN MONTH(curr_date) = 7 AND DAY(curr_date) = 21 THEN 'Belgian National Day'
                WHEN MONTH(curr_date) = 8 AND DAY(curr_date) = 15 THEN 'Assumption of Mary'
                WHEN MONTH(curr_date) = 11 AND DAY(curr_date) = 1 THEN 'All Saints\' Day'
                WHEN MONTH(curr_date) = 11 AND DAY(curr_date) = 11 THEN 'Armistice Holiday'
                WHEN MONTH(curr_date) = 12 AND DAY(curr_date) = 25 THEN 'Christmas Day'
                ELSE NULL
            END,
            CASE -- isWeekend
                WHEN (DAYOFWEEK(curr_date) + 5) % 7 IN (5, 6) THEN TRUE
                ELSE FALSE
            END
        );
        SET curr_date := DATE_ADD(curr_date, INTERVAL 1 DAY);
    END WHILE;
END//
DELIMITER ;

-- Fill up the dim_date table
CALL fill_dim_date();

-- Update DimAirline when name of airline would change
UPDATE DimAirline da SET AirlineName = (SELECT airline_name FROM airfares.airlines WHERE airfares.airlines.airline_iata_code = da.AirlineIataCode);

-- Insert new records into Dim_Airline
INSERT INTO DimAirline(AirlineIataCode, AirlineName) SELECT DISTINCT airline_iata_code, airline_name FROM airfares.airlines WHERE airline_iata_code NOT IN (SELECT DISTINCT AirlineIataCode FROM DimAirline);

-- Update dim_airport when namechange
UPDATE DimAirport da SET AirportName = (SELECT airport_name FROM airfares.airports WHERE airfares.airports.airport_iata_code = da.AirportIataCode);

-- Insert new records into DimAirport
INSERT INTO DimAirport(AirportIataCode, AirportName, Place, Country)
SELECT DISTINCT airport_iata_code, airport_name, place, country FROM airfares.airports WHERE airport_iata_code NOT IN (SELECT DISTINCT AirportIataCode FROM DimAirport);

-- Insert Flights from OLTP that are not already in DimFlight 
-- You can find out which flights are not already in using the flight_id
INSERT INTO DimFlight(FlightCode, FlightNumber, DepartureTime, ArrivalTime, Duration, NumberOfStops, StartDate)
SELECT fl.flight_id, fl.flightnumber, fl.departure_time, fl.arrival_time, fl.duration, fl.number_of_stops, sd.scrape_date
FROM airfares.flight fl 
	JOIN airfares.search_dates sd ON fl.flight_id = sd.flight_id 
WHERE (fl.flight_id NOT IN (SELECT FlightCode FROM DimFlight));

-- Nu moeten we kijken of de vluchten die er wel al inzitten veranderd zijn of niet

-- 1.
-- Create a temp_table to store flights that have changed

DROP TEMPORARY TABLE IF EXISTS temp_table;
CREATE TEMPORARY TABLE temp_table (
  FlightCode varchar(255) NOT NULL,
  FlightNumber varchar(10) NOT NULL,
  DepartureTime varchar(10) NOT NULL,
  ArrivalTime varchar(10) NOT NULL,
  Duration varchar(10) NOT NULL,
  NumberOfStops INT NOT NULL,
  StartDate DATE NOT NULL,
  EndDate DATE
);

-- 2.
-- To know the changed flights, compare 'NumberOfStops','Duration','DepartureTime','ArrivalTime' with the flight
-- in de WHERE - clause de aantal_stops, vertrekuur, aankomstuur, duration uit DimFlight te vergelijken met Flight

INSERT INTO temp_table(FlightCode, FlightNumber, DepartureTime, ArrivalTime, Duration, NumberOfStops, StartDate)
SELECT fl.flight_id, fl.flightnumber, fl.departure_time, fl.arrival_time, fl.duration, fl.number_of_stops, sd.scrape_date
FROM airfares.flight fl 
	JOIN airfares.search_dates sd ON fl.flight_id = sd.flight_id
    JOIN airfaresdwh.DimFlight df ON fl.flight_id = df.FlightCode
WHERE (fl.duration <> df.Duration OR fl.arrival_time <> df.ArrivalTime OR fl.departure_time <> df.DepartureTime OR fl.number_of_stops <> df.NumberOfStops) AND (df.EndDate IS NULL);

-- Update end_date in dim_flight
UPDATE DimFlight
SET EndDate = subdate(current_date, 1)
WHERE FlightCode IN (SELECT FlightCode FROM temp_table);

-- Insert temp_table into dim_flight
INSERT INTO DimFlight(FlightCode, FlightNumber, DepartureTime, ArrivalTime, Duration, NumberOfStops, StartDate)
SELECT FlightCode, FlightNumber, DepartureTime, ArrivalTime, Duration, NumberOfStops, StartDate FROM temp_table;

-- Insert new records into Fact_Flight
INSERT INTO FactFlights(FlightKey, AirlineKey, ScrapeDateKey, DepartureDateKey, ArrivalDateKey, DepartureAirportKey, ArrivalAirportKey, SeatsAvailable, Price) 
SELECT df.FlightKey, da.AirlineKey, dd1.DateKey, dd2.DateKey, dd3.DateKey, das.AirportKey, dad.AirportKey, asd.seats_available, asd.price
FROM airfares.flight af 
	JOIN airfares.search_dates asd ON af.flight_id = asd.flight_id
	JOIN DimAirline da ON af.airline_iata_code = da.AirlineIataCode
	JOIN DimAirport das ON af.departure_airport_iata_code = das.AirportIataCode
    JOIN DimAirport dad ON af.arrival_airport_iata_code = dad.AirportIataCode
    JOIN DimFlight df ON af.flight_id = df.FlightCode
    JOIN DimDate dd1 ON asd.scrape_date = dd1.FullDate
    JOIN DimDate dd2 ON af.departure_date = dd2.FullDate
    JOIN DimDate dd3 ON af.arrival_date = dd3.FullDate
WHERE 
/* Slowly Changing Dimension DimFlight */
asd.scrape_date >= df.StartDate and (df.EndDate is null or asd.scrape_date <= df.EndDate) 
-- AND
/* only add new lines + make sure it runs from an empty FactSales table */
-- asd.flight_id > (SELECT IFNULL(MAX(FactFlightKey),0) from FactFlights)

