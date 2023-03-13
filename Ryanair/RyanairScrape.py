import requests
from bs4 import BeautifulSoup
import json
import csv
import datetime
import time

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
for vertrekplaats, bestemmingen in vluchtroutes.items():
    for bestemming in bestemmingen:
        start_date = datetime.datetime(2023, 3, 1)

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
                            departure_time = departure_time.strftime("%H:%M")
                            arrival_timeAndDate = datetime.datetime.strptime(
                                arrival, "%Y-%m-%dT%H:%M:%S.%f")
                            arrival_time = arrival_timeAndDate.strftime(
                                "%H:%M")
                            arrival_date = arrival_timeAndDate.strftime(
                                "%Y-%m-%d")

                            flight_duration = segments['duration']

                            # als er vluchten zijn, schrijf dan naar csv
                            if flights_exist:
                                print("flight exists, writing ...")
                                with open(f"DEPG15/Ryanair/csv_bestanden/Ryanair_{vertrekplaats}_{bestemming}.csv", 'a', newline='\n') as test_csv:
                                    test_csv_append = csv.writer(test_csv)
                                    test_csv_append.writerow(
                                        ['Ryanair', search_date, departure_date, departure_time, arrival_date, arrival_time, departure_aircode, departure_airport,
                                         arrival_aircode, arrival_airport, flight_duration, flight_number, seats_available, price, flight_key])

            # dag + 1 => volgende dag ophalen
            start_date += datetime.timedelta(days=1)
