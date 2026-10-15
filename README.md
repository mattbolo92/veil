# VEIL — The Last Duel

> *"Small fighters. Impossible moves."*

**VEIL** è un picchiaduro arcade 2.5D incentrato su silhouette, riflessi fulminei e ritmo. L'arena è immersa nell'oscurità e i combattenti sono silhouette nere riconoscibili dalla posa, dallo scheletro e dall'energia luminosa (rim-light neon, scie cinetiche e particelle ad alto contrasto).

Progettato con fisica deterministica a 60 FPS, hit-stop marcati, cancellazioni fluide di combo e il sistema rallentatore *Shadow Reflex*.

---

## 📋 Prerequisiti

* **Engine:** [Godot Engine 4.3+](https://godotengine.org/download) (consigliato Godot 4.3 o successivo, compatibile con Godot 4.7).
* **Renderer:** `Mobile` (configurato con Glow/HDR a 60 FPS).
* **Piattaforme di destinazione:** Android, iOS, macOS, Windows, Linux.

---

## 🚀 Installazione

### 1. Scarica o installa Godot Engine

- **macOS:**
  ```bash
  # Tramite Homebrew:
  brew install --cask godot
  ```
  *Oppure scarica l'applicazione da [godotengine.org/download](https://godotengine.org/download) e trascinala in `/Applications`.*

- **Windows:**
  ```powershell
  # Tramite WinGet:
  winget install GodotEngine.Godot
  ```
  *Oppure scarica l'archivio ZIP standard da [godotengine.org/download](https://godotengine.org/download).*

- **Linux:**
  Scarica il binario o utilizza Flatpak:
  ```bash
  flatpak install flathub org.godotengine.Godot
  ```

### 2. Clona o apri la cartella del progetto

Se non lo hai già fatto, posizionati nella cartella del repository:
```bash
cd "VEIL - The last duel"
```

---

## ▶️ Come Avviare il Progetto

### Metodo 1: Tramite l'Editor di Godot (Consigliato)

1. Avvia **Godot Engine**.
2. Nella finestra del *Project Manager*, clicca su **Import** (o **Importa**).
3. Clicca su **Browse**, naviga fino alla cartella del progetto e seleziona il file `project.godot`.
4. Clicca su **Import & Edit** (Importa e modifica).
5. All'interno dell'editor, premi **F5** (o l'icona ▶️ **Play** in alto a destra) per avviare il gioco.
   * *La scena principale è preconfigurata su `res://scenes/main/main.tscn`.*

---

### Metodo 2: Da Riga di Comando (CLI)

Puoi avviare il gioco direttamente dal terminale senza aprire l'interfaccia dell'editor:

```bash
# Se godot è nel tuo PATH:
godot

# Oppure specificando la scena principale:
godot scenes/main/main.tscn

# Su macOS (se installato nell'app default):
/Applications/Godot.app/Contents/MacOS/Godot scenes/main/main.tscn
```

---

## 🎮 Controlli di Gioco

Il gioco è configurato per il Player 1 (VEIL - Ciano) via tastiera, mentre il Player 2 (SHADE - Arancio/Rosso) è gestito in automatico dall'intelligenza artificiale (`CPUController`).

| Azione | Tasto Tastiera (P1) | Note |
| :--- | :---: | :--- |
| **Movimento Sinistra** | <kbd>A</kbd> | Camminata / corsa a sinistra |
| **Movimento Destra** | <kbd>D</kbd> | Camminata / corsa a destra |
| **Salto** | <kbd>W</kbd> | Salto verticale |
| **Pugno (Punch)** | <kbd>J</kbd> | Attacco rapido, avvia combo di pugni |
| **Calcio (Kick)** | <kbd>K</kbd> | Attacco a medio raggio / combo finisher |
| **Schivata (Dodge)** | <kbd>L</kbd> | Rotolata con invincibilità (Shadow Roll) |
| **Super Art** | <kbd>;</kbd> *(punto e virgola)* | Mossa speciale consuma barra energia |

> **Nota su Touch / Mobile:** Sulle piattaforme touch sono presenti a schermo i controlli virtuali dedicati.

---

## 📱 Generazione APK per Android

Per compilare ed esportare il pacchetto Android (`.apk`) con Godot 4:

### 1. Prerequisiti Android
* **Java (OpenJDK 17):** necessario per firmare e compilare l'APK.
  Su macOS puoi installarlo via Homebrew:
  ```bash
  brew install openjdk@17
  sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
  ```
* **Android SDK:** assicurati di avere l'Android SDK installato (su macOS il percorso predefinito è `~/Library/Android/sdk`).
* **Debug Keystore:** generato automaticamente in `~/.android/debug.keystore` (o generabile con `keytool`).

### 2. Scaricare gli Export Templates in Godot
1. Apri Godot Engine con il progetto caricato.
2. Dal menu in alto: **Editor → Manage Export Templates...** (Gestisci i modelli di esportazione).
3. Clicca su **Download and Install** per scaricare i template corrispondenti alla versione di Godot in uso.

### 3. Configurare i Percorsi Android nell'Editor
1. Vai su **Editor → Editor Settings...** (Impostazioni dell'editor).
2. Nella colonna sinistra seleziona **Export → Android**.
3. Compila i campi:
   - **Android SDK Path:** percorso dell'SDK (es. `/Users/<utente>/Library/Android/sdk` su Mac).
   - **Debug Keystore:** percorso del keystore (es. `/Users/<utente>/.android/debug.keystore`).
   - **Debug Keystore User:** `androiddebugkey`
   - **Debug Keystore Password:** `android`
4. Clicca su **Close**.

### 4. Esportare l'APK
1. Vai su **Project → Export...** (Progetto → Esporta...).
2. Clicca su **Add...** e scegli **Android**.
3. Nelle opzioni del preset a destra:
   - Sotto **Package**: imposta un identificativo univoco in **Unique Name** (es. `com.matteo.veil` o `com.veil.thelastduel`).
   - Sotto **Architectures**: assicurati che sia spuntato **`arm64-v8a`** (standard per tutti i dispositivi moderni).
4. Clicca in basso su **Export Project...**.
5. Seleziona la cartella di output, assegna il nome al file (es. `VEIL.apk`) e clicca **Save** *(lascia spuntata l'opzione "Export With Debug" per le prove di sviluppo)*.

> 💡 **One-Click Deploy (Test Rapido su Dispositivo Fisico):**
> Se colleghi lo smartphone Android al computer via cavo USB con il **Debug USB** attivo nelle *Opzioni Sviluppatore* di Android, nell'angolo in alto a destra dell'editor apparirà l'icona con il logo Android: cliccandola, Godot compilerà, installerà e avvierà l'APK direttamente sul dispositivo in un solo clic!

---

## 🛠️ Script di Generazione Asset (`tools/`)

Il progetto include script `@tool` (`EditorScript`) per rigenerare proceduralmente risorse, scene e materiali:

* `tools/generate_data.gd`: genera i file risorsa `.tres` per mosse e statistiche (`data/moves/` e `data/fighters/`).
* `tools/generate_arena.gd`: genera proceduralmente l'arena, luci, specchiature e shader.
* `tools/generate_fighter.gd`: crea la scena base del combattente con skeleton, collider e aree di colpo.

### Come eseguirli nell'Editor di Godot:
1. Nell'editor di Godot, apri il pannello **FileSystem** (in basso a sinistra).
2. Fai doppio clic su uno degli script in `res://tools/` per aprirlo nell'editor di script.
3. Seleziona dal menu in alto: **File → Run** (Scorciatoia: <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>X</kbd> su Mac, <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>X</kbd> su Windows/Linux).

---

## 📁 Struttura del Progetto

```text
VEIL - The last duel/
├── project.godot          # File di configurazione del motore Godot 4
├── ARCHITECTURE.md        # Specifiche tecniche, regole AI e combat design
├── README.md              # Istruzioni d'uso e avvio del progetto
├── .gitignore             # Esclusioni per Git (.godot/, cache, OS files)
│
├── scenes/                # Scene (.tscn)
│   ├── main/              # Scena principale (main.tscn e main.gd)
│   ├── arena/             # Scene arena e ambiente
│   ├── effects/           # Effetti particellari e VFX
│   └── ui/                # HUD, barre vita, super meter
│
├── scripts/               # Logica in GDScript
│   ├── combat/            # Combat engine a frame deterministici
│   ├── fighters/          # Controller combattente, animazioni e CPU AI
│   ├── resources/         # Definizioni MoveData e FighterStats
│   └── systems/           # MatchManager, AudioSynthesizer, Camera2.5D
│
├── data/                  # Risorse data-driven (.tres)
│   ├── fighters/          # Profili personaggi
│   └── moves/             # Definizioni mosse e catene di combo
│
├── assets/                # Risorse grafiche, shader e audio
│   └── shaders/           # Shader di silhouette neon e stage
│
└── tools/                 # Script @tool di automazione e generazione
```

---

## 📖 Approfondimenti

Per tutti i dettagli tecnici su:
* Determinismo basato su tick a 60 Hz e Local Time Scale
* Combo tree e cancellazioni delle mosse
* Meccaniche di *Hit-Stop*, *Shadow Reflex* e *Wall Bounce*
* Regole di strict typing in GDScript 2.0

Consulta il documento completo [ARCHITECTURE.md](ARCHITECTURE.md).
