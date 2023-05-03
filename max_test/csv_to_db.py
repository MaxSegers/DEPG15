import csv
import mysql.connector
from mysql.connector import Error
import os
path = "DEPG15/max_test/data"

try:
    connection = mysql.connector.connect(host='localhost',
                                         database='airfares',
                                         user='root',
                                         password='wachtwoord')

    cursor = connection.cursor()

    for file in os.listdir(path):
        if file.startswith("All_2023"):

            with open(f"DEPG15/max_test/data/{file}") as file:
                reader_obj = csv.reader(file)
                for row in reader_obj:

                    cursor.execute(f"SELECT * FROM flight WHERE flight_id = '{row[0]}'")
                    data = cursor.fetchall()
                    if not data:
                        print(f"'{row[0]}', '{row[1]}', '{row[2]}', '{row[3]}', '{row[4]}', {row[5]}, '{row[6]}', '{row[7]}', '{row[8]}', '{row[9]}', '{row[10]}'")
                        mySql_insert_query = f"""INSERT INTO flight VALUES 
                                            ('{row[0]}', '{row[1]}', '{row[2]}', '{row[3]}', '{row[4]}', '{row[5]}', '{row[6]}', '{row[7]}', '{row[8]}', '{row[9]}', '{row[10]}') """

                        cursor.execute(mySql_insert_query)
                        connection.commit()
                        print(cursor.rowcount, f"Record inserted successfully into flight table, {row[0]}")
                    

                    cursor.execute(f"SELECT * FROM search_dates WHERE flight_id = '{row[0]}' AND scrape_date = '{row[-3]}'")
                    data = cursor.fetchall()
                    if not data:
                        mySql_insert_query = f"""INSERT INTO search_dates VALUES 
                                            ('{row[-3]}', {row[-2]}, {row[-1]}, '{row[0]}') """

                        cursor.execute(mySql_insert_query)
                        connection.commit()
                        print(cursor.rowcount, f"Record inserted successfully into search_dates table, {row[0],row[1],row[5],row[6],row[-3],row[-1]}")
                
    cursor.close()

except mysql.connector.Error as error:
    print("Failed to insert record {}".format(error))

finally:
    if connection.is_connected():
        connection.close()
        print("MySQL connection is closed")