import csv
import mysql.connector
from mysql.connector import Error
import os
path = "DEPG15/TUI/csv_bestanden"

try:
    connection = mysql.connector.connect(host='localhost',
                                         database='vluchten',
                                         user='root',
                                         password='wachtwoord')

    cursor = connection.cursor()

    for file in os.listdir(path):
        if file.endswith(".csv"):

            with open(f"DEPG15/TUI/csv_bestanden/{file}") as file:
                heading = next(file)
                reader_obj = csv.reader(file)
                for row in reader_obj:
                    
                    mySql_insert_query = f"""INSERT INTO search_dates VALUES 
                                        ('{row[0]}', {row[11]}, {row[10]}, '{row[12]}') """

                    cursor.execute(mySql_insert_query)
                    connection.commit()
                    print(cursor.rowcount, f"Record inserted successfully into search_dates table, {row[0],row[1]}")
            cursor.close()

except mysql.connector.Error as error:
    print("Failed to insert record into Laptop table {}".format(error))

finally:
    if connection.is_connected():
        connection.close()
        print("MySQL connection is closed")

