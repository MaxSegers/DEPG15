# De samenvatting van beide vergaderingen voor week 6

## Samenvatting Analyse

- Geen meeting.
- Probeer doorheen de vakantie regelmatig scrum bord te raadplegen en aanvullen (voor de burndown grafiek)

## Samenvatting Project

1. Eerste week paasvakantie gedeelde databank om resultaten in te zetten
    - Voor TUI / Ryanair script aanpassen zodat data rechtstreeks naar databank gaat ipv csv-files

2. OLAP
   - SQL-script schrijven om de data uit oltp te halen naar het datawarehouse
   - Dim_date moet zeker ook bevatten: isHoliday, nameHoliday, isWeekend
   - Volgorde van stappen om OLTP naar OLAP te zetten:
        1. dimdate vullen
        2. dimairlines opvullen
        3. dimairports opvullen
        4. dimflights (slowly changing) opvullen
        5. fact table opvullen 

4. Wat miss nog moet gebeuren: cronjob om sql dump te maken van data om analyses lokaal uit te voeren