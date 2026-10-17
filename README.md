# ÉTAT DES LIEUX — Projet

Jeu d'horreur psychologique à la première personne, développé sous **Godot 4.x** par une équipe d'agents IA coordonnés.

## Structure du dépôt

```
etat-des-lieux/
├── README.md               ← tu es ici
├── docs/
│   ├── GDD.md              ← Game Design Document (le QUOI)
│   ├── STORY_BIBLE.md      ← Histoire, personnages, chronologie, fins
│   ├── ARCHITECTURE.md     ← Architecture technique Godot + contrats entre modules (le COMMENT)
│   ├── TASKS.md            ← Tâches par module, jalons, statut
│   └── AGENT_BRIEF.md      ← Briefs à coller au début de chaque conversation d'agent
└── game/                   ← Projet Godot (ouvrir game/project.godot)
    ├── autoloads/          ← Singletons globaux (EventBus, GameState, ...)
    ├── scenes/             ← Scènes par domaine
    ├── scripts/            ← Classes partagées (ItemData, PhotoData, ...)
    ├── data/               ← Contenu (objets, documents) en fichiers texte
    ├── assets/             ← Modèles, textures, audio (+ CREDITS.md obligatoire)
    ├── tests/              ← Tests automatiques (gdUnit4)
    └── tools/              ← Scripts d'export / validation
```

## Ordre de lecture pour un nouvel agent

1. `docs/AGENT_BRIEF.md` → règles communes + ton rôle
2. `docs/ARCHITECTURE.md` → les contrats que tu dois respecter
3. `docs/TASKS.md` → ce qui t'est assigné
4. `docs/GDD.md` et `docs/STORY_BIBLE.md` → selon ton rôle

## Règle d'or

> **Un agent = un module = un dossier.** On ne touche jamais au module d'un autre agent.
> Si tu as besoin d'un changement ailleurs, tu écris une demande dans `docs/TASKS.md` (section *Demandes inter-modules*).
