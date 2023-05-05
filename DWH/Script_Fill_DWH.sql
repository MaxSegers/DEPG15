USE AirFaresDWH;

-- Enables DELETE FROM
SET SQL_SAFE_UPDATES = 0;

-- Temporarily remove constraints
SET FOREIGN_KEY_CHECKS=0;

-- Empty and recreate dim_date
DELETE FROM dim_date;

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
        INSERT INTO Dim_Date (date_id, fullDate, dayNumber, nameDay, dayNumberOfWeek, weekNumber, monthNumber, nameMonth, numberOfQuarter, isHoliday, nameHoliday, isWeekend)
        VALUES (
            CONCAT(YEAR(curr_date), LPAD(MONTH(curr_date), 2, '0'), LPAD(DAY(curr_date), 2, '0')), -- date_id
            curr_date, -- fullDate
            DAY(curr_date), -- dayNumber
            CASE WEEKDAY(curr_date) -- nameDay
				WHEN 0 THEN 'Monday'
				WHEN 1 THEN 'Tuesday'
				WHEN 2 THEN 'Wednesday'
				WHEN 3 THEN 'Thursday'
				WHEN 4 THEN 'Friday'
				WHEN 5 THEN 'Saturday'
				WHEN 6 THEN 'Sunday'
			END,
            WEEKDAY(curr_date), -- dayNumberOfWeek
            WEEK(curr_date), -- weekNumber
            MONTH(curr_date) , -- monthNumber
            MONTHNAME(curr_date) , -- nameMonth
            QUARTER(curr_date), -- numberOfQuarter
            CASE -- isHoliday
                WHEN MONTH(curr_date) = 1 AND DAY(curr_date) = 1 THEN TRUE
                WHEN MONTH(curr_date) = 5 AND DAY(curr_date) = 1 THEN TRUE
                WHEN MONTH(curr_date) = 7 AND DAY(curr_date) = 21 THEN TRUE
                WHEN MONTH(curr_date) = 11 AND DAY(curr_date) = 1 THEN TRUE
                WHEN MONTH(curr_date) = 12 AND (DAY(curr_date) = 25 OR DAY(curr_date) = 26) THEN TRUE
                ELSE FALSE
            END,
            CASE -- nameHoliday
                WHEN MONTH(curr_date) = 1 AND DAY(curr_date) = 1 THEN 'New Year\'s Day'
                WHEN MONTH(curr_date) = 5 AND DAY(curr_date) = 1 THEN 'Labour Day'
                WHEN MONTH(curr_date) = 7 AND DAY(curr_date) = 21 THEN 'Belgian National Day'
                WHEN MONTH(curr_date) = 11 AND DAY(curr_date) = 1 THEN 'All Saints\' Day'
                WHEN MONTH(curr_date) = 12 AND DAY(curr_date) = 25 THEN 'Christmas Day'
                WHEN MONTH(curr_date) = 12 AND DAY(curr_date) = 26 THEN 'Boxing Day'
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

-- Update dim_airline when namechange
UPDATE Dim_Airline da SET airline_name = (SELECT airline_name FROM airfares.airlines WHERE airfares.airlines.airline_iata_code = da.airline_iata_code);

-- Insert new records into Dim_Airline
INSERT INTO Dim_Airline(airline_iata_code, airline_name)
SELECT DISTINCT airline_iata_code, airline_name FROM airfares.airlines WHERE airline_iata_code NOT IN (SELECT DISTINCT airline_iata_code FROM Dim_Airline);

-- Update dim_airport when namechange
UPDATE Dim_Airport da SET airport_name = (SELECT airport_name FROM airfares.airports WHERE airfares.airports.airport_iata_code = da.airport_iata_code);

-- Insert new records into Dim_Airport
INSERT INTO Dim_Airport(airport_iata_code, airport_name, city, country)
SELECT DISTINCT airport_iata_code, airport_name, place, country FROM airfares.airports WHERE airport_iata_code NOT IN (SELECT DISTINCT airport_iata_code FROM Dim_Airport);

-- Inserts new records with flight_code that does not exist yet in table into Dim_Flight
INSERT INTO Dim_Flight(flight_code, flight_number, arrival_time, departure_time, flight_duration, layovers, start_date) SELECT fl.flight_id, fl.flightnumber, fl.arrival_time, fl.departure_time, fl.duration, fl.number_of_stops, sd.scrape_date FROM airfares.flights fl JOIN airfares.search_dates sd ON fl.flight_id = sd.flight_id WHERE (fl.flight_id NOT IN (SELECT flight_code FROM dim_flight));

-- Create a temp_table to store flights that have changed
CREATE TEMPORARY TABLE temp_table (
  flight_code varchar(255) NOT NULL,
  flight_number varchar(10) NOT NULL,
  arrival_time DATETIME NOT NULL,
  departure_time DATETIME NOT NULL,
  flight_duration int NOT NULL,
  layovers INT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE
);

-- Insert records that previously existed into temp_table
INSERT INTO Dim_Flight(flight_code, flight_number, arrival_time, departure_time, flight_duration, layovers, start_date) 
	SELECT fl.flight_id, fl.flightnumber, fl.arrival_time, fl.departure_time, fl.duration, fl.number_of_stops, sd.scrape_date 
    FROM airfares.flights fl 
    JOIN dim_flight df ON fl.flight_id = df.flight_code
    WHERE (fl.duration <> df.flight_duration OR fl.arrival_time <> df.arrival_time OR fl.departure_time <> df.departure_time OR fl.number_of_stops <> df.layovers) AND (df.end_date IS NULL);

-- Update end_date in dim_flight
UPDATE Dim_Flight SET end_date = subdate(current_date, 1) WHERE flight_code IN (SELECT flight_code FROM temp_table)

-- Insert temp_table into dim_flight
INSERT INTO Dim_Flight(flight_code, flight_number, arrival_time, departure_time, flight_duration, layovers, start_date) SELECT * FROM temp_table;

-- Insert new records into Fact_Flight
INSERT INTO Fact_Flight(airline_id, dep_airport_id, arr_airport_id, flight_id, scrape_date_id, departure_date_id, arrival_date_id, available_seats, price) 
SELECT da.airline_id, das.airport_id, dad.airport_id, df.flight_id, dd1.date_id, dd2.date_id, dd3.date_id, asd.seats_available, asd.price
FROM airfares.flight af 
	JOIN airfares.search_dates asd ON af.flight_id = asd.flight_id
	JOIN dim_airline da ON af.airline_iata_code = da.airline_iata_code
	JOIN dim_airport das ON af.departure_airport_iata_code = das.airport_iata_code
    JOIN dim_airport dad ON af.arrival_airport_iata_code = dad.airport_iata_code
    JOIN dim_flight df ON af.flight_id = df.flight_code
    JOIN dim_date dd1 ON asd.scrape_date = dd1.fullDate
    JOIN dim_date dd2 ON af.departure_date = dd2.fullDate
    JOIN dim_date dd3 ON af.arrival_date = dd3.fullDate
WHERE 
/* Slowly Changing Dimension dimCustomer */
asd.scrape_date >= df.start_date and (df.end_date is null or asd.scrape_date <= df.end_date) 
AND
/* only add new lines + make sure it runs from an empty FactSales table */
asd.flight_id > (SELECT IFNULL(MAX(factFlight_id),0) from Fact_Flight)
