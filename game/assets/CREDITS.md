# Crédits des assets

> OBLIGATOIRE : chaque asset externe doit figurer ici avec sa source, son auteur et sa licence.
> Licences acceptées : CC0, CC-BY (avec attribution), MIT, OFL (polices), domaine public.
> Tout asset dont la licence n'est pas claire est REFUSÉ.

## Polices — module UI (U-9)

| Fichier | Type | Source (URL) | Auteur | Licence |
|---|---|---|---|---|
| `fonts/courier_prime_regular.ttf` | Police (machine à écrire) | https://github.com/google/fonts/tree/main/ofl/courierprime | Copyright 2015 The Courier Prime Project Authors — Quote-Unquote Apps (https://github.com/quoteunquoteapps/CourierPrime) | SIL OFL 1.1 (texte : `fonts/OFL_courier_prime.txt`) |
| `fonts/courier_prime_bold.ttf` | Police (machine à écrire, gras) | idem | idem | SIL OFL 1.1 |
| `fonts/courier_prime_italic.ttf` | Police (machine à écrire, italique) | idem | idem | SIL OFL 1.1 |
| `fonts/caveat_regular.ttf` | Police (manuscrite, variable — instance par défaut 400) | https://github.com/google/fonts/tree/main/ofl/caveat | Copyright 2014 The Caveat Project Authors — Pablo Impallari (https://github.com/googlefonts/caveat) | SIL OFL 1.1 (texte : `fonts/OFL_caveat.txt`) |
| `fonts/lato_regular.ttf` | Police (sans-serif UI) | https://github.com/google/fonts/tree/main/ofl/lato | Copyright (c) 2011-2015 by tyPoland Lukasz Dziedzic (http://www.typoland.com/), Reserved Font Name « Lato » | SIL OFL 1.1 (texte : `fonts/OFL_lato.txt`) |
| `fonts/lato_bold.ttf` | Police (sans-serif UI, gras) | idem | idem | SIL OFL 1.1 |

> Vérification UI (2026-10-17) : les trois familles couvrent le jeu de caractères français complet utilisé par le jeu
> (`àâäçéèêëîïôöùûüÿ œ Œ` + majuscules accentuées, `« »`, `—`, `–`, `…`, `’`, `€`), vérifié sur la table `cmap`
> de chaque fichier. Aucune police sans licence claire n'est utilisée.

## Audio — module Audio (D-1 à D-8)

**Tous les fichiers audio du jeu sont générés par synthèse procédurale.** Aucun échantillon
tiers n'est utilisé : aucun droit voisin, aucune attribution à porter, et le jeu peut être
diffusé librement (itch.io, gratuit).

| Fichier | Type | Source (URL) | Auteur | Licence |
|---|---|---|---|---|
| `assets/audio/**/*.ogg` (67 fichiers) | sons et musiques | scripts de synthèse fournis dans `assets/audio/_src/` (dépôt du jeu) | Équipe « État des lieux » — généré par ordinateur (numpy / scipy / soundfile) | **CC0 1.0** (œuvre originale générée, placée dans le domaine public) |

Détail par dossier :

| Dossier | Contenu | Script source |
|---|---|---|
| `camera/` | appareil photo : déclencheur, flash, moteur, charge | `_src/synth_camera.py` |
| `player/` | pas (5 matériaux × 4 variantes), souffle, sac | `_src/synth_player.py` |
| `interact/` | ouvertures, prises, papier, feu, lampe, carnet, crayon | `_src/synth_interact.py` |
| `house/` | craquements, tuyaux, pendule + 4 nappes bouclées | `_src/synth_house.py` |
| `presence/` | 10 sons domestiques + impact + nappe de la Présence | `_src/synth_presence.py` |
| `music/` | 2 musiques de fin (66 s) | `_src/synth_music.py` |

Les scripts ne sont pas des dépendances du jeu : ils servent à **régénérer** et à **régler**
les sons. Licences des outils utilisés pour les écrire (non redistribués, non liés au jeu) :
numpy (BSD-3), scipy (BSD-3), soundfile / libsndfile (LGPL-2.1, utilisé uniquement en
ligne de commande pour encoder), matplotlib (PSF/BSD, aperçus).

Format : OGG Vorbis mono 44 100 Hz. Poids total ≈ 1,6 Mo.

---

## Niveau — N-9 / N-7 (hall, livraison J5)

Modèles téléchargés en glTF/GLB, textures Poly Haven limitées à 1K; les scènes leur donnent une échelle adaptée aux dimensions d'`ItemData`. Les textures de surface ambientCG sont en 1K JPG. CC0 vérifié sur les pages officielles de chaque ressource.

