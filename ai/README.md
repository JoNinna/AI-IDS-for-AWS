Pașii pentru testare

1. Verifică dacă ai datele pregătite local
Logurile preprocesate în folderele:
data/suricata/
data/falco/
Să conțină fișiere JSON sau JSONL conform formelor așteptate.

2. Verifică dacă ai modelele antrenate
Fișierele cu greutăți ale modelelor:
models/model_suricata.pt
models/model_falco.pt
Dacă nu ai încă modelele antrenate, va trebui să rulezi notebook-urile de training corespunzătoare pentru a le genera.

3. Pregătește mediul Python
Ai nevoie să ai instalate librăriile:
pip install torch pandas scikit-learn

4. Rulează scriptul de predicție
În terminal, din directorul proiectului:
python predict.py

5. Interpretarea rezultatelor
Scriptul va printa un array de probabilități pentru fiecare intrare din datele preprocesate.
Valorile aproape de 1 indică posibilă intruziune (sau comportament suspect), iar valorile aproape de 0 indică normal.

6. Verificări suplimentare
Dacă scriptul aruncă erori legate de dimensiuni, verifică să fie potrivită forma datelor de input cu așteptările modelului.
Dacă modelele lipsesc, rulează notebook-urile de training pentru Suricata și Falco:
notebooks/training_suricata.ipynb
notebooks/training_falco.ipynb