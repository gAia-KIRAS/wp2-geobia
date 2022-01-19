# gAia - Predicting landslides
*Entwicklung von Gefahrenhinweiskarten für Hangrutschungen aus konsolidierten Inventardaten*  
FFG-KIRAS Projekt

Meeting Konsortium - Bedarfsträger  
19.01.2022, 08:30–11:30

TeilnehmerInnen:
- ZAMG: Michael Avian, Melina Frießenbichler, Matthias Schlögl
- AIT: Martin Jung
- GeoVille: Michaela Seewald
- DCNA: Susanna Weinhart
- Universität Graz (Institut für Geographie und Raumforschung): Christian Bauer, Hannah Wies

---

## Masterarbeit Wies
- Untersuchungsgebiet: Möll- und Liesertal
- Basis: ALS-DGM von 2006-2011
- Höhengrenze: Isohypse 1800 m
- Ergebnis: 519 Rutschungspolygone, 444 Abrisskanten (Abrisskanten teilweise Subset der Rutschungen)
- Klassifikation nach der Robustheit der Detektierbarkeit (3 Klassen: eindeutig &rarr; wahrscheinlich &rarr; rutschungsähnliche Struktur)
- Klassifikation nach Fläche (seicht, mittelgründig, tiefgründig)
- Morphologische Evidenzen in der Kulturlandschaft (muldenförmige Vertiefungen im Ackerland)
- Information zur Landbedeckung (über Höhendifferenz DOM-DGM)
- Detektion von Sekundärprozessen
- Im ALS-Inventar ist (naturgemäß) kein Zeitstempel (Ereignisdatum) verfügbar; nur ein spätestmögliches Dateum des Ereigniseintritts
- Qualitätsanalyse DGM (Punkdichte; guter visueller Eindruck vs "verschwommene Bereiche") beeinflusst Robustheit der Detektierbarkeit von Rutschungen
- Qualität abhängig von der Persistenz der Rutschung

## Diskussion
- Ziele:
    1. Verbesserung Ereignisinventar
    2. Verbesserung der Gefahrenhinweiskarte:
        - Aktuell Bias in Richtung Überschätzung
        - Anmerkung MS: Das liegt sicher nicht nur an Datenlage, sondern wohl auch an der Methodik. Stichwort Limitierungen einfacher logistischer Regression (c.f. Berücksichtigung von Interaktionseffekten und Nichtlinearitäten). Aussagen zur Modellqualität sind - falls vorhanden - vermutlich nicht auf Basis einer sauberen räumlichen Kreuzvalidierung.
- Fokus: 
    - Hauptproblem sind kleine, seichte, abrupte Rutschungen
- Zielgebiet: 3 vorgeschlagene Projektgebiete Oberkärnten, Nockberge, Lavanttal &rarr; Klare Abgrenzung notwendig 
- Datenquellen Inventar:
    - KAGIS Ereigniskataster (basiert auf GEORIOS) &rarr; möglichst aktueller Auszug notwendig
    - räumliche Auflösung (speziell S-2)
    - Zeitliche Abdeckung: ALS < 2012; S-2 > 2015
    - Kompatibilität der Inventare: dürfte sehr, Komplementär sein, (spatial) joins aus jetziger Sicht wohl herausfordernd. 
- Im KAGIS-Inventar befinden sich fast ausschließlich schadenverursachende Rutschungen
- Prozesstypen: Fokus auf Rutschungen. Erdstrom zwar von der Frequenz her relevant, jedoch nicht Gegenstand des Projektes.
- Bereitstellung relevanter Layer seitens des Landes Kärnten
    - Geologische Karten: 1:50000; 1:25000
    - Hangwassersysteme
- *Unmittelbar nach dem Ereignis* aufgenommene Orthophotos / VHR Satellitendaten sind als gute Quellen
- Im Gelände sind große Rutschungen oft nicht unmittelbar erkennbar
