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
    DECLARE start_date DATE;
    DECLARE end_date DATE;
    DECLARE curr_date DATE;
    DECLARE current_day_of_week INT;
    DECLARE current_month INT;
    DECLARE current_day INT;
    DECLARE current_year INT;
    DECLARE is_holiday BOOLEAN;
    DECLARE holiday_name VARCHAR(50);
    DECLARE is_weekend BOOLEAN;

    SET start_date = '2023-01-01';
    SET end_date = '2023-12-31';
    SET curr_date = start_date;

    WHILE curr_date <= end_date DO
        SET current_day_of_week = DAYOFWEEK(curr_date);
        SET current_month = MONTH(curr_date);
        SET current_day = DAY(curr_date);
        SET current_year = YEAR(curr_date);
        SET is_holiday = FALSE;
        SET holiday_name = '';
        SET is_weekend = (current_day_of_week = 1 OR current_day_of_week = 7);

        -- Check for holidays in Belgium
        IF current_month = 1 AND current_day = 1 THEN
            SET is_holiday = TRUE;
            SET holiday_name = 'New Year''s Day';
        ELSEIF current_month = 4 AND current_day = 17 THEN
            SET is_holiday = TRUE;
            SET holiday_name = 'Easter Monday';
        ELSEIF current_month = 5 AND current_day = 1 THEN
            SET is_holiday = TRUE;
            SET holiday_name = 'Labour Day';
        ELSEIF current_month = 5 AND current_day = 25 THEN
            SET is_holiday = TRUE;
            SET holiday_name = 'Ascension Day';
        ELSEIF current_month = 6 AND current_day = 5 THEN
            SET is_holiday = TRUE;
            SET holiday_name = 'Whit Monday';
        ELSEIF current_month = 7 AND current_day = 21 THEN
            SET is_holiday = TRUE;
            SET holiday_name = 'Belgian National Day';
        ELSEIF current_month = 8 AND current_day = 15 THEN
            SET is_holiday = TRUE;
            SET holiday_name = 'Assumption of Mary';
        ELSEIF current_month = 11 AND current_day = 1 THEN
            SET is_holiday = TRUE;
            SET holiday_name = 'All Saints'' Day';
        ELSEIF current_month = 11 AND current_day = 11 THEN
            SET is_holiday = TRUE;
            SET holiday_name = 'Armistice Day';
        ELSEIF current_month = 12 AND current_day = 25 THEN
            SET is_holiday = TRUE;
            SET holiday_name = 'Christmas Day';
        END IF;

        -- Insert the row into the dim_date table
        INSERT INTO dim_date (fullDate, dayNumberOfWeek, isHoliday, nameHoliday, isWeekend)
        VALUES (curr_date, current_day_of_week, is_holiday, holiday_name, is_weekend);

        -- Increment the curr_date variable
        SET curr_date = DATE_ADD(curr_date, INTERVAL 1 DAY);
    END WHILE;
END //

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
SELECT DISTINCT airport_iata_code, airport_name, place, country FROM airfares.airports WHERE airport_iata_code NOT IN (SELECT DISTINCT airport_iata_code FROM Dim_Airline);

-- Create trigger for inserting data in Dim_Flight, if a certain flight_key does not exist yet, it does nothing, if one of it's
-- attributes has changed, it updates the old data's end_date
DELIMITER $$

CREATE TRIGGER update_end_date_dim_flight BEFORE INSERT ON Dim_Flight
FOR EACH ROW
BEGIN
DECLARE end_date_var DATE;
SET end_date_var = DATE_SUB(CURDATE(), INTERVAL 1 DAY);
IF EXISTS (SELECT 1 FROM dim_flight WHERE (end_date IS NULL AND flight_code = NEW.flight_code AND (arrival_time <> NEW.arrival_time OR departure_time <> NEW.departure_time OR flight_duration <> NEW.flight_duration OR layovers <> NEW.layovers OR available_seats <> NEW.available_seats OR price <> NEW.price))) THEN
UPDATE dim_flight df SET end_date = end_date_var WHERE (end_date IS NULL AND flight_code = NEW.flight_code);
END IF;
END$$

DELIMITER ;

-- Inserts new records into Dim_Flight
INSERT INTO Dim_Flight(flight_code, flight_number, arrival_time, departure_time, flight_duration, layovers, available_seats, price, start_date) SELECT fl.flight_id, fl.flightnumber, fl.arrival_time, fl.departure_time, fl.duration, fl.number_of_stops, sd.seats_available, sd.price, sd.scrape_date FROM airfares.flights fl JOIN airfares.search_dates sd ON fl.flight_id = sd.flight_id WHERE (fl.flight_id NOT IN (SELECT flight_id FROM dim_flight) OR EXISTS (SELECT 1 FROM dim_flight WHERE (end_date IS NULL AND flight_id = NEW.flight_id AND (arrival_time <> NEW.arrival_time OR departure_time <> NEW.departure_time OR flight_duration <> NEW.flight_duration OR layovers <> NEW.layovers OR available_seats <> NEW.available_seats OR price <> NEW.price))));

-- Insert new records into Fact_Flight
INSERT INTO Fact_Flight(airline_key, dep_airport_key, arr_airport_key, flight_key, scrape_date_key, departure_date_key, arrival_date_key) 
SELECT da.airline_id, das.airport_id, dad.airport_id, df.flight_id, dd1.date_key, dd2.date_key, dd3.date_key
FROM airfares.flight af 
	JOIN airfares.search_dates asd ON af.flight_id = asd.flight_id
	JOIN dim_airline da ON af.airline_iata_code = da.airline_iata_code
	JOIN dim_airport das ON af.departure_airport_iata_code = das.airport_iata_code
    JOIN dim_airport dad ON af.departure_airport_iata_code = dad.airport_iata_code
    JOIN dim_flight df ON af.flight_id = df.flight_code
    JOIN dim_date dd1 ON asd.scrape_date = dd1.fullDate
    JOIN dim_date dd2 ON fl.departure_date = dd2.fullDate
    JOIN dim_date dd3 ON fl.arrival_date = dd3.fullDate
