# Orange Taxi — Design System

One visual language for every screen. Branding and functionality unchanged; only the presentation layer is unified.

Status: **specification only.** No code has been changed. This document defines the target and maps it onto what exists today.

---

## 1. Foundations

### 1.1 Spacing — 8-point scale

| Token | Value | Use |
|---|---|---|
| `xs` | 8 | Icon-to-label gaps, chip padding |
| `sm` | 16 | Card inner padding, gap between rows |
| `md` | 24 | Screen horizontal padding, gap between cards |
| `lg` | 32 | Gap between major sections |
| `xl` | 40 | Top of screen to first card, bottom safe gutter |

Only these five values. Any 6, 10, 11, 12, 13, 14, 18, 20 currently in the tree is a violation.

**Existing `AppSpacing` does not match** — it is `xs 4, sm 8, md 12, lg 16, xl 20, xxl 24`. It must be redefined to the scale above. It is currently near-unused, so the redefinition is cheap; the risk is the literal `12.height` / `16.width` extension calls scattered through the widgets, which are the real source of the drift.

### 1.2 Radius

| Token | Value | Use |
|---|---|---|
| `card` | 24 | Primary cards — trip, fare, payment, profile hero |
| `control` | 18 | Buttons, small cards, input fields, icon containers on buttons |
| `chip` | 999 | Pills, status badges, tabs |
| `sheet` | 28 (top only) | Bottom sheets |

`AppRadius` today is `sm 12, md 20, lg 30`. Retarget to `control 18 / card 24 / sheet 28`. The screens currently mix 8, 10, 12, 14, 15, 16, 20, 24 and 30 — that spread is the single most visible inconsistency.

### 1.3 Elevation — one shadow

```
color: charcoal @ 6% alpha
blurRadius: 18
offset: (0, 6)
spreadRadius: 0
```

One style everywhere. Replaces the current three-tier `AppShadows.sm/md/lg` plus a dozen inline `BoxShadow`s with per-screen blur values (8, 10, 12, 15, 20, 24) and colored glows (`primary @ 0.4`, `orange @ 0.3`, `amber600 @ 0.25`).

Exceptions, and only these two:
- **Bottom sheets and bottom bars** cast upward: same color/blur, offset `(0, -6)`.
- **Pressed state** drops to blur 8, offset `(0, 2)`.

Colored glows are removed. A yellow shadow under a yellow button reads as a bug at 1x.

### 1.4 Color

| Role | Hex | Current token |
|---|---|---|
| Primary Yellow | `#F6C945` | `AppColors.primary` is `#F4BE34` — close, retune to spec or keep and update the doc |
| Charcoal | `#111827` | No exact match; `darkText`/`charcoal` are `#1E272E`, `darkSlate` is `#1E293B` |
| Secondary Gray | `#64748B` | `AppColors.slate500` — exact match, adopt as the only secondary |
| Surface | `#FFFFFF` | `AppColors.white` |
| Canvas | `#F7F8FA` | `AppColors.backgroundColor` |
| Hairline | `#F3F4F6` | `AppColors.grey100` |
| Success | `#10B981` | `AppColors.successGreen` |
| Error | `#EF4444` | `AppColors.red500` |
| Warning | `#F59E0B` | `AppColors.warning` |

**Consolidation required.** `AppColors` currently exposes four near-identical dark tones (`charcoal`, `darkText`, `darkSlate`, `black`) and two greys used interchangeably for the same job (`grey500 #6B7280`, `slate500 #64748B`). Pick **one** dark and **one** secondary grey; alias the rest so existing call sites keep compiling, then migrate and delete.

Green and red appear **only** for status and alerts. Never for decoration, never as a card background outside a status banner.

### 1.5 Typography

| Role | Size | Weight |
|---|---|---|
| Screen title | 30 | Bold |
| Section title | 22 | Semibold |
| Card title | 18 | Semibold |
| Body | 15 | Regular |
| Caption | 12 | Regular |

Five sizes. Today the tree uses 8, 9, 9.5, 10, 11, 11.5, 12, 12.5, 13, 13.5, 14, 14.5, 15, 16, 17, 18, 19, 20, 22, 24, 26, 28, 30, 38 — roughly twenty-four sizes doing the work of five.

