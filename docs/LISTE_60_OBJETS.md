# Liste maîtresse — 60 objets (Édition Halloween)

> Source : `docs/items_master.csv` (agent Narration). 👻 = objet fantôme (absent au départ).


## EXTÉRIEUR

| # | Libellé 1973 | id | Note |
|---|---|---|---|
| 1 | Portail, deux vantaux, fer forgé | `exterior_gate` |  |
| 2 | Puits, margelle, pierre | `exterior_well` |  |
| 3 | Brouette, une roue | `exterior_wheelbarrow` |  |
| 4 | Banc, pierre, sous le tilleul | `exterior_bench` |  |

## ENTRÉE

| # | Libellé 1973 | id | Note |
|---|---|---|---|
| 5 | Table, console, marbre | `hall_console_table` |  |
| 6 | Baromètre, cadre noyer | `hall_barometer` |  |
| 7 | Porte-manteau, trois patères | `hall_coat_rack` |  |
| 8 | Tableau des clés, dix crochets | `hall_key_board` |  |
| 9 | Miroir, cadre bois, glace | `hall_mirror` |  |
| 10 | Râtelier à parapluies, zinc | `hall_umbrella_stand` |  |
| 11 | Cloche de porte, laiton | `hall_doorbell` |  |
| 12 | Répondeur, à cassette, deux boutons | `hall_answering_machine` |  |
| 13 | Main, sur la rampe | `hall_hand_railing` | 👻 photo_only — apparaît si `checked>=25` |
| 14 | Alliance, gravée M. V. | `hall_ring_1951` | 👻 message — apparaît si `doc_read:living_photo_family` |

## CUISINE

| # | Libellé 1973 | id | Note |
|---|---|---|---|
| 15 | Table de cuisine, formica, quatre pieds | `kitchen_table` |  |
| 16 | Chaises, quatre, paillées | `kitchen_chairs` |  |
| 17 | Évier, pierre, deux bassins | `kitchen_sink` |  |
| 18 | Cuisinière, fonte émaillée, deux feux | `kitchen_stove` |  |
| 19 | Moulin à café, bois et laiton | `kitchen_coffee_mill` |  |
| 20 | Balance de ménage, plateau | `kitchen_scales` |  |
| 21 | Bocaux, six, verre | `kitchen_jars` |  |
| 22 | Confitures, douze pots, étiquetés | `kitchen_preserves` |  |
| 23 | Pendule arrêtée, 3 h 10 | `kitchen_clock_stopped` |  |
| 24 | Calendrier des postes, 1973 | `kitchen_calendar` |  |
| 25 | Batterie de cuisine, sept pièces | `kitchen_cookware` |  |
| 26 | Soupière, faïence, couvercle | `kitchen_tureen` |  |
| 27 | Boîte en fer, biscuits | `kitchen_tin_box` |  |
| 28 | Tabouret, trois pieds | `kitchen_stool` |  |
| 29 | Suspension, abat-jour tôle | `kitchen_lamp` |  |
| 30 | Clé, étiquette "L." | `kitchen_key_l` | 👻 message — apparaît si `doc_read:kitchen_letter_lucienne_1` |

## SALON

| # | Libellé 1973 | id | Note |
|---|---|---|---|
| 31 | Piano droit, bois noirci | `living_piano` |  |
| 32 | Cheminée, manteau de pierre | `living_fireplace` |  |
| 33 | Fauteuils, deux, velours | `living_armchairs` |  |
| 34 | Canapé, trois places | `living_sofa` |  |
| 35 | Buffet, deux corps, noyer | `living_sideboard` |  |
| 36 | Tapis, laine, salon | `living_rug` |  |
| 37 | Cadres, quatre, portraits | `living_frames` |  |
| 38 | Partitions, trente-deux, en cahier | `living_sheet_music` |  |
| 39 | Poste de radio, bakélite | `living_radio` |  |
| 40 | Bibliothèque, trois rayons | `living_bookcase` |  |
| 41 | Rideaux, deux paires, velours | `living_curtains` |  |
| 42 | Panière à ouvrage, osier | `living_workbasket` |  |
| 43 | Rideau, écarté, côté cour | `living_curtain_part` | 👻 photo_only — apparaît si `checked>=35` |
| 44 | Portrait d'homme, cadre cassé | `living_portrait_louis` | 👻 person — apparaît si `doc_read:living_photo_family` |

