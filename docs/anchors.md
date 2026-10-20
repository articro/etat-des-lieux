# Ancres de la maison Varenne — V1 Halloween

> Noms contractuels des `Marker3D` utilisés par `ItemData.anchors[0]` et par les règles. Les identifiants `room_id` restent ceux de l’architecture : `exterior`, `hall`, `kitchen`, `living`, `study`, `cellar`.

## Repères de blockout

- Repère local d’une pièce : origine au centre du sol, `+Y` vers le haut. Les objets sont positionnés par le centre de leur placeholder; un objet à poser au sol a donc une ancre à la moitié de sa hauteur.
- Entrée du hall au `z = -4,5 m`; fond et escalier condamné au `z = +4,5 m`. L’axe `X` mesure la largeur du couloir. Porte ouest à `z = 0` vers la cuisine, porte est vers le bureau, porte ouest à `z = 3,25` vers le salon; le fond nord reste condamné.
- Rez-de-chaussée : plafonds à `2,6 m`; portes `0,9 × 2,1 m`. Hall/couloir `3 × 9 m` (largeur libre ≥ `1,4 m`), cuisine `4,5 × 4,5 m`, salon `5 × 5 m`, bureau `4,5 × 4 m`. Cuisine centrée en `(-3.75, 0, 0)`; salon en `(-4, 0, 4.75)`.
- Cave `6 × 4 m`, hauteur `2,1 m`, sous la cuisine; dans `house.tscn`, racine à `(-3.75, -2.1, 0)`. Trappe cuisine/cave alignée en coordonnées locales `(1, -1)`; elle reste fermée et collidable jusqu’à `cellar_door_opens`. Cour `≈ 14 × 9 m`, racine `(0, 0, -9)`.
- Le hall montre l’escalier barré et le mot de Besnard, mais l’étage n’est pas une zone jouable. Le téléphone et le répondeur sont sur la console du hall.

## Ancres d’événements

| Pièce | Nom | Usage | État |
|---|---|---|---|
| hall | `hall_anchor_console` | Cible des déplacements vers la console; place au sol à côté du meuble | présent dans `rooms/hall.tscn` |
| kitchen | `kitchen_anchor_sink` | Cible de déplacement du tabouret devant l’évier (distincte de l’ancre de l’objet) | présent dans `rooms/kitchen.tscn` |
| kitchen | `kitchen_anchor_preserves` | Apparition de `kitchen_key_l` près des confitures (distincte de l’ancre de l’objet) | présent dans `rooms/kitchen.tscn` |
| living | `living_anchor_fireplace` | Cible des fauteuils devant la cheminée (distincte de l’ancre de l’objet) | présent dans `rooms/living.tscn` |
| study | `study_anchor_shelves` | Cible du cachet sur le dessus du rayonnage | présent dans `rooms/study.tscn` (distincte de l’ancre d’objet) |
| hall | `hall_anchor_stairs_top` | Repère visuel pour la Présence photographiée sur l’escalier, hors zone jouable | présent dans `rooms/hall.tscn` |
| cellar | `cellar_anchor_presence_spawn` | Spawn de la Présence, au fond le plus éloigné de l’échelle | présent dans `rooms/cellar.tscn`; instance de `presence.tscn` alignée sur ce repère |

Le poêle de la cave est un Item dédié (`scenes/items/cellar_stove.tscn`) : `metadata/interact_id = &"cellar_stove"`, `metadata/interact_kind = &"burn"`, `metadata/interact_duration = 8.0`; son API renvoie également `burn` / `8.0` à l’Interactor. Le registre 1847 (`document_id = &"cellar_register_1847"`) est posé sur une table à proximité.

## Ancres initiales par objet

Chaque ligne correspond à un `ItemData` de `docs/items_master.csv`; les 60 `.tres` ont `anchors = [&"<ancre>"]`. `scene` pointe vers `res://scenes/items/item.tscn`, sauf `cellar_stove` qui utilise `res://scenes/items/cellar_stove.tscn` pour son interaction `burn` de 8 s. Les trois objets associés à une cible de règle (`kitchen_sink`, `kitchen_preserves`, `living_fireplace`) ont une ancre initiale dédiée, distincte de la cible.

