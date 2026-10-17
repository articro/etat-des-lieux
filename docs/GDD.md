# ÉTAT DES LIEUX — Game Design Document

> Version 0.1 — Document fondateur. Toute modification de ce document passe par l'agent Architecte.
>
> ⚠️ **Pour la sortie Halloween 2026, le périmètre est réduit : voir `docs/PLAN_HALLOWEEN.md` (prioritaire).** Ce GDD décrit la vision complète (V2).

## 1. Fiche d'identité

| | |
|---|---|
| **Titre** | État des lieux |
| **Genre** | Horreur psychologique, première personne, exploration / enquête |
| **Durée** | 2h30 – 3h30 (une nuit en jeu) |
| **Moteur** | Godot 4.x (GDScript) |
| **Plateformes** | PC (Windows / Linux / macOS), export itch.io |
| **Langue** | Français (voix off / textes), anglais en V2 |
| **Public** | 16+, amateurs de *P.T.*, *Visage*, *Amnesia*, *Mouthwashing* |
| **Références de ton** | *P.T.* (boucle, détails), *Visage* (maison vivante), *Papers, Please* (la tâche bureaucratique), *The Vanishing of Ethan Carter* (narration environnementale) |

## 2. Pitch

Octobre 1998, Morvan. Camille Aubrac, clerc stagiaire, doit réaliser seule, de nuit, l'état des lieux d'une maison dont la propriétaire vient de mourir sans héritier. Elle doit retrouver et photographier les 212 objets d'un inventaire de 1973. La maison n'en contient que 180. Et elle n'est pas la première à essayer.

**Phrase d'accroche :** *« Chaque objet coché te rapproche de la fin. De la liste, et de la tienne. »*

## 3. Piliers de design

1. **La peur par la tâche** — Le joueur n'a pas d'arme et ne fuit pas. Il remplit un inventaire. L'horreur vient de ce que cette tâche banale *signifie* au fur et à mesure.
2. **L'appareil photo est tout** — Lumière, révélateur, protection, piège. Une seule mécanique centrale, poussée à fond.
3. **La maison se souvient** — Les actions du joueur modifient l'état de la maison de façon lisible et cohérente. Pas d'aléatoire gratuit : des *règles* que le joueur apprend.
4. **Zéro cinématique** — Tout se raconte par les objets, les documents, les sons et l'espace.
5. **Moins mais dense** — Une maison, 12 pièces, chaque mètre carré raconte quelque chose.

## 4. Boucle de gameplay

```
Explorer une pièce → Repérer un objet de la liste → Cadrer et photographier
→ La photo se « développe » (10 s) → Cocher dans le carnet → Lire ce que l'objet révèle
→ La maison réagit (règles) → Nouvelle zone / nouvel indice
```

### 4.1 L'appareil photo (mécanique centrale)

