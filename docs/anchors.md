# Ancres de la maison Varenne — V1 Halloween

> Noms contractuels des `Marker3D` utilisés par `ItemData.anchors[0]` et par les règles. Les identifiants `room_id` restent ceux de l’architecture : `exterior`, `hall`, `kitchen`, `living`, `study`, `cellar`.

## Repères de blockout

- Repère local d’une pièce : origine au centre du sol, `+Y` vers le haut. Les objets sont positionnés par le centre de leur placeholder; un objet à poser au sol a donc une ancre à la moitié de sa hauteur.
- Entrée du hall au `z = -4,5 m`; fond et escalier condamné au `z = +4,5 m`. L’axe `X` mesure la largeur du couloir. Le bureau est à l’est du hall; la cave est déjà placée sous l’emplacement réservé à la cuisine.
- Rez-de-chaussée : plafonds à `2,6 m`; portes `0,9 × 2,1 m`. Hall/couloir `3 × 9 m` (largeur libre ≥ `1,4 m`), cuisine `4,5 × 4,5 m`, salon `5 × 5 m`, bureau `4,5 × 4 m`.
- Cave `6 × 4 m`, hauteur `2,1 m`, sous la cuisine; dans `house.tscn`, racine à `(-3.75, -3.5, 0)`, accès par trappe et échelle raide. Cour `≈ 14 × 9 m`.
- Le hall montre l’escalier barré et le mot de Besnard, mais l’étage n’est pas une zone jouable. Le téléphone et le répondeur sont sur la console du hall.

## Ancres d’événements

| Pièce | Nom | Usage | État |
|---|---|---|---|
| hall | `hall_anchor_console` | Cible des déplacements vers la console; place au sol à côté du meuble | présent dans `rooms/hall.tscn` |
| kitchen | `kitchen_anchor_sink` | Cible de déplacement près de l’évier | à créer avec la cuisine (N-5) |
| kitchen | `kitchen_anchor_preserves` | Apparition de `kitchen_key_l` près des confitures | à créer avec la cuisine (N-5) |
| living | `living_anchor_fireplace` | Cible des fauteuils près de la cheminée | à créer avec le salon (N-5) |
| study | `study_anchor_shelves` | Cible du cachet sur le dessus du rayonnage | présent dans `rooms/study.tscn` (distincte de l’ancre d’objet) |
| hall | `hall_anchor_stairs_top` | Repère visuel pour la Présence photographiée sur l’escalier, hors zone jouable | présent dans `rooms/hall.tscn` |
| cellar | `cellar_anchor_presence_spawn` | Spawn de la Présence, au fond le plus éloigné de l’échelle | présent dans `rooms/cellar.tscn`; instance de `presence.tscn` alignée sur ce repère |

Le poêle de la cave est un Item dédié (`scenes/items/cellar_stove.tscn`) : `metadata/interact_id = &"cellar_stove"`, `metadata/interact_kind = &"burn"`, `metadata/interact_duration = 8.0`; son API renvoie également `burn` / `8.0` à l’Interactor. Le registre 1847 (`document_id = &"cellar_register_1847"`) est posé sur une table à proximité.

## Ancres initiales par objet

Chaque ligne correspond à un `ItemData` de `docs/items_master.csv`; les 60 `.tres` ont `anchors = [&"<ancre>"]`. `scene` pointe vers `res://scenes/items/item.tscn`, sauf `cellar_stove` qui utilise `res://scenes/items/cellar_stove.tscn` pour son interaction `burn` de 8 s. Les ancres des pièces pas encore blockoutées seront matérialisées lors de N-5/N-10.

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
| 17 | `kitchen_sink` | `kitchen_anchor_sink` |
| 18 | `kitchen_stove` | `kitchen_anchor_stove` |
| 19 | `kitchen_coffee_mill` | `kitchen_anchor_coffee_mill` |
| 20 | `kitchen_scales` | `kitchen_anchor_scales` |
| 21 | `kitchen_jars` | `kitchen_anchor_jars` |
| 22 | `kitchen_preserves` | `kitchen_anchor_preserves` |
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
| 32 | `living_fireplace` | `living_anchor_fireplace` |
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

- `rooms/hall.tscn` : zone `Area3D` `metadata/room_id = &"hall"`, collision layer `4`, `monitorable = true`; `Anchors` contient les 10 ancres d’objets du hall, `hall_anchor_console` et `hall_anchor_stairs_top`; `Items` reste vide dans la scène source.
- `rooms/study.tscn` : zone `Area3D` `metadata/room_id = &"study"`, collision layer `4`, `monitorable = true`; `Anchors` contient les 12 ancres d’objets plus `study_anchor_shelves` au sommet du rayonnage; `Items` reste vide dans la scène source.
- `rooms/cellar.tscn` : blockout `6 × 4 × 2,1 m`, zone `Area3D` monitorable/couche `4`, ouverture de trappe + échelle, table du registre, 4 ancres d’objets et `cellar_anchor_presence_spawn`; instancie `presence.tscn` à ce repère.
- `house.gd` instancie les objets dans `Items` et écoute `item_moved` / `item_revealed` via `EventBus`. Une ancre cible absente déclenche `push_error` et annule le déplacement sans planter.
- Les zones à venir reprennent exactement la même arborescence `Anchors`, `Items`, `Zone` et le même contrat `room_id`.
