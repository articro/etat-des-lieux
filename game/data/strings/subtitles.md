# Sous-titres de Camille — V1

Émission : depuis le 20/10 (R-10), les lignes sont déclenchées par les **règles** (`HouseDirector`, action `subtitle:<clé>:<durée>` → `EventBus.subtitle_requested`). Les textes sont dans `data/strings/fr.csv`.
Voix en V2 : la V1 est sous-titrée seulement. Aucun point d'exclamation, aucune ligne > 12 mots.

| clé | durée (s) | texte | contexte |
|---|---|---|---|
| `SUB_EXTERIOR_ARRIVAL` | 4.0 | Il fait noir depuis six heures. C'est normal, en octobre. | extérieur, à l'arrivée |
| `SUB_HALL_LIGHT` | 3.5 | L'ampoule du couloir est neuve. Qui l'a vissée. | entrée, première visite |
| `SUB_HALL_KEYS` | 3.0 | Neuf clés. Dix étiquettes. Il en manque une. | entrée, tableau des clés |
| `SUB_HALL_POSTIT` | 2.5 | Il savait que je viendrais seule. | lecture du post-it Besnard |
| `SUB_KITCHEN_CALENDAR` | 3.0 | Octobre 1973. Le trentième jour est entouré. | cuisine, calendrier |
| `SUB_KITCHEN_CLOCK` | 4.0 | Trois heures dix. Je suis arrivée à vingt-deux heures. | cuisine, pendule arrêtée |
| `SUB_KITCHEN_JARS` | 2.5 | Douze pots. Un prénom sur le dernier. | cuisine, confitures |
| `SUB_KITCHEN_LETTER` | 3.0 | Elle écrivait comme on tient un livre ouvert. | lecture d'une lettre de Lucienne |
| `SUB_FIRST_PHOTO` | 3.0 | La photo se développe. Ça prend dix secondes. | première photo développée |
| `SUB_FIRST_CHECK` | 2.5 | Une ligne de moins. Cinquante-neuf. | premier objet coché |
| `SUB_LIVING_PIANO` | 3.0 | Personne n'a joué des aigus depuis longtemps. | salon, piano |
| `SUB_LIVING_PHOTO` | 3.5 | Quatre personnes sur la photo. Cinq sur la liste. | salon, photo de famille |
| `SUB_LIVING_FIREPLACE` | 2.5 | Le feu n'a pas servi. La suie, si. | salon, cheminée |
| `SUB_LIVING_EMPTY_FRAME` | 3.5 | Un cadre vide, et son clou. C'est une place gardée. | salon, cadres |
| `SUB_STUDY_DESK` | 3.5 | Trois tiroirs. Celui du milieu ne s'ouvre pas. | bureau, arrivée |
| `SUB_DRAWER_OPENS` | 3.0 | Le tiroir s'est ouvert. Je n'ai rien touché. | événement act1_drawer_opens |
| `SUB_INVENTORY_1973` | 3.5 | Il a écrit son nom à la fin. Puis il l'a rayé. | lecture de l'inventaire 1973 |
| `SUB_BESNARD_LETTER` | 3.0 | Il le savait. Il m'a envoyée quand même. | lecture de la lettre de Besnard |
| `SUB_NOISE_ABOVE` | 3.0 | On marche au-dessus. La planche est clouée. | attention élevée, bruit d'étage |
| `SUB_PHANTOM_REVEAL` | 3.5 | Cet objet n'était pas là. Il est sur la liste. | révélation d'un fantôme |
| `SUB_TAPE` | 2.5 | C'est la voix du patron. En 1973. | répondeur |
| `SUB_CELLAR_DOOR` | 3.5 | La trappe est ouverte. Je ne l'ai pas ouverte. | événement cellar_door_opens |
| `SUB_CELLAR_STAIRS` | 3.0 | Ça sent le froid. Le froid a une odeur, ici. | descente de la cave |
| `SUB_CELLAR_COAT` | 3.0 | Un manteau à ma taille. Taille quarante-huit. | cave, manteau d'Émile |
| `SUB_REGISTER` | 2.0 | Ils comptaient déjà. En 1847. | lecture du registre |
| `SUB_LAST_OBJECT` | 2.0 | Un objet. Il reste un objet. | dernier objet réel restant |
| `SUB_PRESENCE_SEEN` | 2.5 | Je la vois. Elle ne bouge pas encore. | première apparition physique |
| `SUB_ENDING_CLOSED` | 3.0 | La page s'écrit toute seule. C'est mon nom. | fin Inventaire clos |
| `SUB_BURNING` | 3.5 | Le carnet brûle mal. Le papier ancien est épais. | fin Cendres, interaction longue |
| `SUB_DAWN` | 3.0 | Le jour se lève sur du brouillard. Je repars. | extérieur, fin Cendres |

