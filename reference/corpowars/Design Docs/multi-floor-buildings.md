# Multi-floor buildings (2026-09-26)

- Contract field `floors` (1-3). You insert and extract on G02. G03/G04 are the other floors: copies of the G02 template in hub cluster 20, so a floor keeps its state between visits. Leaving for HUB01 clears the hub.
- `building.zs` (`CW_Building`) derives everything from the mission seed: floor numbers (consecutive, with the insertion floor in a random slot) and each objective's floor (primaries are never on the insertion floor).
- Stair-tower landing doors that lead to mission floors are open and call `ChangeLevel`. You arrive on the same tower's landing, facing that floor's fire door (`ledger.arriveTower`).
- Security passes are tiered by floor index (floppy colour), stored in `ledger.passMask`, and only open that floor's maglocks. The mission panel shows `[FL n]` for each objective and lists the passes you hold.
- Tower Floor contracts: Helix Recovery (2 floors), Brain Drain (2 floors), Black Ledger (3 floors). Field Audit stays single-floor.
- Test with the CVar `cw_floors 2|3` and no mission. Testkit events: `tkstair`, `tkgo`, `tkpass`.
- Verified headless (Wine): generation, floor changes, reopening a floor, the pass tier check, and the hub reset after HUB01.
