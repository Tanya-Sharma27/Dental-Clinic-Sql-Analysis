# Screenshots needed

Save each one into this `screenshots/` folder with **exactly** these filenames.
The README already links to them — get the name wrong and the image shows as broken.

To capture on Mac: **Shift + Cmd + 4**, drag a box around the result panel.
Crop to just the query and its result table. Do not include the browser toolbar
or the History sidebar.

| Filename | What to capture |
|---|---|
| `01-schema-created.png` | Sidebar showing all four tables after running `schema.sql` |
| `02-row-counts.png` | The row-count check: 60 / 6 / 300 / 482 |
| `03-status-breakdown.png` | Q1 result — Completed 235, No-show 38, Cancelled 27 |
| `04-noshow-by-type.png` | Q3 result — Recall at 18.3% at the top |
| `05-noshow-by-provider.png` | Q4 result — hygienists above dentists |
| `06-revenue-by-procedure.png` | Q5 result — D2740 crown at $36,250 |
| `07-lost-revenue.png` | Q6 result — $15,587 and $11,075 |
| `08-overdue-recall.png` | Q7 result — Sofia Okafor at 366 days |
| `09-noshow-by-insurance.png` | Q8 result — Self-pay 15% down to Medicaid 9.2% |

Once all nine are in place, delete this file before uploading to GitHub.

## Row-count query (for screenshot 02)

```sql
SELECT 'patients', COUNT(*) FROM patients
UNION ALL SELECT 'providers', COUNT(*) FROM providers
UNION ALL SELECT 'appointments', COUNT(*) FROM appointments
UNION ALL SELECT 'procedures', COUNT(*) FROM procedures;
```
