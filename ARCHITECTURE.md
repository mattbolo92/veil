# VEIL — Technical Architecture & AI Context (`ARCHITECTURE.md`)

> **ISTRUZIONI PER L'AI ASSISTENTE:**
> Questo documento definisce l'architettura, le regole di codice e le specifiche di gameplay di **VEIL**. Ogni singolo script GDScript, shader o generatore di scene (`@tool`) prodotto DEVE rispettare rigorosamente i vincoli descritti in questo file. Non deviare da queste specifiche senza esplicita richiesta.

---

## 1. Visione del Progetto e Pilastri di Design

* **Titolo del gioco:** VEIL
* **Tagline:** Small fighters. Impossible moves.
* **Genere:** Picchiaduro 2.5D arcade basato su silhouette, riflessi e ritmo.
* **Target Platform:** Android & iOS (Orientamento **Landscape 16:9 / 20:9**, 60 FPS fissi).
* **Direzione Artistica:** Arena immersa nell'oscurità. I combattenti sono silhouette nere pure (3D) riconoscibili dalla postura, dal rig scheletrico e dal colore dell'energia che sprigionano (Rim-Light shader, scie luminose sugli arti, particelle ad alto contrasto e bloom).
* **I 3 Pilastri:**
  1. **Semplice da giocare:** Controlli touch intuitivi a 2 pulsanti d'attacco, nessuna combinazione complessa direzionale stile fighting game tradizionale.
  2. **Spettacolare da guardare:** Hit-stop marcati, scie fluide, rallentamenti (Shadow Reflex) e telecamera dinamica coordinata.
  3. **Data-Driven & Modulare:** I combattenti e le mosse sono definiti tramite risorse Godot (`.tres`). Il codice del combat system non deve mai contenere logiche hardcodate per un singolo personaggio.

---

## 2. Stack Tecnologico e Configurazione Motore

* **Engine:** Godot 4.3+
* **Renderer:** `Mobile` (supporta HDR/Glow per gli effetti neon garantendo 60 FPS su dispositivi mobile).
* **Risoluzione di Riferimento:** 1920x1080 | Stretch Mode: `canvas_items` | Aspect: `expand`.
* **Physics Tick Rate:** 60 Hz fissi (`physics/common/physics_ticks_per_second = 60`).
* **Linguaggio:** GDScript 2.0 (Strict Typing obbligatorio).

---

## 3. Regole di Sviluppo per l'AI (Coding Guidelines)

1. **Tipizzazione Statica Obbligatoria (Strict Typing):**
   Ogni variabile, parametro di funzione, array e valore di ritorno deve essere esplicitamente tipizzato.
   * *Valido:* `var current_frame: int = 0`, `func can_cancel(move: MoveData) -> bool:`
   * *Non valido:* `var current_frame = 0`, `func can_cancel(move):`

2. **Determinismo basato sui Frame e Local Time Scale (NO Timer / NO Await nel Combat System):**
   La durata delle mosse, le finestre di combo, l'hit-stop e l'invincibilità della schivata si misurano in frame fisici dentro `_physics_process(delta: float) -> void`.
   * È vietato usare nodi `Timer` o `await get_tree().create_timer()` per gestire finestre di attacco, recupero o congelamento dei colpi.
   * Per supportare il rallentatore locale (*Shadow Reflex* a `0.2x`) mantenendo i dati delle mosse in `int`, ogni combattente usa `local_time_scale: float = 1.0` e un accumulatore `frame_accumulator: float = 0.0`. Ad ogni tick fisico (se `hit_stop_frames == 0`), `frame_accumulator += local_time_scale`. Quando `frame_accumulator >= 1.0`, si sottrae `1.0` e si incrementa `state_frame: int += 1`.

