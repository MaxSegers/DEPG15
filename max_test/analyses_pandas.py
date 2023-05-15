import pandas as pd
import mysql.connector as msql
from mysql.connector import Error
from datetime import date, timedelta
import warnings

warnings.filterwarnings('ignore')
try:
    conn = msql.connect(host='localhost', database='airfaresdwh', user='root', password='wachtwoord')#give ur username, password

    query = """SELECT SeatsAvailable AS 'Seats Remaining', COUNT(SeatsAvailable) AS 'Total' FROM FactFlights ff
	JOIN DimAirline da ON ff.AirlineKey = da.AirlineKey
	JOIN DimAirport da1 ON ff.DepartureAirportKey = da1.AirportKey
    JOIN DimAirport da2 ON ff.ArrivalAirportKey = da2.AirportKey
    JOIN DimFlight df ON ff.FlightKey = df.FlightKey
    JOIN DimDate dd1 ON ff.ScrapeDateKey = dd1.DateKey
    JOIN DimDate dd2 ON ff.DepartureDateKey = dd2.DateKey
    JOIN DimDate dd3 ON ff.ArrivalDateKey = dd3.DateKey
    WHERE (dd2.FullDate = date_add(dd1.FullDate, INTERVAL 1 DAY)) AND AirlineName LIKE 'TUI fly'
    GROUP BY SeatsAvailable
    ORDER BY 1 DESC;"""
    df = pd.read_sql(query,conn)
    print(df.head(20))
    conn.close() # close the connection
except Exception as e:
    conn.close()
    print(str(e))

## Vraag 1: Hoeveel % van de vluchten zijn volgeboekt

df.plot()