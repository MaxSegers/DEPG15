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
  available_seats INT NOT NULL,
  price DOUBLE NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE
);

CREATE TABLE IF NOT EXISTS Dim_Date (
  date_key INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  fullDate DATE NOT NULL,
  dayNumberOfWeek INT NOT NULL,
  isHoliday BOOLEAN NOT NULL,
  nameHoliday VARCHAR(50),
  isWeekend BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS Fact_Flight (
factFlight_key INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
airline_key INT NOT NULL,
dep_airport_key INT NOT NULL,
arr_airport_key INT NOT NULL,
flight_key INT NOT NULL,
scrape_date_key INT NOT NULL,
departure_date_key INT NOT NULL,
arrival_date_key INT NOT NULL,

CONSTRAINT FK_Airline_Key
FOREIGN KEY (airline_key)
REFERENCES AirFaresDWH.Dim_Airline(airline_id),
CONSTRAINT FK_Dep_airport_Key
FOREIGN KEY (dep_airport_key)
REFERENCES AirFaresDWH.Dim_Airport(airport_id),
CONSTRAINT FK_Arr_airport_Key
FOREIGN KEY (arr_airport_key)
REFERENCES AirFaresDWH.Dim_Airport(airport_id),
CONSTRAINT FK_Flight_Key
FOREIGN KEY (flight_key)
REFERENCES AirFaresDWH.Dim_Flight(flight_id),
CONSTRAINT FK_Scrape_Date_Key
FOREIGN KEY (scrape_date_key)
REFERENCES AirFaresDWH.Dim_Date(date_key),
CONSTRAINT FK_Departure_Date_Key
FOREIGN KEY (departure_date_key)
REFERENCES AirFaresDWH.Dim_Date(date_key),
CONSTRAINT FK_Arrival_Date_Key
FOREIGN KEY (arrival_date_key)
REFERENCES AirFaresDWH.Dim_Date(date_key)
);

-- filling up predetermined columns

LOCK TABLES Dim_Airline WRITE;
INSERT INTO Dim_Airline(airline_iata_code, airline_name) VALUES ('FR','Ryanair'),('TB','TUI fly'),('HV', 'Transavia'),('SN','Brussels Airlines');
UNLOCK TABLES;

LOCK TABLES Dim_Airport WRITE;
INSERT INTO Dim_Airport(airport_iata_code, airport_name, city, country) VALUES ('BRU','Brussels Airports','Zaventem','Belgium'),('ANR','Antwerp International Airport','Deurne','Belgium'),('LGG','Liege Airport','Luik','Belgium'),
('CRL','Brussels South Charleroi Airport','Charleroi','Belgium'),('OST','Ostend Bruges International Airport','Oostende','Belgium');
INSERT INTO Dim_Airport(airport_iata_code, airport_name, city, country) VALUES ('HER','Heraklion International Airport','Crete','Greece'),('CFU','Corfu International Airport','Corfu','Greece'),('RHO','Rhodes International Airport','Rhodes','Greece');
INSERT INTO Dim_Airport(airport_iata_code, airport_name, city, country) VALUES ('PMO','Palermo Falcone-Borsellino Airport','Palermo','Italy'),('NAP','Naples Airport','Naples','Italy'),
('BDS','Brindisi Airport','Brindisi','Italy'),('FAo','Faro Airport','Faro','Portugal');
INSERT INTO Dim_Airport(airport_iata_code, airport_name, city, country) VALUES ('ALC','Alicante Airport','Alicante','Spain'),('AGP','Malaga Costa Del Sol Airport','Malaga','Spain'),('IBZ','Ibiza Airport','Ibiza','Spain'),
('PMI','Palma de Mallorca Airport','Palma','Spain'),('TFS','Tenerife South Airport','Tenerife','Spain');
UNLOCK TABLES;
