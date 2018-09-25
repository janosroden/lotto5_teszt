# lotto5_teszt

Ez a projekt arra készült, hogy akik fix számokkal játszanak az ötös lottón, azoknak megkönnyítse a nyeremény megállapítását.

Synology NAS-on van tesztelve, az ottani beállítások:
- Telepítsük a `Git Server` csomagot, hogy legyen `git` parancsunk
- `git clone https://github.com/janosroden/lotto5_teszt.git`
- `cd lotto5_teszt`
- `cp config.example config`
- `vi config`
  - nyomjuk meg az `i` betűt, hogy szerkesztő módba váltsunk
  - a kurzor billenyűkkel navigáljunk a számokhoz
  - a Del/Backspace billentyűkkel töröljük ki a számokat
  - írjuk be a saját számainkat
  - nyomjuk meg az `ESC`, `:`, `x` billenyűket a mentéshez és kilépéshez
- A webes felületen menjünk el az Ütemezett Feladatokhoz és adjunk hozzá egy "Saját script" típusút
  - állítsuk be, hogy kérünk email értesítést, de csak akkor, ha a futtatás hibával végződött
  - állítsuk be az e-mail címeket
  - a parancs: bash /var/services/homes/admin/lotto5_teszt/check.sh /var/services/homes/admin/lotto5_teszt/config /var/services/homes/admin/lotto5_teszt/
  - fusson a script minden nap minden órában
  - módosítsuk aszerint, hogy hová tettük a scriptet