### Extérieur — `exterior`

| Index | `item_id` | `Marker3D` / `anchors[0]` |
|---:|---|---|
| 1 | `exterior_gate` | `exterior_anchor_gate` |
| 2 | `exterior_well` | `exterior_anchor_well` |
| 3 | `exterior_wheelbarrow` | `exterior_anchor_wheelbarrow` |
| 4 | `exterior_bench` | `exterior_anchor_bench` |

### Entrée / hall — `hall`

| Index | `item_id` | `Marker3D` / `anchors[0]` |
|---:|---|---|
| 5 | `hall_console_table` | `hall_anchor_console_table` |
| 6 | `hall_barometer` | `hall_anchor_barometer` |
| 7 | `hall_coat_rack` | `hall_anchor_coat_rack` |
| 8 | `hall_key_board` | `hall_anchor_key_board` |
| 9 | `hall_mirror` | `hall_anchor_mirror` |
| 10 | `hall_umbrella_stand` | `hall_anchor_umbrella_stand` |
| 11 | `hall_doorbell` | `hall_anchor_doorbell` |
| 12 | `hall_answering_machine` | `hall_anchor_answering_machine` |
| 13 | `hall_hand_railing` | `hall_anchor_hand_railing` |
| 14 | `hall_ring_1951` | `hall_anchor_ring_1951` |

### Cuisine — `kitchen`

| Index | `item_id` | `Marker3D` / `anchors[0]` |
|---:|---|---|
| 15 | `kitchen_table` | `kitchen_anchor_table` |
| 16 | `kitchen_chairs` | `kitchen_anchor_chairs` |
| 17 | `kitchen_sink` | `kitchen_anchor_sink_item` |
| 18 | `kitchen_stove` | `kitchen_anchor_stove` |
| 19 | `kitchen_coffee_mill` | `kitchen_anchor_coffee_mill` |
| 20 | `kitchen_scales` | `kitchen_anchor_scales` |
| 21 | `kitchen_jars` | `kitchen_anchor_jars` |
| 22 | `kitchen_preserves` | `kitchen_anchor_preserves_item` |
| 23 | `kitchen_clock_stopped` | `kitchen_anchor_clock_stopped` |
| 24 | `kitchen_calendar` | `kitchen_anchor_calendar` |
| 25 | `kitchen_cookware` | `kitchen_anchor_cookware` |
| 26 | `kitchen_tureen` | `kitchen_anchor_tureen` |
| 27 | `kitchen_tin_box` | `kitchen_anchor_tin_box` |
| 28 | `kitchen_stool` | `kitchen_anchor_stool` |
| 29 | `kitchen_lamp` | `kitchen_anchor_lamp` |
| 30 | `kitchen_key_l` | `kitchen_anchor_key_l` |

### Salon — `living`

| Index | `item_id` | `Marker3D` / `anchors[0]` |
|---:|---|---|
| 31 | `living_piano` | `living_anchor_piano` |
| 32 | `living_fireplace` | `living_anchor_fireplace_item` |
| 33 | `living_armchairs` | `living_anchor_armchairs` |
| 34 | `living_sofa` | `living_anchor_sofa` |
| 35 | `living_sideboard` | `living_anchor_sideboard` |
| 36 | `living_rug` | `living_anchor_rug` |
| 37 | `living_frames` | `living_anchor_frames` |
| 38 | `living_sheet_music` | `living_anchor_sheet_music` |
| 39 | `living_radio` | `living_anchor_radio` |
| 40 | `living_bookcase` | `living_anchor_bookcase` |
| 41 | `living_curtains` | `living_anchor_curtains` |
| 42 | `living_workbasket` | `living_anchor_workbasket` |
| 43 | `living_curtain_part` | `living_anchor_curtain_part` |
| 44 | `living_portrait_louis` | `living_anchor_portrait_louis` |

