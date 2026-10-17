# ÉTAT DES LIEUX — Tâches & Jalons

> ⚠️ **MODE HALLOWEEN 2026 ACTIF** : lis d'abord `docs/PLAN_HALLOWEEN.md`. Il définit le périmètre réduit, les priorités par agent et le calendrier J1→J14. Les tâches ci-dessous restent la référence des IDs, mais **seules celles citées dans PLAN_HALLOWEEN.md §3 sont à faire**, dans l'ordre indiqué. Le reste = V2.

> Statuts : `TODO` · `EN COURS (agent)` · `REVIEW` · `DONE` · `BLOQUÉ (raison)`
> Chaque agent met à jour **uniquement ses lignes** + la section *Demandes inter-modules*.

## Jalons

| Jalon | Objectif | Critère de validation |
|---|---|---|
| **M0 — Fondation** | Docs + squelette + contrats | Le projet s'ouvre dans Godot, autoloads chargés, 0 erreur |
| **M1 — Vertical slice** | 2 pièces (entrée + bureau), caméra photo complète, carnet, 20 objets, 1 règle de maison, 1 événement (le tiroir) | On peut jouer 10 min et **avoir peur une fois** |
| **M2 — Maison complète** | 13 zones en blockout, tous les systèmes fonctionnels, sauvegarde | On traverse tout le jeu en « gris » du début à la fin |
| **M3 — Contenu complet** | 212 objets, tous documents, 3 fins + fin cachée, Présence | Le jeu est finissable, 4 fins atteignables |
| **M4 — Polish** | Assets finaux, éclairage, audio complet, post-process, options | Playtest externe : 3 testeurs finissent sans bug bloquant |
| **M5 — Release** | Exports Win/Linux/Mac, page itch.io, trailer | En ligne avant le 31 octobre |

**Décision clé après M1** : si la vertical slice ne fait pas peur, on retravaille le design avant de produire du contenu.

---

## M0 — Fondation `[Architecte]`

| ID | Tâche | Statut |
|---|---|---|
| A0-1 | GDD, Story Bible, Architecture, Briefs | DONE |
| A0-2 | Squelette projet Godot + autoloads stubs + classes de données | DONE |
| A0-3 | Dépôt GitHub `articro/etat-des-lieux`, push initial, 6 branches agents | DONE |
| A0-7 | Intégration Narration session 1 (60 objets, 10 docs, 18 règles) sur main, traduction enregistrée | DONE |
| A0-8 | Intégration Narration session 2 (relecture, itch_textes.md) | DONE |
| A0-10 | Intégration Systèmes session 1 (S-2→S-8, 79 assertions) ; playtest utilisateur J1 : feeling validé | DONE |
| A0-9 | Intégration Gameplay session 1 (G-1→G-10, 73 tests) + décisions (coverage 0.04, settings_changed, post-process unique) | DONE |
| A0-4 | Version Godot = **4.7.2**, `config/features` ajusté, check headless OK | DONE |
| A0-5 | Outils : `tools/check.sh`, `tools/install_godot_sandbox.sh`, `tools/run_tests.sh` | DONE |
| A0-6 | Plan Halloween 2026 (périmètre réduit, calendrier) | DONE |

## Module Gameplay `[Gameplay]` — `scenes/player/`, `scenes/fx/`