3. **Generazione Automatica via `@tool` (`EditorScript` / Headless):**
   Le scene (`.tscn`), i materiali shader e le risorse (`.tres`) di base vengono generati programmaticamente tramite script nella cartella `res://tools/`.
   * Ogni script generatore deve impostare `node.owner = root_node` sui nodi creati prima di salvare con `PackedScene.pack(root_node)`.
   * **Regola Sottoscene:** Non modificare mai ricorsivamente la proprietà `owner` dei nodi figli interni appartenenti a una `PackedScene` istanziata (es. `Fighter.tscn` istanziato dentro `Arena.tscn`), altrimenti Godot romperà l'incapsulamento della sottoscena.
   * **Prevenzione Memory Leak:** Al termine del salvataggio su disco con `ResourceSaver.save()`, chiamare sempre `root_node.free()` per evitare nodi orfani in RAM nell'editor.

4. **Disaccoppiamento (Segnali e `@export`):**
   I nodi figli non devono mai chiamare metodi diretti sui genitori tramite `get_parent().metodo()`. Usare `signal` verso l'alto e riferimenti `@export` verso il basso.

5. **Vincolo 2.5D (Axis Lock):**
   Il gioco usa `CharacterBody3D`, ma il movimento avviene esclusivamente sugli assi X (orizzontale) e Y (verticale). L'asse Z deve rimanere sempre bloccato a `0.0` (`axis_lock_linear_z = true`, `global_position.z = 0.0`).

6. **Sintassi GDScript 2.0 Obbligatoria (Prevenzione Errori di Compilazione):**
   * **Vietato `:=` su `Variant`:** Non usare mai l'inferenza `:=` con funzioni che restituiscono `Variant` (`max()`, `min()`, `clamp()`, `ResourceLoader.load()`, accesso a dizionari o array non tipizzati). Usare sempre il tipo esplicito (es. `var x: float = maxf(a, b)` o `var move: MoveData = load(path) as MoveData`).
   * **Cicli tipizzati:** Usare sempre la sintassi tipizzata nei loop, es. `for child: Node in get_children():`.
   * **API `CharacterBody3D`:** Assegnare il vettore a `velocity` e chiamare `move_and_slide()` senza argomenti.
   * **Collisioni Deterministiche (No `set_deferred`):** Non attivare/disattivare mai `CollisionShape3D.disabled` dentro callback di segnali fisici. Le `Area3D` di HitBox e HurtBox restano sempre abilitate (`monitoring = true`, `monitorable = true`); l'attivazione della HitBox è controllata da un flag logico `is_hitbox_active: bool` letto in `_physics_process` interrogando `hitbox_area.get_overlapping_areas()`.

---

## 4. Struttura delle Cartelle del Repository

```text
veil/
├── ARCHITECTURE.md
├── project.godot
├── tools/                  # Script @tool / EditorScript per generare scene e risorse via codice
├── scenes/
│   ├── main/               # Main loop, scene loader
│   ├── arena/              # Scena 3D dell'arena, luci, WorldEnvironment, Camera25D
│   ├── fighters/           # Template base Fighter.tscn
│   ├── ui/                 # HUD touch, barre vita/energia, pulsanti
│   └── effects/            # Scie ribbon, particelle impatto, flash
├── scripts/
│   ├── resources/          # Definizioni class_name per le risorse dati
│   ├── combat/             # State machine, input buffer, hitbox, hurtbox, hit-stop
│   ├── fighters/           # Controller lottatore, logica CPU AI
│   └── systems/            # Telecamera dinamica, match manager
├── data/
│   ├── fighters/           # Risorse .tres dei singoli personaggi
│   └── moves/              # Risorse .tres delle singole mosse e alberi combo
└── assets/
    ├── models/             # Mesh 3D dei manichini e accessori
    ├── animations/         # Librerie di animazioni scheletriche .res
    ├── shaders/            # Shader spatial silhouette e rim light
    ├── audio/              # Effetti sonori e randomizer pitch
    └── vfx/                # Texture e rampe di colore per particelle
```

---

## 5. Architettura Dati (Custom Resources)

