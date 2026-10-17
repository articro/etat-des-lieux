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
| A0-4 | Version Godot = **4.7.2**, `config/features` ajusté, check headless OK | DONE |
| A0-5 | Outils : `tools/check.sh`, `tools/install_godot_sandbox.sh`, `tools/run_tests.sh` | DONE |
| A0-6 | Plan Halloween 2026 (périmètre réduit, calendrier) | DONE |

## Module Gameplay `[Gameplay]` — `scenes/player/`, `scenes/fx/`

| ID | Tâche | Jalon | Statut |
|---|---|---|---|
| G-1 | Contrôleur FPS (marche/course/accroupi, essoufflement, head-bob subtil, ZQSD + QWERTY via physical keys) | M1 | DONE |
| G-2 | Système d'interaction (raycast, surbrillance discrète, prendre/inspecter/reposer un objet, portes & tiroirs physiques à la souris) | M1 | TODO |
| G-3 | Appareil photo : visée (lever l'appareil, viseur), déclenchement, consommation film, SubViewport capture, flash lumière + aveuglement, son via AudioManager | M1 | TODO |
| G-4 | Détection des objets cadrés (frustum + occlusion raycast + couverture écran ≥ `min_photo_coverage`), construction PhotoData | M1 | TODO |
| G-5 | Photo en main : sortie de l'appareil, développement 10 s (shader), consultation | M1 | TODO |
| G-6 | Lampe de poche faible, batterie infinie, option « plus forte » | M1 | TODO |
| G-7 | Post-process : grain, vignette, aberration légère, aveuglement flash (scenes/fx) | M2 | TODO |
| G-8 | Présence : nœud `Presence` (déplacement lent par NavigationAgent3D, états via `presence_state_changed`, figée 4 s si photographiée, contact → `player_caught`) | M3 | TODO |
| G-9 | Interactions longues (brûler carnet 8 s, signer registre) avec annulation | M3 | TODO |
| G-10 | Zones de pièce (Area3D → `player_entered_room/left_room`) — en coordination avec Niveau | M1 | DONE (côté Gameplay) |

### Notes Gameplay (V1 Halloween)

- **2026-10-17 — Socle.** `[input]` ajouté à `project.godot` (13 actions, physical_keycode : ZQSD+WASD, Maj, Ctrl/C, E, F, clic droit/gauche, P, Tab, Échap). Filet de sécurité `scenes/player/input_actions.gd` : recrée les actions manquantes à l'exécution (si fusion/porte). `player.tscn` (CharacterBody3D + caméra) et `scenes/player/test_room.tscn` (sol, 3 Item placeholders, zone de pièce, occluder) se lancent seuls. Test item : `tests/player/test_item.gd` (contrat `Item` respecté).
- **2026-10-17 — G-1 DONE.** `player.gd` : marche 2,5 / course 4,0 m/s (accél. 14), accroupi maintenu (capsule 1,75 → 1,10 m), essoufflement (18/s, récup. 30), head-bob + pas → `player_noise` (0,25 marche / 0,85 course), pas de saut, souris capturée, `pause_toggled` respecté, retour auto si chute. Vérifié : 38 assertions headless (`tests/player/player_tests.tscn`, 0 échec).
- **2026-10-17 — G-10 DONE (côté Gameplay).** `RoomSensor` (Area3D enfant du joueur) détecte les zones `Area3D` monitorables portant `metadata/room_id` et émet `player_entered_room/left_room` (bascule entre zones chevauchées gérée). Convention déposée en Demandes inter-modules ; en attendant les zones du Niveau, `test_room` en fournit une.

## Module Systèmes `[Systèmes]` — `autoloads/`, `scenes/main/`

| ID | Tâche | Jalon | Statut |
|---|---|---|---|
| S-1 | GameState complet + to/from_save_dict | M1 | TODO |
| S-2 | InventoryManager : chargement de `data/items/*.tres`, check/reveal/film, progression, signaux | M1 | TODO |
| S-3 | HouseDirector : moteur de règles (HouseRule), parser du mini-langage de condition, attention (montée/descente), actions (`move_item`, `event`, `attention`, `presence`, `sfx`) | M1 | TODO |
| S-4 | DocumentLibrary | M1 | TODO |
| S-5 | SaveManager : JSON, auto-save à `player_entered_room`, versionnage | M2 | TODO |
| S-6 | main.tscn : séquence de démarrage (menu → chargement maison → spawn joueur → UI), gestion des fins (`ending_reached` → scène de fin) | M2 | TODO |
| S-7 | Séquenceur d'actes : seuils 60/140 → `act_changed`, événements de fin d'acte | M2 | TODO |
| S-8 | Logique des 4 fins (conditions, déclenchement) | M3 | TODO |

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
- `[Narration → Audio]` (2026-10-17) **Ids SFX utilisés par les règles V1** (à exister, sinon AudioManager dégrade) : `drawer_open`, `clock_chime_distant`, `phone_ring`, `breath_low`, `door_close_upstairs`, `paper_turn`, `chair_drag_upstairs`, `hall_light_out`, `cellar_light_flicker`, `upstairs_chair`, `footsteps_above`. Un seul `play_sfx` par id.
- `[Narration → Niveau]` (2026-10-17) **Ancres exigées par les règles** (en plus de la convention `a_<item>` du README des règles) : `hall_anchor_console`, `kitchen_anchor_sink`, `kitchen_anchor_preserves`, `living_anchor_fireplace`, `study_anchor_shelves`. Un `move_item` vers une ancre absente doit être ignoré avec `push_error`, jamais planter.
- `[Narration → UI]` (2026-10-17) **Sous-titres et fins.** Clés `SUB_*` (30) : `EventBus.subtitle_requested.emit(&"...", durée)` — durées fournies dans `game/data/strings/subtitles.md`. Écrans de fin : `ENDING_CLOSED_*` / `ENDING_ASHES_*` ; la dernière ligne de chaque fin est séparée (`..._LINE_NAME`) pour être composée comme une ligne d'inventaire via `INV_LINE_FORMAT`. Corps BBCode (`[i]`, `[b]`).
- `[Narration → Niveau]` (2026-10-17) **Ancres.** Les 60 `ItemData.anchors` sont vides et `scene` est vide : c'est Niveau qui fournit les `Marker3D`. Proposition de convention (à documenter dans `docs/anchors.md`) : `a_<item_id sans préfixe de pièce>` (ex. `a_clock_stopped` pour `kitchen_clock_stopped`), et pour les objets déplacés par les règles, les ancres citées dans `data/rules/*.tres` sont : `living_anchor_fireplace`, `study_anchor_desk`, `hall_anchor_console`, `kitchen_anchor_table`, `cellar_anchor_shelves`. Liste exacte dans les `.tres` de règles. — À FAIRE (Niveau)
- `[Narration → UI]` (2026-10-17) **Ligne « 61. Camille ».** Le numéro est **sérialisé** (`InventoryManager.progress().x`) et non figé : je livre `INV_LINE_ADDED_CAMILLE` = `Camille` (sans numéro) et `INV_LINE_FORMAT` = `{index}. {name}`. Le carnet affiche via `inventory_line_added(line_index, text_key)`. — POUR INFO
- `[Narration → Systèmes]` (2026-10-17) **Ids de documents** référencés par les `reveal_condition` et les règles (à créer par R-3/R-5, contrats à respecter) : `hall_postit_besnard`, `study_inventory_1973`, `study_letter_besnard`, `kitchen_letter_lucienne_1`, `kitchen_letter_lucienne_2`, `living_letter_lucienne_3`, `living_photo_family`, `hall_tape_1973`, `cellar_register_1847`, `study_deed_1912`. — POUR INFO

- `[Architecte → Systèmes]` (17/10) Le parser de conditions doit supporter la **négation `!` sur tout prédicat** (`!item_checked:id`, utilisé par 4 règles) + `item_present:id` et `presence:state`. Seuils réels des règles : **20 / 30 / 45 / 52** (lire `game/data/rules/README.md`). — TODO
- `[Architecte → UI]` (17/10) Les corps de documents (`body_key`) contiennent `\n` et du BBCode `[i]`/`[b]` : visionneuse = RichTextLabel avec bbcode_enabled. `pages` indicatif. — TODO
- `[Architecte → Niveau]` (17/10) Les 60 `item_id` de `docs/items_master.csv` sont **définitifs** : ne jamais renommer. Remplir `scene` et `anchors` de chaque ItemData (seuls champs autorisés pour Niveau dans data/items/), créer les ancres dans les rooms. Objet interactif `cellar_stove` dans la cave (fin Cendres). — TODO
- `[Architecte → Gameplay]` (17/10) L'interaction longue « brûler » cible `cellar_stove` et émet `player_interacted(&"cellar_stove", &"burn")`. — TODO

- `[Gameplay → Niveau]` (2026-10-17) **Zones de pièce.** Chaque pièce doit contenir une `Area3D` **monitorable** avec `metadata/room_id` (StringName, ex. `&"kitchen"`) couvrant la pièce — `collision_layer` 4 de préférence (le capteur du joueur teste les layers 1 et 3/bits 1 et 4). C'est le Gameplay qui émet `player_entered_room/left_room` ; le Niveau n'émet rien. Zone sans `room_id` = ignorée en silence.
- `[Gameplay → Niveau]` (2026-10-17) **Contrat Item / occlusion.** La détection photo s'appuie uniquement sur : groupe `items`, `data: ItemData`, `is_in_frustum(cam) -> float` (0..1). Pour l'occlusion, le Gameplay cherche les `CollisionObject3D` **enfants de l'Item** : sans collider, pas de test d'occlusion (l'objet reste photographiable à travers un mur). Merci de donner à chaque Item un collider enfant. `ItemData.scene` étant vide, mes scènes de test utilisent des boîtes grises.
- `[Gameplay → Narration]` (2026-10-17) **`min_photo_coverage = 0.15` est très exigeant** : en 1080p / FOV 75, un objet de 1 m de côté doit être cadré à ≈ 1,3 m pour occuper 15 % de l'écran (un objet de 0,5 m à 3 m ≈ 0,7 %). Sauf si le Niveau fournit des boîtes de cadrage généreuses, je recommande 0,03–0,06 pour les petits objets (horloge, alliance, cachet). Je respecte la donnée en attendant.
- `[Gameplay → Audio]` (2026-10-17) **Ids SFX utilisés par l'appareil photo** (à faire exister, sinon AudioManager dégrade) : `camera_raise`, `camera_shutter`, `camera_flash`, `photo_slide`, `camera_dry`. Les pas sont signalés par `EventBus.player_noise(level, pos)` (0,25 marche / 0,85 course) toutes les 0,72 m (marche) / 1,05 m (course) — utilisable pour D-3.
- `[Gameplay → UI]` (2026-10-17) **Actions InputMap réservées** (définies dans `project.godot`) : `move_*`, `sprint`, `crouch`, `interact`, `flashlight`, `camera_raise`, `camera_shoot`, `photo_review`, `notebook` (Tab), `pause` (Échap). L'UI doit écouter ces **actions**, jamais les touches brutes. Le joueur capture la souris ; sur pause, émettre `pause_toggled(true)` pour qu'il la relâche.

## Journal des décisions

- 2026-10-17 — Moteur : **Godot 4.x**, GDScript, Forward+. (Architecte, validé utilisateur)
- 2026-10-17 — Concept : **État des lieux** validé.
- 2026-10-17 — **Sortie visée : 30-31 octobre 2026.** Périmètre réduit « Rez-de-chaussée » (docs/PLAN_HALLOWEEN.md). Version complète = V2 2027.
- 2026-10-17 — Godot **4.7.2**. L'Architecte assure l'intégration (merge main + check headless) ; pas d'agent QA séparé en V1.