- **Type** : instantané (style Polaroid/Instax), films limités (packs de 10, trouvés dans la maison, ~30 films au total pour 212 objets → le joueur doit viser juste; films supplémentaires cachés pour les joueurs qui explorent).
- **Flash** : seule source de lumière forte. Éclaire la pièce 0,3 s puis **aveugle le joueur 1,5 s** (écran blanc qui s'estompe). Pendant ce temps, les choses bougent.
- **Développement** : la photo sort de l'appareil et met 10 s à apparaître. Le joueur peut la regarder dans sa main. **Ce qui est sur la photo peut différer de ce qu'il a vu.**
- **Cocher un objet** : si un objet de la liste est cadré et net, il est automatiquement coché dans le carnet. L'objet est alors *fixé* : il ne bougera plus jamais.
- **Photographier la Présence** : la fige 4 s (comme tout objet photographié). Mais chaque photo d'elle ajoute une ligne à la liste : *« Objet n° 213 : … »*.

### 4.2 Le carnet (inventaire)

- Objet physique en 3D dans la main gauche (touche `Tab`), pas un menu plat.
- Contient : la liste de 1973 (212 entrées, classées par pièce), les photos prises, les documents trouvés, le plan de la maison annoté à la main.
- Les descriptions de 1973 sont **ambiguës volontairement** : *« Pendule arrêtée, 3 h 10 »*, *« Chaise, dossier cassé, la troisième »*, *« Photographie de famille (5 personnes) »* — alors que la photo trouvée n'en montre que 4.
- Les 32 « objets fantômes » (sur la liste mais absents) sont le moteur de l'enquête.

### 4.3 La maison se souvient (système HouseDirector)

Un système de règles (pas d'IA aléatoire) qui modifie l'état de la maison en fonction des actions du joueur :

| Entrée | Effet |
|---|---|
| Objet photographié | Fixé définitivement. Peut débloquer un document/événement lié. |
| Objet **non** photographié quand le joueur quitte la pièce | Peut être déplacé (dans la pièce, puis dans la maison) |
| Nombre de flashs dans une pièce | Augmente l'*attention* de la maison (variable cachée 0–100) |
| Seuils de progression (50 / 100 / 150 / 200 objets) | Déclenchent les événements majeurs (voir §6) |
| Lecture d'un document | Peut faire apparaître un objet fantôme |
| Courir / claquer une porte | +attention |
| Rester immobile dans le noir > 20 s | −attention (la maison « oublie » le joueur) |

L'*attention* pilote : fréquence des bruits, apparitions de la Présence sur les photos, puis dans le monde.

### 4.4 La Présence

- Jamais nommée. Jamais vue clairement avant l'acte 3.
- Acte 1 : n'existe que sur les photos (une silhouette à une fenêtre, une main sur une rampe).
- Acte 2 : bruits de pas, portes, objets déplacés en temps réel hors champ.
- Acte 3 : présente physiquement, lente, dans les couloirs. Le joueur la **fige en la photographiant** (coût : un film + une ligne de plus sur la liste).
- Pas de game over classique : si elle touche le joueur, écran noir, il se réveille dans l'entrée, **un objet de plus a été coché à sa place** (perte de contrôle, pas de punition par le temps).

### 4.5 Déplacement et interaction

- FPS lent (marche 2,5 m/s, course 4 m/s limitée par l'essoufflement), accroupi, pas de saut.
- Interaction contextuelle : prendre / tourner un objet en main (inspection), ouvrir tiroirs et portes (physique, à la souris, style *Amnesia*), lire.
- Lampe de poche faible (éclairage de secours, jaune, piles infinies mais faisceau étroit) — le flash reste la vraie lumière.

## 5. Le lieu : la maison Varenne

Ferme bourguignonne transformée en maison de maître, isolée, Morvan. Brouillard permanent dehors.

| # | Pièce | Rôle narratif | Objets listés |
|---|---|---|---|
| 0 | Extérieur (cour, 205 Peugeot, appentis) | Prologue, entrée / sortie, fins | 8 |
| 1 | Entrée & couloir | Hub, tableau des clés, horloge | 12 |
| 2 | Cuisine | Vie quotidienne de Madeleine, 1998 | 28 |
| 3 | Salle à manger | Repas de famille figé, 1951 | 22 |
| 4 | Salon | Photos, piano, cheminée — « l'exposition » | 26 |
| 5 | Bureau | Les inventaires, le notaire, les contrats | 24 |
| 6 | Escalier & palier | Transition, portraits, miroir | 6 |
| 7 | Chambre de Madeleine | Intimité, carnets, la vérité de 1951 | 20 |
| 8 | Chambre d'enfant (fermée à clé) | L'enfant de la photo manquante | 16 |
| 9 | Salle de bain | Le miroir, l'eau, photo révélatrice | 10 |
| 10 | Buanderie / arrière-cuisine | Accès cave, les vêtements des clercs | 12 |
| 11 | Grenier | L'inventaire de 1912, les malles-noms | 18 |
| 12 | Cave | Le registre original, la fin | 10 |
| | **Total** | | **212** |

## 6. Structure en 3 actes

### Acte 1 — « Le rez-de-chaussée » (0 → 60 objets, ~50 min)
- Arrivée en voiture, brouillard, prologue sans peur. Tutoriel intégré par la tâche (le patron a laissé un mot et le carnet).
- Pièces : 0, 1, 2, 3, 4, 5.
- Le joueur apprend : cadrer, développer, cocher, lire.
- Inquiétude : les objets fantômes, une photo montre une silhouette à l'étage, l'horloge indique une heure différente à chaque passage.
- Fin d'acte (60 objets) : dans le bureau, le tiroir fermé s'ouvre seul. Dedans, **l'inventaire de 1973** signé Jean-Paul Doucet. Inachevé. Dernière ligne : *« Objet 181 : Jean-Paul »*. Rayé.

### Acte 2 — « L'étage » (60 → 140 objets, ~70 min)
- Pièces : 6, 7, 8, 9, 10. La chambre d'enfant demande une clé (énigme à base de photos).
- La maison bouge : objets déplacés, portes qui se referment, la Présence hors champ.
- Le joueur comprend les règles (photographier = fixer) et commence à les *utiliser* contre la maison.
- Révélation progressive : Madeleine Varenne était **Lucienne Marchal**, la clerc de 1951. Elle a « signé ». L'enfant de la chambre était celui de la vraie Madeleine Varenne.
- Fin d'acte (140 objets) : le miroir de la salle de bain, photographié, montre Camille en train d'écrire dans le carnet. Elle n'écrit pas. La trappe de la cave s'ouvre.

### Acte 3 — « Dessous et dessus » (140 → 212 objets, ~50 min)
- Pièces : 11, 12. La Présence est physique.
- Le grenier contient les malles des clercs précédents, étiquetées à leur prénom. L'inventaire de 1912 (Émile Ferrand) est **complet** : 212 objets, le 212e est *« Émile »*.
- La cave contient le registre original : la maison tient un inventaire depuis 1847.
- À 200 objets, la liste du joueur se met à écrire seule les dernières lignes.
- **Choix final** (voir STORY_BIBLE §5) : Compléter / Brûler / Signer.

## 7. Les trois fins

| Fin | Condition | Résumé |
|---|---|---|
| **Inventaire clos** | Photographier le 212e objet | Camille devient l'objet 213. Générique sur l'inventaire de 2023, un nouveau clerc. |
| **Cendres** | Brûler le carnet dans la cheminée | Camille sort à l'aube. La maison est vendue. Dernier plan : dans son sac, un carnet neuf, à son écriture. |
| **Gardienne** | Signer le registre de la cave | Camille devient Madeleine. Dernier plan : 2023, elle accueille un clerc. « Vous avez la liste ? » |

Fin cachée (**« Quatre »**) : finir avec exactement les 180 objets réels cochés et zéro fantôme → la maison la laisse partir, vraiment. Difficile, récompense les joueurs attentifs.

## 8. Direction artistique

- **Réalisme sale et daté** : France rurale 1998, papiers peints 70s, formica, néons de cuisine, moquette. Pas de « maison hantée » gothique.
- **Palette** : ocres, verts d'eau, brun tabac. Le flash casse tout en blanc froid.
- **Rendu** : lumière globale très basse, Volumetric fog, SDFGI/VoxelGI selon perf, grain de pellicule, légère aberration chromatique, vignette. Post-process différent quand on regarde une photo (couleurs délavées instantané).
- **Assets** : bibliothèques libres (Poly Haven, Sketchfab CC0/CC-BY, Kenney, ambientCG). Tout crédit dans `assets/CREDITS.md`. Aucun asset sans licence claire.
- **Typo** : machine à écrire pour les inventaires, écriture manuscrite pour les annotations (police libre), Helvetica-like pour l'UI.

## 9. Audio

- Pas de musique pendant le jeu, sauf 3 moments (piano du salon, fin d'acte 2, générique).
- Soundscape en couches : maison (bois, tuyaux, horloge), extérieur (vent, pluie, chouette), joueur (souffle, pas selon matériau, cuir du sac), appareil (déclencheur, moteur du film, flash qui recharge — **le son le plus important du jeu**).
- La Présence : jamais de « monster sound ». Des sons *domestiques* au mauvais endroit (une chaise tirée au-dessus, un robinet, quelqu'un qui tourne les pages du carnet).
- Voix : monologue intérieur de Camille, rare, sobre (TTS de qualité ou comédienne bénévole). Aucun cri.

## 10. Interface

- HUD quasi inexistant : compteur de films (en bas à droite, sur l'appareil lui-même), rien d'autre.
- Le carnet est l'unique menu de jeu.
- Menu principal : la 205 garée dans le brouillard, les phares allumés.
- Options : sensibilité, FOV, sous-titres, mode « lampe plus forte » (accessibilité), daltonisme, remapping.

## 11. Hors périmètre (V1)

Multijoueur, VR, doublage anglais, consoles, mode « new game + », éditeur de maison. On les note, on ne les fait pas.