### 5.1 MoveData (`res://scripts/resources/move_data.gd`)
Rappresenta un singolo attacco, la sua geometria di collisione e i suoi collegamenti nell'albero delle combo a 2 pulsanti:

```gdscript
class_name MoveData extends Resource

# Identità
@export var move_name: StringName = &"unnamed_move"
@export var animation_name: StringName = &"idle"

# Frame Data (60 FPS)
@export var startup_frames: int = 6         # Frame prima dell'attivazione HitBox
@export var active_frames: int = 4          # Durata in frame dell'attività HitBox
@export var recovery_frames: int = 12       # Frame di recupero post-attacco
@export var cancel_window_start: int = 8    # Frame assoluto dall'inizio in cui si sblocca la cancellazione/combo

# Dati Spaziali HitBox
@export var hitbox_size: Vector3 = Vector3(0.8, 0.5, 0.5)    # Dimensioni del BoxShape3D
@export var hitbox_offset: Vector3 = Vector3(0.9, 1.1, 0.0)  # Offset locale (X moltiplicato per facing_direction)

# Danno, Fisica e Juggle
@export var damage: int = 50
@export var hit_stun_frames: int = 16
@export var hit_stop_frames: int = 6
@export var knockback_vector: Vector2 = Vector2(2.5, 0.0)    # X: spinta orizzontale, Y: launcher verticale
@export var forward_impulse: float = 1.5                    # Spinta applicata durante lo startup
@export var juggle_cost: int = 1                            # Incremento del juggle counter
@export var energy_gain_on_hit: float = 15.0
@export var energy_gain_on_whiff: float = 3.0

# Albero Combo
@export var next_on_punch: MoveData                         # Mossa su Pugno nella cancel window
@export var next_on_kick: MoveData                          # Mossa su Calcio nella cancel window
@export var allow_cancel_on_whiff: bool = false             # Se false, cancella solo a segno (has_hit_target == true)
```

**Convenzione di conteggio Frame:**
Il contatore `state_frame` parte da `1` all'inizio dello stato `ATTACK` fino a `total_frames = startup_frames + active_frames + recovery_frames`.
* **Startup:** `state_frame <= startup_frames`
* **Active (HitBox attiva):** `state_frame > startup_frames` e `state_frame <= startup_frames + active_frames`
* **Recovery:** `state_frame > startup_frames + active_frames`
* **Cancel Window:** attiva quando `state_frame >= cancel_window_start`. Ogni singola attivazione di mossa può colpire il bersaglio al massimo una sola volta (`has_hit_target: bool`).

---

### 5.2 FighterStats (`res://scripts/resources/fighter_stats.gd`)
Definisce le caratteristiche e il set iniziale di mosse del combattente:

```gdscript
class_name FighterStats extends Resource

# Generale
@export var fighter_id: StringName = &"veil"
@export var display_name: String = "VEIL"
@export var max_health: int = 1000
@export var max_energy: float = 100.0

# Movimento
@export var move_speed_forward: float = 6.0
@export var move_speed_backward: float = 4.2
@export var jump_velocity: float = 13.0
@export var gravity_scale: float = 2.5

# Schivata
@export var dodge_duration_frames: int = 18
@export var dodge_invincible_frames: int = 10
@export var perfect_dodge_window_frames: int = 4
@export var dodge_speed: float = 10.0

# Knockdown, Wakeup & Juggle
@export var knockdown_duration_frames: int = 30     # Permanenza a terra prima di rialzarsi
@export var wakeup_invincible_frames: int = 12       # Invincibilità al ritorno in IDLE per prevenire loop
@export var max_juggle_hits: int = 4                # Massimo colpi in LAUNCHED prima di diventare invulnerabile

# Stile Visivo
@export var energy_color: Color = Color(0.0, 0.85, 1.0, 1.0)
@export var rim_intensity: float = 3.5              # Moltiplicatore HDR per effetto Glow

# Moveset Base
@export var opener_punch: MoveData
@export var opener_kick: MoveData
@export var air_punch: MoveData
@export var air_kick: MoveData
@export var cinematic_super: MoveData
```

