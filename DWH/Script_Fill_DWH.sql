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

-- Update dim_airline
UPDATE Dim_Airline da SET airline_name = (SELECT airline_name FROM vluchten.airlines WHERE vluchten.airlines.airline_id = da.airline_id);

-- Insert new records into Dim_Airline
INSERT INTO Dim_Airline(airline_id, airline_name)
SELECT DISTINCT airline_id, airline_name FROM vluchten.airlines WHERE airline_id NOT IN (SELECT DISTINCT airline_id FROM Dim_Airline);

-- Update dim_airport
UPDATE Dim_Airport da SET airport_name = (SELECT airport_name FROM vluchten.airports WHERE vluchten.airports.airport_id = da.airport_id);

-- Insert new records into Dim_Airport
INSERT INTO Dim_Airport(airport_id, airport_name, airport_code, city, country)
SELECT DISTINCT airport_id, airport_name, airport_code, city, country FROM vluchten.airports WHERE airport_id NOT IN (SELECT DISTINCT airport_id FROM Dim_Airline);

-- Create trigger for inserting data in Dim_Flight, if a certain flight_key does not exist yet or one of it's other
-- attributes has changed, it updates the old data's end_date and fact_flight's flight_key
DELIMITER $$

CREATE TRIGGER update_end_date_dim_flight BEFORE INSERT ON Dim_Flight
FOR EACH ROW
BEGIN
DECLARE end_date_var DATE;
SET end_date_var = DATE_SUB(CURDATE(), INTERVAL 1 DAY);
IF EXISTS (SELECT 1 FROM dim_flight WHERE (end_date IS NULL AND flight_key = NEW.flight_key AND (arrival_time <> NEW.arrival_time OR departure_time <> NEW.departure_time OR flight_duration <> NEW.flight_duration OR layovers <> NEW.layovers OR available_seats <> NEW.available_seats OR price <> NEW.price))) THEN
UPDATE dim_flight df SET end_date = end_date_var WHERE (end_date IS NULL AND flight_key = NEW.flight_key);
UPDATE fact_flight SET flight_key = max(df.flight_id)+1;
END IF;
END$$

DELIMITER ;

-- Insert new records into Dim_Flight
CREATE TEMPORARY TABLE temp_table(
  airline_name varchar(255) NOT NULL,
  departure_airport_code varchar(10) NOT NULL,
  arrival_airport_code varchar(10) NOT NULL,
  flight_key varchar(255) NOT NULL,
  departure_date DATE NOT NULL,
  arrival_date DATE NOT NULL,
  scrape_date DATE NOT NULL
  );


-- FROM HERE ON THINGS WILL NOT WORK

-- Inserts new records into Dim_Flight
INSERT INTO Dim_Flight(flight_key, arrival_time, departure_time, flight_duration, flight_number, layovers, available_seats, price, start_date) (SELECT fl.flight_key, fl.arrival_time, fl.departure_time, fl.flight_duration, fl.layovers, sd.seats_available, sd.price, sd.search_date FROM vluchten.flights fl JOIN vluchten.search_dates sd ON fl.flight_key = sd.flight_key WHERE fl.flight_key NOT IN (SELECT flight_key FROM dim_flight));
INSERT INTO temp_table;

-- Inserts changed previously existing records into Dim_Flight
INSERT INTO Dim_Flight SELECT fl.flight_key, fl.arrival_time, fl.departure_time, fl.flight_duration, fl.layovers, sd.seats_available, sd.price, sd.search_date FROM dim_flight df JOIN vluchten.flights fl ON df.flight_key = fl.flight_key JOIN vluchten.search_dates sd ON fl.flight_key = sd.flight_key WHERE fl.flight_key = df.flight_key AND (df.arrival_time <> fl.arrival_time OR df.departure_time <> fl.departure_time OR df.flight_duration <> fl.flight_duration OR df.layovers <> fl.layovers OR df.available_seats <> sd.available_seats OR df.price <> sd.price);
INSERT INTO temp_table;

-- insert new records into Fact_Flight
INSERT INTO Fact_Flight SELECT tt.airline_key, tt.dep_airport_key, tt.arr_airport_key, tt.flight_key, scrape_date_key, departure_date_key, arrival_date_key FROM dim_airline airl, dim_airport airp, dim_date dd, dim_flight df, temp_table tt JOIN vluchten.airlines vairl WHERE 