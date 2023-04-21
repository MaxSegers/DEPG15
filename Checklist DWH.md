# Om het datawarehouse aan te maken

1. DimDate tabel aanpassen (zoek script online bv: https://gist.github.com/jrgcubano/c4dbaa879a1cfc9899f961d6eafa737c)

   - Zorg dat de code wel werkt voor mysql (geen sql server)
   - DimDate moet ook zeker een 'isHoliday', 'nameHoliday' en 'isWeekend' bevatten.

2. SQL-script schrijven om de data uit oltp te halen naar het datawarehouse (Zie cursus RDB)

   - Volgorde van stappen om OLTP naar OLAP te zetten:
     1. dimdate vullen
     2. dimairlines opvullen
     3. dimairports opvullen
     4. dimflights (slowly changing) opvullen (start en end)
     5. fact table opvullen

3. Voor specifieke vragen mochten we haar altijd op teams/mail een bericht sturen. (Sabine De Vreese)

4. Wees voorzichtig met de data in de OLTP databank, want we hebben geen back-up data. Dus niet zomaar tabellen clearen