---

## 6. Meccaniche Core e Regole di Gameplay

### 6.1 Posizionamento, Confini Arena e Blocco del Lato Simmetrico (No Side-Switch)
* **Player 1** (`is_player_one = true`): Inizia e rimane sempre a Sinistra (`facing_direction = +1.0`, rivolto verso `+X`).
* **Player 2 / CPU** (`is_player_one = false`): Inizia e rimane sempre a Destra (`facing_direction = -1.0`, rivolto verso `-X`).
* I combattenti non possono mai scavalcarsi, superarsi o invertire l'orientamento, nemmeno durante salti o attacchi in corsa.

**Risoluzione Matematico-Simmetrica (`MatchManager` / `Arena`):**  
Dopo l'esecuzione di `move_and_slide()` di entrambi i combattenti, la separazione orizzontale (`MIN_FIGHTER_DISTANCE: float = 1.1`) e i confini dell'arena (`ARENA_BOUNDS_X: float = 8.0`) vengono risolti simmetricamente:

```gdscript
if p2.global_position.x - p1.global_position.x < MIN_FIGHTER_DISTANCE:
    var mid_x: float = (p1.global_position.x + p2.global_position.x) * 0.5
    p1.global_position.x = mid_x - (MIN_FIGHTER_DISTANCE * 0.5)
    p2.global_position.x = mid_x + (MIN_FIGHTER_DISTANCE * 0.5)

# Clamp ai muri dell'arena preservando la distanza minima:
p1.global_position.x = clampf(p1.global_position.x, -ARENA_BOUNDS_X, ARENA_BOUNDS_X - MIN_FIGHTER_DISTANCE)
p2.global_position.x = clampf(p2.global_position.x, p1.global_position.x + MIN_FIGHTER_DISTANCE, ARENA_BOUNDS_X)
```

---

### 6.2 Controlli Touch (Landscape)
* **Zona Sinistra (Movimento):** Pad direzionale orizzontale (`move_left`, `move_right`) + Salto (`jump`).
* **Zona Destra (4 Pulsanti Azione):**
  * `attack_punch`: Pugno veloce, corto raggio.
  * `attack_kick`: Calcio pesante, allungo, attacco launcher.
  * `dodge`: Schivata con finestra di invincibilità.
  * `super_art`: Mossa speciale cinematografica (disponibile solo quando `current_energy >= max_energy`).

---

### 6.3 Input Buffer
Ogni combattente include un modulo `InputBuffer` che registra gli input d'azione (`attack_punch`, `attack_kick`, `dodge`, `super_art`, `jump`) premuti negli ultimi 10 frame fisici (~166ms). Quando il lottatore entra nella finestra di cancel o torna in stato `IDLE`/`MOVE`, il comando più recente valido viene consumato immediatamente e il buffer viene svuotato.

---

### 6.4 Sistema di Difesa: Shadow Dodge e Shadow Reflex
Non esiste la parata. La fase difensiva si basa unicamente su posizionamento e schivata (`State.DODGE`, disponibile solo a terra):

* **Direzione della Schivata:**  
  Se il giocatore preme la direzione opposta al nemico esegue un *Backdash* (`-facing_direction * dodge_speed`); altrimenti esegue uno *Shadow Step* sul posto o in avanti con attrito progressivo.