**Typeface conflict, needs your decision.** The spec asks for Inter or SF Pro. The app ships **Poppins** only (`pubspec.yaml` declares Regular / Medium 500 / Bold 700, and `CustomText` hardcodes `fontFamily: 'Poppins'` in several places). Switching means adding Inter `.ttf` files, changing the `fonts:` block, and sweeping the hardcoded family strings. Three options:

1. **Keep Poppins.** Zero asset work. Poppins is geometric and rounder than Inter — friendlier, less "fintech". Perfectly credible for ride-hailing.
2. **Move to Inter.** Matches the reference products named (Revolut, Bolt). Costs an asset addition plus a sweep of `fontFamily` literals.
3. **Inter for numerals only.** Fares and distances get Inter's tabular figures; everything else stays Poppins. Best legibility per unit of effort, but two families to maintain.

Recommendation: **(1) or (2), not (3)** — a mixed stack undermines the "one product" goal this whole exercise is for.

Note that only three Poppins weights are bundled. Semibold (600) is **not** among them, so today it silently renders as Medium or is synthesized. Whichever family is chosen, ship the 600 weight or restate the hierarchy in terms of 500/700.

### 1.6 Icon containers

```
size: 48 × 48
radius: 16
background: accentColor @ 12% alpha
icon: 22, accentColor
```

One treatment. Currently these run 30, 32, 36, 38, 40, 42, 44, 46, 48 and 52 across screens, with radii of 8, 10, 11, 12, 14 and full-circle, and backgrounds sampled from `grey50`, `grey100`, `amber50`, `orange50`, or a tinted alpha.

Circular containers are reserved for **avatars and map controls only**.

---

## 2. Components

Every component below is defined once and reused. No screen redefines them locally.

### 2.1 Header — 64px, one pattern

```
height: 64
left:   44px circular back button, white, one shadow
center: title — 18 Semibold, charcoal
right:  zero or one action (icon button or pill), 44px tall
background: canvas, no elevation, no divider
```

Screen titles at 30 Bold live **in the body**, not the header, when a screen has a hero block. Both patterns exist in the app now, chosen inconsistently. Rule: header title always 18; body title 30 only when the screen opens on a hero.

### 2.2 Buttons

| Variant | Fill | Text | Border |
|---|---|---|---|
| Primary | Primary Yellow | Charcoal | none |
| Secondary | White | Charcoal | 1px `grey200` |
| Tertiary | transparent | Primary | none |
| Destructive | White | Error | 1px Error @ 30% |

```
height: 54
radius: 18
shadow: standard (primary and secondary only)
content: centered, icon 20 + 8 gap + label 15 Semibold
pressed: scale 0.98, shadow drops to blur 8 / (0, 2)
disabled: 40% opacity, no shadow
```

`CustomButton` already covers height, press-scale, loading and icon slots — it is the closest thing to a system component in the codebase. Extend it with the variant enum, retarget height 55 → 54 and radius 15 → 18, and **delete the hand-rolled button containers** in `payment_screen`, `trip_finished_screen`, `vehicle_selection`, `offers_screen` and the trip sheet that reimplement it inline.

Gradients on buttons are dropped in favour of flat Primary Yellow. `AppColors.gradientButton` currently appears on some primary actions and not others, which makes the same action look like two different buttons on two screens.

### 2.3 Cards

```
background: white
radius: 24
padding: 24
shadow: standard
gap between cards: 24
```

Internal rules:
- Section label — 12 caption, secondary gray, uppercase, `letterSpacing 0.5`.
- Rows separated by a **1px `grey100` hairline**, never by a gap alone and never by `Divider` with default indent.
- The single most important value in a card is 22 Semibold; everything else is 15 or 12.
- **No duplicated data.** If the total fare is already the emphasised value, the payment card shows method and status only — not the amount again.

### 2.4 Chips and status badges

```
padding: 8 horizontal, 4 vertical
radius: pill
text: 12 Semibold
icon: 14, optional, 4px gap
background: statusColor @ 12%
foreground: statusColor
```

Applies to Paid / Pending / Cancelled / Live / Round Trip / Most Popular. These are five different shapes today.

### 2.5 Input fields

```
height: 54
radius: 18
fill: white
border: 1px grey200 → 1.5px Primary on focus
label: 12 caption above the field, secondary gray
error: 12 caption below, Error color
prefix icon: 20, secondary gray
```

