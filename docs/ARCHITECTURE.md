# ÉTAT DES LIEUX — Architecture technique

> Propriétaire : agent Architecte. **Ce document est un contrat.** Si tu as besoin de le modifier, tu fais une demande dans TASKS.md, tu ne modifies pas directement.

## 1. Stack

- **Godot 4.4+** (vérifier la version exacte dans `project.godot` → `config/features`). Renderer **Forward+**.
- **GDScript uniquement** (pas de C#) — typage statique obligatoire (`var x: int`, `func f() -> void`).
- Tests : **gdUnit4** (addon, dossier `addons/gdUnit4/`, installé par l'agent QA).
- Versionnage : Git. Une branche par agent (`agent/gameplay`, `agent/ui`...), merge sur `main` par l'agent QA/Intégrateur uniquement.

## 2. Arborescence et propriétaires

```
game/
├── project.godot
├── autoloads/                    [Systèmes]
│   ├── event_bus.gd              signaux globaux — LE contrat central
│   ├── game_state.gd             état de partie (acte, flags, attention)
│   ├── inventory_manager.gd      la liste des 212 objets, cochage, progression
│   ├── house_director.gd         règles « la maison se souvient »
│   ├── document_library.gd       accès aux documents lus / lisibles
│   ├── audio_manager.gd          [Audio] bus, soundscape, one-shots
│   └── save_manager.gd           sauvegarde / chargement JSON
├── scenes/
│   ├── main/                     [Systèmes] main.tscn : charge la maison, le joueur, l'UI
│   ├── player/                   [Gameplay] contrôleur FPS, caméra photo, interaction
│   ├── house/                    [Niveau] house.tscn + rooms/<room_id>.tscn
│   ├── items/                    [Niveau+Gameplay] item.tscn (générique), prefabs
│   ├── ui/                       [UI] carnet, HUD, menus, photo, options
│   └── fx/                       [Gameplay/Niveau] flash, grain, post-process
├── scripts/                      [Architecte] classes partagées (Resource/RefCounted)
│   ├── item_data.gd              class_name ItemData
│   ├── photo_data.gd             class_name PhotoData
│   ├── document_data.gd          class_name DocumentData
│   └── house_rule.gd             class_name HouseRule
├── data/                         [Narration]
│   ├── items/<item_id>.tres      212 ItemData
│   ├── documents/<doc_id>.tres   DocumentData
│   ├── rules/*.tres              HouseRule
│   └── strings/fr.csv            toutes les chaînes affichées (clé;texte)
├── assets/                       [Niveau / Audio / UI selon type]
│   ├── models/ textures/ audio/ fonts/
│   └── CREDITS.md                OBLIGATOIRE : source + licence de chaque asset
├── tests/                        [QA] un dossier par module, miroir de scenes/
└── tools/                        [QA] validate_data.gd, export.sh
```

## 3. Conventions

- Fichiers et dossiers : `snake_case`. Classes : `PascalCase`. Signaux : `snake_case` au passé (`item_checked`). Constantes : `UPPER_SNAKE`.
- Identifiants de contenu (`item_id`, `room_id`, `doc_id`) : `snake_case` ASCII, préfixés par la pièce : `kitchen_clock_stopped`, `study_inventory_1973`. Pièces : `exterior, hall, kitchen, dining, living, study, stairs, bedroom_m, bedroom_child, bathroom, laundry, attic, cellar`.
- **Aucune chaîne affichée en dur dans le code** : tout passe par `tr("KEY")` et `data/strings/fr.csv`.
- **Aucun `get_node("../../..")`** entre modules. Communication inter-modules = **signaux EventBus** ou API des autoloads. Point.
- Chaque scène est testable seule (`F6`) : pas de dépendance implicite sur une scène parente.
- Commentaires et docstrings en français, code en anglais.

## 4. Contrat central : EventBus

Tous les signaux globaux. Émetteur indiqué → tout le monde peut écouter.

```gdscript
# autoloads/event_bus.gd
extends Node

# --- Joueur / Caméra (émis par Gameplay) ---
signal photo_taken(photo: PhotoData)                 # au déclenchement (avant développement)
signal photo_developed(photo: PhotoData)             # 10 s après, contenu final connu
signal flash_fired(world_position: Vector3, room_id: StringName)
signal player_entered_room(room_id: StringName)
signal player_left_room(room_id: StringName)
signal player_interacted(target_id: StringName, kind: StringName)   # kind: "open","pickup","read","use"
signal player_caught()                               # la Présence a touché le joueur
signal player_noise(level: float, world_position: Vector3)          # course, porte claquée… 0..1

# --- Inventaire (émis par Systèmes/InventoryManager) ---
signal item_checked(item_id: StringName, photo: PhotoData)
signal item_revealed(item_id: StringName)            # un objet fantôme devient présent
signal inventory_progress(checked: int, total: int)
signal inventory_line_added(line_index: int, text_key: StringName)  # ex : « 213. Camille »

# --- Maison (émis par HouseDirector) ---
signal house_attention_changed(value: float)         # 0..100
signal item_moved(item_id: StringName, from_room: StringName, to_room: StringName, new_anchor: StringName)
signal house_event_triggered(event_id: StringName)   # ex : "act1_drawer_opens"
signal presence_state_changed(state: StringName)     # "dormant","photo_only","offscreen","physical","frozen"
signal act_changed(act: int)

# --- Narration / Documents ---
signal document_found(doc_id: StringName)
signal document_read(doc_id: StringName)
signal ending_reached(ending_id: StringName)         # "closed","ashes","keeper","four"

# --- UI (émis par UI) ---
signal notebook_opened()
signal notebook_closed()
signal pause_toggled(paused: bool)
signal subtitle_requested(text_key: StringName, duration: float)

# --- Sauvegarde ---
signal save_requested()
signal game_loaded()
```

## 5. API des autoloads (ce que les autres modules peuvent appeler)

### GameState
```gdscript
var current_act: int                       # 1..3
var attention: float                       # 0..100 (lecture seule hors HouseDirector)
func get_flag(key: StringName) -> bool
func set_flag(key: StringName, value: bool = true) -> void
func get_counter(key: StringName) -> int
func add_counter(key: StringName, delta: int = 1) -> void
func current_room() -> StringName
```

### InventoryManager
```gdscript
func get_item(item_id: StringName) -> ItemData
func get_items_in_room(room_id: StringName) -> Array[ItemData]
func is_checked(item_id: StringName) -> bool
func check_item(item_id: StringName, photo: PhotoData) -> bool   # false si déjà coché / non visible
func is_present(item_id: StringName) -> bool                     # fantôme révélé ou objet réel
func reveal_item(item_id: StringName) -> void
func progress() -> Vector2i                                      # (cochés, total)
func film_count() -> int
func add_film(count: int) -> void
func consume_film() -> bool                                      # false si vide
```

### HouseDirector
```gdscript
func register_rule(rule: HouseRule) -> void
func request_event(event_id: StringName) -> void      # pour scripting narratif ponctuel
func set_presence_state(state: StringName) -> void
func add_attention(delta: float, reason: StringName) -> void
```

### DocumentLibrary
```gdscript
func get_document(doc_id: StringName) -> DocumentData
func mark_found(doc_id: StringName) -> void
func mark_read(doc_id: StringName) -> void
func found_documents() -> Array[DocumentData]
```

### AudioManager
```gdscript
func play_sfx(sfx_id: StringName, position: Vector3 = Vector3.INF, volume_db: float = 0.0) -> void
func play_ui(sfx_id: StringName) -> void
func set_layer(layer_id: StringName, intensity: float, fade: float = 2.0) -> void  # soundscape 0..1
func play_music(track_id: StringName, fade_in: float = 3.0) -> void
func stop_music(fade_out: float = 3.0) -> void
```

### SaveManager
```gdscript
func save_game(slot: int = 0) -> Error
func load_game(slot: int = 0) -> Error
func has_save(slot: int = 0) -> bool
# Chaque autoload expose : func to_save_dict() -> Dictionary / func from_save_dict(d: Dictionary) -> void
```

## 6. Ressources de données

### ItemData (`scripts/item_data.gd`)
```gdscript
class_name ItemData extends Resource
@export var id: StringName
@export var list_index: int                      # 1..212, position dans l'inventaire 1973
@export var room_id: StringName                  # pièce selon la liste 1973
@export var label_key: StringName                # clé de la description 1973 (ambiguë)
@export var lore_key: StringName                 # texte révélé quand coché (peut être vide)
@export var is_phantom: bool = false             # absent au départ
@export var phantom_kind: StringName             # "person","moved","message","photo_only"
@export var reveal_condition: String             # expression simple : "doc_read:bedroom_journal_3 && checked>=100"
@export var movable: bool = true                 # la maison peut le déplacer si non coché
@export var anchors: Array[StringName]           # points d'ancrage possibles (nœuds Marker3D dans les rooms)
@export var scene: PackedScene                   # modèle 3D (prefab item.tscn hérité)
@export var photo_variant_scene: PackedScene     # optionnel : ce qu'on voit SUR la photo si différent
@export var min_photo_coverage: float = 0.15     # fraction d'écran minimale pour « net »
```

### PhotoData
```gdscript
class_name PhotoData extends RefCounted
var id: int
var timestamp: float                 # temps de jeu
var room_id: StringName
var camera_transform: Transform3D
var visible_item_ids: Array[StringName]      # objets réellement cadrés
var revealed_item_ids: Array[StringName]     # objets visibles seulement sur la photo
var presence_visible: bool
var texture: Texture2D               # rendu (SubViewport capturé au flash)
var developed: bool = false
```

### DocumentData
```gdscript
class_name DocumentData extends Resource
@export var id: StringName
@export var kind: StringName          # "inventory","letter","journal","form","note","postit","tape"
@export var year: int
@export var author: String
@export var title_key: StringName
@export var body_key: StringName      # texte long dans fr.csv (peut contenir BBCode)
@export var pages: int = 1
@export var reveals_items: Array[StringName]
@export var sets_flags: Array[StringName]
@export var visual_scene: PackedScene # rendu 3D du papier dans la main
```

### HouseRule
```gdscript
class_name HouseRule extends Resource
@export var id: StringName
@export var trigger: StringName       # "room_left","progress","attention_above","doc_read","flash_count","idle","item_checked"
@export var trigger_param: String
@export var condition: String         # même mini-langage que reveal_condition
@export var actions: Array[String]    # "move_item:kitchen_knife:living:anchor_table_2", "event:act1_drawer_opens", "attention:+5", "presence:offscreen", "sfx:upstairs_chair"
@export var once: bool = true
@export var cooldown: float = 0.0
```

Mini-langage de condition (implémenté dans `house_director.gd`, testé par QA) :
`checked>=N`, `act==N`, `attention>N`, `flag:name`, `!flag:name`, `doc_read:id`, `item_checked:id`, `room:id`, combinés par `&&` et `||`, parenthèses autorisées.

## 7. Flux clés

### Prendre une photo
1. Gameplay : input → vérifie `InventoryManager.consume_film()`.
2. Gameplay : capture le SubViewport caméra, calcule `visible_item_ids` par raycasts/frustum sur les nœuds `Item` (groupe `"items"`), construit `PhotoData`, émet `flash_fired` puis `photo_taken`.
3. HouseDirector : réagit à `flash_fired` (attention, règles), décide si `revealed_item_ids` / `presence_visible` sont ajoutés à la photo (**mutation de PhotoData autorisée uniquement ici, avant `photo_developed`**).
4. Gameplay : après 10 s, émet `photo_developed`.
5. InventoryManager : écoute `photo_developed`, appelle `check_item` pour chaque id valide, émet `item_checked` / `inventory_progress`.
6. UI : écoute `item_checked` → animation de coche dans le carnet ; `photo_developed` → ajoute la photo.
7. Audio : écoute tout ça pour le son.

### Déplacer un objet (maison)
1. HouseDirector : `player_left_room` → évalue les règles → émet `item_moved(id, from, to, anchor)`.
2. Niveau (`house.gd`) : écoute `item_moved`, déplace le nœud `Item` vers le `Marker3D` nommé `anchor` dans `rooms/<to>.tscn`. Si l'ancre n'existe pas → `push_error` + pas de déplacement (jamais de crash).

### Objets dans les pièces
- Chaque `rooms/<room_id>.tscn` contient un nœud `Anchors` avec des `Marker3D` nommés, et un nœud `Items` où les `Item` sont instanciés **au chargement** par `house.gd` à partir de `InventoryManager.get_items_in_room()`. Le Niveau ne place pas les objets à la main : il place les **ancres**. Le lien objet↔ancre par défaut est dans `ItemData.anchors[0]`.
- Nœud `Item` (`scenes/items/item.gd`) : `class_name Item extends Node3D`, `@export var data: ItemData`, groupe `"items"`, expose `func is_in_frustum(cam: Camera3D) -> float` (couverture écran estimée).

## 8. Performance (budgets)

- Cible : 60 fps sur GTX 1060 / RX 580 en 1080p, 30 fps mini sur Intel Iris Xe.
- Maison chargée entièrement (pas de streaming) : ≤ 300k triangles visibles, ≤ 1,5 Go VRAM, textures ≤ 2k (4k interdit).
- Lumières : ≤ 4 OmniLight avec ombres actives simultanément. Le flash est une lumière dédiée, 1 seule.
- Un `SubViewport` pour la photo, rendu uniquement au déclenchement.

## 9. Sauvegarde

- JSON dans `user://saves/slot_N.json`. Sauvegarde auto à chaque changement de pièce. Pas de sauvegarde manuelle (design).
- Versionné : champ `"version": 1`. Toute évolution du format = migration dans SaveManager.

## 10. Definition of Done (pour toute tâche)

- [ ] Le projet s'ouvre sans erreur ni warning dans la console Godot.
- [ ] La scène du module se lance seule (F6) sans crash.
- [ ] Tests gdUnit4 du module passent (`tools/run_tests.sh`).
- [ ] Aucune chaîne en dur, aucun chemin de nœud inter-module.
- [ ] `docs/TASKS.md` mis à jour (statut + note de ce qui a été fait).
- [ ] Assets ajoutés → `assets/CREDITS.md` mis à jour.
- [ ] Commit sur ta branche avec message `[module] description`.
