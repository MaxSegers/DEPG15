import os
import csv

# --- Script om csv-bestanden leeg te maken en de header te behouden ---

# Relatief pad tot de directory
path = "DEPG15/TUI/csv_bestanden"

# Elk bestand in de dir overlopen
for file in os.listdir(path):
    if file.endswith(".csv"):
        print(file)
        with open(f"DEPG15/TUI/csv_bestanden/{file}", 'w', newline='') as outfile:
            writer = csv.writer(outfile)
            outfile.truncate()
            header = ['search_date', 'departure_date', 'arrival_date', 'departure_time', 'arrival_time', 'departure_airport', 'arrival_airport', 'flight_duration', 'flight_type', 'flight_number', 'available_seats', 'price', 'flight_key']
            writer.writerow(header)
            outfile.close()
