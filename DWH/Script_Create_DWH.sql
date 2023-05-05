UNLOCK TABLES;
DROP DATABASE IF EXISTS AirFaresDWH;
CREATE DATABASE IF NOT EXISTS AirFaresDWH;
USE AirFaresDWH;

-- creating tables with their primary keys and relations between them

CREATE TABLE IF NOT EXISTS Dim_Airline (
  airline_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  airline_iata_code VARCHAR(10) NOT NULL,
  airline_name VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS Dim_Airport (
  airport_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  airport_iata_code VARCHAR(10) NOT NULL,
  airport_name VARCHAR(50) NOT NULL,
  city varchar(255) NOT NULL,
  country varchar(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS Dim_Flight (
  flight_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  flight_code varchar(255) NOT NULL,
  flight_number varchar(10) NOT NULL,
  arrival_time DATETIME NOT NULL,
  departure_time DATETIME NOT NULL,
  flight_duration int NOT NULL,
  layovers INT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE
);

CREATE TABLE IF NOT EXISTS Dim_Date (
  date_id INT PRIMARY KEY,
  fullDate DATE,
  dayNumber INT,
  nameDay VARCHAR(10),
  dayNumberOfWeek INT,
  weekNumber INT,
  monthNumber INT,
  nameMonth VARCHAR(10),
  numberOfQuarter INT,
  isHoliday BOOLEAN,
  nameHoliday VARCHAR(50),
  isWeekend BOOLEAN,
  UNIQUE (date_id)
);

CREATE TABLE IF NOT EXISTS Fact_Flight (
factFlight_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
airline_id INT NOT NULL,
dep_airport_id INT NOT NULL,
arr_airport_id INT NOT NULL,
flight_id INT NOT NULL,
scrape_date_id INT NOT NULL,
departure_date_id INT NOT NULL,
arrival_date_id INT NOT NULL,
available_seats INT NOT NULL,
price DOUBLE NOT NULL,

CONSTRAINT FK_Airline_Key
FOREIGN KEY (airline_id)
REFERENCES AirFaresDWH.Dim_Airline(airline_id),
CONSTRAINT FK_Dep_airport_Key
FOREIGN KEY (dep_airport_id)
REFERENCES AirFaresDWH.Dim_Airport(airport_id),
CONSTRAINT FK_Arr_airport_Key
FOREIGN KEY (arr_airport_id)
REFERENCES AirFaresDWH.Dim_Airport(airport_id),
CONSTRAINT FK_Flight_Key
FOREIGN KEY (flight_id)
REFERENCES AirFaresDWH.Dim_Flight(flight_id),
CONSTRAINT FK_Scrape_Date_Key
FOREIGN KEY (scrape_date_id)
REFERENCES AirFaresDWH.Dim_Date(date_id),
CONSTRAINT FK_Departure_Date_Key
FOREIGN KEY (departure_date_id)
REFERENCES AirFaresDWH.Dim_Date(date_id),
CONSTRAINT FK_Arrival_Date_Key
FOREIGN KEY (arrival_date_id)
REFERENCES AirFaresDWH.Dim_Date(date_id)
);