| Fichier | Type | Source (URL) | Auteur | Licence |
|---|---|---|---|---|
| `assets/models/polyhaven/ClassicConsole_01/ClassicConsole_01_1k.gltf` | modèle glTF (console du hall) | https://polyhaven.com/a/ClassicConsole_01 | Kirill Sannikov / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/ClassicConsole_01/ClassicConsole_01.bin` | géométrie du modèle | idem | Kirill Sannikov / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/ClassicConsole_01/textures/ClassicConsole_01_arm_1k.jpg` | texture AO/roughness/metal, 1K | idem | Kirill Sannikov / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/ClassicConsole_01/textures/ClassicConsole_01_diff_1k.jpg` | texture diffuse, 1K | idem | Kirill Sannikov / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/ClassicConsole_01/textures/ClassicConsole_01_nor_gl_1k.jpg` | normale OpenGL, 1K | idem | Kirill Sannikov / Poly Haven | CC0 1.0 |
| `assets/models/kenney/furniture-kit/coatRackStanding.glb` | modèle GLB (porte-manteau du hall) | https://kenney.nl/assets/furniture-kit | Kenney (Kenney Vleugels) | CC0 1.0 |
| `assets/models/polyhaven/ornate_mirror_01/ornate_mirror_01_1k.gltf` | modèle glTF (miroir du hall) | https://polyhaven.com/a/ornate_mirror_01 | James Ray Cock / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/ornate_mirror_01/ornate_mirror_01.bin` | géométrie du modèle | idem | James Ray Cock / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/ornate_mirror_01/textures/ornate_mirror_01_arm_1k.jpg` | texture AO/roughness/metal, 1K | idem | James Ray Cock / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/ornate_mirror_01/textures/ornate_mirror_01_diff_1k.jpg` | texture diffuse, 1K | idem | James Ray Cock / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/ornate_mirror_01/textures/ornate_mirror_01_nor_gl_1k.jpg` | normale OpenGL, 1K | idem | James Ray Cock / Poly Haven | CC0 1.0 |
| `assets/models/kenney/furniture-kit/trashcan.glb` | modèle GLB (base du porte-parapluies, complétée en CSG) | https://kenney.nl/assets/furniture-kit | Kenney (Kenney Vleugels) | CC0 1.0 |
| `assets/models/polyhaven/cassette_player/cassette_player_1k.gltf` | modèle glTF (répondeur du hall) | https://polyhaven.com/a/cassette_player | Oday Abuzaeed / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/cassette_player/cassette_player.bin` | géométrie du modèle | idem | Oday Abuzaeed / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/cassette_player/textures/cassette_player_body_arm_1k.jpg` | texture AO/roughness/metal du boîtier, 1K | idem | Oday Abuzaeed / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/cassette_player/textures/cassette_player_body_diff_1k.jpg` | texture diffuse du boîtier, 1K | idem | Oday Abuzaeed / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/cassette_player/textures/cassette_player_body_nor_gl_1k.jpg` | normale OpenGL du boîtier, 1K | idem | Oday Abuzaeed / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/cassette_player/textures/cassette_player_tape_arm_1k.jpg` | texture AO/roughness/metal de la cassette, 1K | idem | Oday Abuzaeed / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/cassette_player/textures/cassette_player_tape_nor_gl_1k.jpg` | normale OpenGL de la cassette, 1K | idem | Oday Abuzaeed / Poly Haven | CC0 1.0 |
| `assets/models/polyhaven/cassette_player/textures/cassette_player_tape_orangeblue_diff_1k.jpg` | texture diffuse de la cassette, 1K | idem | Oday Abuzaeed / Poly Haven | CC0 1.0 |
| `assets/textures/ambientcg/Wallpaper002A_1K-JPG_Color.jpg` | couleur de base wallpaper, 1K | https://ambientcg.com/view?id=Wallpaper002A | ambientCG | CC0 1.0 |
| `assets/textures/ambientcg/Wallpaper002A_1K-JPG_NormalGL.jpg` | normale OpenGL wallpaper, 1K | idem | ambientCG | CC0 1.0 |
| `assets/textures/ambientcg/Wallpaper002A_1K-JPG_Roughness.jpg` | rugosité wallpaper, 1K | idem | ambientCG | CC0 1.0 |
| `assets/textures/hall_wallpaper_70s_1K.png` | wallpaper 70s original, dérivé de la base ambientCG Wallpaper002A | https://ambientcg.com/view?id=Wallpaper002A | Équipe « État des lieux » (motif original) + ambientCG (texture de surface) | CC0 1.0 |
| `assets/textures/ambientcg/WoodFloor017_1K-JPG_Color.jpg` | couleur de base parquet, 1K | https://ambientcg.com/view?id=WoodFloor017 | ambientCG | CC0 1.0 |
| `assets/textures/ambientcg/WoodFloor017_1K-JPG_NormalGL.jpg` | normale OpenGL parquet, 1K | idem | ambientCG | CC0 1.0 |
| `assets/textures/ambientcg/WoodFloor017_1K-JPG_Roughness.jpg` | rugosité parquet, 1K | idem | ambientCG | CC0 1.0 |
| `assets/textures/ambientcg/Plaster001_1K-JPG_Color.jpg` | couleur de base plâtre, 1K | https://ambientcg.com/view?id=Plaster001 | ambientCG | CC0 1.0 |
| `assets/textures/ambientcg/Plaster001_1K-JPG_NormalGL.jpg` | normale OpenGL plâtre, 1K | idem | ambientCG | CC0 1.0 |
| `assets/textures/ambientcg/Plaster001_1K-JPG_Roughness.jpg` | rugosité plâtre, 1K | idem | ambientCG | CC0 1.0 |

Les objets restants du hall (`baromètre`, tableau de clés, sonnette, main fantôme et bague) sont des compositions CSG du projet; le porte-parapluies combine un modèle Kenney CC0 et des détails CSG originaux.
