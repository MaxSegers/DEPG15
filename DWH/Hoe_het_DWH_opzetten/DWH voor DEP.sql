UNLOCK TABLES;
DROP DATABASE IF EXISTS AirFaresDWH;
CREATE DATABASE IF NOT EXISTS AirFaresDWH;
USE AirFaresDWH;

-- creating tables with their primary keys and relations between them

CREATE TABLE IF NOT EXISTS DimAirline (
  AirlineKey INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  AirlineIataCode VARCHAR(10) NOT NULL,
  AirlineName VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS DimAirport (
  AirportKey INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  AirportIataCode VARCHAR(10) NOT NULL,
  AirportName VARCHAR(255) NOT NULL,
  Place varchar(255) NOT NULL,
  Country varchar(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS DimFlight (
  FlightKey INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  FlightCode varchar(255) NOT NULL,
  FlightNumber varchar(10) NOT NULL,
  ArrivalTime varchar(10) NOT NULL,
  DepartureTime varchar(10) NOT NULL,
  Duration varchar(10) NOT NULL,
  NumberOfStops INT NOT NULL,
  
  -- Voor de slowly changing dimension
  StartDate DATE NOT NULL,
  EndDate DATE
);

CREATE TABLE IF NOT EXISTS DimDate (
  DateKey INT PRIMARY KEY,
  FullDate DATE, -- date in date object
  
  -- Days
  DayNumberOfWeek INT, -- day in number, ie. 1, 2, .. , 7
  DayNumberOfMonth INT, -- day in number, ie. 1, 2, .. 31
  NameWeekday VARCHAR(10), -- day in name, ie. Monday, Tuesday, .. , Sunday
  
  -- Months
  NumMonth int (2) ,  -- month in number, ie. 12
  NameMonth varchar(20),  -- month in name, ie. December
  
  -- Quarters
  NumQuarter INT, -- Quarter in number, ie. 1, 2, .. , 4
  -- NameQuarter VARCHAR(10), -- Quarter in name, ie. First, Second, .. , Fourth
  
  -- Holidays + weekend
  IsHoliday BOOLEAN, -- Holiday = 1, Not a holiday = 0
  NameHoliday VARCHAR(50), -- name of holiday, ie. Christmas, Easter
  IsWeekend BOOLEAN, -- day in Weekend = 1, Not in weekend = 0
  
  UNIQUE (DateKey)
);

CREATE TABLE IF NOT EXISTS FactFlights (
factFlight_key INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
AirlineKey INT NOT NULL,
DepartureAirportKey INT NOT NULL,
ArrivalAirportKey INT NOT NULL,
FlightKey INT NOT NULL,
ScrapeDateKey INT NOT NULL,
DepartureDateKey INT NOT NULL,
ArrivalDateKey INT NOT NULL,
SeatsAvailable varchar(10) NOT NULL,
Price DOUBLE NOT NULL,

CONSTRAINT FK_Airline_Key FOREIGN KEY (AirlineKey)
REFERENCES AirFaresDWH.DimAirline(AirlineKey),

CONSTRAINT FK_Dep_airport_Key FOREIGN KEY (DepartureAirportKey)
REFERENCES AirFaresDWH.DimAirport(AirportKey),

CONSTRAINT FK_Arr_airport_Key FOREIGN KEY (ArrivalAirportKey)
REFERENCES AirFaresDWH.DimAirport(AirportKey),

CONSTRAINT FK_Flight_Key FOREIGN KEY (FlightKey)
REFERENCES AirFaresDWH.DimFlight(FlightKey),

CONSTRAINT FK_Scrape_Date_Key FOREIGN KEY (ScrapeDateKey)
REFERENCES AirFaresDWH.DimDate(DateKey),

CONSTRAINT FK_Departure_Date_Key FOREIGN KEY (DepartureDateKey)
REFERENCES AirFaresDWH.DimDate(DateKey),

CONSTRAINT FK_Arrival_Date_Key FOREIGN KEY (ArrivalDateKey)
REFERENCES AirFaresDWH.DimDate(DateKey)
);