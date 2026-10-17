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

| Fichier | Type | Source (URL) | Auteur | Licence |
|---|---|---|---|---|
| _(autres modules : à remplir par Niveau, Narration)_ | | | | |
