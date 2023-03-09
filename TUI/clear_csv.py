import os
import csv

direc = "C:/Users/Maxime/Desktop/MT2_Sem2/DataEngineeringProject/GedeeldeGIT/DEPG15/TUI/csv_bestanden"


for x in os.listdir(direc):
    if x.endswith(".csv"):

        with open(f"./csv_bestanden/{x}", 'w', newline='') as outfile:
            writer = csv.writer(outfile)
            outfile.truncate()
            header = ['search_date', 'departure_date', 'arrival_date', 'departure_time', 'arrival_time', 'departure_airport', 'arrival_airport', 'flight_duration', 'flight_type', 'flight_number', 'available_seats', 'price', 'flight_key']
            writer.writerow(header)
            outfile.close()