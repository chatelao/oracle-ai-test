# Roadmap - LLM und Oracle DB SQLcl Integration

Dieses Projekt zielt darauf ab, das Zusammenspiel zwischen einem lokalen Large Language Model (LLM) und einer Oracle Datenbank über `sqlcl` zu testen und zu automatisieren.

## Meilensteine

### 1. Umgebungsvorbereitung (Environment Setup)
- [ ] Auswahl und Setup des lokalen LLM (z.B. Ollama, LocalAI).
- [ ] Bereitstellung einer Oracle Datenbank (lokal oder Docker-basiert).
- [ ] Installation und Konfiguration von Oracle SQLcl.

### 2. Installationsskripte (/install)
- [ ] Skript zur Installation des LLM.
- [ ] Skript zur Konfiguration der Datenbankverbindung.
- [ ] Skript zur Einrichtung von SQLcl.

### 3. Testskript-Entwicklung (test.sh)
- [ ] Entwicklung eines Basistests zur Kommunikation mit dem LLM.
- [ ] Entwicklung eines Basistests zur Ausführung von SQL-Befehlen via SQLcl.
- [ ] Integration: LLM generiert SQL, SQLcl führt es aus, Ergebnisse werden validiert.

### 4. CI/CD Integration
- [ ] Erstellung eines GitHub Action Workflows.
- [ ] Automatisierte Testläufe bei jedem Push.
- [ ] Berichterstattung über Testergebnisse.

## Fortschrittsbewertung
Der Fortschritt wird durch das Bestehen des `test.sh` Skripts in der CI/CD-Pipeline gemessen.
