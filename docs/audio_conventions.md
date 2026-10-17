# Conventions audio — « État des lieux »

> Propriétaire : module **Audio** (`autoloads/audio_manager.gd`, `assets/audio/`, `tests/audio/`).
> Ce document est la référence pour les autres modules : **comment** déclencher du son sans
> jamais appeler l'AudioManager autrement que par l'API de `docs/ARCHITECTURE.md` §5.
>
> Règle d'or : **personne n'a besoin de connaître l'AudioManager.** Chaque module émet ses
> signaux sur l'EventBus ; l'AudioManager écoute et se débrouille. Si un son manque, il ne se
> passe rien de grave (`push_warning` + silence), jamais de crash.

---

## 1. L'API (rappel — elle est figée)

```gdscript
AudioManager.play_sfx(sfx_id: StringName, position: Vector3 = Vector3.INF, volume_db: float = 0.0)
AudioManager.play_ui(sfx_id: StringName)                       # sons d'interface / dans les mains
AudioManager.set_layer(layer_id: StringName, intensity: float, fade: float = 2.0)   # 0..1
AudioManager.play_music(track_id: StringName, fade_in: float = 3.0)
AudioManager.stop_music(fade_out: float = 3.0)
```

Compléments lecture seule (tests, debug, QA) : `sfx_ids()`, `sfx_is_available(id)`,
`sfx_duration(id)`, `layer_intensity(id)`, `bus_volume_db(bus)`, `current_surface()`.

- `play_sfx` avec `position = Vector3.INF` → 2D. Avec une position → 3D (atténuation
  inversement proportionnelle, `unit_size` 10 m, portée 32 m par défaut).
- Un id inconnu ou un fichier absent → **un seul** `push_warning` puis silence définitif
  pour cet id. Aucun son n'est indispensable.

## 2. Graphe de bus

```
Master ──(low-pass, ouvert à 20,5 kHz)
 ├── Music
 └── SFX
      ├── Ambiance
      └── UI
```

Créé **par code** dans `_ready()` (pas de `default_bus_layout.tres` : ce fichier appartient à
l'Architecte, l'AudioManager ne touche pas à `project.godot`).

- **Ambiance et UI envoient vers SFX** : le curseur `volume_sfx` couvre donc l'ambiance *et*
  les sons de l'appareil photo. C'est volontaire : Gameplay joue l'appareil via `play_ui`, et
  le son le plus important du jeu doit obéir au réglage SFX.
- Un **low-pass sur le Master** (ouvert par défaut) sert à étouffer l'oreille : pause (900 Hz)
  et contact de la Présence (420 Hz). Il remonte en 2,5 s.

## 3. Options (`EventBus.settings_changed`)

| Clé | Effet |
|---|---|
| `volume_master` | bus Master |
| `volume_sfx` | bus SFX (donc aussi Ambiance et UI) |
| `volume_music` | bus Music |