| ID | Tâche | Jalon | Statut |
|---|---|---|---|
| G-1 | Contrôleur FPS (marche/course/accroupi, essoufflement, head-bob subtil, ZQSD + QWERTY via physical keys) | M1 | DONE |
| G-2 | Système d'interaction (raycast, surbrillance discrète, prendre/inspecter/reposer un objet, portes & tiroirs physiques à la souris) | M1 | DONE (V1 simplifiée) |
| G-3 | Appareil photo : visée (lever l'appareil, viseur), déclenchement, consommation film, SubViewport capture, flash lumière + aveuglement, son via AudioManager | M1 | DONE |
| G-4 | Détection des objets cadrés (frustum + occlusion raycast + couverture écran ≥ `min_photo_coverage`), construction PhotoData | M1 | DONE |
| G-5 | Photo en main : sortie de l'appareil, développement 10 s (shader), consultation | M1 | DONE |
| G-6 | Lampe de poche faible, batterie infinie, option « plus forte » | M1 | DONE |
| G-7 | Post-process : grain, vignette, aberration légère, aveuglement flash (scenes/fx) | M2 | DONE |
| G-8 | Présence : nœud `Presence` (déplacement lent par NavigationAgent3D, états via `presence_state_changed`, figée 4 s si photographiée, contact → `player_caught`) | M3 | DONE (simplifiée) |
| G-9 | Interactions longues (brûler carnet 8 s, signer registre) avec annulation | M3 | DONE (brûler) |
| G-10 | Zones de pièce (Area3D → `player_entered_room/left_room`) — en coordination avec Niveau | M1 | DONE (côté Gameplay) |

### Notes Gameplay (V1 Halloween)

- **2026-10-17 — Socle.** `[input]` ajouté à `project.godot` (13 actions, physical_keycode : ZQSD+WASD, Maj, Ctrl/C, E, F, clic droit/gauche, P, Tab, Échap). Filet de sécurité `scenes/player/input_actions.gd` : recrée les actions manquantes à l'exécution (si fusion/porte). `player.tscn` (CharacterBody3D + caméra) et `scenes/player/test_room.tscn` (sol, 3 Item placeholders, zone de pièce, occluder) se lancent seuls. Test item : `tests/player/test_item.gd` (contrat `Item` respecté).
- **2026-10-17 — G-1 DONE.** `player.gd` : marche 2,5 / course 4,0 m/s (accél. 14), accroupi maintenu (capsule 1,75 → 1,10 m), essoufflement (18/s, récup. 30), head-bob + pas → `player_noise` (0,25 marche / 0,85 course), pas de saut, souris capturée, `pause_toggled` respecté, retour auto si chute. Vérifié : 38 assertions headless (`tests/player/player_tests.tscn`, 0 échec).
- **2026-10-17 — Réglages (session 2, après intégration).** `player.gd` écoute `EventBus.settings_changed(key, value)` : `mouse_sensitivity` (normalisé 0..1 → 0,0006..0,0080 rad/px ; valeur < 0,02 prise comme rad/px bruts), `fov` (degrés, borné 55..110, appliqué à la caméra et à la visée), `flashlight_strong` (bool → `Flashlight.set_strong()` : énergie 2,4→4,6, portée 9→13 m, faisceau 24→30°). Les clés inconnues sont ignorées en silence. Visée bornée à 45° minimum. Tests : 83 assertions headless, 0 échec.
- **2026-10-17 — G-2 DONE (V1 simplifiée).** `scenes/player/interactor.gd` : `RayCast3D` 2,5 m depuis la caméra, touche E, résolution par méthode `get_interact_id()` → metadata `interact_id` → `document_id` (kind "read") → groupe `items` (kind "pickup") ; `set_highlight(bool)` appelée si présente. Émet `player_interacted(target_id, kind)` et, pour une lecture, `DocumentLibrary.mark_read(id)` (sinon aucun signal `document_read` n'existe pour l'UI). Portes/tiroirs physiques = V2, non faits.
- **2026-10-17 — G-6 DONE.** `scenes/player/flashlight.gd` (`SpotLight3D` enfant de la caméra) : F, faisceau 24°, portée 9 m, énergie 2,4, ombres, piles infinies ; éteinte au départ ; son `flashlight_click` (id déposé côté Audio).
- **2026-10-17 — G-7 DONE.** `scenes/fx/post_process.tscn` + shader : grain animé, vignette, aberration chromatique radiale, `darkness` ; paramètres exportés sur `PostProcess` (`apply_settings()` pour les options). **Instancié une seule fois, dans `player.tscn`** — ne pas en ajouter ailleurs. Sans rendu (headless) aucune erreur.
- **2026-10-17 — G-8 DONE (simplifiée).** `scenes/player/presence.tscn` : `CharacterBody3D` place-holder sombre, écoute `presence_state_changed` ; en `physical`, avance en ligne droite à 0,45 m/s vers le joueur (groupe `player`, pas de NavMesh conformément au PLAN), figée 4 s si `photo_taken` la contient (cône 32°, 25 m), contact ≤ 1,1 m → `player_caught` (une seule fois). Scène autonome (F6) avec caméra/sol/lampe de test. **À placer par le Niveau dans la cave.**
- **2026-10-17 — G-9 DONE (brûler).** Dans `interactor.gd` : si la cible porte `interact_duration` > 0, maintenir E remplit la jauge `HUD/LongAction` (sans texte) ; relâchement ou changement de cible = annulation ; au bout → `player_interacted(id, kind)`. Conçu pour `cellar_stove` / `"burn"` / 8 s (metadata côté Niveau). La signature du registre (autre interaction longue) n'est pas faite : V2.
- **2026-10-17 — G-3 DONE.** `scenes/player/photo_device.gd` : lever maintenu (clic droit, FOV 75→55), viseur dessiné (`viewfinder.gd`, zéro texte), déclencheur (clic gauche) → `InventoryManager.consume_film()`, flash `OmniLight3D` 0,3 s (ombre), aveuglement blanc 1,5 s (0,06 s de montée + 1,44 s de descente), capture `SubViewport` 1280×720 en `UPDATE_ONCE` au déclenchement seulement, sons `camera_raise/shutter/flash/photo_slide/dry` via `AudioManager`. En headless la capture est désactivée (`texture = null`) : le reste du flux est testé.
- **2026-10-17 — G-4 DONE.** `photo_detector.gd` : groupe `items`, `data: ItemData`, `is_in_frustum()` (repli `ScreenMath` si absent), couverture ≥ `data.min_photo_coverage`, occlusion par raycast caméra→centre de l'AABB sur les `CollisionObject3D` enfants de l'Item (exclusion des RID du joueur). `screen_math.gd` calcule la couverture en espace caméra (fov + aspect) — **piège** : `unproject_position` et `get_visible_rect()` ne sont pas homogènes sous headless (écart ×2,8 constaté) ; ne pas revenir à cette méthode.
- **2026-10-17 — G-5 DONE.** `photo_in_hand.gd` + `scenes/fx/photo_develop.gdshader` : la photo sort de l'appareil (tween 0,25 s), se développe en 10 s (`@export develop_time`), bordure instantané + grain + latence laiteuse ; `photo_developed` émis par l'appareil à 10 s ; touche P pour ramener la photo au centre (`PhotoHold`). Texture absente en headless → shader en gris neutre (dégradation).
- **2026-10-17 — G-10 DONE (côté Gameplay).** `RoomSensor` (Area3D enfant du joueur) détecte les zones `Area3D` monitorables portant `metadata/room_id` et émet `player_entered_room/left_room` (bascule entre zones chevauchées gérée). Convention déposée en Demandes inter-modules ; en attendant les zones du Niveau, `test_room` en fournit une.


### HANDOFF — Gameplay (17 oct. 2026, fin de session 1)

**Ce qui marche (branche `agent/gameplay`, 3 commits poussés : `5c98125`, `99fd46d`, `f0a4098`)**
- **G-1** Contrôleur FPS : marche 2,5 / course 4,0 m/s, accélération 14, accroupi maintenu (capsule 1,75→1,10 m), essoufflement (18/s, récupération à 30), head-bob et bruit de pas (`player_noise` 0,25 / 0,85), pas de saut, souris capturée, pause via `pause_toggled`, téléréapparition si chute. ZQSD/QWERTY par `physical_keycode` (13 actions dans `project.godot`, filet de sécurité `input_actions.gd`).
- **G-3 / G-4 / G-5** Appareil photo complet : clic droit maintenu (FOV 75→55), viseur dessiné sans texte, clic gauche → `consume_film()`, flash Omni 0,3 s + aveuglement blanc 1,5 s, capture `SubViewport` 1280×720 en `UPDATE_ONCE`, `PhotoData` (ids cadrés, room, transform, texture), `flash_fired` puis `photo_taken`, `photo_developed` après 10 s (`@export develop_time`), photo en main avec shader de développement et bordure instantané, touche P pour la ramener au centre.
- **Détection** : groupe `items`, `data: ItemData`, `is_in_frustum()`, couverture écran ≥ `min_photo_coverage`, occlusion par raycast sur les colliders enfants de l'Item, exclusion des RID du joueur. Math de couverture en espace caméra (`screen_math.gd`), indépendante de la résolution et du headless.
- **G-2** Interaction V1 : raycast 2,5 m + E → `player_interacted(id, kind)` ; résolution méthode → metadata → `document_id` (« read ») → groupe `items` (« pickup ») ; `DocumentLibrary.mark_read()` sur une lecture ; `set_highlight()` si l'objet l'implémente.
- **G-6** Lampe : F, SpotLight 24°, 9 m, piles infinies, ombres.
- **G-7** Post-process : grain animé, vignette, aberration légère — instancié **une seule fois dans `player.tscn`**.
- **G-8** Présence simplifiée : scène autonome, apparaît sur `presence_state_changed(&"physical")`, avance à 0,45 m/s en ligne droite (groupe `player`), figée 4 s si photographiée (cône 32°, 25 m), contact ≤ 1,1 m → `player_caught` (une fois).
- **G-9** Interaction longue : `interact_duration` sur la cible → maintenir E, jauge `HUD/LongAction`, annulation au relâchement, `player_interacted(&"cellar_stove", &"burn")`.
- **G-10** `RoomSensor` : zones `Area3D` monitorables + `metadata/room_id` → `player_entered_room/left_room`, bascule entre zones chevauchées.
- **Tests** : `game/tests/player/player_tests.tscn` = **73 assertions headless, 0 échec** (lancement : `godot --headless --path game res://tests/player/player_tests.tscn`). Scènes validées seules : `player.tscn`, `test_room.tscn`, `presence.tscn`, `post_process.tscn`. `check.sh` vert avant chaque push.

**Ce qui reste**
1. **Validation visuelle** de la capture `SubViewport`, du shader de développement, du flash et du post-process : impossible sans rendu dans le sandbox. À vérifier en F5/F6 par l'Architecte (headless : capture désactivée, `texture = null`).
2. **Intégration Niveau** : `item.gd` réel (contrat + collider enfant obligatoire pour l'occlusion), zones de pièce avec `metadata/room_id`, poêle avec `interact_duration = 8.0`, instance de `presence.tscn` dans la cave.
3. **Options UI** : sensibilité souris et FOV sont des `@export` du joueur ; l'UI devra les piloter (via une demande à l'Architecte, pas d'API dédiée pour l'instant).
4. **V2 uniquement** : portes/tiroirs physiques à la souris, signature du registre, Présence à NavMesh, objets « photo_only ».
5. `min_photo_coverage = 0.15` (Narration) reste très exigeant pour les petits objets — demande déposée, non bloquante.

**Pièges connus**
1. Après ajout d'un `class_name`, lancer `godot --headless --path game --import` sinon `Could not find type "X"` (cache des classes globales).
2. Godot 4.7 du projet traite en **erreur** l'inférence depuis un `Variant` (`var x := f()` où `f() -> Variant`) : typer explicitement.
3. Ne pas revenir à `unproject_position` + `get_visible_rect()` pour la couverture : tailles incohérentes en headless (écart ×2,8 constaté) → `screen_math.gd` (espace caméra, fov + aspect).
4. `player.tscn` contient un sol de secours (`StandaloneFloor`) activé **seulement** si la scène est lancée seule ; le désactiver ne casse rien.
5. `Player`, `RoomSensor`, `PhotoDevice`, `PhotoInHand`, `Viewfinder`, `Interactor`, `Flashlight`, `Presence`, `PostProcess`, `ScreenMath`, `PhotoDetector`, `TestItem`, `InputActions` sont des noms de classes globaux : ne pas les redéfinir ailleurs.
6. La salle de test a un objet en (0, 0.45, 3.8) : toute Présence de test doit éviter l'axe x=0 (elle se bloque contre l'objet).
7. `game/data/strings/fr.fr.translation` est régénéré par `--import` : le restaurer (`git checkout --`), il n'est pas dans le périmètre Gameplay.
8. `AudioManager` est un stub : chaque son produit un `push_warning`, sans impact sur `check.sh`.
9. Ne pas doubler le post-process (un seul, dans `player.tscn`).

