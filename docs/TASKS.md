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
| A0-21 | **Outil de captures d'écran logiciel** (`tools/shots.sh`, Xvfb + Mesa) : les agents voient le rendu. Baseline dans docs/shots/ | DONE |
| A0-20 | Hygiène débogueur (retour utilisateur) : erreur meta surface par pas, suites gdUnit4 hors parse, unused_signal | DONE |
| A0-19 | Intégration U-11 (file sous-titres), SUB_DAWN, S-10 (fin Cendres, triggers item_moved/ending) ; arbitrages file | DONE |
| A0-18 | Intégration vague « lisibilité » (S-9/U-10/G-11/R-10) ; file sous-titres, fin Cendres, triggers item_moved/ending | DONE |
| A0-17 | Playtest J4 → diagnostic lisibilité, contrat §7 « Lisibilité », action `subtitle:`, tâches S-9/U-10/R-10/N-9/G-11 | DONE |
| A0-16 | Intégration Niveau S2/S3 : éclairage de jeu, 6 zones, 60 objets instanciés, hotfix retiré proprement (104 tests) — **M2 « maison complète » atteint J4** | DONE |
| A0-15 | HOTFIX playtest J1 : PlayerSpawn, TempBlockers, lumières en jeu ; contrat §7 complété | DONE |
| A0-14 | Intégration Audio S1 (67 OGG, 52 ids, AudioManager complet) — les 6 modules ont livré leur priorité V1 en J1 | DONE |
| A0-13 | Intégration Niveau S1 (hall/bureau/cave, 47 tests) + Systèmes S3 + Gameplay S3 + UI S2 — 372 assertions vertes | DONE |
| A0-12 | Intégration UI S1 (92 tests) + Systèmes S2 + Gameplay S2 ; signal interact_target_changed ; API all_items | DONE |
| A0-11 | Validation N-1 (plan maison) + consignes dimensions/ancres | DONE |
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
| G-11 | Cible d'interaction : `interact_target_changed` émis aussi pour les `Item` (contrat), liseré `set_highlight()` sur l'objet visé, robustesse aux instances libérées | M1 | DONE |

### Notes Gameplay (V1 Halloween)

- **2026-10-17 — Socle.** `[input]` ajouté à `project.godot` (13 actions, physical_keycode : ZQSD+WASD, Maj, Ctrl/C, E, F, clic droit/gauche, P, Tab, Échap). Filet de sécurité `scenes/player/input_actions.gd` : recrée les actions manquantes à l'exécution (si fusion/porte). `player.tscn` (CharacterBody3D + caméra) et `scenes/player/test_room.tscn` (sol, 3 Item placeholders, zone de pièce, occluder) se lancent seuls. Test item : `tests/player/test_item.gd` (contrat `Item` respecté).
- **2026-10-17 — G-1 DONE.** `player.gd` : marche 2,5 / course 4,0 m/s (accél. 14), accroupi maintenu (capsule 1,75 → 1,10 m), essoufflement (18/s, récup. 30), head-bob + pas → `player_noise` (0,25 marche / 0,85 course), pas de saut, souris capturée, `pause_toggled` respecté, retour auto si chute. Vérifié : 38 assertions headless (`tests/player/player_tests.tscn`, 0 échec).
- **2026-10-17 — G-11 (session 5) : cible Item vérifiée sur le vrai `item.tscn`.** Le contrat `Item` du Niveau (`get_interact_id()/get_interact_kind()/get_interact_duration()`) est résolu en premier : un Item visé émet bien `interact_target_changed(id, &"pickup")`, et `set_highlight(true/false)` est appelé sur le nœud Item (liseré `Highlight`, alpha 0,22, pas de néon). Test d'intégration avec `item.tscn` réel : visée → signal + liseré, regard détourné → `(&"", &"")` + liseré retiré, retour → rallumé, Item libéré → cible vidée sans erreur.
  **Piège Godot 4 corrigé** : une référence libérée se compare comme `null` (`described_node == _target` devenait vrai) **et** ne peut pas être passée en argument typé `Node` (« previously freed … not a subclass ») → garde `is_instance_valid()` avant l'appel, paramètre `Object`. Le liseré est aussi retiré à la pause (`pause_toggled`). Total : 134 assertions.
