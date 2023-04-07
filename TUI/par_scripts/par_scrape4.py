from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from mysql.connector import Error

import mysql.connector
import json
import datetime

path = "DEPG15/TUI/csv_bestanden"
airline_id = 2
flight_type = ""

try:
    connection = mysql.connector.connect(host='localhost',
                                         database='vluchten',
                                         user='root',)

    cursor = connection.cursor()
    # Opties voor de scraper
    options = webdriver.ChromeOptions()
    options.add_argument("--disable-dev-shm-usage"); # Overcome limited resource problems
    options.add_argument("--no-sandbox"); # Bypass OS security model
    options.add_argument('--headless')
    options.add_experimental_option('excludeSwitches', ['enable-logging'])

    # Locatie van chromedriver
    PATH = "home/vicuser/venv/lib64/python3.9/site-packages/selenium/webdriver/chrome/webdriver.py"
    driver_service = Service(executable_path=PATH)
    driver = webdriver.Chrome(service=driver_service,options=options)

    # Dictionary met Vertrekplaatsen en de mogelijk bestemmingen per vertrekplaats
    vluchtroutes = {
        "LGG": ("HER", "RHO", "ALC", "AGP", "PMI", "TFS")
    }

    # Enkele datumvariabelen
    date = datetime.datetime.now()
    current_date = date.strftime("%Y-%m-%d")
    end_date = datetime.datetime(2023, 10, 1)


    # --- Data van de webpagina halen ---
    # Per vluchtroute de gegevens scrapen tussen start_date en end_date
    for key, values in vluchtroutes.items():
        cursor.execute(f"SELECT airport_id FROM airports WHERE airport_code LIKE '{key}'")
        depairport = cursor.fetchall()[0][0]
        for value in values:

            cursor.execute(f"SELECT airport_id FROM airports WHERE airport_code LIKE '{value}'")
            arrairport = cursor.fetchall()[0][0]

            # Startdatum van de periode die we willen scrapen + statische startdatum die niet verandert om vluchten voor april eruit te filteren
            start_date = date
            static_start_date = start_date

            while start_date <= end_date:
                # De nieuwe datum in het juiste formaat in de URL steken
                date_string = start_date.strftime("%Y-%m-%d")
                url = f"http://www.tuifly.be/flight/nl/search?flyingFrom%5B%5D={key}&flyingTo%5B%5D={value}&depDate={date_string}&adults=1&children=0&childAge=&choiceSearch=true&searchType=pricegrid&nearByAirports=false&currency=EUR&isOneWay=true"
                driver.get(url)

                # Ophalen uit opmaak (element inspecteren)
                data = driver.execute_script("return JSON.stringify(searchResultsJson)")
                json_object = json.loads(data)
                
                
                # --- Data uit dict halen en wegschrijven naar csv bestand ---
                for element in json_object["flightViewData"]:
                    flight_available = False
                    dep_date = element["departureDate"]
                    if (dep_date >= static_start_date.strftime("%Y-%m-%d")) and (dep_date <= end_date.strftime("%Y-%m-%d")):

                        #datum + luchthavencodes
                        arr_date = element["journeySummary"]["arrivalDate"]
                        arrAirport = element["journeySummary"]["arrivalAirportCode"]
                        depAirport = element["journeySummary"]["departAirportCode"]
                        
                        #Nuttige data voor latere analyse
                        journeyType = element["journeySummary"]["journeyType"]
                        price = element["totalPrice"]
                        availableSeats = element["journeySummary"]["availableSeats"]

                        #Uren(lokale tijd) + vluchtduratie
                        dep_time = element["journeySummary"]["depTime"]
                        arr_time = element["journeySummary"]["arrivalTime"]
                        duration = element["journeySummary"]["journeyDuration"]

                        #vluchtnummer gecombineerd (vb: TB en 2315)
                        carrierCode = element["flightsectors"][0]["carrierCode"]
                        flightNumber = element["flightsectors"][0]["flightNumber"]
                        full_flnr = carrierCode + " " + flightNumber

                        #flightkey samenstellen
                        flight_key = f"{carrierCode}~{flightNumber}~ ~{depAirport}~{dep_date} {dep_time}~{arrAirport}~{arr_date} {arr_time}~"
                        
                        flight_available = True

                    if flight_available:
                        cursor.execute(f"SELECT * FROM flights WHERE flight_key = '{flight_key}'")
                        data = cursor.fetchall()
                        if not data:
                        
                            flight_type = 0 if journeyType == 'Direct' else 1

                            duration = duration.split(" ")
                            duration = (int(duration[0][0:-1])*60 + int(duration[1][0:-1]))

                            mySql_insert_query = f"""INSERT INTO flights VALUES 
                                            ('{flight_key}', '{dep_date}', '{arr_date}', '{dep_date} {dep_time}:00', '{arr_date} {arr_time}:00', {duration}, '{flightNumber}', {flight_type}, {depairport}, {arrairport}, {airline_id}) """

                            cursor.execute(mySql_insert_query)
                            connection.commit()
                            print(cursor.rowcount, "Record inserted successfully into flights table")

                        mySql_insert_query = f"""INSERT INTO search_dates VALUES 
                                    ('{current_date}', {price}, {availableSeats}, '{flight_key}') """

                        cursor.execute(mySql_insert_query)
                        connection.commit()
                        print(cursor.rowcount, f"Record inserted successfully into search_dates table")
                        print(f"Vlucht gescraped: {depAirport} naar {arrAirport} op {dep_date} - Script 4")

                    flight_available = False


                # --- Debugging opties ---
                
                # Volledig object in leesbaar formaat
                # dictio = json.dumps(json_object, indent=4)
                # print(element)

                # leesbaarformaat nuttige data
                # print(json.dumps(json_object["flightViewData"], indent=4))

                # Telkens een week bij de datum tellen -> TUI geeft altijd alle vluchten in die week mee dus efficienter dan per dag
                start_date = start_date + datetime.timedelta(weeks=1)

except mysql.connector.Error as error:
    print("Failed to insert record into Laptop table {}".format(error))

finally:
    if connection.is_connected():
        connection.close()
        print("MySQL connection is closed")
