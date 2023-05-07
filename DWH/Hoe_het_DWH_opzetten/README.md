# Hoe het Datawarehouse opstellen?

1. Zorg dat de OLTP database juist is. Run het script `SQL_airfares.sql`
2. Vul via het mapje `max_test` het `csv_to_db.py` script om voor één dag (zelf aan te passen) data in de OLTP database te steken

3. Run het script `DWH voor DEP.sql` in Mysql
4. Run het script `Opvullen volledig DataWareHouse.sql` in Mysql (Ongeveer 20s runtime)

## Wat er nog kan gebeuren?

- Verder aanvullen van DimDate
- Testen voor nieuwe dagen (OLTP verwijderen en aanmaken met data van volgende dag)
- Uitproberen in PowerBI
- Kijken of het feit dat de dates een varchar(10) zijn geen probleem zijn