## BUREAU

| # | Libellé 1973 | id | Note |
|---|---|---|---|
| 45 | Bureau, acajou, trois tiroirs | `study_desk` |  |
| 46 | Fauteuil de bureau, cuir | `study_chair` |  |
| 47 | Rayonnage, dossiers, quarante | `study_shelves` |  |
| 48 | Machine à écrire, Underwood | `study_typewriter` |  |
| 49 | Lampe de bureau, abat-jour vert | `study_lamp` |  |
| 50 | Écritoire, encrier de verre | `study_inkwell` |  |
| 51 | Cachet, laiton, armoiries | `study_stamp` |  |
| 52 | Registres, douze, reliés | `study_registers` |  |
| 53 | Plan cadastral, encadré | `study_cadastre` |  |
| 54 | Coffre-fort, deux serrures | `study_safe` |  |
| 55 | Buvard, écriture fraîche | `study_blotter` | 👻 message — apparaît si `doc_read:study_letter_besnard` |
| 56 | Serviette en cuir, initiales J.-P. D. | `study_briefcase_jpd` | 👻 person — apparaît si `doc_read:study_inventory_1973` |

## CAVE

| # | Libellé 1973 | id | Note |
|---|---|---|---|
| 57 | Étagères, sept, bois blanc | `cellar_shelves` |  |
| 58 | Bouteilles, cent quatorze | `cellar_bottles` |  |
| 59 | Poêle, fonte, un seul feu | `cellar_stove` |  |
| 60 | Manteau d'homme, taille 48 | `cellar_coat_emile` | 👻 person — apparaît si `doc_read:cellar_register_1847` |


# Textes révélés (lore, affiché quand l'objet est coché)


### EXTÉRIEUR

**1. Portail, deux vantaux, fer forgé** — Le vantail de droite ne ferme plus. Il a été redressé plusieurs fois ; la peinture marque chaque réparation.

**2. Puits, margelle, pierre** — Asséché en 1976. Le seau est remonté et pend au-dessus du vide, propre.

**3. Brouette, une roue** — La roue est voilée. Le fond porte une rayure nette, longue d'un mètre. On a transporté là autre chose que des bûches.

**4. Banc, pierre, sous le tilleul** — La pierre est polie à une seule place, à hauteur d'assise. Quelqu'un s'est assis là, toujours au même endroit, pendant des années.


### ENTRÉE

**5. Table, console, marbre** — Le marbre est piqué en son centre, à l'endroit où l'on pose les clés. Le mot du patron y est collé. L'encre est fraîche.

**6. Baromètre, cadre noyer** — L'aiguille est bloquée sur « variable ». Le verre est fêlé en étoile autour d'elle.

**7. Porte-manteau, trois patères** — Trois patères. Un fil de laine vert est noué à celle du milieu ; les deux autres sont vides et propres.

**8. Tableau des clés, dix crochets** — Neuf clés, dix étiquettes. La dixième est vide : le papier a été gratté au couteau.

**9. Miroir, cadre bois, glace** — La glace est bonne. Je m'y vois telle que je suis, avec le sac, la lampe, le carnet. Rien de plus.

**10. Râtelier à parapluies, zinc** — Deux parapluies, un homme et une femme. Les plis gardent encore la forme du dernier jour de pluie.

**11. Cloche de porte, laiton** — Le battant porte une trace de pouce, brillante, à l'intérieur. Comme si on avait sonné depuis la maison.

