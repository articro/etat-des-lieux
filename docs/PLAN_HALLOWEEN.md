# PLAN HALLOWEEN 2026 — « État des lieux : Rez-de-chaussée »

> **Ce document PRIME sur GDD.md et TASKS.md jusqu'au 31 octobre 2026.**
> Le GDD complet reste la cible V2 (2027). Ici : ce qu'on livre en **14 jours** (17 → 31 octobre).

## 1. Le périmètre réduit (ce qui change)

| | Version complète (V2) | **Édition Halloween (V1)** |
|---|---|---|
| Durée | 3 h | **30 – 40 min** |
| Zones | 13 | **6** : extérieur (minimal), entrée, cuisine, salon, bureau, cave |
| Objets | 212 | **60** (52 réels + 8 fantômes) — *la liste remise à Camille ne couvre que le rez-de-chaussée ; l'étage est condamné par une planche clouée, avec un mot : « Étage : demain, avec Maître Besnard. »* |
| Documents | ~45 | **10** |
| Actes | 3 | **1 acte en 3 temps** : calme (0-20) → inquiétude (20-45) → cave (45-60) |
| Fins | 4 | **2** : *Inventaire clos* / *Cendres* |
| Présence | 4 états | **photo_only → offscreen → 1 apparition physique finale** (avance lentement pendant le choix, pas de poursuite, pas de navmesh) |
| Interaction | portes/tiroirs physiques à la souris | **clic = ouvrir/prendre/lire** (simple et robuste) |
| Carnet | 4 onglets 3D | **2 onglets** : liste + photos (documents lus en plein écran) |
| Sauvegarde | auto par pièce | **auto par pièce (déjà codée), pas de menu de chargement complexe** |
| Options | complètes | **sensibilité, FOV, volume, sous-titres, plein écran** |
| Assets | finaux partout | **blockout habillé** : textures CC0 (ambientCG), ~30 modèles libres pour les objets clés, formes simples bien éclairées pour le reste. *Le brouillard, la pénombre, le flash et le grain font le travail.* |
| Audio | complet | **appareil photo (priorité 1), pas, 1 soundscape à 3 intensités, 10 sons « Présence », 1 musique de fin** |
| Voix | comédienne | **sous-titres seulement** (voix en V2) |
| Plateformes | Win/Linux/Mac | **Windows + Linux** (Mac si temps), itch.io gratuit |

### Ce qui ne change PAS
Le cœur : **l'appareil photo** (flash, aveuglement, développement 10 s, cocher = fixer), **la maison qui se souvient** (objets qui bougent si non photographiés, attention), l'histoire par les documents, le ton sobre. **Si le flash ne fait pas peur, rien ne marchera.** Tout l'effort va là.

## 2. Histoire condensée (V1)

Camille arrive à 22 h. Mot de Besnard sur la table : rez-de-chaussée ce soir, étage demain avec lui. Liste de 60 objets. Elle découvre en photographiant : l'inventaire 1973 de Jean-Paul (bureau, tiroir qui s'ouvre à 20 objets), les lettres de Lucienne (cuisine/salon), la photo de famille à 5 personnes où il n'y en a que 4 (salon). À 45 objets : le téléphone sonne, répondeur, voix de Besnard enregistrée *en 1973* qui dit « Jean-Paul, sors de là ». La trappe de la cave s'ouvre. Cave : le registre depuis 1847, les 8 derniers objets, la Présence apparaît au fond et avance. Choix : photographier le 60e objet (*Inventaire clos* : « 61. Camille ») ou jeter le carnet dans le poêle de la cave (*Cendres*).

Le twist Lucienne = Madeleine est **suggéré** (signature, lettres) mais pas déroulé — c'est l'accroche pour la V2.

## 3. L'équipe (6 conversations + l'Architecte)

L'Architecte (cette conversation) fait aussi **l'intégration** : il a Godot 4.7.2 headless, il merge sur `main` et lance `tools/check.sh`. Pas d'agent QA séparé pour la V1.

