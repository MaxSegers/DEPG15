from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.remote.webelement import WebElement

import json
import csv
import datetime
import time

# --- Settings voor Selenium en andere variabelen ---
options = webdriver.ChromeOptions()
options.add_experimental_option('excludeSwitches', ['enable-logging'])

# Locatie van chromedriver
PATH = "driver"
driver_service = Service(executable_path=PATH)
driver = webdriver.Chrome(service=driver_service, options=options)

# Lijst alle bestemmingen aanmaken
bestemmingen = [
    "Corfu",
    "Kreta",
    "Heraklion",
    "Rhodos",
    "Brindisi",
    "Napels",
    "Palermo",
    "Faro",
    "Alicante",
    "Ibiza",
    "Malaga",
    "Palma",
    "Tenerife"
]
weekdays = {
    0: "maandag",
    1: "dinsdag",
    2: "woensdag",
    3: "donderdag",
    4: "vrijdag",
    5: "zaterdag",
    6: "zondag"}

adds = {
    1: "st",
    2: "nd",
    3: "rd",
    21: "st",
    22: "nd",
    23: "rd",
    31: "st"
}

months = {
    1: "januari",
    2: "februari",
    3: "maart",
    4: "april",
    5: "mei",
    6: "juni",
    7: "juli",
    8: "augustus",
    9: "september",
    10: "oktober",
    11: "november",
    12: "december"
}


# Datum waarop dit script wordt uitgevoerd (current_date), eerste datum waarvan het script scraped (start_date), datum tot wanneer er moet worden opgehaald (end_date)
current_date = datetime.datetime(datetime.datetime.now(
).year, datetime.datetime.now().month, datetime.datetime.now().day)
start_date = datetime.datetime(2023, 4, 1)
end_date = datetime.datetime(2023, 10, 1)
search_date = current_date

# Maximumtijd om element te vinden aanmaken om script zo efficiënt mogelijk te laten werken
wait15s = WebDriverWait(driver, 15)
wait30s = WebDriverWait(driver, 30)

# Checked of current date dichter ligt bij end date dan current start date
# en vervangt current start date door current date als dit zo is
if current_date > start_date:
    start_date = current_date


# Cookies afwijzen
def handleCookies():
    try:
        wait30s.until(EC.visibility_of_element_located(
            (By.ID, 'cm-acceptNone')))
        cookie = driver.find_element(By.ID, 'cm-acceptNone')
        time.sleep(1)
        cookie.click()
    except:
        pass