Valeurs 0..1 (`linear_to_db`). `volume_ambiance` n'existe pas au contrat : elle est acceptée
et ignorée (l'ambiance suit SFX). En pause : −8 dB sur SFX et Music (signal `pause_toggled`).

## 4. Registre des sons

Tous les sons sont dans `res://assets/audio/<dossier>/<fichier>.ogg` (mono 44,1 kHz).
Un son = un id = une ou plusieurs variantes tirées au hasard.

### 4.1 Appareil photo — priorité 1 (bus UI)

| Id | Durée | Rôle |
|---|---|---|
| `camera_raise` | 0,60 s | lever l'appareil : dépliage, clac, verrou, ressort |
| `camera_lower` | 0,40 s | le baisser (plus sourd) |
| `camera_shutter` | 0,34 s | le clac du déclencheur : sec, mécanique, sans lumière |
| `camera_flash` | 0,55 s | **le clac du flash** : étincelle, corps, grésillement, pièce |
| `flash_charge` | 1,58 s | **le sifflement qui monte** (condensateur) + clic « prêt » |
| `photo_slide` | 1,45 s | **le moteur qui éjecte la photo** : engage, ronronne, crache, bute |
| `camera_dry` | 0,30 s | plus de film : clac décevant, creux, aucun moteur |
| `photo_ready` | 0,60 s | la photo a fini de se développer (frôlement de papier) |

`camera_raise` sert **à lever et à baisser** (un seul id côté Gameplay) : l'AudioManager
alterne. La charge du flash est programmée 0,35 s après avoir levé l'appareil, puis 1,15 s
après chaque flash : on entend lever → charger → déclencher → flash → moteur → recharger.

### 4.2 Joueur (pas, souffle, sac)

`footstep_<surface>` : `wood`, `tile`, `carpet`, `gravel`, `stone` — 4 variantes chacune.
`bag_leather` (sac, tous les 5 à 8 pas), `breath_in` / `breath_out` (souffle, intervalle 5,4 s
au calme → 2,7 s à l'angoisse).

### 4.3 Interactions (`player_interacted` → son automatique)

| `kind` | Son | Exception par `target_id` |
|---|---|---|
| `open` | `interact_open` | contient `drawer`/`tiroir` → `drawer_open` ; `door`/`porte`/`gate`/`trappe` → `door_open` |
| `pickup` | `interact_pickup` | |
| `read` | `interact_paper` | |
| `burn` | `fire_start` | |
| autre | `interact_generic` | |

### 4.4 Maison (craquements) et horloge

`house_creak_01..03`, `house_pipe_01..02` : joués **en 3D autour du joueur** (4 à 11 m, au
hasard) à intervalles aléatoires — 14-26 s au calme, 5-11 s à l'angoisse. Aucun n'est déclenché
par un script : c'est la maison qui vit.
`clock_chime_distant` : deux coups, étouffés (déclenchable par une règle).

### 4.5 Présence — 10 sons domestiques au mauvais endroit

| Id | Durée | Ce qu'on entend |
|---|---|---|
| `chair_drag_upstairs` | 1,05 s | une chaise tirée, au-dessus |
| `upstairs_chair` | 0,65 s | quelqu'un s'assoit, au-dessus |
| `footsteps_above` | 3,30 s | cinq pas lents, réguliers, au-dessus |
| `door_close_upstairs` | 0,95 s | une porte se ferme à l'étage |
| `phone_ring` | 2,70 s | le téléphone sonne (sonnerie à gongs) |
| `water_drip` | 1,95 s | un robinet goutte |
| `paper_turn` | 1,56 s | **quelqu'un tourne les pages de votre carnet** (son sec, sans réverbe) |
| `breath_low` | 1,47 s | une respiration qui n'est pas la vôtre |
| `hall_light_out` | 0,95 s | le plafonnier s'éteint, le ballast descend |
| `cellar_light_flicker` | 2,30 s | l'ampoule de la cave grésille |

`caught_impact` (2,20 s) : le contact. Pas de cri — un choc sourd, l'air qui manque, un
acouphène, et tout le reste étouffé 2,6 s.

**Aucun de ces sons n'est effrayant par lui-même.** C'est le fait qu'ils arrivent au mauvais
endroit qui fait peur (GDD §9).

### 4.6 Couches (`set_layer`) et musiques

| Couche | Boucle | Pilotée par |
|---|---|---|
| `house_base` | 12 s | 1,0 dans la maison (0,55 dans la cave, 0 dehors) |
| `house_unease` | 12 s | attention 20 → 45 (0 → 1) |
| `house_dread` | 12 s | attention 45 → 70 (0 → 1) |
| `exterior` | 12 s | 1,0 dans la cour, 0 ailleurs |
| `presence` | 10 s | `presence_state_changed` : 1,0 si `physical`, 0,35 sinon, 0 si `dormant`/`frozen` |

Musiques : `music_ending_closed`, `music_ending_ashes` (66 s, fondu 6 s à la fin).
Le soundscape **démarre au premier `player_entered_room`** (jamais pendant le menu principal)
et s'éteint en 4 s sur `ending_reached`.

---

## 5. Convention `metadata/surface` — pour le module Niveau

Le signal `player_noise(level, position)` ne transporte pas le matériau (contrat figé).
L'AudioManager fait donc un **rayon physique** de 0,45 m au-dessus à 1,30 m en dessous de la
position du joueur, et lit la métadonnée `surface` sur le premier corps touché (ou sur ses
parents, jusqu'à 4 niveaux).

**Ce que Niveau doit faire** : sur chaque sol / escalier / plaque de matière différente,
poser la métadonnée sur le `StaticBody3D` (ou sur un parent commun) :

```gdscript
# rooms/kitchen.tscn — nœud Floor (StaticBody3D)
func _ready() -> void:
	set_meta(&"surface", &"tile")      # dans l'inspecteur : Metadata > surface = "tile"
```

Valeurs reconnues (V1) :

| `surface` | Matériau | Où |
|---|---|---|
| `wood` | parquet, plancher | bureau, salon, étage |
| `tile` | carrelage | entrée, cuisine |
| `carpet` | moquette | salon (tapis), chambres |
| `gravel` | gravier, terre | cour, extérieur |
| `stone` | pierre, terre battue | cave |

**Si la métadonnée est absente**, l'AudioManager retombe sur un défaut par pièce
(`exterior` → gravel, `cellar` → stone, `hall`/`kitchen` → tile, `living` → carpet,
`study` → wood, sinon `wood`). Rien ne casse : un sol non renseigné sonne simplement comme
du parquet. Une nouvelle valeur (`&"metal"`, `&"water"`) n'existe que si quelqu'un ajoute
`footstep_<valeur>` : sinon, repli automatique sur `wood`.

## 6. Convention pour le module Gameplay

- **Pas** : `EventBus.player_noise.emit(0.25, position)` pour la marche, `0.85` pour la
  course (au-delà de 0,6 c'est une course : plus fort, plus clair). Un pas est ignoré s'il
  arrive moins de 0,11 s après le précédent (garde anti-mitraille).
- **Appareil photo** : Gameplay appelle déjà `play_ui` pour `camera_raise`, `camera_shutter`,
  `camera_flash`, `photo_slide`, `camera_dry`, et `flashlight_click`. L'AudioManager écoute
  aussi `flash_fired` et `photo_taken`, mais **avec un anti-doublon** (0,4 s / 0,6 s) : si
  Gameplay a déjà joué le son, il ne le rejoue pas. Les deux chemins fonctionnent donc seuls.
- La lampe (`flashlight_click`) et le carnet (`notebook_open`/`notebook_close`) passent par
  `play_ui` : ce sont des sons « dans les mains », non spatialisés.

## 7. Convention pour la Narration et les Systèmes (règles de maison)

Une action de règle `sfx:<id>` (`HouseRule.actions`) appelle `AudioManager.play_sfx(id)` **sans
position**. Pour que le son vienne d'ailleurs, l'AudioManager place lui-même certains ids :

| Id | Position |
|---|---|
| `chair_drag_upstairs`, `upstairs_chair`, `footsteps_above`, `door_close_upstairs` | 3,1 m au-dessus du joueur |
| `clock_chime_distant` | 1 m au-dessus, 6 m derrière |

Pour un son **à un endroit précis** (le téléphone de l'entrée, la trappe de la cave), poser un
`Marker3D` et demander à Systèmes/Gameplay d'émettre le son avec une position… **ce n'est pas
prévu au contrat** : en V1 on garde le placement automatique, et on note la demande dans
`docs/TASKS.md` si un son a vraiment besoin d'être ancré.

Ids déjà utilisés par les règles V1 (tous existent) : `drawer_open`, `clock_chime_distant`,
`phone_ring`, `breath_low`, `door_close_upstairs`, `paper_turn`, `chair_drag_upstairs`,
`hall_light_out`, `cellar_light_flicker`, `upstairs_chair`, `footsteps_above`.

## 8. Assets : provenance et régénération

**Tous les sons sont générés par synthèse procédurale** (numpy/scipy/soundfile) : aucun
échantillon tiers, donc aucune attribution à porter — le jeu reste libre de tout souci de
licence audio. Les scripts sont livrés avec les assets :

```
game/assets/audio/_src/
├── common.py           filtres, enveloppes, réverbe, écriture OGG, bouclage
├── synth_camera.py     D-2 : l'appareil photo
├── synth_player.py     D-3 : pas, souffle, sac
├── synth_interact.py   D-3 : interactions
├── synth_house.py      D-4 : craquements + nappes
├── synth_presence.py   D-5 : sons domestiques
├── synth_music.py      D-6 : musiques de fin
├── analyse.py          contrôle objectif (durée, dynamique, spectre, couture de boucle)
└── preview.py          spectrogrammes (PNG dans /tmp/preview)
```

```bash
python3 game/assets/audio/_src/synth_camera.py     # régénère les sons de l'appareil
python3 game/assets/audio/_src/analyse.py          # 67 fichiers, 0 hors tolérance
```

Format : **OGG Vorbis mono 44,1 kHz**. Les nappes sont bouclées sans couture (fondu croisé
cosinus de 1,5 à 2,5 s) ; `AudioManager` force `loop = true` dessus.

**Ajouter un son** = 3 endroits : le fichier dans `assets/audio/<dossier>/`, l'entrée dans le
registre de `_build_registers()` (`autoloads/audio_manager.gd`), et cette documentation.

## 9. Tests

- **Headless (CI, QA)** : `bash game/tests/audio/run_headless.sh` — joue les 52 ids, vérifie
  les 5 matériaux, émet tous les signaux consommés, vérifie la dégradation sur des ids
  inconnus. Vert = aucune erreur, aucun `ECHEC`.
- **À l'oreille (F6)** : ouvrir `game/tests/audio/test_audio.tscn` — une interface avec un
  bouton par son, cinq sols pour tester les pas, la séquence complète de l'appareil photo, un
  curseur d'attention et les deux fins. La scène fabrique son propre monde : elle ne dépend
  d'aucun autre module.

## 10. Ce qui reste à faire (D-8)

Le mixage « statique » est en place (un niveau en dB par entrée de registre, modifiable en un
seul endroit : `_build_registers()`). Il reste une **écoute de contrôle au casque et sur
enceintes de portable** à faire au jalon J10-J11 (PLAN_HALLOWEEN §4) : l'équilibre entre le
souffle, les nappes et les pas ne se vérifie qu'à l'oreille. Corriger = changer un nombre dans
le registre, rien d'autre.
