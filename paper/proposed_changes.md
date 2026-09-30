# Proposed changes: CFA cross-loadings and follow-ups

*Status on 2026-09-30, after the open science practice items were rescored as engagement ("not familiar" = 0 < "don't plan to use" = 1/3 < "plan to use" = 2/3 < "used" = 1). Nothing in this document has been applied yet.*

## 1. Use the cross-loadings CFA (main change)

### Why

The facet scores used in axis 3 come from a CFA in which items are assigned to facets by the movement they were asked under. The EFA disagrees for two of the six green items:

| Item | EFA loading on Green Science | EFA loading on Ethical Science |
|---|---|---|
| Link between scientific production and environmental sustainability | .31 | .42 |
| Willingness to change one's practices for environmental reasons | .44 | .39 |

The other four green items (importance of sustainability in conducting research and in choosing topics, changed research practices, changed communication practices) load only on Green Science. The two items above are beliefs and intentions rather than practices, and they go with team diversity and care for societal consequences as much as with sustainability in practice.

Three CFA specifications, computed in the notebook (chunk `cfa_alternatives`):

| Model | Green Science | Ethical Science | CFI | TLI | RMSEA | AIC vs. current | *r* (Green, Ethical) |
|---|---|---|---|---|---|---|---|
| Movement-based (current) | 6 green items | diversity, consequences | .891 | .869 | .063 | — | .60 |
| Green beliefs on Ethical | 4 practice items | diversity, consequences, link, willingness | .912 | .894 | .057 | −73 | .75 |
| **Cross-loadings (proposed)** | 6 green items | diversity, consequences, link, willingness | **.919** | **.901** | **.055** | **−97** | .52 |

The cross-loadings model is the current model plus two paths. It fits best and matches the EFA. It also keeps Green Science defined as before, while Ethical Science becomes a broader *responsibility* facet that includes environmental beliefs. Moving the two items to Ethical only is no longer supported: after the rescoring, willingness to change loads slightly more on Green.

### What changes

**Notebook (`analysis/analysis.qmd`):**

- In the `cfa_model` string (CFA chunk), add the two items to Ethical Science:
  ```
  Ethical_Science  =~ ES_Importance_research_team +
                      ES_Consequences_society +
                      GS_Relation_Research_Sustainability +
                      GS_Change_practices_agreeing
  ```
- `cfa_alternatives`: relabel the models so that "(used)" marks the cross-loadings model.
- The CFA path diagram (`p_cfa`, in `fig_structure`): add the two cross-loading arrows. Its layout is placed by hand, so check it.
- Re-render with `--cache-refresh`, because the facet scores feed the clustering and all axis-3 models (about 15 minutes).
- Refit the Profile model on Artemis. The clusters are recomputed, so `data_Profile.csv` changes: `./hpc push && ./hpc fit Profile`, then `./hpc pull` (about 3 minutes, VPN needed). Log the run in `server/AGENT.md`.
- Rewrite the "Headline Findings" section from the new tables.

**Manuscript (`paper/manuscript.qmd`):**

- Rewrite the CFA paragraph in "Four movements, five facets". It should report the cross-loadings model as the one retained, and the movement-based model as the a-priori one it improves on (CFI, AIC). The comparison table could go to the supplementary materials. Remove the bold TO CONFIRM note.
- Figure 2C updates itself. Green–Ethical drops from .60 to about .52; the other correlations should move little, but check them.
- Check "Epistemic and societal sides": the wording depends on which correlations exclude 0.
- All numbers are inline and update on render (notebook first, then manuscript).

**Expected consequences for axis 3:** Open, Rigorous and Slow Science scores are essentially unchanged. Ethical Science scores change most, and Green Science a little. The gender and age effects on Ethical and Green Science, and the cluster profiles, may shift.

## 2. Open question: the name of the Ethical facet

With the environmental beliefs on it, "Ethical Science" covers more than ethics and inclusion. Options:

- Keep **Ethical Science**, and say in the text that it includes environmental responsibility. This is the simplest and matches the notebook.
- Rename it **Responsible Science**. This is more accurate, but the facet name then departs from the movement name, which the facets/movements framing allows.

## 3. Supplementary materials: scoring sensitivity

The manuscript's TO CONFIRM note says the facet structure is robust to how the practice items are scored. So far this was checked in a one-off script, outside the notebook. The proposal is a notebook chunk (`scoring_sensitivity`) that refits the EFA and the retained CFA under four scorings, reporting fit, open science loadings and the correlation of facet scores with the retained scoring:

| Scoring | not familiar | don't plan | plan | used |
|---|---|---|---|---|
| Engagement (retained) | 0 | 1/3 | 2/3 | 1 |
| Former | 1/3 | 0 | 2/3 | 1 |
| Non-engagement pooled | 0 | 0 | 1/2 | 1 |
| Unfamiliarity missing | NA | 0 | 1/2 | 1 |

Results of the one-off check: the Open/Rigorous split appears under all four scorings, and facet scores correlate .86–.98 with the retained one.

## 4. Decision to take before writing axis 3: how many profiles

After the rescoring, the five-profile solution is unstable: bootstrap median ARI = .56 (95% range .30–.89). Two- and three-cluster solutions are stable (.85). Options:

1. Keep five profiles and present them as descriptive, with the stability caveat. This is the current state of the notebook.
2. Use three profiles, which are stable. The Profile model and its labels would change accordingly.
3. Put the facet scores (continuous) at the centre of axis 3, and report the profiles only briefly.

This should be settled after change 1, since the facet scores change the clustering.

## 5. Minor fixes noticed along the way

- `color_vars_resprac` (EFA chunk) lists "Green Science - Ecofriendly Practices" twice. The notebook's EFA network plot (`p_resprac`) then shows that item twice, and one node has no edge. The paper figures are not affected.
- The correlation-matrix plot (`p_cor`) frames facets with hard-coded rectangle positions, which silently misalign if the item order changes. The paper figure (`fig_facets`) computes its frames from the EFA.

## 6. Order of operations

1. Change 1 (cross-loadings), with change 5 alongside.
2. Add the sensitivity chunk (change 3) in the same `--cache-refresh` render.
3. Refit Profile on Artemis, re-render notebook and manuscript, and update the Headline Findings.
4. Decide on the facet name (change 2) and the number of profiles (change 4).
5. Draft axis 3.

## Remaining TO CONFIRM notes in the manuscript (not affected by the above)

- Corresponding author, ORCIDs, emails and CRediT roles of all authors (YAML).
- Badges: `data/` must be committed and pushed; choice of the `-tc` badge.
- Completion time reported as median and IQR.
- IRB number; exact number of items; three or four randomised blocks.
- Recruitment period; implausible ages set to missing.
- Importance ratings of slow science by participants unfamiliar with it.
- Participants selecting no definition of slow science.
- Number of components for the quality criteria.
