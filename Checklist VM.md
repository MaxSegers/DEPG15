# Wat we nog moeten configureren op de VM

1. Public keys toegevoegd
2. mysql server installeren (google mysql almalinux 9)
3. dit moet meteen opstarten alles de vm opstart
4. Python 3 installeren (googelen python 3 almalinux 9)
5. Selenium installeren
6. Venv, virtual environments installeren voor die pip install voor steelt
7. Script runnen + zorgen dat data in de databank komt
8. cron om scripts te schedulen
9. vanuit windows (mysql workbench) connecteren met mysql server op de vm
   - nieuw blokje aanmaken
   - connection method: Standard tcp/ip over ssh

- We zullen gewoon de git op de vm zetten zodat we makkelijk aan alle eerder gescrapte data kunnen en aan alle scripts, zo hebben we ook nieuwe versies indien er nog aanpassingen moeten gebeuren

## Wat is er al gedaan?

- [x] Toevoegen public keys
- [x] mysql + running bij opstart
- [x] Python 3 install
- [ ] Selenium install
- [x] venv install
      => source venv/bin/activate om aan te zetten
      => deactivate om uit te zetten
- [x] Git installeren, deze repo clonen
- [ ] cron om de scripts te schedulen
- [ ] Zorgen dat data in de databank komt
- [ ] Vanuit windows verbinding leggen met mysql server op vm