**Décisions prises seul (à valider)**
- La Présence vit dans `scenes/player/` (seul emplacement de mon périmètre) et lit le joueur via le groupe `player`.
- Le figeage 4 s est géré localement ; `presence_state_changed` reste la propriété de HouseDirector.
- Les conventions d'interaction passent par des **metadata** (`interact_id`, `interact_kind`, `interact_duration`, `document_id`) : zéro dépendance de script entre modules.
- Le son de la lampe utilise un id nouveau `flashlight_click` (demande Audio).

## Module Systèmes `[Systèmes]` — `autoloads/`, `scenes/main/`

| ID | Tâche | Jalon | Statut |
|---|---|---|---|
| S-1 | GameState complet + to/from_save_dict | M1 | TODO |
| S-2 | InventoryManager : chargement de `data/items/*.tres`, check/reveal/film, progression, signaux | M1 | DONE |
| S-3 | HouseDirector : moteur de règles (HouseRule), parser du mini-langage de condition, attention (montée/descente), actions (`move_item`, `event`, `attention`, `presence`, `sfx`) | M1 | DONE |
| S-4 | DocumentLibrary | M1 | TODO |
| S-5 | SaveManager : JSON, auto-save à `player_entered_room`, versionnage | M2 | DONE |
| S-6 | main.tscn : séquence de démarrage (menu → chargement maison → spawn joueur → UI), gestion des fins (`ending_reached` → scène de fin) | M2 | DONE |
| S-7 | Séquenceur d'actes : seuils 60/140 → `act_changed`, événements de fin d'acte | M2 | DONE |
| S-8 | Logique des 4 fins (conditions, déclenchement) | M3 | DONE |

### Notes Systèmes

- **Tests** (2026-10-17) — `game/scenes/main/test_systems.tscn` (scène de test autonome, 89 assertions, exit code CI) + suites gdUnit4 dans `game/tests/autoloads/` (parser, règles, inventaire) prêtes pour Q-1 : elles attendent l'installation de gdUnit4 (`tools/run_tests.sh` les ignorera jusque-là). Les cas de syntaxe invalide (push_error spéculés) sont dans `test_systems.tscn` pour ne pas faire échouer gdUnit4 sur les erreurs volontaires.

