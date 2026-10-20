# Règles de maison — V1 (23 HouseRule)

Chargement attendu (Systèmes, S-3) : `data/rules/*.tres` → `HouseDirector.register_rule()`.
Format : `docs/ARCHITECTURE.md` §6. Seuils V1 : **20 / 45 / 60** (PLAN_HALLOWEEN §2 et §4).

| id | trigger | param | condition | actions | once | cooldown |
|---|---|---|---|---|---|---|
| `r01_study_drawer_opens` | progress | `20` | `—` | `event:act1_drawer_opens`<br>`sfx:drawer_open`<br>`attention:+6` | oui | 0 |
| `r02_hall_clock_moves` | progress | `30` | `—` | `event:hall_clock_moves`<br>`sfx:clock_chime_distant`<br>`attention:+5` | oui | 0 |
| `r03_phone_and_cellar` | progress | `45` | `—` | `event:phone_rings`<br>`event:cellar_door_opens`<br>`sfx:phone_ring`<br>`attention:+12`<br>`presence:offscreen` | oui | 0 |
| `r04_cellar_entry_presence` | room_entered | `cellar` | `checked>=44` | `presence:physical`<br>`sfx:breath_low`<br>`attention:+10` | oui | 0 |
| `r05_last_eight_in_cellar` | progress | `52` | `room:cellar` | `event:cellar_presence_awakens`<br>`presence:physical`<br>`attention:+15` | oui | 0 |
| `r06_cellar_left_unfinished` | room_left | `cellar` | `checked>=44` | `presence:offscreen`<br>`sfx:door_close_upstairs` | oui | 0 |
| `r07_hall_umbrella_moves` | room_left | `hall` | `!item_checked:hall_umbrella_stand && checked>=8` | `move_item:hall_umbrella_stand:hall:hall_anchor_console`<br>`attention:+4` | oui | 0 |
| `r08_kitchen_stool_moves` | room_left | `kitchen` | `!item_checked:kitchen_stool && checked>=10` | `move_item:kitchen_stool:kitchen:kitchen_anchor_sink`<br>`attention:+4` | oui | 0 |
| `r09_living_armchair_moves` | room_left | `living` | `!item_checked:living_armchairs && checked>=25` | `move_item:living_armchairs:living:living_anchor_fireplace`<br>`attention:+5` | oui | 0 |
| `r10_study_stamp_moves` | room_left | `study` | `!item_checked:study_stamp && checked>=32` | `move_item:study_stamp:study:study_anchor_shelves`<br>`attention:+5` | oui | 0 |
| `r11_key_to_preserves` | room_entered | `kitchen` | `doc_read:kitchen_letter_lucienne_1 && !item_checked:kitchen_key_l` | `move_item:kitchen_key_l:kitchen:kitchen_anchor_preserves`<br>`attention:+3` | oui | 0 |
| `r12_inventory_read` | doc_read | `study_inventory_1973` | `—` | `attention:+8`<br>`sfx:paper_turn`<br>`presence:offscreen` | oui | 0 |
| `r13_photo_family_read` | doc_read | `living_photo_family` | `—` | `attention:+10`<br>`sfx:chair_drag_upstairs`<br>`presence:offscreen` | oui | 0 |
| `r14_tape_heard` | doc_read | `hall_tape_1973` | `—` | `attention:+15`<br>`event:hall_light_out`<br>`presence:offscreen` | oui | 0 |
| `r15_register_read` | doc_read | `cellar_register_1847` | `—` | `attention:+10`<br>`event:cellar_light_flicker`<br>`presence:offscreen` | oui | 0 |
| `r16_dark_idle_forgets` | idle | `20` | `—` | `attention:-6` | non | 20 |
| `r17_attention_30` | attention_above | `30` | `—` | `sfx:upstairs_chair`<br>`presence:offscreen` | non | 40 |
| `r18_attention_65` | attention_above | `65` | `—` | `sfx:footsteps_above`<br>`presence:offscreen`<br>`attention:-4` | non | 45 |

## Dépendances hors Narration

**Ancres `Marker3D` attendues (Niveau)** : `hall_anchor_console`, `kitchen_anchor_preserves`, `kitchen_anchor_sink`, `living_anchor_fireplace`, `study_anchor_shelves`.