* **Gestione Frame-Perfect nella HurtBox (Nessun nodo extra richiesto):**  
  Quando una HitBox nemica attiva interseca la `HurtBox3D` del difensore, viene invocato `defender.receive_attack(move: MoveData, attacker: FighterController)`:
  * **Shadow Reflex (Frame 1 .. `perfect_dodge_window_frames`, default 1..4):**
    * Il colpo viene annullato (0 danni) e consumato sull'attaccante (`has_hit_target = true`).
    * L'attaccante subisce `local_time_scale = 0.2` per 36 frame fisici reali.
    * Il difensore guadagna `+25.0` di energia, emette un flash visivo ciano/bianco e azzera il recupero tornando immediatamente in `IDLE` a velocità `1.0x`, pronto alla punizione.
  * **Schivata Ordinaria (Frame 5 .. `dodge_invincible_frames`, default 5..10):**
    * Il colpo attraversa l'ombra senza effetto (0 danni, nessun rallentatore).
  * **Recovery Vulnerabile (Frame 11 .. `dodge_duration_frames`, default 11..18):**
    * Il difensore viene colpito normalmente (*Counter Hit*).

---

### 6.5 Macchina a Stati del Combattente (FSM) e Regole Juggle
Gli stati validi (`enum State`) per un lottatore sono:

* `IDLE`: Stazionario a terra, pronto a qualsiasi azione.
* `MOVE`: Spostamento a terra in avanzamento (`move_speed_forward`) o arretramento (`move_speed_backward`).
* `AIR`: Fase di volo da salto volontario (può eseguire `air_punch` o `air_kick`).
* `ATTACK`: Esecuzione di una mossa attiva; riceve `energy_gain_on_whiff` allo sblocco degli `active_frames`.
* `DODGE`: Movimento di schivata difensiva a terra.
* `HIT_STUN`: Blocco da colpo subito a terra con knockback orizzontale; dura `move.hit_stun_frames`.
* `LAUNCHED`: Stato di volo subito da un colpo con `knockback_vector.y > 0.0` o da un colpo subito mentre già in aria (sistema Juggle attivo).
* `KNOCKDOWN`: Tocca terra dopo `LAUNCHED`. Rimane a terra invulnerabile per `stats.knockdown_duration_frames`, poi passa a `IDLE` resettando `juggle_counter = 0` e attivando `wakeup_invincible_timer = stats.wakeup_invincible_frames`.
* `CINEMATIC_SUPER`: Esecuzione mossa speciale non interrompibile (consuma il 100% di energia).

**Protezione Infinite Juggle:**  
Ad ogni colpo subito in `LAUNCHED`, `juggle_counter += move.juggle_cost` e la gravità di caduta aumenta del 15% per ogni punto di `juggle_counter`. Se `juggle_counter >= stats.max_juggle_hits`, il combattente diventa invulnerabile ad ulteriori attacchi finché non tocca il pavimento.

---

## 7. Collision Layers & Masks (Fisica 3D)

Entrambi i lottatori istanziano la medesima scena `Fighter.tscn`. La proprietà `@export var is_player_one: bool = true` configura dinamicamente nel metodo `_ready()` i layer e le maschere delle `Area3D`:

| Layer | Nome | Descrizione e Configurazione |
|---|---|---|
| **Layer 1** | `Environment` | `StaticBody3D` del pavimento e barriere dell'arena. |
| **Layer 2** | `FighterBody` | `CharacterBody3D` dei lottatori. `collision_layer = Layer 2`, `collision_mask = Layer 1` (non collidono fisicamente tra loro per evitare stacking verticale; la repulsione orizzontale è gestita matematicamente). |
| **Layer 3** | `HitBox_P1` | `Area3D` d'attacco Player 1. `collision_mask = Layer 4`. |
| **Layer 4** | `HurtBox_P2` | `Area3D` vulnerabile Player 2. `collision_mask = 0` (passiva, rilevata da `HitBox_P1`). |
| **Layer 5** | `HitBox_P2` | `Area3D` d'attacco Player 2. `collision_mask = Layer 6`. |
| **Layer 6** | `HurtBox_P1` | `Area3D` vulnerabile Player 1. `collision_mask = 0` (passiva, rilevata da `HitBox_P2`). |

---

## 8. Rendering, Effetti Visivi e Game Feel

