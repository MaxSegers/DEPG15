# De samenvatting van beide vergaderingen voor week 6

## Samenvatting Analyse

- 24 uur minimum sprint backlog per sprint
- Scrum bord meer gebruiken
- Nieuwe sprint aanmaken via backlog
- Nu maandag nieuwe sprint beginnen (26u)
- Task: Script checken (5m per keer loggen ofzo)
- Searchdate as key, opslaan als datetime object
- Voor de rest redelijk goed

## Samenvatting Project

1. OLTP
    - Zwakke entiteit van maken voor de sleutel

2. OLAP
   - Dim_flight is slowly changing dimension
   - Sql script dat ervoor zorgt dat alle data vanuit de oltp naar het olap gaat

3. Rotating proxies:
   - Om ervoor te zorgen dat we niet altijd van hetzelfde ip adres scrapen
   - Ongeveer voor elke bestemming per luchtvaartmaatschappij een nieuwe proxy

4. Zie 'Checklist VM' voor wat we nog met de vm moeten doen



Eerste week paasvakantie gedeelde databank om resultaten in te zetten

SQL schrijven om de data uit oltp te halen naar het datawarehouse

isholiday
naamholiday
isweekend

1. dimdate vullen
2. dimairlines opvullen
3. dimairports opvullen
4. dimflights (slowly changing) opvullen
5. fact table opvullen

Miss cronjob om sql dump te maken van data om analyses lokaal uit te voeren