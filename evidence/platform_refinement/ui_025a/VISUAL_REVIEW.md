# Responsive UI — source candidate0.2.5 still review

All28 actual PNGs in this directory were inspected at their native image dimensions on 2026-09-09. Foreground labels and controls fit the reviewed viewports; no additional blocking overlap was observed. This is a bounded agent still review, not human readability, reach or motion approval.

| Reviewed set | Observed scope |
| --- | --- |
| 1280×720: title, play, play_default_text, pause, pause_scrolled, controls_scrolled | Title/buttons fit; default/max text target cards remain separate from Pip and touch controls. Settings and remap rows are readable at their respective scroll positions, including Back. These gameplay frames use touch controls, not the historical keyboard-only desktop baseline. |
| 1024×768: same six views | Expanded aspect leaves more world area; cards and controls remain distinct. Foreground menu copy and bottom actions fit. |
| Requested667×375, actual666×374: same six views | Objective/help text wraps within the compact cards. Pip remains visible on the spoon. Size buttons, joystick and actions stay separated. The pause menu intentionally scrolls; its initial view crops later rows, and the lower capture exposes settings/navigation without clipping the bottom buttons. |
| 844×390: title, play, play_default_text, pause, pause_scrolled, controls_scrolled | Pip and the active spoon remain visible in play. Scrolled menus expose lower settings and remap rows; the gamepad help wraps above Back. |
| 844×390: keyboard_hints, controller_hints | Footer mappings change and remain contained. Touch controls are hidden in these hint states. Pip and the spoon remain clear; the hint text is smaller than the mobile action labels and has not been human readability-tested. |
| 390×844: portrait_guard | Centered rotation guidance is fully contained, with no gameplay controls competing behind it. |
| 844×390: rotation_recovered | Landscape controls and target card return with Pip visible. One still does not establish transition comfort or real-device rotation behavior. |

The dim world HUD remains visible behind the modal scrim, with some cards partially covered by the menu. That is an underlay, not foreground label clipping; simplifying this background could be considered in a later human presentation review. Scrolled menus intentionally crop content outside their viewport. These observations do not treat the initial clipped lower rows as lost controls because the lower captures show them accessible.

The [capture report](capture_report.json) records **PASS,1293 assertions,0 failures**, and28 captures. It uses isolated checkpoint/player-placement fixtures, injected touch/notifications and some direct button signals/programmatic scrolling. It is not an ordinary-input stage solution. Safe insets are explicit asymmetric simulations; odd requested667×375 pixels render666×374 in macOS backing-store rounding. Rendered pixels are not physical iOS points. No iOS Simulator, physical device, hardware controller, performance, subjective audio or human approval is established here.

The separate [Milk Harbor route review](../phone_max_025a/VISUAL_REVIEW.md) covers the corrected persistent-card avoidance during a full injected-input route. Dynamic placement comfort and all mandatory human proportions/cohesion/motion gates remain pending. No runtime or image bytes were edited. [review_sources.json](review_sources.json) records all28 image hashes and dimensions plus the report hash.
