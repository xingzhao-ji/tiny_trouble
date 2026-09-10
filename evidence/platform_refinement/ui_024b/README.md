# Adaptive source follow-up · 0.2.4 preparation

**PASS 1,289 checks; all 28 native source PNGs reviewed.** These are Mac desktop viewport simulations, not iOS Simulator or physical iPhone/iPad tests. The corrected fixture uses the actual stage title and long subgoal, then checks objective and target cards shrinking back to short copy at text 1.0/1.25. The earlier eight fixture failures from an unwrapped artificial stage title are not a passing result; this fresh run replaces that fixture result while preserving earlier evidence.

Direct inspection found no new concrete clipping, focus-label, card/action overlap or missing-control defect in these views. Default/max-text gameplay cards and action labels fit. Scroll captures expose lower settings and Back actions; partially clipped upper content is inside the intended scroll viewport. K/L keyboard and controller hints fit. The portrait guard is readable and landscape returns after explicit resume. Pip stays visible in the shown Crumb interaction fixture.

| Scope | Recorded evidence |
| --- | --- |
| Viewports | 1280×720, 1024×768, 844×390, requested 667×375 (actual 666×374), and 390×844 portrait; 28 captures, each focused at capture time |
| Controls/layout | Eight 88-logical-unit action targets plus pad, safe-inset fixture L48/T16/R32/B24, default/max text, actual concurrent Crumb actions, cancellation, modes, pause/reset and explicit portrait recovery |
| Minimum rendered target | 45.71 pixels at the smallest actual window; this is a Mac pixel measurement, not an iOS physical-point claim |
| New card checks | Long-to-short objective and target height at default/max text for each landscape fixture |

This remains a seeded Crumb scene/input fixture, not a complete route or a complete camera/composition review. Menu scrolling is exercised programmatically. Physical touch, controller/accessory keyboard, actual device safe areas and human readability/ergonomics remain unverified. The separate Harbor source touch route (`../phone_024a/`) supplies actual route/projection evidence; this review does not replace its geometry checks. A corrected packaged 0.2.4 result is still pending.

`review.json` hashes the 28 directly inspected PNGs, report and this README. It does not assign current source hashes retroactively to the captured runtime. The historical `evidence/platform_ui/` 1,265-check/28-capture record and rejected frozen 0.2.3 package evidence remain untouched.
