# Assets déposés par le producteur (humain) — `game/assets/incoming/`

Le producteur choisit à l'œil des assets **gratuits et libres** et les dépose ici. Niveau les intègre en priorité.

## Règles de dépôt
- Formats : **`.glb`** (préféré) ou `.gltf` + textures, ou `.fbx`/`.obj` si rien d'autre. Textures : `.png`/`.jpg` ≤ 2048 px.
- Un sous-dossier par source : `incoming/<source>_<nom-du-pack>/…` (ex. `incoming/kenney_furniture-kit/`).
- **Dans chaque sous-dossier, un fichier `SOURCE.txt`** avec : l'URL de la page, l'auteur, la licence (CC0 / CC-BY / OFL…). Sans ça, Niveau n'a pas le droit de l'utiliser.
- Licences acceptées : CC0, CC-BY (attribution), MIT, licences « free for commercial use with attribution ». **Refusées** : « personal use only », « non-commercial », tout asset extrait d'un jeu.
- Taille : rester sous ~150 Mo au total (dépôt Git).

## Comment déposer (sans commande)
Sur github.com/articro/etat-des-lieux → ouvrir `game/assets/incoming/` → **Add file → Upload files** → glisser le dossier → en bas, « Commit changes » directement sur `main`. L'Architecte voit le commit et prévient Niveau.
(Limite GitHub web : 100 fichiers par envoi, 25 Mo par fichier. Les packs plus gros : dézipper et envoyer en plusieurs fois, ou GitHub Desktop → Changes → Commit → Push.)

## Ce que Niveau fait ensuite
Convertit/importe dans `assets/models/<room>/`, assigne aux `ItemData.scene`, ajoute la ligne dans `assets/CREDITS.md`, vérifie avec `tools/shots.sh`.