- **S-5** (2026-10-17) — SaveManager vérifié : JSON versionné (v1), auto-sauvegarde ajoutée sur `player_entered_room`, `save_requested` OK, chargement en dégradé si version différente. Aller-retour save/load couvert par `test_systems.tscn`. Limite connue : les déplacements d'objets (`item_moved`) déjà consommés par Niveau ne sont pas rejoués au chargement (les règles `room_left` passées ne se refirent pas) — à noter pour la V2 si besoin.
- **S-6** (2026-10-17) — `main.tscn` : menu (UI `main_menu.tscn` si présent, sinon placeholder `tr()` avec `UI_*`) → jeu (`house.tscn` + `player.tscn` + `hud.tscn`, chargés par chemin avec `push_warning` si absents) → fin (`ending_reached` → `ending_screen.tscn` ou placeholder `ENDING_*_TITLE`). Nouvelle partie réinitialise les autoloads (`from_save_dict({})`) ; Continuer charge la sauvegarde APRÈS instanciation maison/joueur (rattrapage `game_loaded`).
- **S-7** (2026-10-17) — Séquenceur V1 dans HouseDirector : seuils 20/45/60 → `act_changed` (phases calme/inquiétude/cave = act 1/2/3 sur le signal existant, pas de changement de contrat) + `house_event_triggered` en secours (`act1_drawer_opens`, `phone_rings`, `cellar_door_opens`) **dédoublonné avec les règles** (les règles r01/r03 portent ces événements ; le séquenceur ne les réémet pas s'ils le sont déjà). Rattrapage après `game_loaded`.
- **S-8** (2026-10-17) — 2 fins V1 : `closed` au 60e objet coché (+ ligne « 61. Camille » via `inventory_line_added(61, &"INV_LINE_ADDED_CAMILLE")`), `ashes` sur `player_interacted(&"cellar_stove", &"burn")`. Première fin gagne ; la ligne finale est supprimée après `ashes` (carnet brûlé).
- **S-3** (2026-10-17) — HouseDirector : parser complet (tous prédicats §6 + négation `!` universelle, `item_present:`, `presence:`, `&&`/`||`/parenthèses ; invalide = `push_error` + `false`), moteur de règles (9 triggers, 5 actions, `once`/`cooldown`, validation douce au chargement), attention (+3/flash, +6×bruit, −1.5/s après 20 s d'immobilité, valeurs calables), révélation des fantômes sur `document_read`/`item_checked`/`inventory_progress`/`player_entered_room`. Les 18 règles de `data/rules/` se chargent et se déclenchent. DocumentLibrary applique `sets_flags`/`reveals_items` au `mark_found` (demande Narration). Vérifié par `scenes/main/test_systems.tscn` (62 assertions).
- **S-2** (2026-10-17) — Chargement `data/items/` robuste (ids vides/dupliqués → erreur sans crash, tri par `list_index` dans `get_items_in_room`), garde-fous `check_item`/`reveal_item`/photo nulle. À toute la liste cochée : `inventory_line_added(total+1, &"INV_LINE_ADDED_CAMILLE")` (« 61. Camille », numéro sérialisé via `INV_LINE_FORMAT` côté UI).

### HANDOFF — Systèmes (session 1, 2026-10-17)

**Ce qui marche**
- S-2 InventoryManager : chargement `data/items/` (60 objets OK), check/reveal/film/progress, ligne finale `inventory_line_added(total+1, &"INV_LINE_ADDED_CAMILLE")` quand toute la liste est cochée (supprimée si une fin est déjà survenue).
- S-3 HouseDirector : parser mini-langage complet (§6 + négation `!` universelle, `item_present:`, `presence:`) — invalide = `push_error` + `false` ; moteur de règles (les 18 règles de `data/rules/` chargées et déclenchées : 9 triggers, 5 actions, `once`/`cooldown`) ; attention (flash +3, bruit +6×niveau, −1.5/s après 20 s d'immobilité) ; révélation des fantômes sur `document_read`/`item_checked`/`inventory_progress`/`player_entered_room`.
- S-7 séquenceur : seuils 20/45/60 → `act_changed` (act 1/2/3 = phases calme/inquiétude/cave) ; événements narratifs portés par les règles r01/r03, avec secours séquenceur **dédoublonné** (`act1_drawer_opens`, `phone_rings`, `cellar_door_opens`).
- S-8 fins : `closed` au 60e coche (+ ligne « 61. Camille »), `ashes` sur `player_interacted(&"cellar_stove", &"burn")` — première fin gagne.
- S-6 `main.tscn` : menu → `house.tscn` + `player.tscn` + `hud.tscn` → fin ; chaque scène absente = `push_warning` + dégradation (menu/fin placeholder avec `tr()`).
- S-5 SaveManager : auto-sauvegarde sur `player_entered_room`, JSON v1, aller-retour vérifié. DocumentLibrary applique `sets_flags`/`reveals_items` (demande Narration).
- Tests : `res://scenes/main/test_systems.tscn` — 89 assertions, tout vert, exit code 0/1 (`godot --headless --path game res://scenes/main/test_systems.tscn`). Suites gdUnit4 prêtes dans `game/tests/autoloads/` (parser, règles, inventaire) pour Q-1.

**Ce qui reste**
- Intégration J4 : côté Niveau (`house.gd` qui consomme `item_moved`/`item_revealed`/`house_event_triggered` ; ancres `hall_anchor_console`, `kitchen_anchor_sink`, `kitchen_anchor_preserves`, `living_anchor_fireplace`, `study_anchor_shelves`), Gameplay (pipeline photo → `photo_developed`, `player_interacted(cellar_stove, burn)`), UI (signaux du menu : `new_game_requested`, `continue_requested`, `options_requested`, `quit_requested` ; `ending_screen.tscn` + `set_ending_id`), Audio (ids sfx listés par Narration).
- Réglages d'attention à caler au playtest J5 (constantes en tête de `house_director.gd`).
- V2 : rejouer les déplacements d'objets au chargement (les règles `room_left` déjà passées ne se refirent pas) ; écran de fin complet côté UI.

**Pièges**
- Ne JAMAIS émettre `act1_drawer_opens`/`phone_rings`/`cellar_door_opens` ailleurs que par les règles ou le séquenceur (dédoublonnage en place, `_emit_event(id, only_if_new)`).
- `check.sh` échoue sur toute ligne `ERROR:` : ne pas évaluer de condition invalide au démarrage d'une scène de test normalisée (les erreurs volontaires vivent dans `test_systems.tscn`).
- Les clés strings de la ligne finale sont `INV_LINE_ADDED_CAMILLE` (prénom seul) + `INV_LINE_FORMAT` = `{index}. {name}` — le numéro 61 est sérialisé (`total + 1`), jamais figé.
- `register_rule` rejette silencieusement (warning) les règles à syntaxe de condition invalide : vérifier `data/rules/` si une règle ne part pas.

## Module Niveau `[Niveau]` — `scenes/house/`, `scenes/items/`, `assets/models|textures`

| ID | Tâche | Jalon | Statut |
|---|---|---|---|
| N-1 | Plan 2D de la maison (image dans docs/) validé par Architecte : 13 zones, cohérent avec GDD §5 | M1 | TODO |
| N-2 | Blockout entrée + bureau (CSG ou meshes gris), ancres Marker3D nommées, zones Area3D | M1 | TODO |
| N-3 | `house.tscn` + `house.gd` : instanciation des Items depuis InventoryManager, écoute `item_moved`, `item_revealed` | M1 | TODO |
| N-4 | `item.tscn` générique + `item.gd` (`is_in_frustum`, surbrillance, inspection) | M1 | TODO |
| N-5 | Blockout des 11 zones restantes | M2 | TODO |
| N-6 | Éclairage de base (lumière basse, fog volumétrique, budget ARCHITECTURE §8) | M2 | TODO |
| N-7 | Assets finaux : sourcing CC0/CC-BY (Poly Haven, Sketchfab, Kenney, ambientCG), import, matériaux, CREDITS.md | M4 | TODO |
| N-8 | Set-dressing final des 13 zones (1998 rural, voir GDD §8) | M4 | TODO |
| N-9 | Modèles des ~212 objets (assets libres, variantes par matériau, placeholders acceptés jusqu'à M4) | M3→M4 | TODO |
| N-10 | Extérieur : cour, 205, brouillard, appentis | M2 | TODO |

## Module Narration `[Narration]` — `data/`

| ID | Tâche | Jalon | Statut |
|---|---|---|---|
| R-1 | Liste maîtresse des 212 objets (tableur `docs/items_master.csv` : id, index, pièce, libellé 1973, fantôme ?, type, condition, lore) | M1 | DONE |
| R-2 | 20 ItemData de la vertical slice (entrée + bureau) en `.tres` + strings | M1 | DONE |
| R-3 | Documents de la vertical slice : post-it Besnard, inventaire 1973 (extrait), 2 lettres | M1 | DONE |
| R-4 | Tous les ItemData (212) | M3 | DONE |
| R-5 | Tous les documents (~45 : inventaires 1912/1951/1973, carnets de Lucienne ×8, dessins de Louis, lettres, formulaires, répondeur) | M3 | DONE |
| R-6 | Monologues de Camille (≤ 80 lignes, ≤ 12 mots chacune) + sous-titres | M3 | DONE |
| R-7 | Règles de maison (`data/rules/*.tres`) en coordination avec Systèmes : ~40 règles | M2→M3 | DONE |
| R-8 | Textes des 4 fins + génériques | M3 | DONE |
| R-9 | Recherche documentaire : formulaires notariaux 1912 / 1951 / 1973, vocabulaire, Morvan | M1 | DONE |


### Notes Narration (V1 Halloween)

- **2026-10-17 — R-1 DONE.** `docs/items_master.csv` : 60 lignes, 8 colonnes exactes (id, list_index, room_id, label_1973, is_phantom, phantom_kind, reveal_condition, lore). Répartition : extérieur 4 / entrée 10 / cuisine 16 / salon 14 / bureau 12 / cave 4.
  8 fantômes : 3 « personnes comptées » (`living_portrait_louis` Louis, `study_briefcase_jpd` Jean-Paul, `cellar_coat_emile` Émile) + 3 objets-messages (`kitchen_key_l` clé de la chambre de Louis, `hall_ring_1951` alliance gravée M. V., `study_blotter` buvard) + 2 photo_only (`hall_hand_railing`, `living_curtain_part`). Indices 1-60 ordonnés par pièce pour que le carnet se remplisse de haut en bas.
- **2026-10-17 — R-2 + R-4 DONE (livrés d'un bloc ; R-4 porte sur les 60 objets V1, pas les 212 de la V2).** Les 60 `ItemData` `.tres` sont dans `game/data/items/`, `scene` vide (Niveau), `anchors` vide (Niveau définit les noms). 125 clés `ITEM_<ID>_LABEL` / `ITEM_<ID>_LORE` dans `fr.csv`. Validation : ids/indices uniques, id = nom de fichier, clés présentes, fantômes tous conditionnés.
- **2026-10-17 — R-9 DONE (recherche minimale).** Vocabulaire notarial vérifié : procès-verbal de description, prisée, succession vacante, actif/charges, sceau, liasse, minute, expédition, clerc de notaire, étude. Sources citées dans ce fichier (voir bloc Sources en fin de module). Pas de copie de formulaire réel : formulaires reconstitués, mentions plausibles 1912/1951/1973 (dactylographie, cachet sec, en-tête « Étude de Maître … », article de loi non cité nommément — décision : rester allusif pour éviter tout faux).

- **2026-10-17 — R-3 + R-5 DONE.** Les 10 documents de la V1 sont dans `game/data/documents/` (10 `.tres`) avec `DOC_<ID>_TITLE` / `DOC_<ID>_BODY` dans `fr.csv` : post-it Besnard, inventaire 1973 (60 lignes générées depuis la liste maîtresse + page détachée « 181. Jean-Paul » rayée), 3 lettres de Lucienne (1976 à Louis / 1998 au prochain clerc / 1953 sur la vraie Madeleine), photo de famille annotée (4 personnes, 5 noms), cassette du répondeur 1973 (transcription), registre 1847, lettre de Besnard, dernière page de l'inventaire 1912 d'Émile Ferrand.
  Corps écrits en une seule clé avec `\n` (l'importeur Godot `unescape_translations=true` les rend en vrais retours à la ligne) et BBCode `[i]`/`[b]` pour les annotations manuscrites. `sets_flags` et `reveals_items` renseignés ; ils supposent que DocumentLibrary les applique (voir demande).
- **2026-10-17 — R-7 DONE.** 18 `HouseRule` dans `game/data/rules/` + `README.md` (tableau des règles, ancres attendues, événements, sons). Seuils respectés : tiroir à 20, horloge à 30, téléphone + trappe à 45, Présence à 52 dans la cave (8 objets restants). 4 règles de déplacement d'objets non photographiés utilisent `!item_checked:<id>` — **non documenté dans ARCHITECTURE §6**, demande déposée ; si le parser ne le gère pas, la règle ne s'exécute pas et le jeu reste finissable.
- **2026-10-17 — R-8 DONE.** Textes des 2 fins : `ENDING_CLOSED_*` (Inventaire clos, « 61. Camille » sérialisé via `ENDING_CLOSED_LINE_NAME` + `INV_LINE_FORMAT`) et `ENDING_ASHES_*` (Cendres, poêle de la cave conformément au PLAN §2 — le STORY_BIBLE parle de la cheminée du salon, le PLAN prime). Phrase finale de Cendres : « 1. Volant, cuir, usé ».
- **2026-10-17 — R-6 DONE.** 30 sous-titres ≤ 12 mots dans `fr.csv` (`SUB_*`) + `game/data/strings/subtitles.md` (clé, durée calculée à 14 car./s, contexte d'émission) pour l'UI et l'Audio.

- **2026-10-17 — Relecture des 10 documents (session 2).** Relus à voix haute et corrigés dans `fr.csv` (4 lignes touchées, aucun libellé d'inventaire modifié) : transcription de 1973 « reconstituée après la destruction de la minute », cycle de Lucienne « à chaque génération » (1912/1951/1973/1998 n'est pas trentenaire), Louis « treize ans » sur la photo de 1951 (né en 1938, STORY_BIBLE §2), lettre de Besnard « plus loin que la liste ». `docs/itch_textes.md` : les 5 captures de texte pour itch.io, mot pour mot, avec accroche, ordre et légendes.
  Point de canon signalé (non bloquant V1) : la photo datée « été 1951 » nomme Madeleine à la maison alors que STORY_BIBLE §2 la dit internée depuis 1946. Laissé tel quel — l'annotation peut être un mensonge de Lucienne, et le jeu ne donne pas la date d'internement. À trancher par l'Architecte avant la V2.
- **2026-10-17 — Narration en mode disponible.** Priorité V1 terminée et intégrée (branche réalignée sur `22037e8`). En attente : retours de playtest J5 sur les textes, demandes ponctuelles des autres modules (libellés, sous-titres, légendes). Aucune tâche R bloquante en cours.

**Sources R-9 (consultées le 17 oct. 2026, usage : vocabulaire et ordre des opérations uniquement, aucun formulaire reproduit)**
- Notaires de Paris — « Succession : en pratique, comment se déroule un inventaire ? » (description pièce par pièce, « prisée ») : https://paris.notaires.fr/fr/actualites/succession-en-pratique-comment-se-deroule-un-inventaire
- Légifrance — Code civil, art. 809 et suivants (succession vacante, curatelle, inventaire estimatif article par article) : https://www.legifrance.gouv.fr/codes/section_lc/LEGITEXT000006070721/LEGISCTA000006136274/
- Légifrance — Code civil, art. 730 et suivants (acte de notoriété) : https://www.legifrance.gouv.fr/codes/id/LEGISCTA000006165514
- LexisNexis — « Inventaire : mesures conservatoires après décès » (procès-verbal, minute, expédition, apposition des scellés) : https://www.lexisnexis.com/blogs/fr-juridique/b/droit-notarial/posts/synthese-inventaire-mesures-conservatoires-apres-deces
- DGFiP — « Successions vacantes : le notaire, partenaire du Domaine » (délai de six mois, constat de vacance) : https://www.impots.gouv.fr/sites/default/files/media/3_Documentation/depliants/parte_successions_vacantes_notaire_partenaire_domaine.pdf

### HANDOFF — Narration & Contenu (17 oct. 2026, fin de session 1)

**Ce qui marche**
- `docs/items_master.csv` : **60 objets** (4 extérieur / 10 entrée / 16 cuisine / 14 salon / 12 bureau / 4 cave), 8 fantômes, 8 colonnes exactes. C'est la source de vérité : tout le reste est dérivé de ce fichier.
- `game/data/items/` : **60 `.tres` ItemData** valides, `scene` et `anchors` vides (Niveau). Un `.tres` par id, `id = nom de fichier`, indices 1-60 uniques.
- `game/data/documents/` : **10 `.tres` DocumentData** (post-it Besnard, inventaire 1973 + page « 181. Jean-Paul », 3 lettres de Lucienne, photo de famille, cassette répondeur 1973, registre 1847, lettre Besnard, inventaire 1912). `sets_flags` et `reveals_items` renseignés.
- `game/data/rules/` : **18 HouseRule** + `README.md` (tableau, ancres attendues, événements, sons). Seuils 20 / 30 / 45 / 52.
- `game/data/strings/fr.csv` : **192 clés** (`UI_*` préservées, `ITEM_*` 120, `DOC_*` 20, `SUB_*` 30, `ENDING_*` 15, `INV_*` 2). Aucun point d'exclamation dans tout le contenu.
- `game/data/strings/subtitles.md` : 30 sous-titres avec durée (14 car./s) et contexte d'émission.
- `check.sh` vert après chaque commit ; deux pushs sur `agent/narration` (`d3f2dee`, `35c6908`). Validation data faite hors `tools/` : 0 id/indice dupliqué, 0 clé manquante, 0 condition pointant un document inexistant.

**Ce qui reste (V1)**
- Rien de bloquant côté contenu : les 9 tâches R sont livrées pour le périmètre 60 objets / 10 documents. Reste à **valider la liste maîtresse** (Architecte) puis à **intégrer** : charges Systèmes (règles + flags) et Niveau (ancres) ci-dessous.
- Si le planning glisse : les 3 lettres de Lucienne peuvent être réduites à 1, et les 8 règles de déplacement à 4, sans casser la fin.
- V2 : les 212 objets, les 32 fantômes, les 45 documents et les fins Gardienne/Quatre ne sont **pas** commencés (hors périmètre Halloween).

**Pièges connus**
1. **`fr.csv` n'est pas enregistré dans `project.godot`** (`locale/translations` vide) : `tr()` renvoie les clés. Le `.translation` se génère bien à l'import ; il manque une ligne côté Architecte. Tant que ce n'est pas fait, l'UI affichera `ITEM_KITCHEN_CLOCK_STOPPED_LABEL` à l'écran.
2. **Qui révèle les fantômes ?** `ItemData.reveal_condition` n'est évalué par personne dans les stubs. Proposition : HouseDirector sur `doc_read` / `progress` / `item_checked`. Tant que ce n'est pas tranché, les fantômes n'apparaissent pas — le jeu reste finissable sur 52 objets réels (la Présence et les fins ne dépendent pas d'eux).
3. **`!item_checked:<id>`** est utilisé par 4 règles de déplacement mais **n'est pas dans ARCHITECTURE §6**. Si le parser le rejette, ces règles ne tirent pas : aucun crash, mais la maison ne bouge plus les objets non photographiés.
4. **Ne jamais renommer un `item_id`** : il est le nom du `.tres`, l'ancre future, la clé `fr.csv` et la cible des conditions. Un renommage = 4 fichiers à reprendre à la main.
5. Les corps de documents sont **une seule clé** contenant des `\n` et du BBCode `[i]`/`[b]` : la visionneuse UI doit rendre le BBCode, sinon les annotations manuscrites s'affichent en clair. `pages` n'est qu'indicatif.
6. L'inventaire 1973 est **généré depuis la liste maîtresse** : si un libellé change dans le CSV, il faut régénérer le document (les deux doivent rester mot pour mot identiques, c'est le principe de l'énigme).

**Décisions prises seul (à valider)**
- La fin *Inventaire clos* écrit **« 61. Camille »** (PLAN §2), pas 213 : numéro sérialisé via `INV_LINE_FORMAT`, jamais figé.
- La fin *Cendres* se joue au **poêle de la cave** (PLAN §2), pas à la cheminée du salon (STORY_BIBLE §5).
- Les 8 fantômes = 3 personnes comptées + 3 objets-messages + 2 photo_only. Aucun `phantom_kind = "moved"` en V1 (les déplacements sont déjà couverts par les règles).
- Le fantôme `hall_ring_1951` est une alliance gravée « M. V. » : c'est un objet-message de Lucienne, pas une personne comptée.

### HANDOFF — Narration & Contenu (17 oct. 2026, session 2, mode disponible)

- **Fait** : branche réalignée sur `origin/agent/narration` (`22037e8`, intégration Architecte). Relecture complète des 10 documents, 5 micro-corrections de cohérence dans `fr.csv` (voir note ci-dessus), `check.sh` vert, `fr.fr.translation` régénérée. `docs/itch_textes.md` livré : 5 captures de texte mot pour mot (post-it, registre 1847, photo annotée, cassette 1973, inventaire 1912) + accroche Lucienne, prêtes pour la page itch.io (J13).
- **Reste** : rien de bloquant. Narration **disponible** pour les retours de playtest et les demandes ponctuelles (textes d'interface, légendes, sous-titres additionnels).
- **À trancher (Architecte, non bloquant)** : photo « été 1951 » nommant Madeleine à la maison contre STORY_BIBLE §2 (internée depuis 1946). Laissé comme possible mensonge d'annotation ; décision requise seulement pour la V2.
- **Piège inchangé** : toute modification d'un libellé de `docs/items_master.csv` impose de régénérer le corps de l'inventaire 1973, et toute capture itch.io faite avant le 17/10 au soir est périmée pour la photo.

## Module UI `[UI]` — `scenes/ui/`, `assets/fonts`

| ID | Tâche | Jalon | Statut |
|---|---|---|---|
| U-1 | Carnet 3D en main : ouverture/fermeture, pages, onglets (liste / photos / documents / plan) | M1 | TODO |
| U-2 | Liste d'inventaire : 212 lignes par pièce, coche animée, lignes « ajoutées » (écriture qui apparaît) | M1 | TODO |
| U-3 | Visionneuse de photo (en main + dans le carnet) | M1 | TODO |
| U-4 | HUD minimal : compteur de films sur l'appareil, réticule contextuel discret | M1 | TODO |
| U-5 | Lecture de document (papier en main, pages, BBCode, typo machine/manuscrite) | M1 | TODO |
| U-6 | Menu principal (205 dans le brouillard), pause, options (sensibilité, FOV, sous-titres, accessibilité, remapping) | M2 | TODO |
| U-7 | Sous-titres (`subtitle_requested`) | M2 | TODO |
| U-8 | Écrans de fin, générique | M3 | TODO |
| U-9 | Polices libres (machine à écrire, manuscrite, UI) + CREDITS | M1 | TODO |

## Module Audio `[Audio]` — `autoloads/audio_manager.gd`, `assets/audio`

| ID | Tâche | Jalon | Statut |
|---|---|---|---|
| D-1 | AudioManager : bus (Master/SFX/Ambiance/Music/UI), one-shots 3D, couches de soundscape, musique | M1 | TODO |
| D-2 | Sons de l'appareil photo (le plus important du jeu) : déclencheur, moteur, flash charge, photo qui sort | M1 | TODO |
| D-3 | Pas par matériau (bois, carrelage, moquette, gravier), souffle, sac | M1 | TODO |
| D-4 | Soundscape maison (3 couches × intensité) + extérieur | M2 | TODO |
| D-5 | Banque « sons domestiques au mauvais endroit » pour la Présence (~25) | M2 | TODO |
| D-6 | 3 morceaux (piano salon, fin acte 2, générique) — libres de droits ou générés | M4 | TODO |
| D-7 | Voix de Camille (TTS qualité ou comédienne) — après R-6 | M4 | TODO |
| D-8 | Mixage final, CREDITS | M4 | TODO |

## Module QA / Intégration `[QA]` — `tests/`, `tools/`, branche `main`

| ID | Tâche | Jalon | Statut |
|---|---|---|---|
| Q-1 | Installer gdUnit4, `tools/run_tests.sh` headless, CI GitHub Actions (tests + export) | M0 | TODO |
| Q-2 | `tools/validate_data.gd` : vérifie que les 212 ids sont uniques, les ancres existent, les clés de strings existent, les conditions parsent | M1 | TODO |
| Q-3 | Tests du parser de conditions HouseDirector (≥ 30 cas) | M1 | TODO |
| Q-4 | Tests InventoryManager (check, reveal, films, save/load) | M1 | TODO |
| Q-5 | Playtest M1 + rapport (`docs/playtests/M1.md`) | M1 | TODO |
| Q-6 | Merge des branches agents → main, résolution des conflits | continu | TODO |
| Q-7 | Profilage perf (budgets ARCHITECTURE §8) | M2, M4 | TODO |
| Q-8 | Exports Win/Linux/Mac, page itch.io | M5 | TODO |

---

## Demandes inter-modules

> Format : `[De → Vers] (date) Description. — Statut`

- `[Narration → Architecte]` (2026-10-17) `game/data/strings/fr.csv` **n'est pas enregistré** dans `project.godot` (`locale/translations=PackedStringArray()` vide) : `tr()` renverra les clés brutes. Le `.import` du CSV génère bien `fr.fr.translation`. Il faut ajouter `res://data/strings/fr.fr.translation` dans `internationalization/locale/translations`. Hors périmètre Narration. — **DONE** (Architecte, 17/10 : enregistré, tr() vérifié headless)
- `[Narration → Systèmes]` (2026-10-17) **Qui évalue `ItemData.reveal_condition` ?** ARCHITECTURE §6 la définit mais aucune API ne la traite : `InventoryManager.reveal_item()` est appelé sans condition. Proposition : HouseDirector évalue toutes les `reveal_condition` des fantômes non révélés sur les triggers `doc_read`, `progress`, `item_checked` et `act_changed`, et appelle `InventoryManager.reveal_item()`. En attendant, aucun fantôme n'apparaît : le jeu reste finissable sur 52 objets réels. — **TRANCHÉ (Architecte)** : oui, HouseDirector évalue les `reveal_condition` (ARCHITECTURE §6 mis à jour, paragraphe « Révélation »). Tâche S-3 pour Systèmes.
- `[Narration → Systèmes]` (2026-10-17) **Seuil de la cave.** PLAN_HALLOWEEN §2 dit « à 45 objets : le téléphone sonne, la trappe s'ouvre » et « les 8 derniers objets » se trouvent dans la cave. Avec la répartition validée (cave = 4 objets réels), il reste 8 objets au moment où il en manque 8 **si** 52 sont cochés (56 réels + 8 fantômes = 60, donc 52 cochés = 4 réels + 4 fantômes restants). Je livre les règles à `progress 45` (téléphone/répondeur, trappe) conformément au PLAN, et je **ne change pas** la répartition. La règle `cellar_door` reste à 45. — POUR INFO
- `[Narration → Systèmes]` (2026-10-17) **DocumentLibrary doit appliquer les données.** Sur `mark_found()` : appliquer `DocumentData.sets_flags` (`GameState.set_flag`) et `DocumentData.reveals_items` (`InventoryManager.reveal_item`). Le stub actuel ne le fait pas ; sinon 5 fantômes ne se révèlent que par `reveal_condition`.
- `[Narration → Systèmes]` (2026-10-17) **Chargement des règles.** Personne ne charge `res://data/rules/*.tres` aujourd'hui : il faut un `_ready()` dans HouseDirector qui instancie et `register_rule()` chaque `.tres` (18 fichiers V1). Prévu en S-3 normalement — je le note pour ne pas l'oublier.
- `[Narration → Systèmes]` (2026-10-17) **Négation `!item_checked:<id>` demandée.** ARCHITECTURE §6 ne documente que `!flag:<nom>`. Quatre règles de déplacement en dépendent (`r07` à `r10`, plus `r11`). Si vous refusez, dites-le et je convertirai en règles `flagged` déclenchées par un compteur `GameState.add_counter`.
- `[Systèmes → UI]` (2026-10-17) **Protocole main ↔ menu/écrans.** `main.tscn` charge `res://scenes/ui/main_menu.tscn` (menu principal), `res://scenes/ui/hud.tscn` (HUD en jeu), `res://scenes/ui/ending_screen.tscn` (écrans de fin). Si la racine de `main_menu.tscn` expose les signaux `new_game_requested()`, `continue_requested()`, `options_requested()`, `quit_requested()`, main les connecte automatiquement ; sinon menu placeholder utilisé (dégradation). `ending_screen.tscn` peut exposer `set_ending_id(id: StringName)` pour connaître la fin (`closed`/`ashes`). — EN COURS

**Réponses Systèmes (2026-10-17, S-3)** aux demandes Narration : révélation des fantômes par HouseDirector **OK** ; chargement `data/rules/` + `register_rule()` **OK** ; DocumentLibrary applique `sets_flags`/`reveals_items` **OK** ; négation `!item_checked:` **OK** (et `!` sur tout prédicat). Le séquenceur (S-7) respecte les seuils de règles 20/30/45/52 (événements narratifs portés par les règles) et pilote `act_changed` sur 20/45 (phases V1) + fin à 60.

- `[Narration → Audio]` (2026-10-17) **Ids SFX utilisés par les règles V1** (à exister, sinon AudioManager dégrade) : `drawer_open`, `clock_chime_distant`, `phone_ring`, `breath_low`, `door_close_upstairs`, `paper_turn`, `chair_drag_upstairs`, `hall_light_out`, `cellar_light_flicker`, `upstairs_chair`, `footsteps_above`. Un seul `play_sfx` par id.
- `[Narration → Niveau]` (2026-10-17) **Ancres exigées par les règles** (en plus de la convention `a_<item>` du README des règles) : `hall_anchor_console`, `kitchen_anchor_sink`, `kitchen_anchor_preserves`, `living_anchor_fireplace`, `study_anchor_shelves`. Un `move_item` vers une ancre absente doit être ignoré avec `push_error`, jamais planter.
- `[Narration → UI]` (2026-10-17) **Sous-titres et fins.** Clés `SUB_*` (30) : `EventBus.subtitle_requested.emit(&"...", durée)` — durées fournies dans `game/data/strings/subtitles.md`. Écrans de fin : `ENDING_CLOSED_*` / `ENDING_ASHES_*` ; la dernière ligne de chaque fin est séparée (`..._LINE_NAME`) pour être composée comme une ligne d'inventaire via `INV_LINE_FORMAT`. Corps BBCode (`[i]`, `[b]`).
- `[Narration → Niveau]` (2026-10-17) **Ancres.** Les 60 `ItemData.anchors` sont vides et `scene` est vide : c'est Niveau qui fournit les `Marker3D`. Proposition de convention (à documenter dans `docs/anchors.md`) : `a_<item_id sans préfixe de pièce>` (ex. `a_clock_stopped` pour `kitchen_clock_stopped`), et pour les objets déplacés par les règles, les ancres citées dans `data/rules/*.tres` sont : `living_anchor_fireplace`, `study_anchor_desk`, `hall_anchor_console`, `kitchen_anchor_table`, `cellar_anchor_shelves`. Liste exacte dans les `.tres` de règles. — À FAIRE (Niveau)
- `[Narration → UI]` (2026-10-17) **Ligne « 61. Camille ».** Le numéro est **sérialisé** (`InventoryManager.progress().x`) et non figé : je livre `INV_LINE_ADDED_CAMILLE` = `Camille` (sans numéro) et `INV_LINE_FORMAT` = `{index}. {name}`. Le carnet affiche via `inventory_line_added(line_index, text_key)`. — POUR INFO
- `[Narration → Systèmes]` (2026-10-17) **Ids de documents** référencés par les `reveal_condition` et les règles (à créer par R-3/R-5, contrats à respecter) : `hall_postit_besnard`, `study_inventory_1973`, `study_letter_besnard`, `kitchen_letter_lucienne_1`, `kitchen_letter_lucienne_2`, `living_letter_lucienne_3`, `living_photo_family`, `hall_tape_1973`, `cellar_register_1847`, `study_deed_1912`. — POUR INFO

- `[Architecte → Systèmes]` (17/10) Le parser de conditions doit supporter la **négation `!` sur tout prédicat** (`!item_checked:id`, utilisé par 4 règles) + `item_present:id` et `presence:state`. Seuils réels des règles : **20 / 30 / 45 / 52** (lire `game/data/rules/README.md`). — **DONE** (Systèmes S-3 : négation universelle + `item_present:` + `presence:` supportés ; seuils lus dans `data/rules/`)
- `[Architecte → UI]` (17/10) Les corps de documents (`body_key`) contiennent `\n` et du BBCode `[i]`/`[b]` : visionneuse = RichTextLabel avec bbcode_enabled. `pages` indicatif. — TODO
- `[Architecte → Niveau]` (17/10) Les 60 `item_id` de `docs/items_master.csv` sont **définitifs** : ne jamais renommer. Remplir `scene` et `anchors` de chaque ItemData (seuls champs autorisés pour Niveau dans data/items/), créer les ancres dans les rooms. Objet interactif `cellar_stove` dans la cave (fin Cendres). — TODO
- `[Architecte → Gameplay]` (17/10) L'interaction longue « brûler » cible `cellar_stove` et émet `player_interacted(&"cellar_stove", &"burn")`. — TODO

- `[Narration → Architecte]` (17/10) Photo « été 1951 » nomme Madeleine à la maison alors qu'elle est internée depuis 1946. — **TRANCHÉ** : on garde. C'est Lucienne qui a annoté la photo après avoir pris l'identité : l'annotation est le premier mensonge. Cohérent et plus fort. À exploiter en V2.
- `[Gameplay → Niveau]` (2026-10-17) **Zones de pièce.** Chaque pièce doit contenir une `Area3D` **monitorable** avec `metadata/room_id` (StringName, ex. `&"kitchen"`) couvrant la pièce — `collision_layer` 4 de préférence (le capteur du joueur teste les layers 1 et 3/bits 1 et 4). C'est le Gameplay qui émet `player_entered_room/left_room` ; le Niveau n'émet rien. Zone sans `room_id` = ignorée en silence.
- `[Gameplay → Niveau]` (2026-10-17) **Contrat Item / occlusion.** La détection photo s'appuie uniquement sur : groupe `items`, `data: ItemData`, `is_in_frustum(cam) -> float` (0..1). Pour l'occlusion, le Gameplay cherche les `CollisionObject3D` **enfants de l'Item** : sans collider, pas de test d'occlusion (l'objet reste photographiable à travers un mur). Merci de donner à chaque Item un collider enfant. `ItemData.scene` étant vide, mes scènes de test utilisent des boîtes grises.
- `[Gameplay → Narration]` (2026-10-17) **`min_photo_coverage = 0.15` est très exigeant** : en 1080p / FOV 75, un objet de 1 m de côté doit être cadré à ≈ 1,3 m pour occuper 15 % de l'écran (un objet de 0,5 m à 3 m ≈ 0,7 %). Sauf si le Niveau fournit des boîtes de cadrage généreuses, je recommande 0,03–0,06 pour les petits objets (horloge, alliance, cachet). Je respecte la donnée en attendant.
- `[Gameplay → Audio]` (2026-10-17) **Ids SFX utilisés par l'appareil photo** (à faire exister, sinon AudioManager dégrade) : `camera_raise`, `camera_shutter`, `camera_flash`, `photo_slide`, `camera_dry`. Les pas sont signalés par `EventBus.player_noise(level, pos)` (0,25 marche / 0,85 course) toutes les 0,72 m (marche) / 1,05 m (course) — utilisable pour D-3.
- `[Gameplay → UI]` (2026-10-17) **Actions InputMap réservées** (définies dans `project.godot`) : `move_*`, `sprint`, `crouch`, `interact`, `flashlight`, `camera_raise`, `camera_shoot`, `photo_review`, `notebook` (Tab), `pause` (Échap). L'UI doit écouter ces **actions**, jamais les touches brutes. Le joueur capture la souris ; sur pause, émettre `pause_toggled(true)` pour qu'il la relâche.

- `[Gameplay → Niveau]` (2026-10-17) **Poêle de la cave (fin Cendres).** Poser sur le nœud du poêle : `metadata/interact_id = &"cellar_stove"`, `metadata/interact_kind = &"burn"`, `metadata/interact_duration = 8.0`. C'est la convention lue par `interactor.gd` ; sans elle, l'interaction longue n'existe pas (aucun crash).
- `[Gameplay → Niveau]` (2026-10-17) **Présence.** Instancier `res://scenes/player/presence.tscn` dans la cave (à un `Marker3D` de votre choix). Elle reste invisible tant que `HouseDirector` n'émet pas `presence_state_changed(&"physical")`. Ne pas déplacer le nœud pendant la partie : il avance seul vers le joueur.
- `[Gameplay → UI]` (2026-10-17) **Jauge d'interaction longue.** `player.tscn` contient `HUD/LongAction` (`ProgressBar` sans texte, masquée) : c'est le retour visuel des 8 s de « brûler ». L'UI n'a rien à faire, mais ne pas créer d'autre barre pour ce flux.
- `[Gameplay → Audio]` (2026-10-17) **Id SFX supplémentaire** : `flashlight_click` (bascule F). Rappel des ids appareil : `camera_raise`, `camera_shutter`, `camera_flash`, `photo_slide`, `camera_dry`.
- `[Gameplay → Systèmes]` (2026-10-17) **Flux Présence.** `player_caught` est émis une seule fois au contact (≤ 1,1 m). Le figeage 4 s est géré localement par la Présence ; `presence_state_changed` reste émis uniquement par `HouseDirector`. La Présence lit la position du joueur via le groupe `player` (convention), pas via un chemin de nœud.
- `[Gameplay → Architecte]` (2026-10-17) **Post-process unique.** `player.tscn` instancie `scenes/fx/post_process.tscn` (CanvasLayer 3). Si `main.tscn` en ajoute un second, le grain et la vignette seront doublés. Les réglages (grain, vignette, aberration, assombrissement) sont des `@export` sur le nœud `PostProcess`.

- `[Architecte → tous]` (17/10) **Décisions sur les demandes Gameplay** : (a) `min_photo_coverage` par défaut passe de 0.15 à **0.04** dans `ItemData` (les 60 .tres mis à jour mécaniquement par l'Architecte ; `hall_ring_1951` et `kitchen_key_l` à 0.01 car très petits — Narration : ajuster au cas par cas si besoin). (b) **Options** : nouveau signal `EventBus.settings_changed(key, value)` (ARCHITECTURE §4 et §7) — UI émet, Player/Audio écoutent. (c) **Post-process unique** dans player.tscn : Systèmes, `main.tscn` n'en ajoute pas. (d) Présence dans `scenes/player/` : validé. (e) Conventions metadata d'interaction et zones de pièce : officialisées dans ARCHITECTURE §7. — DONE
- `[Architecte → Systèmes]` (17/10) `main.tscn` : instancier `res://scenes/player/player.tscn` (pas de post-process supplémentaire), puis `house.tscn` dès que Niveau livre ; au démarrage appeler l'application des réglages UI (voir ARCHITECTURE §7 Options). Écouter `player_caught` → téléporter le joueur à l'entrée + cocher un objet aléatoire non coché (GDD §4.4). — TODO
- `[Architecte → Audio]` (17/10) Ids SFX à faire exister en priorité : `camera_raise`, `camera_shutter`, `camera_flash`, `photo_slide`, `flashlight_click` (+ ceux listés par Gameplay ci-dessus). — TODO

- `[Gameplay → UI]` (2026-10-17, session 2) **Format des réglages consommés par le joueur** (`EventBus.settings_changed`) : `mouse_sensitivity` = **normalisé 0..1** (défaut recommandé 0,15 ; toute valeur < 0,02 est interprétée comme des rad/px bruts), `fov` = degrés bornés 55..110 (défaut 75), `flashlight_strong` = bool (défaut false). Les autres clés (`volume_*`, `subtitles`, `fullscreen`) sont ignorées en silence par le joueur — aucune erreur si l'UI en ajoute. Rappel : l'UI doit émettre chaque clé une fois au démarrage (ARCHITECTURE §7), **après l'instanciation du joueur** (un `call_deferred` suffit) — sinon le joueur garde ses valeurs par défaut ; en complément, réémettre sur `game_loaded` couvre le chargement d'une partie.
- `[Architecte → Gameplay]` (17/10, playtest utilisateur) **Bug Échap** : la touche Échap n'affiche pas la souris. Attendu : Échap bascule `Input.mouse_mode` CAPTURED ↔ VISIBLE **et** émet `pause_toggled`. Le reste du feeling (flash, développement, déplacements, grain) validé par l'utilisateur en F6 sur `test_room.tscn` : « tout marche ». — TODO
- `[Architecte → Niveau]` (17/10) **Noms d'ancres déjà référencés par les règles de Narration** (doivent exister dans les rooms, sinon `item_moved` est ignoré) : `hall_anchor_console`, `kitchen_anchor_preserves`, `kitchen_anchor_sink`, `living_anchor_fireplace`, `study_anchor_shelves`. Convention : `<room>_anchor_<nom>`. Les autres ancres (position initiale des 60 objets) sont à ton choix, à documenter dans `docs/anchors.md` et à écrire dans `ItemData.anchors[0]`. — TODO
- `[Architecte → UI]` (17/10) Systèmes a documenté le protocole menu ↔ main dans `docs/TASKS.md` (section Systèmes) : signaux `new_game_requested`, `continue_requested`, `options_requested`, `quit_requested` sur `scenes/ui/main_menu.tscn`, `scenes/ui/hud.tscn`, `scenes/ui/ending_screen.tscn` avec `set_ending_id(id)`. Respecter ces noms. — TODO

## Journal des décisions

- 2026-10-17 — Moteur : **Godot 4.x**, GDScript, Forward+. (Architecte, validé utilisateur)
- 2026-10-17 — Concept : **État des lieux** validé.
- 2026-10-17 — **Sortie visée : 30-31 octobre 2026.** Périmètre réduit « Rez-de-chaussée » (docs/PLAN_HALLOWEEN.md). Version complète = V2 2027.
- 2026-10-17 — Godot **4.7.2**. L'Architecte assure l'intégration (merge main + check headless) ; pas d'agent QA séparé en V1.