**12. Répondeur, à cassette, deux boutons** — La cassette est engagée. Le compteur indique 1. Personne n'a effacé.

**13. Main, sur la rampe** — Une main d'adulte, posée à plat sur la rampe, doigts écartés. Elle n'appartient à personne dans la pièce.

**14. Alliance, gravée M. V.** — Un anneau d'or, gravé à l'intérieur : M. V. - 1951. Le doigt qui la portait était plus fin que le mien.


### CUISINE

**15. Table de cuisine, formica, quatre pieds** — Le formica est brûlé à une place, toujours la même. On a posé là un fer, ou une casserole, pendant vingt ans.

**16. Chaises, quatre, paillées** — Quatre chaises, quatre places. Une seule est tirée ; les trois autres sont poussées sous la table, à la même distance du bord.

**17. Évier, pierre, deux bassins** — Le robinet d'eau chaude goutte. L'eau qui tombe est froide : le ballon doit être vide depuis longtemps.

**18. Cuisinière, fonte émaillée, deux feux** — L'intérieur du four est propre. Le cendrier est vide. La cendre est dans le seau, dehors, sous la pluie.

**19. Moulin à café, bois et laiton** — Le tiroir est plein de café moulu. Il sent encore.

**20. Balance de ménage, plateau** — Le plateau porte des graduations à la craie. Le dernier trait est plus appuyé que les autres.

**21. Bocaux, six, verre** — Six bocaux vides, alignés du plus grand au plus petit. Les couvercles sont rangés à part, dans le même ordre.

**22. Confitures, douze pots, étiquetés** — Douze pots. Onze portent une date. Le douzième porte un prénom, sans date : Louis.

**23. Pendule arrêtée, 3 h 10** — Arrêtée à 3 h 10. Le ressort est remonté. On dirait qu'elle s'est arrêtée en marche.

**24. Calendrier des postes, 1973** — Le calendrier est de 1973. La page est restée à octobre. Le 30 est entouré au crayon.

**25. Batterie de cuisine, sept pièces** — Sept pièces, sept tailles. La plus petite n'a jamais servi : le culot est encore noir de fabrique.

**26. Soupière, faïence, couvercle** — Le couvercle est collé au plat. Trois miettes à l'intérieur, très vieilles.

**27. Boîte en fer, biscuits** — La boîte est vide. Le papier du fond garde l'empreinte ronde d'un biscuit.

**28. Tabouret, trois pieds** — Le tabouret est usé sur un seul coin. Il manque dix centimètres pour atteindre les étagères hautes.

**29. Suspension, abat-jour tôle** — L'abat-jour est propre en dessous, sale au-dessus. La poussière commence exactement au niveau des yeux.

**30. Clé, étiquette "L."** — Une clé de chambre, petite, à étiquette de carton. Les dents sont usées jusqu'au plat.


### SALON

**31. Piano droit, bois noirci** — Le couvercle est ouvert. Les touches du milieu sont creusées ; les aigus sont comme neufs.

**32. Cheminée, manteau de pierre** — La pierre est noire de suie jusqu'à hauteur de main. Plus haut, elle est claire. Le feu n'a pas été allumé depuis longtemps.

**33. Fauteuils, deux, velours** — Les deux fauteuils se font face, à un mètre. Personne ne s'est assis dans celui de gauche : le velours y est intact.

**34. Canapé, trois places** — Un journal de 1976 est glissé sous le coussin. Il n'a pas été lu : les pages sont encore collées au tranchant.

**35. Buffet, deux corps, noyer** — Le buffet est vide, sauf un tiroir. Le tiroir contient six ronds de serviette gravés à six initiales.

**36. Tapis, laine, salon** — Le tapis est plus clair à l'endroit où un meuble a été posé. Ce meuble n'est plus là.

