from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

import json
import csv
import datetime

# Opties voor de scraper
options = webdriver.ChromeOptions()
options.add_experimental_option('excludeSwitches', ['enable-logging'])

# Locatie van chromedriver
PATH = "C:\Program Files (x86)\Google\chromedriver"
driver_service = Service(executable_path=PATH)
driver = webdriver.Chrome(service=driver_service,options=options)

# Dictionary met Vertrekplaatsen en de mogelijk bestemmingen per vertrekplaats
vluchtroutes = {
    "ANR": ("ALC", "IBZ", "AGP", "PMI"),
    "BRU": ("CFU", "HER", "RHO", "FAO", "BDS", "NAP", "PMO", "ALC", "IBZ", "AGP", "PMI", "TFS"),
    "LGG": ("HER", "RHO", "ALC", "AGP", "PMI", "TFS"),
    "OST": ("HER", "RHO", "ALC", "IBZ", "AGP", "PMI", "TFS")
}

# Enkele datumvariabelen
current_date = datetime.datetime.now().strftime("%Y-%m-%d")
end_date = datetime.datetime(2023, 6, 1)


# --- Data van de webpagina halen ---
# Per vluchtroute de gegevens scrapen tussen start_date en end_date
for key, values in vluchtroutes.items():
    for value in values:

        # Startdatum van de periode die we willen scrapen + statische startdatum die niet verandert om vluchten voor april eruit te filteren
        start_date = datetime.datetime(2023, 5, 1)
        static_start_date = start_date

        while start_date <= end_date:
            # De nieuwe datum in het juiste formaat in de URL steken
            date_string = start_date.strftime("%Y-%m-%d")
            url = f"http://www.tuifly.be/flight/nl/search?flyingFrom%5B%5D={key}&flyingTo%5B%5D={value}&depDate={date_string}&adults=1&children=0&childAge=&choiceSearch=true&searchType=pricegrid&nearByAirports=false&currency=EUR&isOneWay=true"
            driver.implicitly_wait(50)
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
                    with open(f'C:/Users/Maxime/Desktop/MT2_Sem2/DataEngineeringProject/Scripts/csv/TUI_{key}_{value}.csv', 'a', newline='\n') as csvBestand:
                        voegToe = csv.writer(csvBestand)
                        voegToe.writerow([current_date, dep_date, arr_date, dep_time, arr_time, depAirport, arrAirport,
                        duration, journeyType, full_flnr, availableSeats, price, flight_key])
                    print(f"Vlucht gescraped: {depAirport} naar {arrAirport} op {dep_date}")

                flight_available = False


            # --- Debugging opties ---
            
            # Volledig object in leesbaar formaat
            # dictio = json.dumps(json_object, indent=4)
            # print(element)

            # leesbaarformaat nuttige data
            # print(json.dumps(json_object["flightViewData"], indent=4))

            # Telkens een week bij de datum tellen -> TUI geeft altijd alle vluchten in die week mee dus efficienter dan per dag
            start_date = start_date + datetime.timedelta(weeks=1)