**Événements à consommer (Niveau / Systèmes)** : `act1_drawer_opens`, `cellar_door_opens`, `cellar_light_flicker`, `cellar_presence_awakens`, `hall_clock_moves`, `hall_light_out`, `phone_rings`.

**Sons à fournir (Audio)** : `breath_low`, `chair_drag_upstairs`, `clock_chime_distant`, `door_close_upstairs`, `drawer_open`, `footsteps_above`, `paper_turn`, `phone_ring`, `upstairs_chair`.

## Notes de conception

- `r01_study_drawer_opens` — Le tiroir du bureau s'ouvre seul à 20 objets : l'inventaire 1973 devient lisible.
- `r02_hall_clock_moves` — L'horloge de l'entrée change d'heure sans bruit de mécanisme.
- `r03_phone_and_cellar` — Le téléphone sonne, le répondeur se déclenche, la trappe de la cave s'ouvre. Seuil du PLAN §2.
- `r04_cellar_entry_presence` — Première descente après 44 objets : la Présence devient physique.
- `r05_last_eight_in_cellar` — Il reste 8 objets à compter : la Présence apparaît au fond de la cave et avance.
- `r06_cellar_left_unfinished` — Remonter de la cave sans avoir fini : la Présence repasse hors champ. Jamais de poursuite.
- `r07_hall_umbrella_moves` — Objet non photographié : le râtelier à parapluies finit près de la console.
- `r08_kitchen_stool_moves` — Le tabouret se retrouve devant l'évier, comme quelqu'un qui vient de se laver les mains.
- `r09_living_armchair_moves` — Les fauteuils se rapprochent de la cheminée, face au feu éteint.
- `r10_study_stamp_moves` — Le cachet quitte le bureau pour le rayonnage, côté dossiers.
- `r11_key_to_preserves` — Après la lettre à Louis, la clé « L. » apparaît parmi les confitures.
- `r12_inventory_read` — Lire la liste de Jean-Paul attire l'attention. Rien de plus, rien de moins.
- `r13_photo_family_read` — La cinquième personne de la photo : une chaise se tire à l'étage.
- `r14_tape_heard` — La voix de Besnard en 1973 : l'ampoule de l'entrée s'éteint.
- `r15_register_read` — Le registre de 1847 : la lumière de la cave vacille une fois.
- `r16_dark_idle_forgets` — Immobile dans le noir : la maison oublie un peu le joueur. Récompense la patience.
- `r17_attention_30` — Attention > 30 : un meuble se déplace à l'étage, hors champ.
- `r18_attention_65` — Attention > 65 : pas lents au-dessus du joueur, puis retombée partielle.

## R-10 — Sous-titres déclenchés par les règles (playtest J4, 20/10)

Action `subtitle:<clé>:<durée>` (ARCHITECTURE §7). Câblage complet : voir `game/data/strings/subtitles.md` (table « Déclenchement par les règles »).

- `r19_onboarding_hall` (`room_entered:hall`, once) : les 3 lignes d'onboarding, dans l'ordre mot de Besnard → « Tab : carnet » → contrôles photo. **Exige une file d'émission côté Systèmes** : `SubtitleBox` affiche une ligne à la fois et écrase la précédente ; sans file, seule la 3e ligne serait visible.
- `r20_first_photo` (`flash_count` = 1), `r21_progress_10`, `r22_progress_58`, `r23_ending_closed_line` (`progress` = 60) : jalons du monologue.
- Actions `subtitle:` ajoutées aux règles d'événement existantes : `r01` (tiroir, 20), `r02` (horloge, 30), `r03` (téléphone puis trappe, 45 — même exigence de file), `r04` (première descente), `r05` (Présence, 52), `r07` (premier objet déplacé).
- « Premier objet déplacé » : câblé sur `r07`, le déplacement le plus précoce possible (sortie de l'entrée, 8 objets). Si le joueur a coché le râtelier avant, aucun déplacement n'a lieu à ce moment et la ligne ne joue pas ; un déclencheur `item_moved` global reste demandé à Systèmes (non bloquant).
- Fin *Cendres* : aucun déclencheur de règle pour l'interaction « brûler » ; les clés `SUB_BURNING` / `SUB_DAWN` existent et attendent le séquenceur de fin.