**37. Cadres, quatre, portraits** — Quatre portraits. Trois hommes d'âge mûr, trois visages différents, la même expression. Le quatrième cadre est vide, avec son clou.

**38. Partitions, trente-deux, en cahier** — Trente-deux partitions, toutes de la même main. La dernière porte une date, 1976, et deux mesures inachevées.

**39. Poste de radio, bakélite** — Le poste est réglé sur une fréquence vide. Le bouton de volume est cassé en position haute.

**40. Bibliothèque, trois rayons** — Trois rayons. Les livres sont classés par taille du haut vers le bas, et par couleur de dos de gauche à droite. Quelqu'un a eu le temps.

**41. Rideaux, deux paires, velours** — Les rideaux sont tirés. Le velours garde la marque d'un écartement, à hauteur d'homme, côté cour.

**42. Panière à ouvrage, osier** — Un gilet d'enfant, taille quatre ans, commencé. Les aiguilles sont plantées dans la laine, en attente.

**43. Rideau, écarté, côté cour** — Le rideau n'est écarté que sur la photographie. Dans la pièce, il est tiré.

**44. Portrait d'homme, cadre cassé** — Un homme assis, la main posée sur un genou. Le cadre est cassé en bas à droite. Au dos, au crayon : Louis, 38 ans.


### BUREAU

**45. Bureau, acajou, trois tiroirs** — Trois tiroirs. Celui du milieu est fermé à clé. La clé est dans la serrure, côté intérieur.

**46. Fauteuil de bureau, cuir** — Le cuir est craquelé aux accoudoirs. Le siège garde la forme de quelqu'un qui s'asseyait sur le bord.

**47. Rayonnage, dossiers, quarante** — Quarante dossiers, quarante noms. Le trente-neuvième est vide et porte une étiquette neuve.

**48. Machine à écrire, Underwood** — La machine est chargée. Le ruban est neuf. Le chariot est à mi-course, au milieu d'un mot.

**49. Lampe de bureau, abat-jour vert** — Ampoule à filament, quarante watts. Le verre est noirci par le haut : elle brûle depuis longtemps.

**50. Écritoire, encrier de verre** — L'encrier est plein. Le bouchon est posé à côté, du bon côté de la main droite.

**51. Cachet, laiton, armoiries** — Le cachet est encré. L'empreinte porte les armes de la maison Varenne et, dessous, un nom gratté au couteau.

**52. Registres, douze, reliés** — Douze registres. Onze sont rangés par année. Le douzième n'a pas d'année sur le dos.

**53. Plan cadastral, encadré** — Le plan est celui du cadastre de 1845. La maison est dessinée en entier ; l'aile qui n'existe plus n'a pas été effacée.

**54. Coffre-fort, deux serrures** — Les deux serrures sont ouvertes. À l'intérieur, une liasse de lettres et une place vide de la taille d'une serviette.

**55. Buvard, écriture fraîche** — Le buvard garde l'empreinte d'une dernière ligne, à l'encre encore fraîche : Il ne manque plus que moi.

**56. Serviette en cuir, initiales J.-P. D.** — Une serviette plate, vide. Les initiales sont gravées à chaud. À l'intérieur, la marque d'un stylo-bille et un numéro à six chiffres.


### CAVE

**57. Étagères, sept, bois blanc** — Sept étagères. Les conserves sont rangées par année, de droite à gauche. Les plus vieilles sont devant.

**58. Bouteilles, cent quatorze** — Cent quatorze bouteilles. Douze sont pleines, alignées à part, étiquetées 1973. Aucune n'a été ouverte.

**59. Poêle, fonte, un seul feu** — Le poêle est froid. Le cendrier est plein, tassé : on a brûlé du papier, puis on a refermé la porte.

**60. Manteau d'homme, taille 48** — Un manteau pend à un clou derrière la porte. Le tissu est propre. Dans la poche intérieure, une carte de visite : Émile Ferrand, clerc de notaire, Dijon.
