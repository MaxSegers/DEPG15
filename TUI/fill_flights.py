import csv
import mysql.connector
from mysql.connector import Error
import os

path = "DEPG15/TUI/csv_bestanden"
airport_id = 2
flight_type = ""

try:
    connection = mysql.connector.connect(host='localhost',
                                         database='vluchten',
                                         user='root',
                                         password='wachtwoord')

    cursor = connection.cursor()
    

    for file in os.listdir(path):
        if file.endswith(".csv"):
            cursor.execute(f"SELECT airport_id FROM airports WHERE airport_code LIKE '{file[4:7]}'")
            depairport = cursor.fetchall()[0][0]
            cursor.execute(f"SELECT airport_id FROM airports WHERE airport_code LIKE '{file[8:11]}'")
            arrairport = cursor.fetchall()[0][0]
            print(depairport, arrairport)
            print(file)
            with open(f"DEPG15/TUI/csv_bestanden/{file}") as file:
                heading = next(file)
                reader_obj = csv.reader(file)
                for row in reader_obj:
                    cursor.execute(f"SELECT * FROM flights WHERE flight_key = '{row[12]}'")
                    data = cursor.fetchall()
                    if not data:
                        
                        flight_type = 0 if row[8] == 'Direct' else 1

                        duration = row[7].split(" ")
                        duration = (int(duration[0][0:-1])*60 + int(duration[1][0:-1]))

                        mySql_insert_query = f"""INSERT INTO flights VALUES 
                                            ('{row[12]}', '{row[1]}', '{row[2]}', '{row[1]} {row[3]}:00', '{row[2]} {row[4]}:00', {duration}, '{row[9]}', {flight_type}, {depairport}, {arrairport}, {airport_id}) """

                        cursor.execute(mySql_insert_query)
                        connection.commit()
                        print(cursor.rowcount, "Record inserted successfully into flights table")

    cursor.close()

except mysql.connector.Error as error:
    print("Failed to insert record into Laptop table {}".format(error))

finally:
    if connection.is_connected():
        connection.close()
        print("MySQL connection is closed")