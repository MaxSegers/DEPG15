-- MySQL dump 10.13  Distrib 8.0.26, for Win64 (x86_64)
--
-- Host: localhost    Database: vluchten
-- ------------------------------------------------------
-- Server version	8.0.26

--
-- DATABASE set-up
--
DROP DATABASE IF EXISTS airfares;
CREATE DATABASE airfares;
USE airfares;

--
-- Table structure for table `airlines`
--

DROP TABLE IF EXISTS `airlines`;
CREATE TABLE `airlines` (
  `airline_iata_code` varchar(10) NOT NULL,
  `airline_name` varchar(255) NOT NULL,
  PRIMARY KEY (`airline_iata_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOCK TABLES `airlines` WRITE;
INSERT INTO `airlines` VALUES ('FR','Ryanair'),('TB','TUI fly'),('HV', 'Transavia'),('SN','Brussels Airlines');
UNLOCK TABLES;


--
-- Table structure for table `airports`
--

DROP TABLE IF EXISTS `airports`;
CREATE TABLE `airports` (
  `airport_iata_code` varchar(10) NOT NULL,
  `airport_name` varchar(255) NOT NULL,
  `place` varchar(255) NOT NULL,
  `country` varchar(255) NOT NULL,
  PRIMARY KEY (`airport_iata_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOCK TABLES `airports` WRITE;
INSERT INTO `airports` VALUES ('BRU','Brussels Airports','Zaventem','Belgium'),('ANR','Antwerp International Airport','Deurne','Belgium'),('LGG','Liege Airport','Luik','Belgium'),
('CRL','Brussels South Charleroi Airport','Charleroi','Belgium'),('OST','Ostend Bruges International Airport','Oostende','Belgium');
INSERT INTO `airports` VALUES ('HER','Heraklion International Airport','Crete','Greece'),('CFU','Corfu International Airport','Corfu','Greece'),('RHO','Rhodes International Airport','Rhodes','Greece');
INSERT INTO `airports` VALUES ('PMO','Palermo Falcone-Borsellino Airport','Palermo','Italy'),('NAP','Naples Airport','Naples','Italy'),
('BDS','Brindisi Airport','Brindisi','Italy'),('FAo','Faro Airport','Faro','Portugal');
INSERT INTO `airports` VALUES ('ALC','Alicante Airport','Alicante','Spain'),('AGP','Malaga Costa Del Sol Airport','Malaga','Spain'),('IBZ','Ibiza Airport','Ibiza','Spain'),
('PMI','Palma de Mallorca Airport','Palma','Spain'),('TFS','Tenerife South Airport','Tenerife','Spain');
UNLOCK TABLES;

--
-- Table structure for table `flights`
--

DROP TABLE IF EXISTS `flight`;
CREATE TABLE `flight` (
  `flight_id` varchar(255) NOT NULL,
  `flightnumber` varchar(10) NOT NULL,
  `departure_date` date NOT NULL,
  `arrival_date` date NOT NULL,
  `departure_time` datetime NOT NULL,
  `arrival_time` datetime NOT NULL,
  `duration` int NOT NULL,
  `number_of_stops` INT NOT NULL,
  `airline_iata_code` varchar(10) NOT NULL,
  `departure_airport_iata_code` varchar(10) NOT NULL,
  `arrival_airport_iata_code` varchar(10) NOT NULL,
  PRIMARY KEY (`flight_id`),
  KEY `fk_flights_dep_airports` (`departure_airport_iata_code`),
  KEY `fk_flights_arr_airports` (`arrival_airport_iata_code`),
  KEY `fk_flights_airlines` (`airline_iata_code`),
  CONSTRAINT `fk_flights_dep_airports` FOREIGN KEY (`departure_airport_iata_code`) REFERENCES `airports` (`airport_iata_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_flights_arr_airports` FOREIGN KEY (`arrival_airport_iata_code`) REFERENCES `airports` (`airport_iata_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_flights_airlines` FOREIGN KEY (`airline_iata_code`) REFERENCES `airlines` (`airline_iata_code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Table structure for table `search_dates`
--

DROP TABLE IF EXISTS `search_dates`;
CREATE TABLE `search_dates` (
  `scrape_date` date NOT NULL,
  `seats_available` INT NOT NULL,
  `price` INT NOT NULL,
  `flight_id` varchar(255) NOT NULL,
  PRIMARY KEY (`scrape_date`, `flight_id`),
  FOREIGN KEY (`flight_id`) REFERENCES `flight` (`flight_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