| Agent | Priorité absolue J1-J5 | Ensuite |
|---|---|---|
| **Gameplay** | G-1, G-3, G-4, G-5 (FPS + appareil photo complet), G-2 simplifié (clic) | G-6 lampe, G-7 post-process, G-8 Présence simplifiée, G-9 interaction longue (brûler) |
| **Systèmes** | S-2 Inventory, S-3 HouseDirector (parser + 5 actions), S-7 séquenceur (seuils 20/45/60) | S-6 main (menu → jeu → fin), S-8 2 fins, S-5 déjà codé à vérifier |
| **Niveau** | N-1 plan 6 zones, N-2 blockout entrée + bureau, N-3 house.gd, N-4 item.tscn | N-5 cuisine/salon/cave/extérieur, N-6 lumière + brouillard, N-7/N-9 habillage CC0 |
| **Narration** | R-1 liste maîtresse **60 objets**, R-2 ItemData entrée + bureau, R-3 post-it Besnard + inventaire 1973 | R-4 tous les ItemData, R-5 10 documents, R-7 ~15 règles, R-8 2 fins, R-6 ~30 sous-titres |
| **UI** | U-9 polices, U-1/U-2 carnet (liste + coches), U-3 photos, U-4 compteur films | U-5 lecture document, U-6 menu + pause + options mini, U-7 sous-titres, U-8 2 écrans de fin |
| **Audio** | D-1 AudioManager, D-2 sons appareil photo, D-3 pas | D-4 soundscape, D-5 10 sons Présence, D-6 1 musique, D-8 mix |

## 4. Calendrier (J1 = vendredi 17 octobre)

| Jour | Objectif | Validation (Architecte) |
|---|---|---|
| **J1 ven 17** | Fondation, push GitHub, lancement des 6 agents | `check.sh` vert sur main |
| **J2-J3 sam-dim** | Chaque agent livre sa priorité absolue. Narration livre la liste des 60 objets le **J2 midi** (tout le monde en dépend) | Merge quotidien, check vert |
| **J4 lun 20** | Intégration **vertical slice** : entrée + bureau, 20 objets, appareil photo, carnet, 1 règle, événement du tiroir | Build jouable |
| **J5 mar 21** | **PLAYTEST 1 — « Est-ce que ça fait peur ? »** Tu joues. Décision : on ajuste le feeling du flash / des règles avant de produire le reste | Rapport dans docs/playtests/J5.md |
| **J6-J8 mer-ven** | Contenu complet : 6 zones, 60 objets placés, 10 documents, 15 règles, séquenceur, Présence, 2 fins | Jeu finissable en gris |
| **J9 sam 25** | **PLAYTEST 2 — complet.** Liste de bugs priorisée | docs/playtests/J9.md |
| **J10-J11 dim-lun** | Polish : habillage CC0, lumière, post-process, audio complet, options, écrans de fin | Build « quasi final » |
| **J12 mar 28** | **PLAYTEST 3** par 2-3 personnes extérieures (amis) + correctifs | docs/playtests/J12.md |
| **J13 mer 29** | Exports Windows/Linux, page itch.io (texte, 5 captures, 1 GIF du flash), build testé sur un autre PC | Page en brouillon |
| **J14 jeu 30** | Gel. Seulement les bugs bloquants. Publication le soir | **EN LIGNE** |
| **ven 31** | Halloween. Partage. | 🎃 |

**Marge** : zéro. Donc règles de coupe (§5).

## 5. Règles de coupe (si on est en retard)

Dans cet ordre, on supprime :
1. Fin *Cendres* → une seule fin.
2. Extérieur → le jeu commence dans l'entrée (écran noir, bruit de porte).
3. Habillage CC0 → blockout + matériaux simples + brouillard dense.
4. Options → sensibilité + volume uniquement.
5. Salon → 5 zones, 50 objets.
6. Présence physique → reste photo_only + offscreen ; la fin se déclenche au 60e objet sans elle.

Ce qu'on ne coupe **jamais** : appareil photo complet, carnet avec coches, objets qui bougent, le tiroir qui s'ouvre, la cave, une fin.

## 6. Règles de travail spécifiques V1

- **Placeholders d'abord, beauté après.** Un cube gris nommé `kitchen_clock_stopped` qui se coche correctement vaut mieux qu'une horloge magnifique qui ne se coche pas.
- **Pas de refactoring.** Si ça marche et que c'est moche, on note dans TASKS.md et on avance.
- **Chaque agent push au moins 2 fois par jour** sur sa branche, avec `check.sh` vert.
- **Toute dépendance à un autre module** → l'agent fait un *stub* local temporaire et note la demande. On n'attend jamais.
- L'humain (producteur) fait les playtests J5, J9, J12 et transmet les HANDOFF. C'est son seul job critique.
