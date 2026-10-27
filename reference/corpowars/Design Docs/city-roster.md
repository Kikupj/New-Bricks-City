# City Roster — Corps, Subsidiaries, Properties (v1, 2026-09-27)

Planning only. **Supersedes the 12-subsidiary / 23-building counts** in the older docs. The goal is to use map generation more: more subsidiaries, each with a logical set of properties, so there are many more mission sites.

## Decisions
- **Scale:** **32 subsidiaries** (5–6 per corp) and **67 properties** (1–3 per subsidiary). Room to grow toward ~80 if we want more sites.
- **Every property is a mission site**, generated from its building type with a **fixed seed per save**. The layout is the same on every visit; security, owner and theme can change.
- **Win:** your patron (or your own corp) controls a **majority of subsidiaries** (17 of 32), or is the last corp standing. Property counts decide income, not the win.
- **Market:** trades **single properties** most of the time (foreclosure, distress, lease expiry, scandal). Whole subsidiaries move only in distress sales, collapse carve-ups and receivership.
- A subsidiary that loses all its properties still exists (as a brand or holding) until it's sold or its corp collapses.
- **Length:** still ~60 days. Corps fall through economics more than through you hitting every site.
- **No growth** still applies: no new subsidiaries appear during a save.

---

## Roster

Type key: OFF office tower · HQ corp HQ tower · CLN clinic · STU studio · TRN training centre · RND R&D site · LAB lab · DC data centre · FARM underground farm · BNK bunker · WH storage warehouse · DOCK sea dock · FAB fabrication facility · PLT power plant · SUB substation · PARK outdoor industrial park site · SAL salvage yard

Districts: MR Meridian Row · EG Eastgate Research Park · IS Ironside Docks · OQ Old Quarter · HL Highline

### Oriole Biosciences (6 subsidiaries, 13 properties)
| Subsidiary | Niche | Vis. | Properties |
|---|---|---|---|
| Helix Labs | core R&D | public | HQ (EG), LAB (EG), LAB (EG) |
| Oriole Clinical | clinics | public | CLN (OQ), CLN (OQ), CLN (MR) |
| Verdant Grow | pharma crops | public | FARM (OQ), FARM (IS) |
| Oriole Pharma Supply | manufacture & distribution | public | FAB (IS), WH (IS) |
| Kestrel Trials | unlicensed trials | shell | OFF (MR), CLN (OQ, hidden drug-lab wing) |
| Oriole Biobank | specimen storage | public | LAB (HL), a secure cold vault |

### Castellan Systems (5 subsidiaries, 10 properties)
| Subsidiary | Niche | Vis. | Properties |
|---|---|---|---|
| Bastion Arms | weapons R&D | public | HQ (HL), RND (EG), BNK (HL) |
| Castellan Secure | in-house security | public | TRN (HL), OFF (MR, dispatch) |
| Bastion Fabrication | arms manufacturing | public | FAB (HL), WH (IS, armoury stock) |
| Ironwall Proving Grounds | test ranges | public | PARK (IS, range), BNK (HL) |
| Aegis Contracting | deniable ops, procurement | shell | OFF (OQ) |

### Halvorsen Logistics (6 subsidiaries, 13 properties)
| Subsidiary | Niche | Vis. | Properties |
|---|---|---|---|
| Halvorsen Freight | trucking, storage | public | HQ (IS), WH (IS), WH (HL) |
| Halvorsen Maritime | shipping | public | DOCK (IS), DOCK (IS), OFF (IS, harbour office) |
| Grey Harbor Salvage | salvage, fencing | shell | SAL (IS), SAL (OQ) |
| Halvorsen Cold Chain | refrigerated storage | public | WH (IS, cold), WH (EG, cold) |
| Northgate Rail | rail freight | public | PARK (IS, rail yard), PARK (HL, rail yard) |
| Tidewater Brokerage | customs, paperwork | shell | OFF (MR) |

### Sable Media Group (5 subsidiaries, 11 properties)
| Subsidiary | Niche | Vis. | Properties |
|---|---|---|---|
| Sable Newsnet | broadcast | public | HQ (MR), STU (OQ), STU (HL) |
| Candor Analytics | data brokerage | shell | OFF (MR), OFF (EG) |
| Sable Outdoor | advertising, print | public | OFF (OQ), FAB (IS, print/signage) |
| Relay Broadcast | transmission | public | PARK (IS, antenna farm), DC (HL) |
| Glasshouse Live | events, venues | public | STU (MR, arena), OFF (OQ) |

### Corvane Energy (5 subsidiaries, 10 properties)
| Subsidiary | Niche | Vis. | Properties |
|---|---|---|---|
| Corvane Grid | power tech core | public | HQ (HL), PLT (IS), SUB (HL) |
| Corvane Generation | power plants | public | PLT (IS), PLT (IS, in an industrial park) |
| Corvane Distribution | substations | public | SUB (EG), SUB (OQ) |
| Corvane Research | power R&D | public | RND (HL), LAB (EG) |
| Voltaic Holdings | investments, deniable hires | shell | OFF (MR) |

### Lattice Dynamics (5 subsidiaries, 10 properties)
| Subsidiary | Niche | Vis. | Properties |
|---|---|---|---|
| Lattice Compute | core compute | public | HQ (MR), DC (EG), DC (HL) |
| Northstar Talent | headhunting | shell | OFF (MR), OFF (EG) |
| Lattice Fabrication | chips, servers | public | FAB (HL), FAB (IS) |
| Lattice Edge | small data centres | public | DC (OQ), DC (IS) |
| Helion Power | Lattice's secret power project | shell | PLT (IS, in an industrial park) |

### Totals
- **32 subsidiaries** (8 shells) · **67 properties**.
- By type: OFF 12 · HQ 6 · WH 6 · FAB 5 · DC 5 · LAB 4 · CLN 4 · PARK 4 · PLT 4 · STU 3 · SUB 3 · FARM 2 · RND 2 · BNK 2 · DOCK 2 · SAL 2 · TRN 1. The drug-lab wing is inside a Kestrel clinic.
- By district: IS 21 · HL 15 · OQ 11 · EG 10 · MR 10. Ironside is the big industrial district.
- Shells worth uncovering: Kestrel Trials (Oriole's illegal trials), Aegis (Castellan's deniable ops), Tidewater (Halvorsen's customs cover), Helion Power (Lattice secretly building its own power, a big Corvane story).

Executives for every subsidiary are named in executives-and-insertion.md.