- **2026-10-17 — `interact_target_changed` (session 4).** `interactor.gd` diffuse `EventBus.interact_target_changed(target_id, kind)` à chaque changement réel de cible (aucune réémission tant que la cible ne bouge) et `(&"", &"")` quand le réticule ne vise plus rien. Kinds émis : `read`, `pickup`, `use`, `burn` (metadata `interact_kind`). Piège corrigé : sur cible nulle, le kind retombait sur le défaut `"use"` — désormais vidé explicitement.
- **2026-10-17 — sensibilité : format UI (session 4).** `UiSettings` envoie un **multiplicateur** 0,2–3,0 (1,0 = défaut) et non un 0..1 : `player.gd` convertit `rad/px = 0,0022 × multiplicateur` (bornes inchangées), une valeur < 0,1 reste interprétée comme des rad/px bruts (tests/compat). Vérifié sur le fichier réel `user://settings.cfg` (section `settings`).
- **2026-10-17 — intégration pause avec l'UI (session 4).** Test réel avec `scenes/ui/pause_menu.tscn` ajouté après le joueur (comme `main.tscn`) : Échap est capté par l'UI, l'arbre est mis en pause, le joueur s'aligne (`pause_toggled`) et la souris est rendue ; second Échap = reprise symétrique. **Aucun double basculement.** 123 assertions au total.
- **2026-10-17 — Bug Échap corrigé (session 3).** `player.gd` traite l'action `pause` **avant** le verrou d'entrée (sinon impossible de sortir de pause) : `set_paused()` bascule le mode souris (CAPTURED ↔ VISIBLE), coupe les entrées, vide l'accroupi, et émet `pause_toggled`. `get_viewport().set_input_as_handled()` évite le double traitement. Si l'état vient de l'UI, le joueur s'aligne **sans réémettre** (`set_paused(paused, notify=false)`) : aucune boucle possible. `PhotoDevice` baisse l'appareil sur `pause_toggled(true)` (sinon il resterait levé, le relâchement du clic n'étant plus capté). De plus, le joueur rend la souris dans `_exit_tree()` (fin de partie : `main.tscn` libère le jeu, puis l'écran de fin doit être cliquable). Vérifié : 104 assertions (Échap réel injecté via `Input.parse_input_event`).
- **2026-10-17 — settings_changed terminé (session 3).** Nouveau `scenes/player/settings_source.gd` : relecture silencieuse de `user://settings.cfg` au `_ready()` du joueur (clés `mouse_sensitivity`, `fov`, `flashlight_strong`, cherchées dans n'importe quelle section) — couvre le cas où l'UI émet les réglages **avant** l'instanciation du joueur (menu → partie). Fichier absent ou clé inconnue = valeurs par défaut, sans erreur. Ordre d'application garanti : fichier puis signal (le signal gagne). Méthode publique `apply_persisted_settings()`.
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
| S-9 | Actions de règle `subtitle:<clé>[:<durée>]` (→ `subtitle_requested`) et `reveal:<item_id>` — playtest J4, lisibilité | M3 | DONE |
| S-10 | Fin Cendres différée (`SUB_BURNING` + `ending_reached("ashes")` 4 s plus tard) et déclencheurs de règle `item_moved` / `ending` | M3 | DONE |

### Notes Systèmes

- **Tests** (2026-10-17) — `game/scenes/main/test_systems.tscn` (scène de test autonome, 89 assertions, exit code CI) + suites gdUnit4 dans `game/tests/autoloads/` (parser, règles, inventaire) prêtes pour Q-1 : elles attendent l'installation de gdUnit4 (`tools/run_tests.sh` les ignorera jusque-là). Les cas de syntaxe invalide (push_error spéculés) sont dans `test_systems.tscn` pour ne pas faire échouer gdUnit4 sur les erreurs volontaires.

- **S-5** (2026-10-17) — SaveManager vérifié : JSON versionné (v1), auto-sauvegarde ajoutée sur `player_entered_room`, `save_requested` OK, chargement en dégradé si version différente. Aller-retour save/load couvert par `test_systems.tscn`. Limite connue : les déplacements d'objets (`item_moved`) déjà consommés par Niveau ne sont pas rejoués au chargement (les règles `room_left` passées ne se refirent pas) — à noter pour la V2 si besoin.
- **S-6** (2026-10-17) — `main.tscn` : menu (UI `main_menu.tscn` si présent, sinon placeholder `tr()` avec `UI_*`) → jeu (`house.tscn` + `player.tscn` + `hud.tscn`, chargés par chemin avec `push_warning` si absents) → fin (`ending_reached` → `ending_screen.tscn` ou placeholder `ENDING_*_TITLE`). Nouvelle partie réinitialise les autoloads (`from_save_dict({})`) ; Continuer charge la sauvegarde APRÈS instanciation maison/joueur (rattrapage `game_loaded`).
- **S-7** (2026-10-17) — Séquenceur V1 dans HouseDirector : seuils 20/45/60 → `act_changed` (phases calme/inquiétude/cave = act 1/2/3 sur le signal existant, pas de changement de contrat) + `house_event_triggered` en secours (`act1_drawer_opens`, `phone_rings`, `cellar_door_opens`) **dédoublonné avec les règles** (les règles r01/r03 portent ces événements ; le séquenceur ne les réémet pas s'ils le sont déjà). Rattrapage après `game_loaded`.
- **S-8** (2026-10-17) — 2 fins V1 : `closed` au 60e objet coché (+ ligne « 61. Camille » via `inventory_line_added(61, &"INV_LINE_ADDED_CAMILLE")`), `ashes` sur `player_interacted(&"cellar_stove", &"burn")`. Première fin gagne ; la ligne finale est supprimée après `ashes` (carnet brûlé).
- **S-3** (2026-10-17) — HouseDirector : parser complet (tous prédicats §6 + négation `!` universelle, `item_present:`, `presence:`, `&&`/`||`/parenthèses ; invalide = `push_error` + `false`), moteur de règles (9 triggers, 5 actions, `once`/`cooldown`, validation douce au chargement), attention (+3/flash, +6×bruit, −1.5/s après 20 s d'immobilité, valeurs calables), révélation des fantômes sur `document_read`/`item_checked`/`inventory_progress`/`player_entered_room`. Les 18 règles de `data/rules/` se chargent et se déclenchent. DocumentLibrary applique `sets_flags`/`reveals_items` au `mark_found` (demande Narration). Vérifié par `scenes/main/test_systems.tscn` (62 assertions).
- **S-10 (2026-10-20, intégration du soir).** (1) **Fin Cendres différée** : sur `player_interacted(&"cellar_stove", &"burn")`, HouseDirector émet `subtitle_requested(&"SUB_BURNING", 4.0)` immédiatement puis `ending_reached(&"ashes")` **4,0 s plus tard** (`BURN_ENDING_DELAY`), via `create_timer` (fonctionne aussi en pause). Un seul brûlage programmé à la fois ; un chargement ou une new game (`from_save_dict`) annule l'attente ; une fin déjà atteinte reste prioritaire (ni sous-titre ni fin différée). `SUB_DAWN` reste porté par l'écran de fin (UI). (2) **Déclencheurs `item_moved` et `ending`** câblés dans le moteur de règles : `item_moved` (param = `item_id`, vide = n'importe quel objet) est évalué à chaque `EventBus.item_moved` — donc après une action `move_item` **et** après le rejeu au chargement (les règles `once` déjà parties restent muettes grâce à `rules_fired`) ; garde anti-récursion `MAX_MOVE_CHAIN` = 8 pour les règles `item_moved` qui déplacent elles-mêmes un objet. `ending` (param = `ending_id`, vide = n'importe quelle fin) est évalué **après** l'émission de `ending_reached`, dans `_trigger_ending` (première fin gagne). Test_systems : **131 assertions, 0 échec** (dont mesure du délai réel : 4,01 s, double brûlage, brûlage après la fin ignoré, item_moved générique/paramétré, ending paramétré). gdUnit4 : cas `ashes` mis à jour en `await` + 2 nouveaux cas (`test_item_moved_trigger`, `test_ending_trigger`). `check.sh` vert.
- **S-9 (2026-10-20, playtest J4).** Deux actions de règle dans HouseDirector : `subtitle:<clé>[:<durée>]` → `EventBus.subtitle_requested` (durée omise = 3,0 s, `SUBTITLE_DEFAULT_DURATION`) et `reveal:<item_id>` → `InventoryManager.reveal_item`. Validation au chargement (warning) et à l'exécution (push_error + action ignorée) : une règle à action invalide ne casse rien. 6 assertions `test_systems` + 1 cas gdUnit4 (111 assertions au total). Les monologues de Camille se déclenchent donc dès que Narration livre les règles `subtitle:` (R-10).
- **Session 3 — retours Architecte (2026-10-17).** `InventoryManager.all_items() -> Array[ItemData]` ajouté au contrat §5 (trié par `list_index`, couvert par les tests) ; `main.gd::_on_options()` vidée ; appel/warning `/root/Settings.apply_all()` supprimés (`UiSettings.apply_all()` est porté par le menu et le HUD côté UI, main n'a rien à faire).
- **Session 2 — player_caught + rejeu déplacements (2026-10-17).** `main.gd` écoute `player_caught` : téléportation du joueur au transform de spawn (l'entrée, enregistrement à l'instanciation — pas d'ancre dépendante de Niveau) + `InventoryManager._check_random_unchecked()` (coche « Présence », photo nulle dans `item_checked`). HouseDirector mémorise les `move_item` (`_moved_items`) et les **rejoue sur `game_loaded`** avant le rattrapage de progression : l'état « la maison se souvient » survit au chargement. `main.gd` appelle aussi `Settings.apply_all()` via `/root/Settings` (ARCHITECTURE §7), appelé au démarrage ET au lancement de partie (le joueur reçoit `settings_changed` après son instanciation). Test_systems : 103 assertions.
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
| N-1 | Plan 2D de la maison (image dans docs/) validé par Architecte : 13 zones, cohérent avec GDD §5 | M1 | DONE |
| N-2 | Blockout entrée + bureau (CSG ou meshes gris), ancres Marker3D nommées, zones Area3D | M1 | DONE |
| N-3 | `house.tscn` + `house.gd` : instanciation des Items depuis InventoryManager, écoute `item_moved`, `item_revealed` | M1 | DONE |
| N-4 | `item.tscn` générique + `item.gd` (`is_in_frustum`, surbrillance, inspection) | M1 | DONE |
| N-5 | Blockout cuisine/salon et intégration des 6 zones V1 | M2 | DONE |
| N-6 | Éclairage de base (lumière basse, fog volumétrique, budget ARCHITECTURE §8) | M2 | DONE |
| N-7 | Assets finaux V1 : modèles/CSG pour les 60 objets, textures CC0 ambientCG pour les six pièces, matériaux, CREDITS.md et tests | M4 | EN COURS (Niveau) |
| N-8 | Set-dressing final des 13 zones (1998 rural, voir GDD §8) | M4 | TODO |
| N-9 | Objets V1 (60) reconnaissables : ≥ 40 modèles glTF CC0, CSG distinctif pour le reste, dimensions réelles (priorité après J4) | M3→M4 | EN COURS (Niveau) |
| N-10 | Extérieur V1 minimal : cour 14 × 9 m, portail fermé, 205 décor (appentis hors périmètre Halloween) | M2 | DONE |

### Notes Niveau (V1 Halloween)

- **2026-10-17 — N-1 DONE.** Plan V1 validé par l’Architecte et copié dans `docs/plan_maison.png`; source SVG conservée dans `game/scenes/house/plan_maison.svg`.
- **2026-10-17 — N-2 DONE.** Hall 3 × 9 m : longue vue entrée → escalier condamné, mot Besnard, téléphone/répondeur, console et `hall_anchor_stairs_top`; zone monitorable couche 4.
  Bureau 4,5 × 4 m à l’est, porte 0,9 × 2,1 m et 12 ancres; cave critique 6 × 4 × 2,1 m ajoutée sous la cuisine réservée, avec échelle, `cellar_anchor_presence_spawn`, Présence et registre 1847.
- **2026-10-17 — N-3 DONE.** `house.gd` indexe les salles par `room_id`, instancie les 26 objets des scènes disponibles et écoute `item_moved` / `item_revealed` via `EventBus`.
  Déplacement testé (reparent + ancre cible), fantôme testé (visibilité/collider); `house.tscn` se lance seul avec hall, bureau et cave.
- **2026-10-17 — N-4 DONE.** Prefab gris avec collider enfant, groupe `items`, couverture écran, interaction et surbrillance; l’API d’inspection renvoie id et clés/textes traduits.
  Les 60 `.tres` ont `scene` + `anchors[0]` renseignés (aucun autre champ de données modifié); le poêle a son prefab dédié `burn` / 8 s. Ancres documentées dans `docs/anchors.md`.
- **Tests Niveau.** `tests/house/house_tests.tscn` : 47 assertions, 0 échec (dimensions/zones, ancres, 26 instanciations, révélation, déplacement, inspection, frustum, Présence et poêle). Vérification ItemData : 60/60 conformes, seuls `scene`/`anchors` modifiés.
- **2026-10-20 — N-6 DONE.** `house.tscn` reçoit un environnement ACES très sombre, fog de distance + volumétrique léger; plafonnier faible du hall, lampe de bureau et ampoule nue en cave.
- Éclairage pratique de jeu séparé de la preview F6; 2 Omni avec ombres (hall/bureau), cave sans ombres. `house.gd` restaure `visible = standalone`; `PlayerSpawn` conservé. `check.sh` vert, tests Niveau : 59 assertions, 0 échec.
- **2026-10-20 — N-5/N-10 DONE (V1 minimal).** Cuisine, salon et cour 14 × 9 m ajoutés; 205 en décor, 34 ancres matérialisées, 60 objets instanciés. Trappe cuisine/cave alignée et ouverte par `cellar_door_opens`.
- Portes alignées vers les six zones; `TempBlockers` retirés. Clôtures/portail extérieur et fond d’escalier sont collidables; appentis exclu par `PLAN_HALLOWEEN`. Vérifié : `check.sh` vert, tests Niveau 104 assertions, 0 échec.
- **2026-10-21 — N-9/N-7 en cours, première livraison hall (J5).** Les 10 objets du hall ont quitté le cube gris : 5 utilisent des modèles CC0 (console, porte-manteau, miroir, porte-parapluies composite, répondeur) et 5 sont des compositions CSG uniques (baromètre, tableau à clés, sonnette, main fantôme, bague). Mur décoré d’un motif 70s original dérivé de Wallpaper002A CC0; sol WoodFloor017, plafond Plaster001 (ambientCG, 1K). Sources et chaque fichier listés dans `game/assets/CREDITS.md`; dimensions hall conservées/renseignées dans `item.gd`. Tests Niveau : 137 assertions, 0 échec; `bash game/tools/check.sh` vert. Commit hall `8899fa2` (`[level] habille le hall en assets CC0`) poussé sur `origin/agent/level`; branche réalignée sur l’intégration amont `f4c2a1f`. **Refusée visuellement par l’utilisateur le 21/10; corrigée ci-dessous.**
- **2026-10-21 — N-9/N-7, reprise visuelle du hall.** Les murs est de la cuisine et les doublons mitoyens du bureau/salon sont réservés au mode autonome; le papier peint s’affiche désormais directement sur les murs du hall. Orientations des objets muraux corrigées par les ancres. Escalier refait en 8 marches (16,5 cm de haut × 30 cm de giron), mains courantes et palier; surface audio `wood` sur sol, marches et palier. Plafonnier, appliques et léger rebond lumineux; contrôle supplémentaire sans torche. `shots.sh` exécuté et PNG inspectés : `hall_from_door.png`, `hall_console.png`, `hall_to_stairs.png` et variantes `_no_torch`. Vérification : `check.sh` OK, tests Niveau 176/0, tests systèmes 131/0. Les captures du hall, y compris les vues sans torche, sont jointes au lot de correction; le bureau ne reprend qu’après publication de ce lot.

### HANDOFF — Niveau (17 oct. 2026, session 2)

**Ce qui marche**
- N-1 validé; plan dans `docs/plan_maison.png`, source SVG dans `game/scenes/house/plan_maison.svg`.
- N-2/N-3/N-4 livrés : `hall.tscn`, `study.tscn`, cave de jeu critique `cellar.tscn`, `house.tscn` autonome avec **26 objets instanciés**, prefab Item et variante dédiée du poêle.
- Les 60 ItemData ont uniquement `scene` et `anchors` renseignés; les 60 ancres initiales sont listées dans `docs/anchors.md`.
- `tests/house/house_tests.tscn` : 47 assertions headless, 0 échec. Vérification ItemData : 60/60 corrects, aucun autre champ modifié.

**Ce qui reste**
- **État historique à la clôture du 17/10** : N-5 (cuisine/salon) et N-10 (extérieur) restaient à faire; voir le HANDOFF Niveau du 20/10 pour leur livraison.
- `bash game/tools/check.sh` était vert avant les scènes nouvelles. Les validations courantes et l'état de push sont consignés dans le HANDOFF Niveau du 20/10; ne pas merger sur `main`.

**Pièges connus**
- PLAN_HALLOWEEN prime sur les descriptions V2 : la cible reste 6 zones et 60 objets, pas 13 zones/212.
- `item.tscn`/`cellar_stove.tscn` lancés seuls sans `ItemData` affichent un `push_warning` et gardent leur placeholder; c’est la dégradation prévue. Dans `house.tscn`, les 26 ItemData présents sont fournis par InventoryManager.
- Aucun asset externe n’a été ajouté; aucune modification à `CREDITS.md` nécessaire.

### HANDOFF — Niveau (20 oct. 2026, session 3)

**Livré**
- N-6 : environnement de jeu ACES sombre avec fog de distance/volumétrique léger; pratiques du hall, bureau, cave, cuisine, salon et porche. Deux Omni pratiques ont des ombres; le total reste sous le budget ARCHITECTURE §8. Les previews F6 sont séparées et `house.gd` ne les force plus visibles en jeu.
- N-5/N-10 V1 : cuisine, salon et cour; six zones composées, 60 objets instanciés et 60 ancres vérifiées. Les trois cibles de règle cuisine/salon sont distinctes des ancres des ItemData; trappe cuisine/cave alignée, collidable fermée puis ouverte sur `cellar_door_opens`.
- Sécurité : `KitchenDoorTemp` et `FrontDoorTemp` retirés après construction; portes vers les pièces présentes alignées. Cour fermée par clôtures et portail collidables; escalier d'étage obturé par planches/barrière collidables. `PlayerSpawn` et `player_spawn_transform()` conservés.
- Vérifications Godot 4.7.2 : `bash game/tools/check.sh` vert; `tests/house/house_tests.tscn` = **104 assertions, 0 échec**; lancement headless F6 des six rooms et de `house.tscn` sans erreur. Aucun asset externe ajouté; `CREDITS.md` inchangé.

**À vérifier / limites**
- Le sandbox est headless : aucune validation visuelle F5 n'a été faite. À faire côté Architecte : playtest du niveau éclairé, fog, densité visuelle et circulation.
- La trappe s'ouvre par événement; montée/descente réelle de l'échelle raide non vérifiée en F5. Le Gameplay n'expose pas de contrôleur d'escalade dédié.
- Appentis non construit : exclu par `PLAN_HALLOWEEN` (extérieur V1 minimal). Habillage/assets N-7/N-8/N-9 restent hors de ce blockout.
- Commits Niveau `f08ea17` (N-6) et `22da7bf` (N-5/N-10) sur `agent/level`, sans merge main. Après vérifications vertes, `origin/agent/level` a été poussé jusqu'à `22da7bf`; l'authentification utilisateur n'a été utilisée que dans l'URL de la commande `git push`, sans être enregistrée dans le workspace.

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
| R-10 | Onboarding + moments clés (playtest J4) : règles `subtitle:`, clé `UI_HINT_PHOTOGRAPH`, post-it explicite en 3 lignes | M2 | DONE |
| R-11 | Rebrancher « premier objet déplacé » sur le déclencheur `item_moved` (S-10) | M2 | DONE |


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
- **2026-10-20 — R-10 DONE (playtest J4 : zéro onboarding, sous-titres jamais joués).** 8 nouvelles clés `SUB_*` (`SUB_TUTO_CONSOLE`, `SUB_TUTO_CARNET`, `SUB_TUTO_PHOTO`, `SUB_PROGRESS_10`, `SUB_CLOCK_30`, `SUB_PHONE_45`, `SUB_FIRST_MOVED`, `SUB_PROGRESS_58` ; 38 `SUB_*` au total, toutes ≤ 12 mots) + `UI_HINT_PHOTOGRAPH` (« Photographier pour inventorier. ») dans `fr.csv` (201 clés). Post-it de Besnard réécrit : la tâche est dite en 3 lignes (« Photographiez chaque objet de la liste, un par un. / La ligne se coche quand la photo est développée. / Il y a soixante lignes. Rien de plus. ») ; capture itch.io n° 1 mise à jour en conséquence.
  Câblage : 5 nouvelles règles (`r19_onboarding_hall`, `room_entered:hall`, once, 3 lignes dans l'ordre ; `r20_first_photo` sur `flash_count` = 1 ; `r21_progress_10` ; `r22_progress_58` ; `r23_ending_closed_line` à 60) et actions `subtitle:` ajoutées à `r01` (20, tiroir), `r02` (30, horloge), `r03` (45, téléphone puis trappe), `r04` (descente cave), `r05` (Présence, 52), `r07` (premier objet déplacé). `check.sh` vert ; tant que S-9 n'est pas intégré, HouseDirector émet un `push_warning` par action `subtitle:` et les lignes ne s'affichent pas (dégradation propre, aucun crash).
- **2026-10-20 — R-11 DONE.** « Premier objet déplacé » rebranché sur le déclencheur `item_moved` (S-10) : nouvelle règle `r24_first_moved` (`item_moved`, param vide = tout objet, `once`, `subtitle:SUB_FIRST_MOVED:3.5`), action `subtitle:` retirée de `r07`. La ligne joue au premier déplacement réel — y compris la clé « L. » déplacée par `r11`. README des règles et `subtitles.md` à jour ; demande correspondante close.

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
| U-1 | Carnet 3D en main : ouverture/fermeture, pages, onglets (liste / photos / documents / plan) | M1 | DONE (V1 : 2 onglets, surcouche 2D) |
| U-2 | Liste d'inventaire : 212 lignes par pièce, coche animée, lignes « ajoutées » (écriture qui apparaît) | M1 | DONE (60 lignes V1) |
| U-3 | Visionneuse de photo (en main + dans le carnet) | M1 | DONE (carnet + zoom ; « en main » = Gameplay G-5) |
| U-4 | HUD minimal : compteur de films sur l'appareil, réticule contextuel discret | M1 | DONE (réticule non contextuel : signal manquant, voir demandes) |
| U-5 | Lecture de document (papier en main, pages, BBCode, typo machine/manuscrite) | M1 | DONE |
| U-6 | Menu principal (205 dans le brouillard), pause, options (sensibilité, FOV, sous-titres, accessibilité, remapping) | M2 | DONE (mini V1 : remapping/daltonisme = V2) |
| U-7 | Sous-titres (`subtitle_requested`) | M2 | DONE |
| U-8 | Écrans de fin, générique | M3 | DONE (2 fins ; générique = V2) |
| U-9 | Polices libres (machine à écrire, manuscrite, UI) + CREDITS | M1 | DONE |
| U-10 | Lisibilité J4 : libellé 1973 sous le réticule + état coché, bandeau ✓ 2,5 s puis lore, aide « photographier », rappel « Tab : carnet » | M1 | DONE |
| U-11 | File de sous-titres : FIFO, max 4 en attente, durées cumulées, écart 0,3 s, lore après les lignes de règle | M1 | DONE |

### Notes UI (V1 Halloween)

- **2026-10-17 — U-9 DONE.** `assets/fonts/` : Courier Prime (R/B/I, machine à écrire), Caveat (manuscrite, variable), Lato (R/B, sans-serif) — SIL OFL 1.1, textes de licence joints, `assets/CREDITS.md` rempli. Couverture française vérifiée sur la table `cmap` des 3 familles (`œ Œ`, majuscules accentuées, `« » — – … ’ €`) : aucun glyphe manquant.
- **2026-10-17 — Chaînes UI.** `data/strings/fr.csv` est le périmètre Narration : mes clés vivent dans `scenes/ui/ui_strings.csv`, enregistré dans le `TranslationServer` par `UiText.ensure()` (appelé en tête de chaque `_ready` UI), avec repli sur une lecture directe du CSV. `tr()` fonctionne ensuite normalement. Demande de fusion déposée.
- **2026-10-17 — U-1/U-2 DONE.** `scenes/ui/notebook.tscn` (CanvasLayer 20, Tab) : 2 onglets. Liste = 60 lignes + 6 en-têtes de pièce, groupées dans l'ordre de `list_index`, libellés `tr(label_key)`, format `INV_LINE_FORMAT` ; coche tracée en 0,34 s (`check_mark.gd`, stylo-bille) sur `item_checked` — animée à l'ouverture si l'objet a été coché carnet fermé. `inventory_line_added` ajoute une ligne manuscrite révélée caractère par caractère (« 61. Camille ») ; `item_revealed` fait clignoter la ligne à l'encre fraîche ; fin `ashes` = les lignes ajoutées disparaissent.
- **2026-10-17 — U-3 DONE.** Onglet Photos : une vignette par `photo_developed` (bordure + légende pièce), sélection ↑↓, Entrée = zoom plein écran. Texture absente (headless, capture SubViewport indisponible) → vignette grise + `UI_NOTEBOOK_PHOTO_UNDEVELOPED`, jamais de crash.
- **2026-10-17 — U-4 DONE.** `scenes/ui/hud.tscn` (CanvasLayer **2**, sous le post-process 3 et le voile de flash 5 du joueur : le grain et l'aveuglement s'appliquent au HUD). Compteur de films en bas à droite (`UI_FILM_COUNT`, rougi à 0), mis à jour sur `photo_taken` (le film est consommé avant l'émission). Réticule : point discret qui pulse sur `player_interacted` et se masque carnet ouvert ; `set_context(kind)` est prêt mais aucun signal de cible survolée n'existe (demande déposée). Viseur photo, voile blanc et jauge d'interaction longue appartiennent à `player.tscn` : rien n'est doublé.
- **2026-10-17 — U-5 DONE.** `scenes/ui/document_viewer.tscn` (CanvasLayer 30) : `document_found` → `DocumentLibrary.get_document()` → `RichTextLabel` BBCode, typo machine à écrire (`inventory/form/note/tape`) ou manuscrite (`letter/journal/postit`) selon `kind`, pagination par budget de caractères (pas de mesure de texte : déterministe et testable), navigation ↑↓←→, `mark_read()` appelé à l'ouverture (déclenche `document_read` → révélations).
- **2026-10-17 — U-6 DONE (mini).** `main_menu.tscn` : noir + brouillard généré (`menu_fog.gd`, dégradés radiaux qui dérivent + 2 halos chauds = phares de la 205), titre manuscrit, 4 boutons émettant `new_game_requested`/`continue_requested`/`options_requested`/`quit_requested` (contrat S-6 respecté, le placeholder de main.gd n'est plus utilisé), Continuer grisé sans sauvegarde. `pause_menu.tscn` (CanvasLayer 90, `process_mode` ALWAYS) : Échap = `get_tree().paused` + `pause_toggled`, mais **jamais** quand une surcouche UI est ouverte (arbitrage `UiState`, testé). `options_panel.gd` partagé menu/pause : sensibilité, FOV, volume, sous-titres, plein écran, lampe forte — persistés dans `user://settings.cfg` par `UiSettings`, `settings_changed` émis à chaque changement et une fois par clé au démarrage (`apply_all()`).
- **2026-10-17 — U-7 DONE.** `scenes/ui/subtitles.tscn` (Control instancié dans le HUD et l'écran de fin) : fondu 0,16 s, maintien `duration`, fondu 0,5 s ; respecte le réglage `subtitles` en direct ; clé inconnue = warning + rien à l'écran (jamais de clé brute).
- **2026-10-17 — U-8 DONE.** `scenes/ui/ending_screen.tscn` (Control, `set_ending_id()` appelé par main.gd) : `ENDING_<ID>_TITLE`, puis P1..P5 écrits un par un, puis la dernière ligne composée via `INV_LINE_FORMAT` (index **sérialisé** : `progress().y + 1` = 61 pour `closed`, 1 pour `ashes`), puis `ENDING_GENERIC_EPILOGUE`, puis boutons « Revenir au menu » / « Quitter ». Entrée accélère, Échap révèle tout.
- **2026-10-17 — Tests.** `game/tests/ui/ui_tests.tscn` = **92 vérifications headless, 0 échec** (`godot --headless --path game res://tests/ui/ui_tests.tscn`, exit 0/1) : chaînes, thème, réglages, carnet (lignes, coche, ligne ajoutée, photos), documents (pagination, mark_read, dégradation), HUD, sous-titres, pause, options, contrat menu, 2 fins, **priorité des entrées** (Tab/Échap), **rattrapage `game_loaded`** (coches retrouvées, photos vidées). Banc d'essai manuel : `scenes/ui/test_ui.tscn` (touches 1-7 → signaux factices). Les 9 scènes du module se lancent seules (F6) sans erreur ni warning.

- **2026-10-20 (soir) — U-11 DONE (file de sous-titres, contrat §7).** `subtitle_box.gd` n'écrase plus la ligne en cours : `show_line()` **empile** (FIFO), `MAX_QUEUED = 4` lignes en attente (au-delà : `push_warning` + demande ignorée), chaque ligne garde sa durée (**durées cumulées**, `remaining_time()` = total restant fondu/écart compris), **0,3 s d'écart** (`GAP`) entre deux lignes. La lore d'un objet coché passe par la même porte (`hud_hints` → `show_line`) et tombe donc **après toute ligne déjà en file**. `hide_line()` vide la file (réglage « sous-titres » coupé, retour au menu). API de test : `current_key`, `is_showing`, `queued_count`, `queue_keys`, `remaining_time`. Conséquence directe : `r19_onboarding_hall` (3 lignes) et `r03_phone_and_cellar` (téléphone puis trappe) se jouent en entier. **Tests : 136 vérifications, 0 échec** (+15) ; Gameplay 134/0, Niveau 104/0 ; les 9 scènes F6 sans erreur.
- **2026-10-20 — U-10 DONE (lisibilité, contrat §7).** `scenes/ui/hud_hints.gd` (`Hints`, plein cadre, `mouse_filter=IGNORE`, dans `hud.tscn`) porte les 4 retours du playtest J4 : (1) libellé 1973 (`INV_LINE_FORMAT`) sous le réticule sur `interact_target_changed`, + « déjà inventorié » si l'objet est coché ; (2) bandeau « ✓ n° X — libellé » 2,5 s sur `item_checked`, puis la ligne de lore en sous-titre 4 s après le coche (`SubtitleBox.show_line`) ; (3) `UI_HINT_PHOTOGRAPH` sur `player_interacted(*, &"pickup")`, 3 s ; (4) rappel « Tab : carnet » après 2 photos si le carnet n'a jamais été ouvert (une fois par partie, durable après un chargement). Le « ✓ » est **dessiné** (`check_mark.gd`) : U+2713 est absent du cmap de Courier Prime. Aucun son joué ici : `AudioManager` joue déjà `pencil_check`/`notebook_open`/`notebook_close`. Une photo qui coche plusieurs objets enfile les bandeaux (jamais deux à la fois), la lore du dernier ferme le lot. **Tests : 121 vérifications, 0 échec** (+24 pour U-10) ; Gameplay 123/0, Niveau 104/0 inchangés ; les 9 scènes F6 sans erreur.
- **2026-10-17 — Réalignement post-merge (`c1b4afd`).** (1) Réticule branché sur `EventBus.interact_target_changed` (contrat du 17/10) : la cible survolée pilote la forme, `(&"", &"")` = réticule nu ; tant que Gameplay n'émet rien, repli automatique sur `player_interacted` (1,4 s). (2) `notebook._collect_items()` utilise `InventoryManager.all_items()` dès qu'elle existe (`has_method` + `call`, l'API n'est pas encore implémentée) avec repli `data/items/` ; invariant testé : le carnet liste exactement les objets d'InventoryManager. (3) Le repli s'annonce par un `print` unique et non un warning (console propre). **Tests : 97 vérifications, 0 échec** ; Gameplay 104/0 et Systèmes 103/0 inchangés ; les 9 scènes F6 sans erreur ni warning.

### HANDOFF — UI (17 oct. 2026, fin de session 1)

**Ce qui marche (branche `agent/ui`, 2 pushes)**
- **U-9** Polices OFL dans `assets/fonts/` : Courier Prime (R/B/I) = machine à écrire, Caveat = manuscrite, Lato (R/B) = sans-serif. Textes de licence joints, `assets/CREDITS.md` rempli, couverture française vérifiée sur la table `cmap` (`œ Œ`, accents majuscules, `« » — – … ’ €`).
- **U-1/U-2** `notebook.tscn` (CanvasLayer 20, touche Tab) : 2 onglets. Liste = 60 lignes + 6 en-têtes de pièce dans l'ordre de `list_index`, libellés `tr(label_key)`, format `INV_LINE_FORMAT` ; coche tracée en 0,34 s sur `item_checked` (jouée à l'ouverture si l'objet a été coché carnet fermé) ; `inventory_line_added` écrit une ligne manuscrite caractère par caractère (« 61. Camille ») ; `item_revealed` fait clignoter la ligne à l'encre fraîche ; fin `ashes` = les lignes ajoutées disparaissent.
- **U-3** Onglet Photos : vignette par `photo_developed` + légende de pièce, sélection ↑↓, Entrée = zoom plein écran ; texture absente → vignette grise et libellé, jamais de crash.
- **U-4** `hud.tscn` (CanvasLayer **2**) : compteur de films en bas à droite (rougi à 0, à jour sur `photo_taken`), réticule discret qui pulse sur `player_interacted` et se masque carnet ouvert. Rien de doublé avec le HUD du joueur (viseur, voile blanc, jauge longue = `player.tscn`).
- **U-5** `document_viewer.tscn` (CanvasLayer 30) : `document_found` → `DocumentLibrary.get_document()` → RichTextLabel BBCode, typo machine à écrire ou manuscrite selon `kind`, pagination, `mark_read()` à l'ouverture (donc `document_read` → révélations).
- **U-6** `main_menu.tscn` (noir + brouillard généré + 2 halos = phares de la 205, les 4 signaux du contrat S-6), `pause_menu.tscn` (Échap = `get_tree().paused` + `pause_toggled`, jamais par-dessus une surcouche), `options_panel.gd` partagé menu/pause (sensibilité, FOV, volume, sous-titres, plein écran, lampe forte) persisté dans `user://settings.cfg` par `UiSettings` + `settings_changed` (une fois par clé au démarrage).
- **U-7** `subtitles.tscn` : fondu 0,16 s / maintien `duration` / fondu 0,5 s, respecte le réglage en direct, clé inconnue ignorée.
- **U-8** `ending_screen.tscn` : `set_ending_id()` → titre, P1..P5 écrits un par un, dernière ligne composée (`INV_LINE_FORMAT`, index sérialisé : 61 pour `closed`, 1 pour `ashes`), épilogue, boutons « Revenir au menu » / « Quitter ». Entrée accélère, Échap révèle tout.
- **Tests** : `res://tests/ui/ui_tests.tscn` = **92 vérifications headless, 0 échec** (exit 0/1). Les 9 scènes du module se lancent seules (F6) sans erreur ni warning. `check.sh` vert à chaque push — `main.tscn` charge désormais mon menu (le warning « main_menu.tscn absente » a disparu).

**Ce qui reste**
1. **Validation visuelle impossible ici** (rendu dummy en headless) : à regarder en F5/F6 — rendu des polices, pagination réelle des documents, brouillard du menu, position du compteur de films, lisibilité des sous-titres, aspect du papier. La mise en page est vérifiée par les tests (liste de 1926 px dans une fenêtre de 800), pas les pixels.
2. **Réticule non contextuel** : il faut `interact_target_changed(target_id, kind)` (demande déposée). `Reticle.set_context()` est déjà câblé.
3. **Aucun son UI** : ids déposés côté Audio (`notebook_open/close/page`, `pencil_check`, `photo_thumb`, `menu_move/select`, `typewriter_line`). À brancher sur `AudioManager.play_ui()` après D-1.
4. **Carnet 3D en main** (GDD §4.2) : V2, demande un `Marker3D` dans `player.tscn`.
5. **Options V2** : remapping et daltonisme non faits (coupure PLAN §5 assumée).
6. **Fusion `scenes/ui/ui_strings.csv` → `data/strings/fr.csv`** (demande déposée, non bloquante).

**Pièges**
1. `UiText.ensure()` doit précéder tout `tr()` de l'UI — il est en tête de chaque `_ready` du module ; toute nouvelle scène UI doit le faire aussi.
2. Un `CanvasLayer` n'est **pas** un `CanvasItem` : pas de `modulate` ni de `theme` sur la racine. Les fondus passent par les enfants (`notebook._set_fade`), les thèmes sont posés sur les `Panel`.
3. Le HUD est en CanvasLayer **2** : ne pas le passer au-dessus de 3 (post-process) ni de 5 (voile de flash du joueur), sinon le compteur de films n'est plus grainé ni aveuglé.
4. **Ordre des nœuds dans `hud.tscn`** : `PauseMenu` est le dernier fils, donc il reçoit `_unhandled_input` en premier ; il laisse passer Échap si `UiState.any_overlay_open()`. Ne pas réordonner sans rejouer le test « Entrées clavier ».
5. `document_viewer.open_document()` pose `_current_id`/`_open` **avant** `DocumentLibrary.mark_read()` : `mark_read` réémet `document_found`, c'est cette garde qui empêche la réentrée. Ne pas déplacer l'appel.
6. Le carnet énumère `data/items/` (pas d'API globale) : une pièce sans clé `ROOM_*` tombe sur « Pièce non classée » + warning.
7. `game/data/strings/fr.fr.translation` est régénéré par `--import` : le restaurer (`git checkout --`) s'il apparaît modifié (hors périmètre UI). `scenes/ui/ui_strings.fr.translation` est à moi : à commiter avec le CSV.
8. `AudioManager` est un stub : ne pas brancher les sons UI avant D-1 (chaque appel = warning).
9. Godot 4.7 traite l'inférence depuis un `Variant` comme une **erreur** (déjà signalé par Gameplay) : typer explicitement.

**Décisions prises seul (à valider)**
- Chaînes UI dans `scenes/ui/ui_strings.csv` + `TranslationServer` (aucune chaîne en dur, aucun fichier hors périmètre touché).
- Carnet = surcouche 2D, pas d'objet 3D dans la main (V1).
- La visionneuse appelle `DocumentLibrary.mark_read()` à l'ouverture (sinon `document_read` ne part que si l'interaction vient du joueur).
- La pause pose `get_tree().paused` **en plus** de `pause_toggled` (le joueur n'écoute que le signal).
- « Revenir au menu » = `get_tree().reload_current_scene()` (aucun signal de retour au menu dans le contrat).
- Fin `closed` : index de la dernière ligne = `progress().y + 1` (61) ; fin `ashes` : 1.
- `UiSettings.apply_all()` est appelé par le menu puis le HUD (idempotent) faute d'appel dans `main.tscn`.

### HANDOFF — UI (20 oct. 2026, U-10 lisibilité)

**Ce qui marche (branche `agent/ui`)**
- **U-10** `scenes/ui/hud_hints.gd`, nœud `Hints` de `hud.tscn` (Control plein cadre, `mouse_filter=IGNORE`, après `Reticle`). Les 4 retours du contrat §7 :
  1. `interact_target_changed(id, kind)` → si `id` est un objet de la liste : libellé 1973 (`UiText.inventory_line(index, tr(label_key))`) sous le réticule, + « déjà inventorié » (petit ✓ dessiné) si l'objet est coché. Cible vide → effacement en fondu 0,2 s.
  2. `item_checked` → bandeau « ✓ n° X — libellé » 2,5 s, puis la ligne de lore en sous-titre 4 s après le coche (via `SubtitleBox.show_line`, donc le réglage « sous-titres » s'applique).
  3. `player_interacted(*, &"pickup")` → « Photographier pour inventorier. » 3 s, sous le libellé.
  4. 2 `photo_taken` sans `notebook_opened` → « Tab : carnet » 4,5 s, **une seule fois** (le drapeau survit à `game_loaded` : c'est un acquis du joueur, pas de la session).
- **Aucun son joué par l'UI** : `AudioManager` écoute déjà `item_checked`/`notebook_opened`/`notebook_closed` et joue `pencil_check`/`notebook_open`/`notebook_close`. Tout appel ajouté ici doublerait le son.
- **Banc d'essai** : touche **8** de `test_ui.tscn` simule l'arrivée sur un objet puis le quitte (libellé + aide + ✓).
- **Tests** : `res://tests/ui/ui_tests.tscn` = **121 vérifications, 0 échec** (exit 0/1), dont 24 pour U-10. Gameplay 123/0, Niveau 104/0, Audio OK. Les 9 scènes du module se lancent seules (F6). `check.sh` vert.

**Ce qui reste**
1. **Validation visuelle** : les positions des 3 blocs de `Hints` sont posées en ancres (cible ~+60 px sous le centre, bandeau −214/−176, rappel −272/−240 depuis le bas) et testées logiquement, pas regardées. À vérifier en F5 sur une vraie résolution (les sous-titres occupent −150/−70 : ne pas descendre le bandeau plus bas).
2. **`UI_HINT_PHOTOGRAPH`** : formulation de repli locale en attendant Narration R-10 (la clé du projet gagnera seule dès qu'elle existera).
3. Inchangé : carnet 3D en main (V2), options remapping/daltonisme (V2), fusion `ui_strings.csv` → `fr.csv`.

**Pièges (nouveaux)**
1. **Ne pas tester l'alpha d'un fondu** : `target_visible()`/`banner_text()`/`notice_text()` renvoient l'**état logique** (`_target_shown`, `_banner_shown`, `_notice_shown`), pas `modulate.a` — un `await process_frame` pendant un fondu de 0,2 s est une loterie en headless (delta de frame variable).
2. **La file de bandeaux** : `_busy` doit être remis à `false` **avant** d'enchaîner `_pump_queue()`, sinon le deuxième bandeau ne part jamais. Chronologie d'un lot : bandeaux de 2,5 s enchaînés, puis la lore du **dernier** objet (une seule ligne par photo, pas de mur de texte).
3. **`InventoryManager.check_item()` refuse un objet déjà coché** (et n'émet rien) : les tests de bandeau doivent passer par `check_item` sur un objet non coché, pas par un `EventBus.item_checked.emit()` direct (qui ne met pas à jour `is_checked`).
4. **U+2713 absent de Courier Prime/Caveat/Lato** : tout « ✓ » est dessiné (`check_mark.gd`). Vérifier le `cmap` avant de composer un symbole.
5. `UiTheme.FONT_TYPEWRITER_BOLD` pour le bandeau, `FONT_UI` 14 px en `UI_DIM` pour « déjà inventorié » : le libellé reste en machine à écrire, l'état est discret.

**Décisions prises seul (à valider)**
- Lore d'un lot = celle du **dernier** objet coché (les autres n'ont que leur bandeau) : évite 8 s de sous-titres par objet.
- « Carnet déjà ouvert » survit à `game_loaded` (rappel jamais rejoué pour un joueur qui a trouvé le carnet).
- Le rappel « Tab : carnet » se déclenche à **2** photographies (`PHOTOS_BEFORE_REMINDER`), pas à la première.
- `typewriter_line` abandonné côté UI (réponse à la demande Audio du 17/10).

### HANDOFF — UI (20 oct. 2026, soirée — U-11 file de sous-titres)

**Ce qui marche**
- **U-11** `subtitle_box.gd` : file FIFO dans `SubtitleBox` (plus de `Timer`, tout passe par un `Tween` par ligne : fondu 0,16 s → durée → fondu 0,5 s → **écart 0,3 s** → ligne suivante). `MAX_QUEUED = 4` lignes en attente ; au-delà, `push_warning` + demande ignorée. `remaining_time()` = temps restant de toute la file (durées cumulées). `hide_line()` vide la file.
- La lore d'un objet coché n'a pas de chemin privilégié : `hud_hints._show_lore()` appelle `show_line()`, donc elle prend sa place **derrière** les lignes déjà en file (contrat §7). Rien à changer dans `hud_hints.gd`.
- **Tests** : `res://tests/ui/ui_tests.tscn` = **138 vérifications, 0 échec**, dont 15 pour U-11 et 2 pour `SUB_DAWN` (ordre FIFO, non-écrasement, écart de 0,3 s mesuré entre deux lignes, plafond à 4, lore derrière les règles, `hide_line` vide la file). Gameplay 134/0, Niveau 104/0, Audio OK, `check.sh` vert.

- **SUB_DAWN** (consigne Architecte 20/10 soir) : `ending_screen.gd` émet désormais la réplique de l'aube à l'épilogue de la fin **Cendres** (une fois, 4,0 s). Elle n'existait nulle part dans le code avant ce commit.

**Pièges (nouveaux)**
1. **Plus de nœud `Hold`** dans `subtitles.tscn` : le minutage est porté par le tween. Ne pas recréer de `Timer` à côté.
2. `current_text()` renvoie `""` pendant les fondus **et** pendant l'écart de 0,3 s : un test qui attend une ligne doit se placer dans la fenêtre de maintien (fondu 0,16 s + durée), pas au tout début.
3. `show_line()` est désormais une **demande**, pas un affichage immédiat : tout appelant qui voulait interrompre doit passer par `hide_line()` d'abord.
4. Le plafond compte les lignes **en attente** (hors ligne affichée) : 5 lignes émises dans la même frame = 1 affichée + 4 en attente, la 6e ignorée.

**Décisions VALIDÉES par l'Architecte (20/10 nuit, `[Architecte → UI]`)**
- File unique, sans priorité explicite : la lore « passe après les règles déjà en file » par simple FIFO ; **une règle arrivée *après* une lore attend derrière elle** (validé).
- Dépasser le plafond **ignore** la nouvelle ligne (warning) plutôt que d'évincer la plus ancienne (validé).

**État au 20/10 nuit : module UI en veille jusqu'au prochain playtest utilisateur.** Rien d'ouvert côté UI. Chez les autres modules, trois demandes UI restent en attente et ne bloquent rien : `photo_thumb` + `menu_move`/`menu_select` (Audio), la fusion `ui_strings.csv` → `data/strings/fr.csv` (Narration/Architecte), le carnet 3D en main (V2). Reprendre ici au prochain playtest.

## Module Audio `[Audio]` — `autoloads/audio_manager.gd`, `assets/audio`

| ID | Tâche | Jalon | Statut |
|---|---|---|---|
| D-1 | AudioManager : bus (Master/SFX/Ambiance/Music/UI), one-shots 3D, couches de soundscape, musique | M1 | **DONE** |
| D-2 | Sons de l'appareil photo (le plus important du jeu) : déclencheur, moteur, flash charge, photo qui sort | M1 | **DONE** |
| D-3 | Pas par matériau (bois, carrelage, moquette, gravier), souffle, sac | M1 | **DONE** |
| D-4 | Soundscape maison (3 couches × intensité) + extérieur | M2 | **DONE** |
| D-5 | Banque « sons domestiques au mauvais endroit » pour la Présence (~25) | M2 | **DONE** (10 sons + impact + nappe) |
| D-6 | 3 morceaux (piano salon, fin acte 2, générique) — libres de droits ou générés | M4 | **DONE** (périmètre V1 : 1 musique de fin = 2 variantes, PLAN §1) |
| D-7 | Voix de Camille (TTS qualité ou comédienne) — après R-6 | M4 | **HORS V1** (PLAN §1 : sous-titres seulement) |
| D-8 | Mixage final, CREDITS | M4 | **EN COURS** (mix statique + CREDITS faits ; écoute de contrôle à J10-J11) |

**Notes par tâche**

- **D-1** — `audio_manager.gd` réécrit (API ARCHITECTURE §5 inchangée). Bus créés **par code** via
  `AudioServer` (pas de `default_bus_layout.tres`, qui appartient à l'Architecte) ; Ambiance et UI
  **envoient vers SFX** pour que le curseur `volume_sfx` couvre l'appareil photo. Pools de 16
  joueurs 2D + 12 joueurs 3D, cache de flux, chargement paresseux, tween de fondu, low-pass Master
  pour la pause/le contact. Écoute : settings_changed, player_noise, player_entered_room,
  player_interacted, player_caught, house_attention_changed, presence_state_changed, flash_fired,
  photo_taken, photo_developed, item_checked, notebook_*, pause_toggled, ending_reached.
- **D-2** — 8 sons : déclencheur (clac à 10 ms, pas de latence perçue), flash (étincelle + corps +
  grésillement + queue de salle), moteur (engage → ronronne 1 s → crache le papier → butée),
  **charge du flash** (sifflement 1 150 → 5 600 Hz qui accélère, coupé net sur un clic « prêt »),
  lever/baisser, déclenchement à vide (creux, sans moteur), photo prête. Relais `flash_fired` /
  `photo_taken` **avec anti-doublon** : fonctionne avec ou sans Gameplay.
- **D-3** — 5 matériaux × 4 variantes (wood, tile, carpet, gravel, stone), souffle (intervalle
  5,4 s → 2,7 s selon l'attention), sac en cuir tous les 5-8 pas. Convention `metadata/surface`
  documentée dans `docs/audio_conventions.md` §5 (rayon physique + repli par pièce).
- **D-4** — 5 nappes bouclées sans couture : `house_base`, `house_unease` (attention 20→45),
  `house_dread` (45→70), `exterior`, `presence`. Craquements et tuyaux tirés au hasard **en 3D
  autour du joueur** (4-11 m), intervalles 14-26 s au calme → 5-11 s à l'angoisse.
- **D-5** — les 10 sons domestiques demandés par Narration existent tous (chaise tirée, pas à
  l'étage, porte, téléphone, robinet, pages du carnet, respiration, lumière, cave) + `caught_impact`
  (choc sourd + acouphène, aucun cri). Les ids `*_upstairs` / `*_above` sont joués 3,1 m au-dessus
  du joueur même quand la règle n'a pas de position.
- **D-6** — 2 musiques de 66 s (piano synthétisé + bourdon + nappe qui s'ouvre) : `music_ending_closed`
  (mineure non résolue) et `music_ending_ashes` (majeure, s'apaise).
- **D-8** — CREDITS.md : tout l'audio est **synthétisé** (CC0, aucun asset tiers, scripts dans
  `assets/audio/_src/`). Mixage « statique » : un niveau en dB par entrée, tous dans
  `_build_registers()`. Reste l'écoute de contrôle (casque + enceintes de portable) au jalon J10-J11.

### HANDOFF — Audio (17 oct. 2026, session 1)

- **Fait** : D-1 à D-6 + CREDITS. 67 fichiers OGG (1,6 Mo), 52 ids tous disponibles,
  `bash game/tools/check.sh` **vert**, `bash game/tests/audio/run_headless.sh` **vert**
  (joue les 52 ids, vérifie les 5 matériaux et la dégradation). Doc : `docs/audio_conventions.md`.
- **Reste** : (1) écoute de contrôle du mixage à J10-J11 (D-8) — corriger = changer un dB dans le
  registre. (2) Ancrer éventuellement 2 ou 3 sons dans l'espace (téléphone de l'entrée, trappe de
  la cave) : le contrat ne permet pas de passer une position depuis une règle, voir la demande
  inter-modules ci-dessous. (3) Si Niveau veut d'autres matériaux (`metal`, `water`), il suffit
  d'ajouter `footstep_<valeur>` — me le dire.
- **Pièges connus** :
  1. **Le soundscape démarre au premier `player_entered_room`**, pas au `_ready()` de l'autoload :
     sinon on entend la maison pendant le menu principal, et surtout Godot signale
     « resources still in use at exit » → **`tools/check.sh` échoue pour tout le monde**.
     Règle générale pour les autres autoloads : ne rien laisser *en lecture* à la fermeture.
  2. `AudioManager._exit_tree()` rend tous les flux ; ne pas le retirer (même raison).
  3. Un pas est ignoré s'il arrive moins de **0,11 s** après le précédent : en test, il faut
     espérer les émissions de `player_noise` (piège dans lequel je suis tombé).
  4. `AudioEffectLowPassFilter` s'appelle ainsi en 4.7 (plus `AudioEffectLowPass`).
  5. `sf.write()` de soundfile **plante** (segfault libsndfile) au-delà de ~2²¹ échantillons :
     écrire par blocs de 10 s (déjà fait dans `_src/common.py`).
  6. `DisplayServer.get_name()` vaut **`"headless"`** en 4.7 headless (pas `"dummy"`).
  7. À la fermeture, l'AudioServer libère ses playbacks **de façon asynchrone** : même après
     `stop()` + 0,6 s d'attente, Godot annonce parfois « resources still in use at exit »
     (1 run sur 3). Ce n'est pas une erreur de l'AudioManager et le joueur ne le voit jamais :
     `tests/audio/run_headless.sh` exclut ces deux lignes du verdict (commentaire dans le script).
     **Conséquence pour tout le monde** : `tools/check.sh` reste vert parce que rien ne joue
     pendant le menu. Si un jour un son se déclenche dans les premières frames de `main.tscn`,
     le check passera rouge — la parade est dans `_exit_tree()` de l'AudioManager.

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

- `[Narration → Systèmes]` (2026-10-20, **bloquant pour R-10**) **File d'émission des `subtitle:`.** `SubtitleBox.show_line()` écrase la ligne en cours : si S-9 émet les actions `subtitle:` d'une même règle dans la même frame, seule la dernière s'affiche. Il faut une file (durées cumulées) dans HouseDirector ou dans `SubtitleBox`. Concerne `r19_onboarding_hall` (3 lignes d'onboarding) et `r03_phone_and_cellar` (téléphone puis trappe). — **FAIT côté UI (U-11, 20/10 soir)** : la file est dans `SubtitleBox` (FIFO, 4 en attente max, durées cumulées, 0,3 s d'écart). HouseDirector n'a rien à faire de plus : émettre les 3 `subtitle:` dans la même frame suffit, elles se jouent dans l'ordre. Seule limite à connaître côté Narration : au-delà de 4 lignes en attente la demande est ignorée (warning) — ne pas enchaîner plus de 5 lignes d'un coup.
- `[Narration → Systèmes]` (2026-10-20) **Fin Cendres : aucun déclencheur HouseRule** pour l'interaction `player_interacted(cellar_stove, burn)`. Les clés existent (`SUB_BURNING` pendant l'interaction longue, `SUB_DAWN` à l'épilogue) : les émettre depuis le séquenceur de fin (S-8) ou l'écran de fin. La fin *Inventaire clos* est câblée (`r23`, `progress` = 60). — TODO
- `[Narration → Systèmes]` (2026-10-20) **« Premier objet déplacé constaté »** : câblé au plus simple sur `r07` (déplacement le plus précoce). Un déclencheur `item_moved` ou un prédicat `moved:<id>` permettrait de le jouer quel que soit l'objet déplacé en premier. Non bloquant. — **DONE** (S-10 livré ; rebranché par Narration, R-11 : `r24_first_moved`)

> Format : `[De → Vers] (date) Description. — Statut`

- `[Narration → Architecte]` (2026-10-17) `game/data/strings/fr.csv` **n'est pas enregistré** dans `project.godot` (`locale/translations=PackedStringArray()` vide) : `tr()` renverra les clés brutes. Le `.import` du CSV génère bien `fr.fr.translation`. Il faut ajouter `res://data/strings/fr.fr.translation` dans `internationalization/locale/translations`. Hors périmètre Narration. — **DONE** (Architecte, 17/10 : enregistré, tr() vérifié headless)
- `[Narration → Systèmes]` (2026-10-17) **Qui évalue `ItemData.reveal_condition` ?** ARCHITECTURE §6 la définit mais aucune API ne la traite : `InventoryManager.reveal_item()` est appelé sans condition. Proposition : HouseDirector évalue toutes les `reveal_condition` des fantômes non révélés sur les triggers `doc_read`, `progress`, `item_checked` et `act_changed`, et appelle `InventoryManager.reveal_item()`. En attendant, aucun fantôme n'apparaît : le jeu reste finissable sur 52 objets réels. — **TRANCHÉ (Architecte)** : oui, HouseDirector évalue les `reveal_condition` (ARCHITECTURE §6 mis à jour, paragraphe « Révélation »). Tâche S-3 pour Systèmes.
- `[Narration → Systèmes]` (2026-10-17) **Seuil de la cave.** PLAN_HALLOWEEN §2 dit « à 45 objets : le téléphone sonne, la trappe s'ouvre » et « les 8 derniers objets » se trouvent dans la cave. Avec la répartition validée (cave = 4 objets réels), il reste 8 objets au moment où il en manque 8 **si** 52 sont cochés (56 réels + 8 fantômes = 60, donc 52 cochés = 4 réels + 4 fantômes restants). Je livre les règles à `progress 45` (téléphone/répondeur, trappe) conformément au PLAN, et je **ne change pas** la répartition. La règle `cellar_door` reste à 45. — POUR INFO
- `[Narration → Systèmes]` (2026-10-17) **DocumentLibrary doit appliquer les données.** Sur `mark_found()` : appliquer `DocumentData.sets_flags` (`GameState.set_flag`) et `DocumentData.reveals_items` (`InventoryManager.reveal_item`). Le stub actuel ne le fait pas ; sinon 5 fantômes ne se révèlent que par `reveal_condition`.
- `[Narration → Systèmes]` (2026-10-17) **Chargement des règles.** Personne ne charge `res://data/rules/*.tres` aujourd'hui : il faut un `_ready()` dans HouseDirector qui instancie et `register_rule()` chaque `.tres` (18 fichiers V1). Prévu en S-3 normalement — je le note pour ne pas l'oublier.
- `[Narration → Systèmes]` (2026-10-17) **Négation `!item_checked:<id>` demandée.** ARCHITECTURE §6 ne documente que `!flag:<nom>`. Quatre règles de déplacement en dépendent (`r07` à `r10`, plus `r11`). Si vous refusez, dites-le et je convertirai en règles `flagged` déclenchées par un compteur `GameState.add_counter`.
- `[Systèmes → UI]` (2026-10-17) **`item_checked` peut porter une `photo` nulle** (coche « Présence » après `player_caught`, GDD §4.4 — pas de photo dans ce flux). L'animation de coche du carnet doit le tolérer. — EN COURS

- `[Systèmes → UI]` (2026-10-17) **Protocole main ↔ menu/écrans.** `main.tscn` charge `res://scenes/ui/main_menu.tscn` (menu principal), `res://scenes/ui/hud.tscn` (HUD en jeu), `res://scenes/ui/ending_screen.tscn` (écrans de fin). Si la racine de `main_menu.tscn` expose les signaux `new_game_requested()`, `continue_requested()`, `options_requested()`, `quit_requested()`, main les connecte automatiquement ; sinon menu placeholder utilisé (dégradation). `ending_screen.tscn` peut exposer `set_ending_id(id: StringName)` pour connaître la fin (`closed`/`ashes`). — EN COURS

**Réponses Systèmes (2026-10-17, S-3)** aux demandes Narration : révélation des fantômes par HouseDirector **OK** ; chargement `data/rules/` + `register_rule()` **OK** ; DocumentLibrary applique `sets_flags`/`reveals_items` **OK** ; négation `!item_checked:` **OK** (et `!` sur tout prédicat). Le séquenceur (S-7) respecte les seuils de règles 20/30/45/52 (événements narratifs portés par les règles) et pilote `act_changed` sur 20/45 (phases V1) + fin à 60.

- `[Narration → Audio]` (2026-10-17) **Ids SFX utilisés par les règles V1** (à exister, sinon AudioManager dégrade) : `drawer_open`, `clock_chime_distant`, `phone_ring`, `breath_low`, `door_close_upstairs`, `paper_turn`, `chair_drag_upstairs`, `hall_light_out`, `cellar_light_flicker`, `upstairs_chair`, `footsteps_above`. Un seul `play_sfx` par id.
- `[Narration → Niveau]` (2026-10-17) **Ancres exigées par les règles** (en plus de la convention `a_<item>` du README des règles) : `hall_anchor_console`, `kitchen_anchor_sink`, `kitchen_anchor_preserves`, `living_anchor_fireplace`, `study_anchor_shelves`. Un `move_item` vers une ancre absente doit être ignoré avec `push_error`, jamais planter. — **DONE Niveau** (cinq cibles présentes; les cibles cuisine/salon sont séparées des ancres initiales des objets).
- `[Narration → UI]` (2026-10-17) **Sous-titres et fins.** Clés `SUB_*` (30) : `EventBus.subtitle_requested.emit(&"...", durée)` — durées fournies dans `game/data/strings/subtitles.md`. Écrans de fin : `ENDING_CLOSED_*` / `ENDING_ASHES_*` ; la dernière ligne de chaque fin est séparée (`..._LINE_NAME`) pour être composée comme une ligne d'inventaire via `INV_LINE_FORMAT`. Corps BBCode (`[i]`, `[b]`).
- `[Narration → Niveau]` (2026-10-17) **Ancres.** La proposition initiale `a_<item_id sans préfixe de pièce>` est remplacée par la décision Architecte `<room>_anchor_<nom>`; les ancres de déplacement restent celles citées par `data/rules/*.tres` (dont `living_anchor_fireplace`, `study_anchor_shelves`, `hall_anchor_console`, `kitchen_anchor_sink`, `cellar_anchor_shelves`). Convention et liste des 60 objets documentées dans `docs/anchors.md`; les 60 `ItemData` ont leurs champs `scene`/`anchors` renseignés. — **DONE Niveau** (6 zones V1 composées; toutes les ancres et cibles matérialisées).
- `[Narration → UI]` (2026-10-17) **Ligne « 61. Camille ».** Le numéro est **sérialisé** (`InventoryManager.progress().x`) et non figé : je livre `INV_LINE_ADDED_CAMILLE` = `Camille` (sans numéro) et `INV_LINE_FORMAT` = `{index}. {name}`. Le carnet affiche via `inventory_line_added(line_index, text_key)`. — POUR INFO
- `[Narration → Systèmes]` (2026-10-17) **Ids de documents** référencés par les `reveal_condition` et les règles (à créer par R-3/R-5, contrats à respecter) : `hall_postit_besnard`, `study_inventory_1973`, `study_letter_besnard`, `kitchen_letter_lucienne_1`, `kitchen_letter_lucienne_2`, `living_letter_lucienne_3`, `living_photo_family`, `hall_tape_1973`, `cellar_register_1847`, `study_deed_1912`. — POUR INFO

- `[Architecte → Systèmes]` (17/10) Le parser de conditions doit supporter la **négation `!` sur tout prédicat** (`!item_checked:id`, utilisé par 4 règles) + `item_present:id` et `presence:state`. Seuils réels des règles : **20 / 30 / 45 / 52** (lire `game/data/rules/README.md`). — **DONE** (Systèmes S-3 : négation universelle + `item_present:` + `presence:` supportés ; seuils lus dans `data/rules/`)
- `[Architecte → UI]` (17/10) Les corps de documents (`body_key`) contiennent `\n` et du BBCode `[i]`/`[b]` : visionneuse = RichTextLabel avec bbcode_enabled. `pages` indicatif. — TODO
- `[Architecte → Niveau]` (17/10) Les 60 `item_id` de `docs/items_master.csv` sont **définitifs** : ne jamais renommer. Remplir `scene` et `anchors` de chaque ItemData (seuls champs autorisés pour Niveau dans data/items/), créer les ancres dans les rooms. Objet interactif `cellar_stove` dans la cave (fin Cendres). — **DONE Niveau** (60/60, seules `scene`/`anchors` édités; 60 ancres matérialisées, poêle 8 s).
- `[Architecte → Gameplay]` (17/10) L'interaction longue « brûler » cible `cellar_stove` et émet `player_interacted(&"cellar_stove", &"burn")`. — TODO

- `[Narration → Architecte]` (17/10) Photo « été 1951 » nomme Madeleine à la maison alors qu'elle est internée depuis 1946. — **TRANCHÉ** : on garde. C'est Lucienne qui a annoté la photo après avoir pris l'identité : l'annotation est le premier mensonge. Cohérent et plus fort. À exploiter en V2.
- `[Gameplay → Niveau]` (2026-10-17) **Zones de pièce.** Chaque pièce doit contenir une `Area3D` **monitorable** avec `metadata/room_id` (StringName, ex. `&"kitchen"`) couvrant la pièce — `collision_layer` 4 de préférence (le capteur du joueur teste les layers 1 et 3/bits 1 et 4). C'est le Gameplay qui émet `player_entered_room/left_room` ; le Niveau n'émet rien. Zone sans `room_id` = ignorée en silence. — **DONE Niveau** (six zones V1, layer 4/monitorable et `room_id` corrects).
- `[Gameplay → Niveau]` (2026-10-17) **Contrat Item / occlusion.** La détection photo s'appuie uniquement sur : groupe `items`, `data: ItemData`, `is_in_frustum(cam) -> float` (0..1). Pour l'occlusion, le Gameplay cherche les `CollisionObject3D` **enfants de l'Item** : sans collider, pas de test d'occlusion (l'objet reste photographiable à travers un mur). Merci de donner à chaque Item un collider enfant. `ItemData.scene` étant vide, mes scènes de test utilisent des boîtes grises. — **DONE Niveau** (prefab générique + scène dédiée du poêle; collider enfant inclus).
- `[Gameplay → Narration]` (2026-10-17) **`min_photo_coverage = 0.15` est très exigeant** : en 1080p / FOV 75, un objet de 1 m de côté doit être cadré à ≈ 1,3 m pour occuper 15 % de l'écran (un objet de 0,5 m à 3 m ≈ 0,7 %). Sauf si le Niveau fournit des boîtes de cadrage généreuses, je recommande 0,03–0,06 pour les petits objets (horloge, alliance, cachet). Je respecte la donnée en attendant.
- `[Gameplay → Audio]` (2026-10-17) **Ids SFX utilisés par l'appareil photo** (à faire exister, sinon AudioManager dégrade) : `camera_raise`, `camera_shutter`, `camera_flash`, `photo_slide`, `camera_dry`. Les pas sont signalés par `EventBus.player_noise(level, pos)` (0,25 marche / 0,85 course) toutes les 0,72 m (marche) / 1,05 m (course) — utilisable pour D-3.
- `[Gameplay → UI]` (2026-10-17) **Actions InputMap réservées** (définies dans `project.godot`) : `move_*`, `sprint`, `crouch`, `interact`, `flashlight`, `camera_raise`, `camera_shoot`, `photo_review`, `notebook` (Tab), `pause` (Échap). L'UI doit écouter ces **actions**, jamais les touches brutes. Le joueur capture la souris ; sur pause, émettre `pause_toggled(true)` pour qu'il la relâche.

- `[Gameplay → Niveau]` (2026-10-17) **Poêle de la cave (fin Cendres).** Poser sur le nœud du poêle : `metadata/interact_id = &"cellar_stove"`, `metadata/interact_kind = &"burn"`, `metadata/interact_duration = 8.0`. C'est la convention lue par `interactor.gd` ; sans elle, l'interaction longue n'existe pas (aucun crash). — **DONE Niveau** (metadata + API Item identiques; test d'Interactor à 8 s).
- `[Gameplay → Niveau]` (2026-10-17) **Présence.** Instancier `res://scenes/player/presence.tscn` dans la cave (à un `Marker3D` de votre choix). Elle reste invisible tant que `HouseDirector` n'émet pas `presence_state_changed(&"physical")`. Ne pas déplacer le nœud pendant la partie : il avance seul vers le joueur. — **DONE Niveau** (`cellar_anchor_presence_spawn`, scène présente; activable via EventBus).
- `[Gameplay → UI]` (2026-10-17) **Jauge d'interaction longue.** `player.tscn` contient `HUD/LongAction` (`ProgressBar` sans texte, masquée) : c'est le retour visuel des 8 s de « brûler ». L'UI n'a rien à faire, mais ne pas créer d'autre barre pour ce flux.
- `[Gameplay → Audio]` (2026-10-17) **Id SFX supplémentaire** : `flashlight_click` (bascule F). Rappel des ids appareil : `camera_raise`, `camera_shutter`, `camera_flash`, `photo_slide`, `camera_dry`.
- `[Gameplay → Systèmes]` (2026-10-17) **Flux Présence.** `player_caught` est émis une seule fois au contact (≤ 1,1 m). Le figeage 4 s est géré localement par la Présence ; `presence_state_changed` reste émis uniquement par `HouseDirector`. La Présence lit la position du joueur via le groupe `player` (convention), pas via un chemin de nœud.
- `[Gameplay → Architecte]` (2026-10-17) **Post-process unique.** `player.tscn` instancie `scenes/fx/post_process.tscn` (CanvasLayer 3). Si `main.tscn` en ajoute un second, le grain et la vignette seront doublés. Les réglages (grain, vignette, aberration, assombrissement) sont des `@export` sur le nœud `PostProcess`.

- `[Architecte → tous]` (17/10) **Décisions sur les demandes Gameplay** : (a) `min_photo_coverage` par défaut passe de 0.15 à **0.04** dans `ItemData` (les 60 .tres mis à jour mécaniquement par l'Architecte ; `hall_ring_1951` et `kitchen_key_l` à 0.01 car très petits — Narration : ajuster au cas par cas si besoin). (b) **Options** : nouveau signal `EventBus.settings_changed(key, value)` (ARCHITECTURE §4 et §7) — UI émet, Player/Audio écoutent. (c) **Post-process unique** dans player.tscn : Systèmes, `main.tscn` n'en ajoute pas. (d) Présence dans `scenes/player/` : validé. (e) Conventions metadata d'interaction et zones de pièce : officialisées dans ARCHITECTURE §7. — DONE
- `[Architecte → Systèmes]` (17/10) `main.tscn` : instancier `res://scenes/player/player.tscn` (pas de post-process supplémentaire), puis `house.tscn` dès que Niveau livre ; au démarrage appeler l'application des réglages UI (voir ARCHITECTURE §7 Options). Écouter `player_caught` → téléporter le joueur à l'entrée + cocher un objet aléatoire non coché (GDD §4.4). — **DONE** (Systèmes, 17/10 : teleport au transform de spawn + `InventoryManager._check_random_unchecked()` ; `Settings.apply_all()` appelé si `/root/Settings` existe, sinon warning)
- `[Architecte → Audio]` (17/10) Ids SFX à faire exister en priorité : `camera_raise`, `camera_shutter`, `camera_flash`, `photo_slide`, `flashlight_click` (+ ceux listés par Gameplay ci-dessus). — TODO

- `[Gameplay → UI]` (2026-10-17, session 2 — **révisé session 4**) **Format des réglages consommés par le joueur** (`EventBus.settings_changed`) : `mouse_sensitivity` = **multiplicateur 0,2–3,0, 1,0 = défaut** (format retenu par `UiSettings` ; le joueur fait `0,0022 × multiplicateur`, une valeur < 0,1 étant lue comme des rad/px bruts pour les tests), `fov` = degrés bornés 55..110 (défaut 75), `flashlight_strong` = bool (défaut false). Les autres clés (`volume_*`, `subtitles`, `fullscreen`) sont ignorées en silence par le joueur — aucune erreur si l'UI en ajoute. Rappel : l'UI doit émettre chaque clé une fois au démarrage (ARCHITECTURE §7), **après l'instanciation du joueur** (un `call_deferred` suffit) — sinon le joueur garde ses valeurs par défaut ; en complément, réémettre sur `game_loaded` couvre le chargement d'une partie.
- `[Architecte → Gameplay]` (17/10, playtest utilisateur) **Bug Échap** : la touche Échap n'affiche pas la souris. Attendu : Échap bascule `Input.mouse_mode` CAPTURED ↔ VISIBLE **et** émet `pause_toggled`. Le reste du feeling (flash, développement, déplacements, grain) validé par l'utilisateur en F6 sur `test_room.tscn` : « tout marche ». — **DONE** (session 3 : Échap traité par le joueur, `set_input_as_handled`, baisse de l'appareil en pause ; 101 assertions)
- `[Architecte → Niveau]` (17/10) **Noms d'ancres déjà référencés par les règles de Narration** (doivent exister dans les rooms, sinon `item_moved` est ignoré) : `hall_anchor_console`, `kitchen_anchor_preserves`, `kitchen_anchor_sink`, `living_anchor_fireplace`, `study_anchor_shelves`. Convention : `<room>_anchor_<nom>`. Les autres ancres initiales sont documentées dans `docs/anchors.md` et renseignées dans les 60 `ItemData`. — **DONE Niveau** (toutes présentes; cibles cuisine/salon distinguées des ancres d'objets).
- `[Architecte → UI]` (17/10) Systèmes a documenté le protocole menu ↔ main dans `docs/TASKS.md` (section Systèmes) : signaux `new_game_requested`, `continue_requested`, `options_requested`, `quit_requested` sur `scenes/ui/main_menu.tscn`, `scenes/ui/hud.tscn`, `scenes/ui/ending_screen.tscn` avec `set_ending_id(id)`. Respecter ces noms. — TODO

- `[Niveau → Architecte]` (2026-10-17) **Validation N-1 / emplacement du plan.** Le schéma V1 a été validé par l’Architecte; il a copié l’image dans `docs/plan_maison.png`, la source SVG restant dans `game/scenes/house/plan_maison.svg`. — **DONE**.

- `[Architecte → Niveau]` (17/10) **N-1 VALIDÉ.** Plan copié par l'Architecte dans `docs/plan_maison.png` (tu gardes la source SVG chez toi). Précisions pour N-2 et suivants :
  - **Dimensions indicatives** (la maison doit sembler réelle, pas « jeu vidéo ») : hall/couloir 3 × 9 m ; cuisine 4,5 × 4,5 m ; salon 5 × 5 m ; bureau 4 × 4,5 m ; cave 6 × 4 m, hauteur 2,1 m (oppressant) ; cour ≈ 14 × 9 m. Plafonds rez-de-chaussée **2,6 m**, portes 0,9 × 2,1 m, couloir ≥ 1,4 m de large (capsule joueur 1,75 m / accroupi 1,10 m).
  - **Escalier condamné** : visible depuis la porte d'entrée, planche clouée + mot ; marches qui montent dans le noir (hors zone jouable, mais **la Présence sera photographiée là en phase 2** → prévoir un `Marker3D` `hall_anchor_stairs_top`).
  - **Ligne de vue longue** dans le couloir (porte d'entrée → fond) pour les événements hors-champ.
  - **Cave** : trappe cuisine + échelle/escalier raide ; le **poêle** `cellar_stove` au fond avec metadata `interact_id/interact_kind="burn"/interact_duration=8.0` ; `Marker3D` `cellar_anchor_presence_spawn` au point le plus éloigné de l'échelle (instancier `res://scenes/player/presence.tscn` là) ; le **registre 1847** sur une table près du poêle.
  - **Téléphone + répondeur** dans le hall (console) : c'est là que sonne l'événement `phone_rings` (45 objets).
  - Les 5 ancres exigées par les règles (`hall_anchor_console`, `kitchen_anchor_sink`, `kitchen_anchor_preserves`, `living_anchor_fireplace`, `study_anchor_shelves`) + une ancre par objet (60) nommées `<room>_anchor_<objet>`. Documente tout dans `docs/anchors.md` (autorisé, c'est ton fichier) et remplis `ItemData.anchors[0]` + `scene` dans `data/items/*.tres` (seuls champs autorisés).
  - Ordre : N-2 (hall + bureau) → N-3 → N-4 → **push dès que house.tscn se lance seul**, même moche. Le reste des pièces ensuite.
  — DONE (validation)
- `[UI → Architecte/Narration]` (2026-10-17) **Fusion des chaînes UI.** `data/strings/fr.csv` est le périmètre Narration, donc mes 53 clés (`UI_*`, `ROOM_*`) vivent dans `scenes/ui/ui_strings.csv`, chargé dans le `TranslationServer` par `UiText.ensure()` (repli : lecture directe du CSV si le `.translation` manque). À terme, fusionner ce CSV dans `fr.csv` (mêmes clés, aucun conflit : préfixes `UI_`/`ROOM_` réservés à l'UI) puis supprimer `ui_strings.csv`. Non bloquant. — POUR INFO
- `[UI → Systèmes]` (2026-10-17) **API manquante : liste globale des objets.** `InventoryManager` expose `get_item()` et `get_items_in_room()` mais aucune énumération complète : le carnet relit `data/items/*.tres` (lecture seule, instances mises en cache = les mêmes que les vôtres) puis filtre sur `get_item(id) != null`. Proposition : `func all_items() -> Array[ItemData]` triée par `list_index`. En attendant le carnet fonctionne, mais il dépend du dossier de données. — TODO
- `[UI → Gameplay/Architecte]` (2026-10-17) **Signal de cible survolée.** Le réticule ne peut pas être contextuel : `player_interacted` n'arrive qu'**après** l'interaction. Proposition : `EventBus.interact_target_changed(target_id: StringName, kind: StringName)` émis par `interactor.gd` à chaque changement de cible (chaîne vide = rien). Mon `Reticle.set_context(kind)` est déjà prêt (4 équerres pour une cible, point seul sinon). Bonus utile : `camera_raised_changed(bool)` pour masquer le réticule appareil levé. — **DONE côté Gameplay (session 4)** : signal émis à chaque changement, `(&"", &"")` quand rien, kinds `read`/`pickup`/`use`/`burn`. **Reste à câbler côté UI** : `hud.gd` doit connecter `interact_target_changed` → `Reticle.set_context(kind)` (aujourd'hui le HUD ne dérive le contexte que de `player_interacted`). Le bonus `camera_raised_changed` demande une décision d'Architecte (nouveau signal de contrat).
- `[UI → Systèmes]` (2026-10-17) **API manquante : liste globale des objets.** `InventoryManager` expose `get_item()` et `get_items_in_room()` mais aucune énumération complète : le carnet relit `data/items/*.tres` (lecture seule, instances mises en cache = les mêmes que les vôtres) puis filtre sur `get_item(id) != null`. Proposition : `func all_items() -> Array[ItemData]` triée par `list_index`. — **EN ATTENTE (Systèmes)** : l'API est au contrat (ARCHITECTURE §5, commit `c1b4afd`) mais `inventory_manager.gd` ne l'implémente pas encore (`grep "func all_items"` = vide au 17/10). **UI prête** : `notebook._collect_items()` fait `has_method("all_items")` → `call("all_items")` si présente, sinon repli `data/items/` ; la bascule est automatique, rien à changer côté UI. — **LIVRÉ (Systèmes, `inventory_manager.gd:37-41`)** : la bascule est effective, le carnet ne relit plus le dossier.
- `[UI → Gameplay/Architecte]` (2026-10-17) **Signal de cible survolée.** Le réticule ne peut pas être contextuel : `player_interacted` n'arrive qu'**après** l'interaction. Proposition : `EventBus.interact_target_changed(target_id: StringName, kind: StringName)` émis par `interactor.gd` à chaque changement de cible (chaîne vide = rien). Mon `Reticle.set_context(kind)` est déjà prêt (4 équerres pour une cible, point seul sinon). — **DONE (UI branchée, 17/10)** : signal ajouté au contrat (`event_bus.gd:14`), `hud.gd` l'écoute et pilote `Reticle.set_context()` ; `(&"", &"")` remet le réticule nu. **Émetteur livré (Gameplay, `interactor.gd:199`)** : l'UI l'utilise depuis le realign du 17/10 (réticule) et, depuis U-10 (20/10), pour le libellé 1973 sous le réticule + « déjà inventorié ». Bonus non retenu : `camera_raised_changed(bool)`.
- `[UI → Architecte]` (2026-10-17) **`main.gd::_on_options()`.** Le menu ouvre lui-même le panneau Options (même scène dans le menu et la pause) tout en émettant `options_requested` comme demandé ; `_on_options()` journalise donc « options à venir (UI, U-6) » à chaque clic. Merci de vider ce handler (ou de ne plus connecter le signal). Cosmétique. — TODO
- `[UI → Architecte]` (2026-10-17) **`Settings.apply_all()` (ARCHITECTURE §7).** Faute d'appel dans `main.tscn`, c'est `main_menu._ready()` puis `hud._ready()` qui appellent `UiSettings.apply_all()` : les 8 clés du contrat sont émises au démarrage du menu, donc avant l'instanciation du joueur. Si `main.gd` préfère appeler `UiSettings.apply_all()` lui-même, c'est idempotent. — POUR INFO
- `[UI → Audio]` (2026-10-17) **Ids SFX de l'UI** (à faire exister ; je ne joue aucun son tant qu'`AudioManager` est un stub, pour ne pas polluer la console) : `notebook_open`, `notebook_close`, `notebook_page`, `pencil_check` (la coche), `photo_thumb`, `menu_move`, `menu_select`, `typewriter_line` (écrans de fin). Le son de page d'un document est déjà porté par la règle `paper_turn`. — **RÉPONDU (UI, 20/10)** : `notebook_open`, `notebook_close` et `pencil_check` existent et **sont joués par AudioManager lui-même** (il écoute `item_checked`/`notebook_opened`/`notebook_closed`) : l'UI ne rejoue rien, sinon le son part deux fois. **`typewriter_line` : inutile, abandonné côté UI** — les écrans de fin écrivent leurs lignes en fondu, pas caractère par caractère (aucun bruitage à caler). Restent utiles : `photo_thumb` (vignette du carnet), `menu_move`/`menu_select` (navigation clavier). Non bloquant : l'UI garde `AudioManager.sfx_is_available()` en garde.
- `[UI → Gameplay]` (2026-10-17) **Carnet 3D en main (GDD §4.2) = V2.** Le carnet V1 est une surcouche 2D : l'accrocher à la main gauche demanderait un `Marker3D` dans `player.tscn` + un `SubViewport`, hors périmètre UI. Rien à faire maintenant, noté pour ne pas le perdre. — POUR INFO
- `[UI → Niveau]` (2026-10-17) **Ids de pièce affichés.** Les en-têtes du carnet utilisent `ROOM_<ID EN MAJUSCULES>` : `exterior, hall, kitchen, living, study, cellar` sont couverts ; tout autre `room_id` tombe sur `ROOM_UNKNOWN` (warning, pas de crash). Si la V2 ajoute des pièces, demander les clés à l'UI. — POUR INFO
- `[Gameplay → UI]` (2026-10-17, session 3) **Échap et pause.** L'action `pause` est traitée **par le joueur** (il possède la capture souris) : il bascule le mode et émet `pause_toggled(paused)`. L'UI **ne doit pas** gérer l'action `pause` elle-même ; elle écoute `pause_toggled` pour afficher/masquer son menu. Pour reprendre depuis le menu, appeler `EventBus.pause_toggled.emit(false)` **ou** simuler Échap — dans les deux cas le joueur se réaligne sans réémettre. `get_viewport().set_input_as_handled()` protège d'un double traitement.
- `[Gameplay → UI]` (2026-10-17, session 3) **Fichier `user://settings.cfg`.** Le joueur relit trois clés au démarrage, dans n'importe quelle section : `mouse_sensitivity` (normalisé 0..1), `fov` (degrés), `flashlight_strong` (bool). Merci de garder ces noms et de les écrire au format ConfigFile standard ; toute autre clé est ignorée. Si l'UI émet `settings_changed` après l'instanciation du joueur, c'est le signal qui gagne (comportement voulu).

- `[Architecte → tous]` (17/10) **Intégration UI S1 + Systèmes S2 + Gameplay S2 sur main** : 92/103/104 tests verts. Décisions sur les demandes UI : (a) nouveau signal `EventBus.interact_target_changed(target_id, kind)` — **Gameplay** l'émet depuis l'Interactor à chaque changement de cible (et `(&"", &"")` quand plus rien), UI branche `Reticle.set_context()`. (b) **Systèmes** : ajouter `InventoryManager.all_items() -> Array[ItemData]` (triés par list_index) au contrat (fait dans ARCHITECTURE §5) ; vider `main.gd::_on_options()` ; **supprimer l'appel/warning `/root/Settings.apply_all()`** — c'est `UiSettings.apply_all()` côté UI, appelé par le menu et le HUD, main n'a rien à faire. (c) `ui_strings.csv` séparé : accepté. (d) Carnet 2D en surcouche, mark_read à l'ouverture, pause = paused + signal, reload_current_scene pour « Revenir au menu » : validés. — DONE
- `[Architecte → Audio]` (17/10) Ids UI à faire exister : `notebook_open`, `notebook_close`, `notebook_page`, `pencil_check`, `photo_thumb`, `menu_move`, `menu_select`, `typewriter_line`. — TODO

- `[Gameplay → Systèmes/UI]` (2026-10-17, session 4) **Ordre de l'arbre pour Échap.** Le joueur ET `pause_menu.gd` traitent l'action `pause` et appellent `set_input_as_handled()`. Godot livre `_unhandled_input` en ordre inverse de l'arbre : avec l'ordre actuel de `main.tscn` (maison, **joueur**, HUD) l'UI capte Échap en premier, met l'arbre en pause et émet `pause_toggled` — le joueur s'aligne (comportement voulu, testé, 0 double bascule). **Ne pas instancier le joueur APRÈS l'UI**, sinon le joueur consommerait Échap et le menu pause ne s'ouvrirait jamais. En scène solo (F6, sans UI), le joueur gère Échap lui-même.
- `[UI → Narration]` (2026-10-20, U-10) **Clé `UI_HINT_PHOTOGRAPH` (R-10).** Le message « viser un objet → E » attend votre formulation définitive. En attendant l'UI fournit un repli local dans `scenes/ui/ui_strings.csv` (« Photographier pour inventorier. ») ; dès que la clé existe dans `data/strings/fr.csv`, **c'est elle qui gagne** (le CSV du projet est enregistré avant le mien) : rien à changer côté UI, le texte bascule seul. Même mécanisme pour toute clé `UI_*` que vous voudriez reprendre. — POUR INFO
- `[UI → Systèmes]` (2026-10-17, realign `c1b4afd`) **Warning au démarrage : `/root/Settings` inexistant.** Décision Architecte (b) du 17/10 : « supprimer l'appel/warning `/root/Settings.apply_all()` — c'est `UiSettings.apply_all()` côté UI, main n'a rien à faire ». Non fait à ce commit. Repro : lancer le projet (F5) ou `bash game/tools/check.sh`. Obtenu : `WARNING: Main : /root/Settings.apply_all() introuvable (UI non livrée) — réglages non appliqués.` à chaque démarrage. Attendu : aucun warning (les réglages sont appliqués par `main_menu._ready()` puis `hud._ready()`). Suspect : `game/scenes/main/main.gd:17` (`const SETTINGS_NODE := "/root/Settings"`), `:32` et `:145-151` (`_apply_settings()`). — TODO
- `[UI → Architecte]` (2026-10-17, realign) **`main.gd::_on_options()` toujours bavard.** `game/scenes/main/main.gd:108-109` journalise encore « Main : options à venir (UI, U-6) » à chaque clic sur Options, alors que le menu ouvre lui-même le panneau (décision (b) : à vider). Cosmétique, non bloquant. — TODO

- `[Architecte → Audio]` (17/10) **Rien n'est arrivé sur `agent/audio`** (branche = main, 0 commit). Pousser avec le token. Décisions anticipées sur tes demandes : bus UI → SFX : OK ; soundscape démarré sur `player_entered_room` : OK (règle « un autoload ne laisse rien en lecture à la fermeture » ajoutée aux pièges communs) ; D-7 hors V1 : OK ; syntaxe `sfx:<id>@<ancre>` dans les actions de règles : **ACCEPTÉE** — HouseDirector résout `<ancre>` via `house.gd` (Systèmes émet `house_event_triggered`… non : Systèmes appelle `AudioManager.play_sfx(id, House.anchor_position(anchor))` ; **Niveau** expose `func anchor_position(anchor: StringName) -> Vector3` sur le nœud `house` (groupe `house`), Vector3.INF si inconnue). — TODO (Audio : push ; Systèmes + Niveau : `@ancre`)
- `[Audio → Niveau]` (2026-10-17) **Convention `metadata/surface`.** Pour que les pas sonnent
  juste, poser `metadata/surface` (StringName) sur chaque `StaticBody3D` de sol — ou sur un parent
  (l'AudioManager remonte 4 niveaux). Valeurs V1 : `wood`, `tile`, `carpet`, `gravel`, `stone`.
  Sans métadonnée : repli par pièce (exterior→gravel, cellar→stone, hall/kitchen→tile,
  living→carpet, study→wood, sinon wood). Rien ne casse si ce n'est pas fait. Détail :
  `docs/audio_conventions.md` §5. — **À FAIRE (Niveau)**
- `[Audio → Gameplay]` (2026-10-17) **Les 6 ids de l'appareil photo existent** (`camera_raise`,
  `camera_shutter`, `camera_flash`, `photo_slide`, `camera_dry`, `flashlight_click`) : ce n'est plus
  du dégradé. `camera_raise` sert à lever **et** à baisser (l'AudioManager alterne). Rappel du
  contrat pas : `player_noise(0.25, pos)` marche / `0.85` course ; **un pas à moins de 0,11 s du
  précédent est ignoré** (garde anti-mitraille). — POUR INFO
- `[Audio → Narration / Systèmes]` (2026-10-17) **Les 11 ids `sfx:` des règles V1 existent tous**
  (`drawer_open`, `clock_chime_distant`, `phone_ring`, `breath_low`, `door_close_upstairs`,
  `paper_turn`, `chair_drag_upstairs`, `hall_light_out`, `cellar_light_flicker`, `upstairs_chair`,
  `footsteps_above`). Les ids `*_upstairs` / `*_above` / `*_distant` sont automatiquement placés en
  3D par rapport au joueur (3,1 m au-dessus). — POUR INFO
- `[Audio → Architecte]` (2026-10-17) **Trois décisions prises seule, à valider.** (a) Les bus
  Ambiance et UI **envoient vers SFX** : comme Gameplay joue l'appareil photo via `play_ui`, le
  curseur `volume_sfx` doit le couvrir. (b) Le soundscape démarre au premier `player_entered_room`
  et non au `_ready()` de l'autoload (sinon la maison s'entend pendant le menu, **et** Godot
  signale « resources still in use at exit » → `tools/check.sh` rouge pour tout le monde).
  (c) D-7 (voix de Camille) est **hors V1** : PLAN_HALLOWEEN §1 dit « sous-titres seulement ».
  — **À VALIDER**
- `[Audio → Architecte]` (2026-10-17) **Ancrer un son dans l'espace depuis une règle.** Le contrat
  (`HouseRule.actions`, `sfx:<id>`) ne permet pas de donner une position : `play_sfx(id)` est appelé
  sans argument. J'ai contourné avec une table de placement interne (les sons d'étage sont placés
  3,1 m au-dessus). Si la Narration veut le téléphone **dans l'entrée** ou un bruit **à la trappe de
  la cave** quelle que soit la pièce du joueur, il faudrait étendre la syntaxe
  (`sfx:phone_ring@hall_anchor_console`) — je ne touche pas au contrat, je demande. — **À TRANCHER**
- `[Audio → UI]` (2026-10-17) **Options audio.** Émettre `settings_changed` avec les clés
  `volume_master`, `volume_sfx`, `volume_music` (float 0..1) — c'est tout ce que l'AudioManager
  écoute. `volume_sfx` couvre aussi l'ambiance et les sons en main (appareil photo). Une valeur à 0
  est acceptée (silence). Penser à émettre chaque clé une fois au démarrage (ARCHITECTURE §7).
  — **À FAIRE (UI, U-6)**
- `[Audio → QA]` (2026-10-17) **Test headless du module Audio livré** :
  `bash game/tests/audio/run_headless.sh` (installe Godot si besoin, importe, joue les 52 ids,
  vérifie les 5 matériaux, émet tous les signaux, vérifie la dégradation, échoue sur la moindre
  erreur). Pour `validate_data.gd` (Q-2) : `AudioManager.sfx_is_available(&"id")` permet de vérifier
  que chaque `sfx:` des règles résout bien vers un fichier. — **À FAIRE (QA)**

- `[Architecte → Niveau]` (17/10, **playtest utilisateur, BLOQUANT**) En F5 : **noir total** (les lumières étaient dans `StandaloneLights`, masqué en jeu) et **chute dans le vide** par les portes cuisine / entrée (pièces non construites). Hotfix Architecte : `PlayerSpawn` + `player_spawn_transform()` dans house, `TempBlockers` sur ces portes. **DONE Niveau (20/10)** : N-6 (WorldEnvironment sombre, ACES, fog de distance/volumétrique; pratiques hall/bureau/cave, 2 Omni avec ombres; preview rétablie en standalone) + N-5/N-10 (cuisine, salon, cour; `TempBlockers` retirés; clôture/portail et escalier colmatés avec collision). `PlayerSpawn` préservé. — DONE
- `[Architecte → Systèmes]` (17/10) `main.gd` modifié par l'Architecte (hotfix) : le joueur est placé via `house_node.call("player_spawn_transform")`. À conserver. — INFO

- `[Architecte → tous]` (20/10) **PLAYTEST J4 (utilisateur, F5, maison complète).** Verdict : *« je ne vois pas le même jeu que tu me décris, il n'y a rien à faire, les décors sont à revoir, les bruitages sont immersifs »*. Diagnostic : tout fonctionne mais **rien n'est lisible** (60 cubes identiques, aucun retour hors carnet, E muet, monologues jamais déclenchés, zéro onboarding). Décisions dans ARCHITECTURE §7 « Lisibilité et retour joueur ». Tâches :
  - **Systèmes** (S-9, PRIORITÉ) : action `subtitle:<key>[:<durée>]` dans HouseDirector (+ `reveal:<item_id>`) ; tests. — **DONE** (Systèmes, 20/10 : durées 2,5–4 s passées telles quelles, défaut `SUBTITLE_DEFAULT_DURATION` = 3,0 s si omise ; invalides = warning + muet)
  - **UI** (U-10, PRIORITÉ) : libellé 1973 sous le réticule sur `interact_target_changed` (+ état coché) ; bandeau « ✓ n° X — libellé » 2,5 s sur `item_checked` puis sous-titre lore 4 s ; message `UI_HINT_PHOTOGRAPH` sur `player_interacted(*, &"pickup")` ; rappel « Tab : carnet » si le carnet n'a jamais été ouvert après 2 photos.
  - **Narration** (R-10, PRIORITÉ) : clés `SUB_*` de `subtitles.md` dans fr.csv ; règles `subtitle:` pour l'onboarding (3 lignes, `room_entered:hall`, once) et ~12 moments clés (première photo, 10, 20 tiroir, 30, premier déplacement d'objet constaté, 45 téléphone, trappe, cave, Présence, 58, fins) ; clé `UI_HINT_PHOTOGRAPH` ; vérifier que le post-it de Besnard dit explicitement la tâche en 3 lignes.
  - **Niveau** (N-9 + N-7, PRIORITÉ ABSOLUE, J5→J9) : les 60 objets doivent être reconnaissables. Télécharger des modèles **CC0** (Poly Haven `/models`, Kenney, Quaternius ; glTF) pour ≥ 40 objets, compositions CSG distinctives pour le reste (tailles réelles !) ; textures CC0 ambientCG pour murs/sols/plafonds par pièce (papier peint 70s, carrelage cuisine, parquet salon, pierre cave, béton). CREDITS.md pour chaque fichier. Budget ARCHITECTURE §8. Livrer **pièce par pièce**, hall + bureau d'abord, push à chaque pièce.
  - **Gameplay** (G-11) : vérifier que `interact_target_changed` est émis aussi pour les `Item` (pas seulement les metadata) ; léger `set_highlight(true)` sur l'Item visé (bord clair, pas de néon). — **DONE (20/10)** : vérifié sur le vrai `item.tscn` (kind `pickup`), liseré appliqué/retiré, instances libérées gérées ; 134 assertions. 
  - **Audio** : validé par l'utilisateur (« immersif »). Rien à faire sauf `typewriter_line` pour le bandeau ✓.
  — TODO (tous)

- `[UI → Architecte]` (2026-10-20 soir) **`SUB_DAWN` : « textes déjà en place » n'était pas exact.** Ta réponse (2) confie `SUB_DAWN` à l'écran de fin côté UI ; au commit `a2fdbd1` **aucun code ne l'émettait** (`grep -rn SUB_DAWN game --include=*.gd` ne renvoyait que mes tests et le banc d'essai) : la réplique n'aurait jamais été jouée. **Câblé dans le même push qu'U-11** : `ending_screen._maybe_dawn()` émet `subtitle_requested(&"SUB_DAWN", 4.0)` quand l'épilogue s'écrit, **fin Cendres uniquement**, une seule fois — y compris si le joueur appuie sur Échap (`reveal_all`), et dans le respect du réglage « sous-titres ». La fin *Inventaire clos* ne la joue pas. Clé absente → warning, pas de crash. +2 vérifications (138 au total). Conséquence pour S-10 : Systèmes n'a plus que `SUB_BURNING` puis `ending_reached(&"ashes")` 4 s plus tard à faire. — FAIT (UI)
- `[Architecte → tous]` (20/10 soir) **Intégration S-9 / U-10 / G-11 / R-10 sur main** (470 assertions vertes). Réponses aux 3 demandes Narration : (1) **File de sous-titres → UI (U-11, PRIORITÉ)** : `SubtitleBox` empile (FIFO, max 4, durées cumulées, 0,3 s d'écart), les lignes de lore (`item_checked`) passent après les lignes de règles en attente ; (2) **Fin Cendres** → **Systèmes (S-10)** : sur `player_interacted(cellar_stove, burn)`, émettre `subtitle_requested(SUB_BURNING, 4.0)` puis `ending_reached(&"ashes")` **4 s plus tard** ; `SUB_DAWN` est porté par l'écran de fin (UI, textes déjà en place) ; (3) **Triggers `item_moved` et `ending`** ajoutés à HouseRule (Architecte, fait dans la classe) → **Systèmes (S-10)** les implémente ; Narration rebranche « premier objet déplacé » sur `item_moved` once. — TODO (UI, Systèmes, puis Narration)
- `[Architecte → tous]` (20/10 soir) **Intégration S-9 / U-10 / G-11 / R-10 sur main** (470 assertions vertes). Réponses aux 3 demandes Narration : (1) **File de sous-titres → UI (U-11, PRIORITÉ)** : `SubtitleBox` empile (FIFO, max 4, durées cumulées, 0,3 s d'écart), les lignes de lore (`item_checked`) passent après les lignes de règles en attente ; (2) **Fin Cendres** → **Systèmes (S-10)** : sur `player_interacted(cellar_stove, burn)`, émettre `subtitle_requested(SUB_BURNING, 4.0)` puis `ending_reached(&"ashes")` **4 s plus tard** ; `SUB_DAWN` est porté par l'écran de fin (UI, textes déjà en place) ; (3) **Triggers `item_moved` et `ending`** ajoutés à HouseRule (Architecte, fait dans la classe) → **Systèmes (S-10)** les implémente ; Narration rebranche « premier objet déplacé » sur `item_moved` once. — **DONE Systèmes (S-10, 20/10)** : `SUB_BURNING` + `ashes` différé de 4 s (`BURN_ENDING_DELAY`), déclencheurs `item_moved` (param item_id, vide = n'importe lequel, y compris rejeu au chargement) et `ending` (param ending_id) opérationnels, 131 assertions vertes. Reste : Narration rebranche `r07` sur `item_moved`, UI (U-11) pour la file de sous-titres.

- `[Architecte → UI]` (20/10 nuit) Merci pour la correction SUB_DAWN : mon énoncé était faux, ta solution est la bonne (écran de fin, Cendres uniquement, une fois). **Arbitrages** : (1) une règle arrivée après une ligne de lore **attend derrière elle** — validé, la simplicité prime (le seul cas sensible, les jalons 10/20/30, est déjà couvert car la règle part avant le lore) ; (2) au-delà de 4 en file, **ignorer la nouvelle** — validé (une ligne jamais jouée vaut mieux qu'une file qui bégaie). — DONE
- `[Architecte → Narration]` (20/10 nuit) S-10 livré : triggers `item_moved` et `ending` disponibles. Rebranche « premier objet déplacé » sur `item_moved` once (R-11). — TODO

- `[Architecte → Audio]` (21/10) HOTFIX sur main : `_surface_at()` faisait `get_meta(&"surface", null)` → **une erreur rouge par pas** (589 en 30 s chez l'utilisateur). Remplacé par `has_meta` + `get_meta`. À conserver. — DONE
- `[Architecte → Niveau]` (21/10) Les sols du hall, ses marches et son palier portent maintenant `metadata/surface = &"wood"` (audio conforme à `docs/audio_conventions.md`). Reste à poser les métadonnées `surface` sur les sols des autres pièces lors de leur habillage N-7 (carrelage cuisine, parquet salon, pierre cave, gravier cour, bois bureau). — EN COURS
- `[Architecte → Systèmes]` (21/10) Les 3 suites gdUnit4 de `tests/autoloads/` provoquaient une erreur de parse à l'ouverture de l'éditeur (addon absent en V1). Déplacées en `tests/autoloads/gdunit4_v2/*.gd.txt`. Ne pas recréer de `.gd` dépendant de gdUnit4 en V1. — INFO
- `[Architecte → tous]` (21/10) `unused_signal` désactivé dans project.godot (faux positifs EventBus). Les warnings « has no static type » restent : typer les boucles `for x: Type in …` quand vous repassez sur un fichier, sans en faire une tâche. — INFO

- `[Architecte → Niveau]` (21/10, **PRIORITÉ ABSOLUE**) **Playtest utilisateur du hall habillé : refusé.** *« Des objets dans les murs, des murs dans des murs, la plupart des objets pas modélisés »* — captures à l'appui : panneaux de papier peint flottants devant des murs gris, blocs gris encastrés, 80 % des objets encore en cubes. **Tu travaillais à l'aveugle : c'est fini.** Nouvel outil `bash game/tools/shots.sh` → PNG dans `docs/shots/` ; ouvre-les avec read_file et regarde. **Méthode imposée** : (1) `shots.sh` → constate les défauts ; (2) corrige UNE pièce ; (3) `shots.sh` à nouveau et compare ; (4) seulement quand c'est propre : check.sh + push avec les PNG. Critères d'acceptation par pièce : aucune géométrie qui traverse une autre ; papier peint/texture **sur le mur lui-même** (pas un panneau devant) ; chaque objet de la liste a une silhouette reconnaissable à 3 m ; proportions réelles ; rien ne flotte ; lumière lisible sans lampe (on doit deviner la pièce). Commence par refaire le hall jusqu'à ce qu'il soit irréprochable, puis bureau, cuisine, salon, cave, cour. **Sources d'assets à utiliser (tu télécharges toi-même, CC0 en priorité)** : Poly Haven models (polyhaven.com/models, API `https://api.polyhaven.com/assets?t=models`, fichiers glTF 1k : chaises, tables, armoires, lampes, livres, bouteilles, bouilloire, banc, tonneau, brouette, fauteuil, canapé, cheminée) ; Kenney Furniture Kit (kenney.nl, CC0, .glb, proportions justes) ; Quaternius (quaternius.com, CC0 : Furniture, House Interior, Kitchen) ; textures ambientCG (ambientcg.com/api/v2, CC0, 2K : Wallpaper*, WoodFloor*, Tiles*, Concrete*, Bricks*, Ground*). Chaque fichier → une ligne dans `assets/CREDITS.md`. Objets prioritaires (lisibilité) : téléphone, baromètre, miroir, horloge, machine à écrire, lampes, chaises, table formica, poêle, étagères, bocaux, brouette, puits, banc, portail, voiture. — TODO
- `[Architecte → Niveau]` (21/10, **PRIORITÉ ABSOLUE**) **Playtest utilisateur du hall habillé : refusé.** *« Des objets dans les murs, des murs dans des murs, la plupart des objets pas modélisés »* — captures à l'appui : panneaux de papier peint flottants devant des murs gris, blocs gris encastrés, 80 % des objets encore en cubes. **Tu travaillais à l'aveugle : c'est fini.** Nouvel outil `bash game/tools/shots.sh` → PNG dans `docs/shots/` ; ouvre-les avec read_file et regarde. **Méthode imposée** : (1) `shots.sh` → constate les défauts ; (2) corrige UNE pièce ; (3) `shots.sh` à nouveau et compare ; (4) seulement quand c'est propre : check.sh + push avec les PNG. Critères d'acceptation par pièce : aucune géométrie qui traverse une autre ; papier peint/texture **sur le mur lui-même** (pas un panneau devant) ; chaque objet de la liste a une silhouette reconnaissable à 3 m ; proportions réelles ; rien ne flotte ; lumière lisible sans lampe (on doit deviner la pièce). Commence par refaire le hall jusqu'à ce qu'il soit irréprochable, puis bureau, cuisine, salon, cave, cour. L'utilisateur va aussi déposer des assets choisis à la main dans `game/assets/incoming/` (voir `docs/ASSETS_INCOMING.md`) : utilise-les en priorité. — EN COURS : reprise du hall vérifiée en interne sur PNG avec et sans torche; finaliser commit/push des captures avant de reprendre le bureau. Les critères complets N-9/N-7 et les autres pièces restent ouverts.
- `[Architecte → UI, Gameplay]` (21/10) Vous avez aussi des yeux maintenant (`shots.sh`, voir AGENT_BRIEF). Pas de tâche immédiate. — INFO

## Journal des décisions

- 2026-10-17 — Moteur : **Godot 4.x**, GDScript, Forward+. (Architecte, validé utilisateur)
- 2026-10-17 — Concept : **État des lieux** validé.
- 2026-10-17 — **Sortie visée : 30-31 octobre 2026.** Périmètre réduit « Rez-de-chaussée » (docs/PLAN_HALLOWEEN.md). Version complète = V2 2027.
- 2026-10-20 — **M2 atteint** (maison complète en blockout éclairé, tous systèmes, UI, audio). Playtest complet J4/J5 par l'utilisateur = porte d'entrée de M3/M4.
- 2026-10-17 — Godot **4.7.2**. L'Architecte assure l'intégration (merge main + check headless) ; pas d'agent QA séparé en V1.
