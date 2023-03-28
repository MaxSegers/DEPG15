-- MySQL dump 10.13  Distrib 8.0.26, for Win64 (x86_64)
--
-- Host: localhost    Database: vluchten
-- ------------------------------------------------------
-- Server version	8.0.26

--
-- DATABASE set-up
--
DROP DATABASE IF EXISTS vluchten;
CREATE DATABASE vluchten;
USE vluchten;

--
-- Table structure for table `airlines`
--

DROP TABLE IF EXISTS `airlines`;
CREATE TABLE `airlines` (
  `airline_id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `airline_name` varchar(255) NOT NULL,
  PRIMARY KEY (`airline_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOCK TABLES `airlines` WRITE;
INSERT INTO `airlines` VALUES (1,'Ryanair'),(2,'TUI fly'),(3,'Brussels Airlines');
UNLOCK TABLES;


--
-- Table structure for table `airports`
--

DROP TABLE IF EXISTS `airports`;
CREATE TABLE `airports` (
  `airport_id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `airport_name` varchar(255) NOT NULL,
  `airport_code` varchar(10) NOT NULL,
  `place` varchar(255) NOT NULL,
  `country` varchar(255) NOT NULL,
  PRIMARY KEY (`airport_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOCK TABLES `airports` WRITE;
INSERT INTO `airports` VALUES (1,'Brussels Airports','BRU','Zaventem','Belgium'),(2,'Antwerp International Airport','ANR','Deurne','Belgium'),(3,'Liege Airport','LGG','Luik','Belgium'),
(4,'Brussels South Charleroi Airport','CRL','Charleroi','Belgium'),(5,'Ostend Bruges International Airport','OST','Oostende','Belgium');
INSERT INTO `airports` VALUES (6,'Heraklion International Airport','HER','Crete','Greece'),(7,'Corfu International Airport','CFU','Corfu','Greece'),(8,'Rhodes International Airport','RHO','Rhodes','Greece');
INSERT INTO `airports` VALUES (9,'Palermo Falcone-Borsellino Airport','PMO','Palermo','Italy'),(10,'Naples Airport','NAP','Naples','Italy'),
(11,'Brindisi Airport','BDS','Brindisi','Italy'),(12,'Faro Airport','FAO','Faro','Portugal');
INSERT INTO `airports` VALUES (13,'Alicante Airport','ALC','Alicante','Spain'),(14,'Malaga Costa Del Sol Airport','AGP','Malaga','Spain'),(15,'Ibiza Airport','IBZ','Ibiza','Spain'),
(16,'Palma de Mallorca Airport','PMI','Palma','Spain'),(17,'Tenerife South Airport','TFS','Tenerife','Spain');
UNLOCK TABLES;


--
-- Table structure for table `search_dates`
--

DROP TABLE IF EXISTS `search_dates`;
CREATE TABLE `search_dates` (
  `search_date` date NOT NULL,
  `price` INT NOT NULL,
  `seats_available` INT NOT NULL,
  PRIMARY KEY (`search_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Table structure for table `flights`
--

DROP TABLE IF EXISTS `flights`;
CREATE TABLE `flights` (
  `flight_key` varchar(255) NOT NULL,
  `departure_date` date NOT NULL,
  `arrival_date` date NOT NULL,
  `departure_time` datetime NOT NULL,
  `arrival_time` datetime NOT NULL,
  `flight_duration` int NOT NULL,
  `flight_number` varchar(10) NOT NULL,
  `layovers` INT NOT NULL,
  `departure_airport_id` int UNSIGNED NOT NULL,
  `arrival_airport_id` int UNSIGNED NOT NULL,
  `airline_id` int UNSIGNED NOT NULL,
  `search_date` date NOT NULL,
  PRIMARY KEY (`flight_key`),
  KEY `fk_flights_dep_airports` (`departure_airport_id`),
  KEY `fk_flights_arr_airports` (`arrival_airport_id`),
  KEY `fk_flights_airlines` (`airline_id`),
  KEY `fk_flights_search_dates` (`search_date`),
  CONSTRAINT `fk_flights_dep_airports` FOREIGN KEY (`departure_airport_id`) REFERENCES `airports` (`airport_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_flights_arr_airports` FOREIGN KEY (`arrival_airport_id`) REFERENCES `airports` (`airport_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_flights_airlines` FOREIGN KEY (`airline_id`) REFERENCES `airlines` (`airline_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_flights_search_dates` FOREIGN KEY (`search_date`) REFERENCES `search_dates` (`search_date`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;