Validation messages stay inline under the field — never a snackbar.

### 2.6 Bottom navigation

```
height: 72 + safe area
background: white
radius: 24 top corners
shadow: standard, inverted
active: Primary Yellow icon + 12 Semibold label
inactive: secondary gray icon + 12 Regular label
```

### 2.7 Notification card

```
layout:  4px colored left accent | 48px icon container | content | timestamp
radius:  18
unread:  white surface, 15 Semibold title, 6px Primary dot right-aligned
read:    canvas surface, 15 Regular title, secondary gray body
accent + icon tint: by category (trip / payment / offer / system)
```

---

## 3. Screen-level restructuring

### 3.1 Trip Details

Target order — one card per step, 24px between:

1. **Route summary** — pickup/destination timeline, then a divider, then the meta strip (date · distance/duration · vehicle).
2. **Fare breakdown** — icon container + card title + caption, then hairline-separated rows.
3. **Total Fare** — tinted block inside the fare card, amount at 22 Semibold.
4. **Payment status** — method, status chip, and a status banner. **No amount.**
5. **Primary action** — View Invoice, then the secondary help action.

The amount currently appears in both the fare total and the payment card. Remove it from the payment card; the total is the emphasised value and repeating it weakens both.

### 3.2 Deals

- Coupon card: 24 radius, colored value stub on the left, code and terms centre, copy action right.
- Copy button becomes a **secondary button at 40px**, not a bordered text container. Confirmation state swaps icon and label in place — no snackbar.
- Offer details expand inside the card with the standard hairline rows.
- One shadow, 24px gaps, section headers using the 48px icon container.

### 3.3 Profile

- Hero: **96px avatar**, name at 22 Semibold, member-since caption, and an **outlined Edit button** (secondary variant) — not the current icon-in-a-card.
- Contact rows: one leading 48px icon container, label + value stacked, chevron right. **One icon per row.** Today phone and email each render a small inline icon while the row also carries meaning from its position — pick the icon container and drop the inline duplicate.
- Settings list: hairline separators, no indent, 48px icon containers with per-item tint.

---

## 4. Migration order

Sequenced so each step is independently shippable and reviewable. Nothing here is a rewrite.

| # | Step | Touches | Risk |
|---|---|---|---|
| 1 | Retarget `AppSpacing`, `AppRadius`, `AppShadows` to the tokens above; add `AppTypography` | `app_tokens.dart` | Low — additive, old names kept |
| 2 | Consolidate `AppColors` dark tones and greys behind aliases | `app_colors.dart` | Low — aliases keep call sites compiling |
| 3 | Extend `CustomButton` with variants; delete inline button containers | 6 screens | Medium — visual diff on every primary action |
| 4 | Build `AppCard`, `AppHeader`, `AppChip`, `AppIconTile`, `AppListRow` | new `core/custom_widgets/` files | Low — new code, no call sites yet |
| 5 | Migrate screen by screen: Trip Details → Deals → Profile → Notifications → My Trips → Payment | one screen per PR | Medium |
| 6 | Typeface decision and sweep, if Inter is chosen | `pubspec.yaml`, `CustomText`, assets | Medium — whole-app visual diff |
| 7 | Delete the old tokens and the compatibility aliases | `app_tokens.dart`, `app_colors.dart` | Low — analyzer catches every miss |

Do **not** run steps 3 and 6 in the same PR. If both the buttons and the typeface change at once, no reviewer can tell which change caused a given regression.

---

## 5. Open decisions

These need your answer before implementation starts; each one changes the work materially.

1. **Typeface** — keep Poppins, or add Inter? (§1.5)
2. **Primary Yellow** — retune `#F4BE34` → `#F6C945`, or keep the current brand value and amend this doc? The two are close but not identical, and the shipped app is the one users have seen.
3. **Charcoal** — `#111827` is darker than the current `#1E272E`. Adopt the spec value, or standardise on the existing one?
4. **Gradients** — `AppColors.gradientButton` is used on primary CTAs across several screens. This spec drops it for flat yellow. Confirm, or keep gradients as the primary-button fill.
5. **Semibold** — bundle the 600 weight, or restate the hierarchy against the 500/700 weights already shipped?

---

## 6. What this document is not

It does not cover motion, dark mode, accessibility contrast ratios, or localisation reflow. Those are worth their own passes once the static system is in place.
