import pandas as pd
import mysql.connector as mysql
from mysql.connector import Error
from datetime import date, timedelta
import shutil
import os

try:
    # autocommit is zéér belangrijk.
    conn = mysql.connect(host='localhost', database='airfares',
                         user='root', password='S@1ExQ1693L', autocommit=True)
    if conn.is_connected():
        print('connected to database')
        # choose a specific start_date
        start_date = date(2023, 4, 7)
        end_date = date(2023, 4, 26)
        delta = timedelta(days=1)
        while start_date <= end_date:

            date_format = start_date.strftime("%Y_%m_%d")

            # for each date and for each airline check if the file exists and copy the file to C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\
            for airline in ('Ryanair', 'Tui', 'Transavia', 'BA'):
                old_path = "C:\\Users\\stalm\\OneDrive\\Documenten\\2022-2023\\Semester 2\\Data Engineering Project\\DEP_git\\DEPG15\\Data_globaal\\" + \
                    airline + "_" + date_format + ".csv"
                new_path = "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\" + airline + ".csv"
                # Remove file if it already exists
                if os.path.exists(new_path):
                    os.remove(new_path)
                if os.path.exists(old_path):
                    shutil.copy(old_path, new_path)

            # conn.reconnect is important, otherwise error
            conn.reconnect()
            cursor = conn.cursor()
            print('reconnected')

            # Execute commands in file LoadFiles.sql to import data into database airfares
            with open('C:\\Users\\stalm\\OneDrive\\Documenten\\2022-2023\\Semester 2\\Data Engineering Project\\DEP_git\\DEPG15\\loadFiles.sql', 'r') as f:
                print('executing sql')
                cursor.execute(f.read(), multi=True)
            cursor.close()

            start_date += delta

    conn.close()


except Error as e:
    print("Error while connecting to MySQL", e)