| `SUB_TUTO_CONSOLE` | 3.0 | Le mot de Maître Besnard est sur la console. | onboarding, entrée dans le hall (r19) |
| `SUB_TUTO_CARNET` | 2.0 | Tab : carnet | onboarding, entrée dans le hall (r19) |
| `SUB_TUTO_PHOTO` | 3.5 | Clic droit : viser. Clic gauche : photographier. | onboarding, entrée dans le hall (r19) |
| `SUB_PROGRESS_10` | 3.5 | Dix lignes. La maison ne proteste pas. Pas encore. | 10 objets cochés (r21) |
| `SUB_CLOCK_30` | 3.5 | J'entends un carillon. C'est l'horloge de l'entrée. | 30 objets, horloge (r02) |
| `SUB_PHONE_45` | 3.5 | Le téléphone sonne. Il n'y a plus d'abonné, ici. | 45 objets, téléphone (r03) |
| `SUB_FIRST_MOVED` | 3.5 | Cet objet a bougé. Je l'avais laissé ailleurs. | premier déplacement d'objet (r24, `item_moved`) |
| `SUB_PROGRESS_58` | 3.5 | Cinquante-huit. Plus que deux lignes à compter. | 58 objets cochés (r22) |

Total : 38 lignes (30 de R-6 + 8 de R-10).

## Déclenchement par les règles (R-10, playtest J4)

| règle | déclencheur | clé(s) jouée(s) |
|---|---|---|
| `r19_onboarding_hall` | `room_entered:hall`, une seule fois | `SUB_TUTO_CONSOLE` → `SUB_TUTO_CARNET` → `SUB_TUTO_PHOTO` |
| `r20_first_photo` | `flash_count` = 1 | `SUB_FIRST_PHOTO` |
| `r21_progress_10` | `progress` = 10 | `SUB_PROGRESS_10` |
| `r01_study_drawer_opens` | `progress` = 20 (tiroir) | `SUB_DRAWER_OPENS` |
| `r02_hall_clock_moves` | `progress` = 30 (horloge) | `SUB_CLOCK_30` |
| `r24_first_moved` | `item_moved` (tout objet, une seule fois) | `SUB_FIRST_MOVED` |
| `r03_phone_and_cellar` | `progress` = 45 (téléphone, trappe) | `SUB_PHONE_45` puis `SUB_CELLAR_DOOR` |
| `r04_cellar_entry_presence` | `room_entered:cellar` | `SUB_CELLAR_STAIRS` |
| `r05_last_eight_in_cellar` | `progress` = 52, dans la cave (Présence) | `SUB_PRESENCE_SEEN` |
| `r22_progress_58` | `progress` = 58 | `SUB_PROGRESS_58` |
| `r23_ending_closed_line` | `progress` = 60 (fin Inventaire clos) | `SUB_ENDING_CLOSED` |

Dépendances : les règles supposent que les actions `subtitle:` d'une même règle sont émises **en file** (durées cumulées) — sinon seule la dernière s'affiche (`r19`, `r03`). La fin *Cendres* n'a pas de déclencheur HouseRule : `SUB_BURNING` (interaction longue) et `SUB_DAWN` (épilogue) sont à émettre par le séquenceur de fin (demande à Systèmes dans TASKS.md).
