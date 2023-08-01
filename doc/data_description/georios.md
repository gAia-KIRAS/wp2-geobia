# GEORIOS

Beschreibung des GEORIOS-Exports `GEORIOS_for_gAia.gdb.zip` vom 2023-08-01

| Spaltenname | Beschreibung                                                                                                                                                         |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GR_NR       | GEORIOS_Nummer (eindeutig)                                                                                                                                            |
| URSPR_NR    | Ursprünglich vom Kartierer/Digitalisierer vergebene Nummer der Massenbewegung                                                                                         |
| Code        | Vereinheitlichte Prozessansprache auf höchster/2 höchster Hierarchieebene                                                                                             |
| DATENQUELL  | primäre Datenquelle: Jene Quelle, die erstmals die Massenbewegung als solche identifiziert hat                                                                        |
| DATQUEL_TX  | Nähere Präzisierung der Datenquelle                                                                                                                                   |
| QUAL_LAGE   | Bewertungskriterium: Beurteilung der Lagegenauigkeit (zu erkennbaren Objekten wie Haus, Straßenseite, Flussufer, ...)                                                 |
| EREIGNI_TX  | Textliche Beschreibung/Ergänzungen zum Ereigniszeitpunkt                                                                                                              |
| Date_Anfan  | Beginn der Zeitangabe, in welcher das Massenbewegungsereignis stattgefunden haben kann (in Ortszeit - MEZ)                                                            |
| Date_End_a  | Ende der Zeitangabe, in welcher das Massenbewegungsereignis stattgefunden haben kann (in Ortszeit - MEZ)                                                              |
| Zeitspanne  | Gesamte Länge der Zeitspanne, in welcher das Massenbewegungsereignis stattgefunden haben kann (Differenz Date_End_a – Date_Anfan)(-> ist nicht der Bewegungszeitraum) |
| EREIGNIS_d  | Datum des Prozesses in Ortszeit (MEZ). Wird nur ausgefüllt, wenn J, M, T bekannt ist! Wird auch bei 2 aufeinanderfolgender Tagen angegeben (dann Datum des 2.Tages)   |
| EREIGNIS_J  | Jahr des Prozesses (bei eindeutigem Kalenderjahr; auch bei Jahreswechsel von 2 Tagen Zeitspanne (dann Eingabe 2. Jahr))                                               |
| EREIGNIS_M  | Monat des Prozesses (bei eindeutigem Kalendermonat; auch bei Monatswechsel von 2 Tagen Zeitspanne (dann Eingabe 2. Monat))                                            |
| EREIGNIS_T  | Tag des Prozesses in Ortszeit (MEZ). (bei eindeutigem Datum; auch bei Datumswechsel von 2 Tagen Zeitspanne (dann Eingabe 2. Datum))                                   |
| EREIGNI_ST  | Stunde des Prozesses in Ortszeit (MEZ). (bei eindeutiger Stunde)                                                                                                      |
| EREIGNI_MI  | Minute des Prozesses in Ortszeit (MEZ). (bei eindeutiger Minute)                                                                                                      |