# Main code
for bestemming in bestemmingen:
    print(bestemming)
    URL = f"https://www.brusselsairlines.com/lhg/be/nl/o-d/cy-cy/brussel-{bestemming}"
    driver.get(URL)
    handleCookies()
    # Checkt of de bestemming word bediend
    try:
        element = driver.find_element(By.XPATH, '//*[@id="content"]/div/h1')
        text = element.get_attribute("innerHTML")
        if text == "Pagina niet gevonden":
            bestemmingen.remove(bestemming)
    except:

        # Bestemming word bediend
        time.sleep(1)
        driver.find_element(
            By.XPATH, '//*[@id="content"]/div[3]/p[4]/a').click()
        wait30s.until(EC.visibility_of_element_located(
            (By.XPATH, '//*[@id="MODIFY_SEARCH_ARRIVAL_LOCATION_1_0"]')))

        # Invullen van gegevens
        input = driver.find_element(
            By.XPATH, '//*[@id="MODIFY_SEARCH_ARRIVAL_LOCATION_1_0"]')
        time.sleep(1)
        input.click()
        input.send_keys(bestemming)
        while start_date < end_date:

            print(start_date)

            # Klik op agenda vertrekdatum
            wait30s.until(EC.visibility_of_element_located(
                (By.XPATH, '//*[@id="page"]/cont-modify-search/pres-modify-search/div/div[2]/cont-datepicker[1]/pres-datepicker-v2/div/span')))
            time.sleep(1)
            driver.find_element(
                By.XPATH, '//*[@id="page"]/cont-modify-search/pres-modify-search/div/div[2]/cont-datepicker[1]/pres-datepicker-v2/div/span').click()
            time.sleep(1)

            # Bereken gegevens voor aria-label
            day = start_date.day
            weekday = weekdays[start_date.weekday()]
            month = months[start_date.month]
            year = start_date.year
            if day in [1, 2, 3, 21, 22, 23, 31]:
                add = adds[day]
            else:
                add = "th"

            # Klik op correcte datum
            wait15s.until(EC.visibility_of_element_located(
                (By.CSS_SELECTOR, f"div[aria-label='{weekday} {day}{add} {month} {year}']")))
            time.sleep(1)
            driver.find_element(
                By.CSS_SELECTOR, f"div[aria-label='{weekday} {day}{add} {month} {year}']").click()
            time.sleep(2)

            # Klik op zoekknop om vliegtrajecten ingegeven dag te bekijken
            driver.find_element(
                By.XPATH, '//*[@id="page"]/cont-modify-search/pres-modify-search/div/div[3]/div[3]/button').click()
            time.sleep(1)

            try:
                aantalOpPagina = len(driver.find_elements(
                    By.CLASS_NAME, "ng-tns-c78-1 ng-star-inserted"))
                departure_airport = driver.find_element(
                    By.XPATH, '//*[@id="MODIFY_SEARCH_DEPARTURE_LOCATION_1_0-airport-value"]').get_attribute("value")
                arrival_airport = driver.find_element(
                    By.XPATH, '//*[@id="MODIFY_SEARCH_ARRIVAL_LOCATION_1_0-airport-value"]').get_attribute("value")
                departure_date = start_date
                times = driver.find_elements(By.CLASS_NAME, 'time')
                for index, hours in enumerate(times):
                    times[index] = hours.get_attribute('innerHTML')
                for index, hours in enumerate(times):
                    times[index] = str(hours).split('-')
                stops = driver.find_elements(
                    By.CLASS_NAME, 'nbStops ng-star-inserted')
                flight_info = driver.find_elements(By.CLASS_NAME, 'right')
                flight_info2 = [[WebElement]]
                flight_numbers = []
                airline_names = []
                for index, right in enumerate(flight_info):
                    flight_info2[index] = right.find_elements(
                        By.CLASS_NAME, 'availInfoAirlineContainer airlineDetails ng-star-inserted')
                for index, list in enumerate(flight_info2):
                    temp_numbers = []
                    temp_names = []
                    for item in list:
                        temp_numbers.append(item.find_element(
                            By.CLASS_NAME, 'flightNumber').get_attribute('innerHTML'))
                        temp_names.append(item.find_element(
                            By.CLASS_NAME, 'airlineName ng-star-inserted').get_attribute('innerHTML'))
                    flight_numbers[index] = temp_numbers
                    airline_names[index] = temp_names
                prizes = driver.find_elements(
                    By.CLASS_NAME, 'container cabinE ng-star-inserted')
                available_seats = []
                for index, price in enumerate(prizes):
                    prizes[index] = price.find_element(
                        By.CLASS_NAME, 'cabinPrice').get_attribute('innerHTML')
                    try:
                        available_seats[index] = str(price.find_element(
                            By.CLASS_NAME, 'seats ng-star-inserted').get_attribute('innerHTML'))
                    except:
                        available_seats[index] = "8+"
                for i in range(aantalOpPagina):
                    if 'Brussels Airlines' in airline_names[i]:
                        loc_bru = airline_names[i].index(
                            'Brussels Airlines')
                        dep_time = times[i][0]
                        arr_time = times[i][1]
                        dep_hours = int(dep_time[0:2])
                        dep_minutes = int(dep_time[3:5])
                        arr_hours = int(arr_time[1:3])
                        arr_minutes = int(arr_time[4:6])
                        if dep_hours > arr_hours and dep_minutes > arr_minutes:
                            flight_duration = f"{24-dep_hours+arr_hours}:{60-dep_minutes+arr_minutes}"
                        elif dep_hours > arr_hours and dep_minutes < arr_minutes:
                            flight_duration = f"{24-dep_hours+arr_hours}:{arr_minutes-dep_minutes}"
                        elif dep_hours < arr_hours and dep_minutes > arr_minutes:
                            flight_duration = f"{arr_hours-dep_hours}:{60-dep_minutes+arr_minutes}"
                        else:
                            flight_duration = f"{arr_hours-dep_hours}:{arr_minutes-dep_minutes}"
                        arrival_date = datetime.datetime(year=departure_date.year, month=departure_date.month, day=departure_date.day,
                                                         hour=dep_hours, minute=dep_minutes) + datetime.datetime(hour=flight_duration[0:2], minute=flight_duration[3:4])
                        f = open('Data.csv', 'w')
                        writer = csv.writer(f, delimiter=',')
                        writer.writerow(search_date, departure_date, arrival_date, dep_time, arr_time, departure_airport, arrival_airport,
                                        flight_duration, flight_numbers[i][loc_bru], available_seats, price)
            except:
                pass
            start_date = start_date + datetime.timedelta(days=1)
