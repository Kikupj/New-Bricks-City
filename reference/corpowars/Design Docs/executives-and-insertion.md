# Executives, Leaders & Insertion Rules (v2, 2026-09-27)

Planning only. Companion to sim-behavior-draft.md, city-roster.md and building-types.md.

## Decisions
- **38 corp executives** (6 CEOs + 32 subsidiary heads) and **8 minor-player leaders**, all named below (drafts, editable).
- District and minor-player names are final.
- Floors and entry points come from the property's building type, heat and intel.
- Numbers are tuned in code.

---

## Corp executives (38)
CEO bonus: +income across the corp. Head bonus: +income to their subsidiary. Location is their main property (or HQ).

### Oriole Biosciences
| Role | Name | Works at |
|---|---|---|
| CEO | Dr. Imelda Voss | Oriole HQ (EG) |
| Helix Labs | Dr. Aaron Vance | Helix lab (EG), the existing recruit target |
| Oriole Clinical | Dr. Priya Okonjo | clinic (OQ) |
| Verdant Grow | Marisol Ekwueme | underground farm (OQ) |
| Oriole Pharma Supply | Gregor Lindqvist | fabrication facility (IS) |
| Kestrel Trials (shell) | Dr. Silas Wren | Kestrel clinic (OQ) |
| Oriole Biobank | Dr. Anouk Brandt | Biobank lab (HL) |

### Castellan Systems
| Role | Name | Works at |
|---|---|---|
| CEO | Marcus Hale | Castellan HQ (HL) |
| Bastion Arms | Ingrid Soler | Bastion R&D (EG) |
| Castellan Secure | Col. Dmitri Rusk | training centre (HL) |
| Bastion Fabrication | Petra Kowalczyk | fabrication facility (HL) |
| Ironwall Proving Grounds | Maj. Owen Tate | bunker (HL) |
| Aegis Contracting (shell) | Leon Graves ("Mr. Grey") | Aegis office (OQ) |

### Halvorsen Logistics
| Role | Name | Works at |
|---|---|---|
| CEO | Elsa Halvorsen | Halvorsen HQ (IS) |
| Halvorsen Freight | Tomas Bergqvist | warehouse (IS) |
| Halvorsen Maritime | Capt. Signe Aalto | harbour office (IS) |
| Grey Harbor Salvage (shell) | "Dutch" Maren | salvage yard (IS), your fence |
| Halvorsen Cold Chain | Farid Haddad | cold warehouse (EG) |
| Northgate Rail | Walter Brennan | rail yard (IS) |
| Tidewater Brokerage (shell) | Celeste Duval | Tidewater office (MR) |

### Sable Media Group
| Role | Name | Works at |
|---|---|---|
| CEO | Vivian Sable | Sable HQ (MR) |
| Sable Newsnet | Julian Reyes | studio (OQ) |
| Candor Analytics (shell) | Noor Castell | Candor office (MR) |
| Sable Outdoor | Marco Bellini | Sable Outdoor office (OQ) |
| Relay Broadcast | Yusuf Adeyemi | Relay data centre (HL) |
| Glasshouse Live | Tamsin Rook | arena (MR) |

### Corvane Energy
| Role | Name | Works at |
|---|---|---|
| CEO | Augustin Corvane | Corvane HQ (HL) |
| Corvane Grid | Dr. Hana Ito | plant (IS), Lattice's top target |
| Corvane Generation | Henrik Solberg | plant (IS) |
| Corvane Distribution | Grace Mbeki | substation (EG) |
| Corvane Research | Dr. Felix Okafor | Corvane R&D (HL) |
| Voltaic Holdings (shell) | Simon Pike | Voltaic office (MR) |

### Lattice Dynamics
| Role | Name | Works at |
|---|---|---|
| CEO | Kai Mercer | Lattice HQ (MR) |
| Lattice Compute | Dr. Lena Wirth | data centre (EG) |
| Northstar Talent (shell) | Ruben Achebe | Northstar office (MR) |
| Lattice Fabrication | Mei Tanaka | fabrication facility (HL) |
| Lattice Edge | Daniel Cruz | data centre (OQ) |
| Helion Power (shell) | Soren Vale | Helion plant (IS) |

## Minor-player leaders (8)
Bonus: boosts the group's operations and turf gain. Location: a stronghold.
| Group | Leader | Role | Stronghold |
|---|---|---|---|
| Rustline Crew | Reyna "Knuckles" Ortiz | boss | bar (OQ) |
| | Viktor Kane | dock lieutenant | drug lab (IS) |
| Local 9 | Rosa Delgado | president | union hall (IS) |
| | Tomasz Wolski | chief steward | union office (HL) |
| NullSet | "Cipher" | founder, identity unknown | hacker den (EG) |
| | "Moth" | operator | hacker den (MR) |
| Tenants' Assoc. | Ada Nwosu | chair | meeting hall (OQ) |
| | Father Luis Moreno | organiser | church hall (OQ) |

---

## Floors and entry points

### Floors per contract (by building type)
| Building type | Floors |
|---|---|
| HQ, office tower | 2–3 (the executive floor is the top one) |
| Lab, data centre, R&D site, training centre | 2 |
| Clinic, studio, fab, bunker, farm | 1–2 (bunker and farm are underground levels) |
| Warehouse, dock, plant, substation, industrial park, salvage yard | 1 outdoor lot (plus interiors inside it) |
| Neutral sites | 1 area |

Floor numbers come from building height: tall in Meridian Row and Highline, low-rise in Ironside and the Old Quarter.

### Entry options (by type and district)
- **Towers:** elevators, stairwells A/B, street lobby, roof stair; **garage (B1)** for HQs, offices, labs, data centres and R&D sites in Meridian Row, Eastgate and Highline.
- **Underground (bunker, farm):** main entrance, service lift from a building above, vents/emergency exit.
- **Outdoor lots:** main gate, side gate, rail line/water side (docks), fence breach.
- **Safehouse routes** (Tenants' Association Friendly+): adjacent rooftop or tunnel in the Old Quarter and Ironside.

### How the entry is chosen
1. Default: random among the property's options (garage ~40% where available).
2. Intel (site survey, an **Intel** odd job or a Local 9 tip) lets you **choose** the entry at deploy.
3. Heat carries over: after a hot job (heat > 50) against the same corp within 2 days, its sites stay alert. Lobby, garage and gate entries are more likely watched, and extraction scenarios roll hotter.
4. Extraction: any exit on the insertion level; reroutes and scenarios by heat, limited to the property's options.