### 8.1 Local Hit-Stop
All'impatto di un colpo non si modifica mai `Engine.time_scale`. Viene impostato `hit_stop_frames = move.hit_stop_frames` su entrambi i lottatori:
* Finché `hit_stop_frames > 0`, viene decrementato di 1 ad ogni `_physics_process`.
* L'`AnimationPlayer` del lottatore viene messo in pausa (`speed_scale = 0.0`).
* La logica della FSM e la fisica del lottatore non avanzano.
* Il nodo visuale (`VisualRoot: Node3D`) di chi subisce il colpo applica uno shake locale sull'asse X (`randf_range(-0.06, 0.06)`), azzerato al termine dell'hit-stop.
* Particelle, telecamera e HUD continuano a girare a 60 FPS.

---

### 8.2 Shader Silhouette e Rim-Light (`res://assets/shaders/fighter_silhouette.gdshader`)
Ogni combattente utilizza uno `ShaderMaterial` con `resource_local_to_scene = true` (per permettere colori indipendenti tra P1 e P2 e flash di stato senza conflitti):

```glsl
shader_type spatial;
render_mode unshaded, cull_back;

// Colore base del corpo: nero profondo
const vec3 BASE_COLOR = vec3(0.02, 0.02, 0.03);

uniform vec4 rim_color : source_color = vec4(0.0, 0.85, 1.0, 1.0);
uniform float rim_intensity : hint_range(0.0, 10.0) = 3.5;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0; // Per impatti o Shadow Reflex

void fragment() {
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
    vec3 rim = rim_color.rgb * rim_intensity * fresnel;
    vec3 col = mix(BASE_COLOR + rim, vec3(1.0), flash_amount);
    ALBEDO = col;
}
```

Il calcolo Fresnel perimetrale moltiplicato per `rim_color.rgb * rim_intensity` innesca l'effetto Glow/Bloom nel `WorldEnvironment`.

---

### 8.3 Telecamera Dinamica 2.5D (`Camera25D`)
* **Posizionamento X:** Centrato sul punto medio tra i due lottatori con interpolazione fluida (`lerpf`).
* **Posizionamento Z:** Calcolato dinamicamente in base alla distanza `absf(p2.x - p1.x)` entro un range `[min_distance_z, max_distance_z]`.
* **Screen Shake:** Basato su `trauma: float` (`0.0 .. 1.0`) che decade linearmente nel tempo e applica un offset `trauma * trauma` sugli assi X/Y della camera.

---

## 9. Roadmap di Sviluppo Incrementale

* **Fase 1 — Progetto, Arena e Silhouette:**  
  Setup `project.godot`, shader silhouette, e script generatore `@tool` per la scena arena, luci, `WorldEnvironment`, `Camera25D` e manichini 3D procedurali.

* **Fase 2 — Movimento, Fisica 2.5D e No Side-Switch:**  
  Implementazione `FighterStats`, `MoveData`, `FighterController`, movimento, salto, vincolo simmetrico di posizione laterale, HUD salute/energia e attacchi base (Pugno/Calcio) con collisioni deterministiche.

* **Fase 3 — Game Feel e Meccaniche Difensive:**  
  Implementazione dell'Hit-Stop locale, scie luminose sugli arti, particelle d'impatto e sistema Shadow Dodge con Shadow Reflex (`local_time_scale = 0.2`).

* **Fase 4 — Albero Combo, Juggle e Cinematic Super:**  
  Concatenazione mosse via `InputBuffer`, gestione stato `LAUNCHED` con limite Juggle, `KNOCKDOWN` con wakeup invulnerabile e mossa speciale `CINEMATIC_SUPER`.

* **Fase 5 — CPU AI e Struttura Incontro:**  
  Comportamento autonomo dell'avversario tramite FSM dedicata (`CPUController`), round timer, gestione KO e condizioni di vittoria/sconfitta.

* **Fase 6 — Mobile Build & Rifinitura:**  
  Ottimizzazione controlli touch a schermo, feedback visivo dei pulsanti, verifica 60 FPS stabili e profilazione per Android e iOS.