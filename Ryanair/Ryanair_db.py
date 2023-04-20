#!/usr/bin/python3

import requests
from bs4 import BeautifulSoup
import json
import csv
import datetime
import time
import mysql.connector
from mysql.connector import Error

# dictionary met vertrekplaatsen en mogelijke bestemmingen
vluchtroutes = {
    "CRL": ("CFU", "HER", "RHO", "BDS", "NAP", "PMO", "FAO",
            "ALC", "IBZ", "AGP", "PMI", "TFS"),
    "BRU": ("ALC", "AGP", "PMI")
}

# datums
search_date = datetime.datetime.now().strftime("%Y-%m-%d")
end_date = datetime.datetime(2023, 10, 1)

# url opbouwen

try:
    connection = mysql.connector.connect(host='localhost',
                                         database='vluchten',
                                         user='root',
                                         password='S@1ExQ1693L'
                                         )

    cursor = connection.cursor()
    for vertrekplaats, bestemmingen in vluchtroutes.items():
        for bestemming in bestemmingen:
            start_date = datetime.datetime.now()

         # data ophalen voor elke dag tussen start en einddatum
            while start_date <= end_date:
                datum = start_date.strftime("%Y-%m-%d")
                print(vertrekplaats, bestemming, datum)

                URL = f"https://www.ryanair.com/api/booking/v4/nl-nl/availability?ADT=1&CHD=0&DateOut={datum}&Destination={bestemming}&Disc=0&INF=0&Origin={vertrekplaats}&TEEN=0&promoCode=&IncludeConnectingFlights=true&RoundTrip=false&ToUs=AGREED"

                # HTML object uit webpagina halen
                # error handling zodat programma niet afsluit bij een error
                page = None

                while page is None:
                    try:
                        page = requests.get(URL)
                    except requests.ConnectionError as ce:
                        print("Connection error, trying again in 5 seconds.", ce)
                        time.sleep(5)
                        continue
                    except requests.Timeout as te:
                        print("Timeout error, trying again in 5 seconds.", te)
                        time.sleep(5)
                        continue
                    except requests.RequestException as re:
                        print("Request error, trying again in 5 seconds.", re)
                        time.sleep(5)
                        continue
                    except KeyboardInterrupt as ki:
                        print("Keyboard interrupt, stopping.", ki)
                        exit(1)

                soup = BeautifulSoup(page.content, "lxml")
                result = soup.find("p").text

                # convert string to  object
                json_object = json.loads(result)

                flights_exist = False

                # data uit json object halen
                for trips in (json_object['trips']):
                    departure_aircode, departure_airport = (
                        trips['origin']), trips['originName']
                    arrival_aircode, arrival_airport = trips['destination'], trips['destinationName']

                    for dates in trips['dates']:
                        departure_date = dates['dateOut']
                        departure_date = datetime.datetime.strptime(
                            departure_date, "%Y-%m-%dT%H:%M:%S.%f")
                        departure_date = departure_date.strftime("%Y-%m-%d")

                        for flights in dates['flights']:
                            flights_exist = True
                            seats_available = flights['faresLeft']
                            flight_key = flights['flightKey']

                            # bij sommige URL's zit de prijs niet in de regularFare, maar in de segments (HTML structuur is anders)
                            try:
                                for fares in flights['regularFare']['fares']:
                                    price = fares['publishedFare']

                            except:
                                for segment in flights['segments']:
                                    price = fares['publishedFare']

                            for segments in flights['segments']:
                                flight_number = segments['flightNumber']
                                departure, arrival = segments['time'][0], segments['time'][1]
                                departure_time = datetime.datetime.strptime(
                                    departure, "%Y-%m-%dT%H:%M:%S.%f")
                                departure_time = departure_time.strftime(
                                    "%H:%M")
                                arrival_timeAndDate = datetime.datetime.strptime(
                                    arrival, "%Y-%m-%dT%H:%M:%S.%f")
                                arrival_time = arrival_timeAndDate.strftime(
                                    "%H:%M")
                                arrival_date = arrival_timeAndDate.strftime(
                                    "%Y-%m-%d")

                                flight_duration = segments['duration']
                                duration = flight_duration.split(":")
                                duration = (
                                    int(duration[0])*60 + int(duration[1]))

                                if (flights_exist):
                                    cursor.execute(
                                        f"SELECT airport_id FROM airports WHERE airport_code LIKE '{departure_aircode}'")
                                    depairport = cursor.fetchall()[0][0]
                                    cursor.execute(
                                        f"SELECT airport_id FROM airports WHERE airport_code LIKE '{arrival_aircode}'")
                                    arrairport = cursor.fetchall()[0][0]

                                    cursor.execute(
                                        f"SELECT * FROM flights WHERE flight_key = '{flight_key}'")
                                    flight_indb = cursor.fetchall()

                                    if not flight_indb:
                                        mySql_insert_query = f"""INSERT INTO flights VALUES 
                                    ('{flight_key}', '{departure_date}', '{arrival_date}', '{departure_date} {departure_time}:00', '{arrival_date} {arrival_time}:00', '{duration}', '{flight_number}', '{"0"}', '{depairport}', '{arrairport}', '{"1"}')"""
                                        cursor.execute(mySql_insert_query)
                                        connection.commit()
                                        print(cursor.rowcount,
                                              "Record inserted successfully into flights table")

                                    mySql_insert_query = f"""INSERT INTO search_dates VALUES 
                                ('{search_date}','{price}', '{seats_available}', '{flight_key}')"""
                                    cursor.execute(mySql_insert_query)
                                    connection.commit()
                                    print(cursor.rowcount,
                                          "Record inserted successfully into search_dates table")

            # dag + 1 => volgende dag ophalen
                start_date += datetime.timedelta(days=1)

except mysql.connector.Error as error:
    print(
        "Failed to insert record into Laptop table {}".format(error))

finally:
    if (connection.is_connected()):
        cursor.close()
        connection.close()
        print("MySQL connection is closed")
