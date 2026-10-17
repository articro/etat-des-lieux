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
| A0-3 | Dépôt GitHub `articro/etat-des-lieux`, push initial | EN COURS (attente token) |
| A0-4 | Version Godot = **4.7.2**, `config/features` ajusté, check headless OK | DONE |
| A0-5 | Outils : `tools/check.sh`, `tools/install_godot_sandbox.sh`, `tools/run_tests.sh` | DONE |
| A0-6 | Plan Halloween 2026 (périmètre réduit, calendrier) | DONE |

## Module Gameplay `[Gameplay]` — `scenes/player/`, `scenes/fx/`

| ID | Tâche | Jalon | Statut |
|---|---|---|---|
| G-1 | Contrôleur FPS (marche/course/accroupi, essoufflement, head-bob subtil, ZQSD + QWERTY via physical keys) | M1 | TODO |
| G-2 | Système d'interaction (raycast, surbrillance discrète, prendre/inspecter/reposer un objet, portes & tiroirs physiques à la souris) | M1 | TODO |
| G-3 | Appareil photo : visée (lever l'appareil, viseur), déclenchement, consommation film, SubViewport capture, flash lumière + aveuglement, son via AudioManager | M1 | TODO |
| G-4 | Détection des objets cadrés (frustum + occlusion raycast + couverture écran ≥ `min_photo_coverage`), construction PhotoData | M1 | TODO |
| G-5 | Photo en main : sortie de l'appareil, développement 10 s (shader), consultation | M1 | TODO |
| G-6 | Lampe de poche faible, batterie infinie, option « plus forte » | M1 | TODO |
| G-7 | Post-process : grain, vignette, aberration légère, aveuglement flash (scenes/fx) | M2 | TODO |
| G-8 | Présence : nœud `Presence` (déplacement lent par NavigationAgent3D, états via `presence_state_changed`, figée 4 s si photographiée, contact → `player_caught`) | M3 | TODO |
| G-9 | Interactions longues (brûler carnet 8 s, signer registre) avec annulation | M3 | TODO |
| G-10 | Zones de pièce (Area3D → `player_entered_room/left_room`) — en coordination avec Niveau | M1 | TODO |

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
| R-1 | Liste maîtresse des 212 objets (tableur `docs/items_master.csv` : id, index, pièce, libellé 1973, fantôme ?, type, condition, lore) | M1 | TODO |
| R-2 | 20 ItemData de la vertical slice (entrée + bureau) en `.tres` + strings | M1 | TODO |
| R-3 | Documents de la vertical slice : post-it Besnard, inventaire 1973 (extrait), 2 lettres | M1 | TODO |
| R-4 | Tous les ItemData (212) | M3 | TODO |
| R-5 | Tous les documents (~45 : inventaires 1912/1951/1973, carnets de Lucienne ×8, dessins de Louis, lettres, formulaires, répondeur) | M3 | TODO |
| R-6 | Monologues de Camille (≤ 80 lignes, ≤ 12 mots chacune) + sous-titres | M3 | TODO |
| R-7 | Règles de maison (`data/rules/*.tres`) en coordination avec Systèmes : ~40 règles | M2→M3 | TODO |
| R-8 | Textes des 4 fins + génériques | M3 | TODO |
| R-9 | Recherche documentaire : formulaires notariaux 1912 / 1951 / 1973, vocabulaire, Morvan | M1 | TODO |

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

_(vide)_

## Journal des décisions

- 2026-10-17 — Moteur : **Godot 4.x**, GDScript, Forward+. (Architecte, validé utilisateur)
- 2026-10-17 — Concept : **État des lieux** validé.
- 2026-10-17 — **Sortie visée : 30-31 octobre 2026.** Périmètre réduit « Rez-de-chaussée » (docs/PLAN_HALLOWEEN.md). Version complète = V2 2027.
- 2026-10-17 — Godot **4.7.2**. L'Architecte assure l'intégration (merge main + check headless) ; pas d'agent QA séparé en V1.