### Bureau — `study`

| Index | `item_id` | `Marker3D` / `anchors[0]` |
|---:|---|---|
| 45 | `study_desk` | `study_anchor_desk` |
| 46 | `study_chair` | `study_anchor_chair` |
| 47 | `study_shelves` | `study_anchor_shelves_item` |
| 48 | `study_typewriter` | `study_anchor_typewriter` |
| 49 | `study_lamp` | `study_anchor_lamp` |
| 50 | `study_inkwell` | `study_anchor_inkwell` |
| 51 | `study_stamp` | `study_anchor_stamp` |
| 52 | `study_registers` | `study_anchor_registers` |
| 53 | `study_cadastre` | `study_anchor_cadastre` |
| 54 | `study_safe` | `study_anchor_safe` |
| 55 | `study_blotter` | `study_anchor_blotter` |
| 56 | `study_briefcase_jpd` | `study_anchor_briefcase_jpd` |

### Cave — `cellar`

| Index | `item_id` | `Marker3D` / `anchors[0]` |
|---:|---|---|
| 57 | `cellar_shelves` | `cellar_anchor_shelves` |
| 58 | `cellar_bottles` | `cellar_anchor_bottles` |
| 59 | `cellar_stove` | `cellar_anchor_stove` |
| 60 | `cellar_coat_emile` | `cellar_anchor_coat_emile` |

## Scènes et zones

- `rooms/hall.tscn` : zone `Area3D` `metadata/room_id = &"hall"`, collision layer `4`, `monitorable = true`; `Anchors` contient les 10 ancres d’objets du hall, `hall_anchor_console` et `hall_anchor_stairs_top`; `Items` reste vide dans la scène source. La livraison visuelle J5 applique papier peint 70s, parquet et plâtre ambientCG CC0; les 10 Items se construisent à l’exécution en 5 modèles CC0 et 5 objets CSG distinctifs via `item_visuals.gd`. Les ancres des éléments muraux sont alignées sur les faces intérieures; la bague repose sur le plateau de la console.
- `rooms/study.tscn` : zone `Area3D` `metadata/room_id = &"study"`, collision layer `4`, `monitorable = true`; `Anchors` contient les 12 ancres d’objets plus `study_anchor_shelves` au sommet du rayonnage; `Items` reste vide dans la scène source.
- `rooms/cellar.tscn` : blockout `6 × 4 × 2,1 m`, zone `Area3D` monitorable/couche `4`, ouverture de plafond alignée sur la trappe cuisine, échelle, table du registre, 4 ancres d’objets et `cellar_anchor_presence_spawn`; instancie `presence.tscn` à ce repère.
- `rooms/kitchen.tscn` : cuisine `4,5 × 4,5 m`, 16 ancres d’objets, évier/cuisinière en blockout, cible de règle séparée près de l’évier et cible des confitures; trappe à charnière collidable, ouverte par l’événement `cellar_door_opens`.
- `rooms/living.tscn` : salon `5 × 5 m`, cheminée en blockout, 14 ancres d’objets et cible de règle séparée devant le foyer; porte ouest du hall alignée sur son ouverture est.
- `rooms/exterior.tscn` : cour `14 × 9 m`, 4 ancres d’objets, 205 en décor, sol et clôtures collidables; portail sud fermé avec collision, seule sortie reliée au hall au nord.
- `rooms/hall.tscn` ouvre les portes vers cuisine, salon, bureau et cour; l’accès à l’étage reste condamné par planches et barrière collidables. `house.tscn` compose les six zones et 60 objets; les `TempBlockers` cuisine/entrée ont été retirés.
- Chaque room conserve `Anchors`, `Items`, `Zone` et le contrat `room_id`; `room.gd` cache les remplissages et lumières de preview quand la room est composée. `house.gd` écoute `item_moved` / `item_revealed` et `house_event_triggered` via `EventBus`; ancre cible absente = `push_error` sans crash.
