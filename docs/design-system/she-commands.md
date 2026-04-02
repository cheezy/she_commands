# She Commands Design System — Executive Command

- **Stitch Project:** `projects/14057949281428043901`
- **Stitch Asset (original):** `assets/2960323348998855921`
- **Stitch Asset (Executive Command):** `assets/d31dd418206d40278c84a84f722592c2`

---

## 1. Overview & Creative North Star

The Creative North Star is **"The Executive Editorial."**

Moving away from generic SaaS-blue dashboard aesthetics into high-end, bespoke publication design. Built for power — extreme contrast, intentional negative space, commanding attention. Breaks the traditional rigid grid through **intentional asymmetry**: overlapping imagery, offset text blocks, and varying typographic scales that mimic a physical luxury magazine. Every screen should feel curated, not generated.

---

## 2. Theme Configuration

| Property | Value |
|---|---|
| Color Mode | Light |
| Color Variant | Fidelity |
| Custom Color | `#1A1A1A` |
| Primary Override | `#1A1A1A` |
| Secondary Override | `#3C635B` |
| Tertiary Override | `#E0B771` |
| Neutral Override | `#F8F7F3` |
| Headline Font | Space Grotesk |
| Body Font | Inter |
| Label Font | Work Sans |
| Roundness | Round 4 (sharp/minimal) |
| Spacing Scale | 3 |

---

## 3. Color Palette

### Color Roles

| Role | Hex | Token | Usage |
|---|---|---|---|
| **Primary** | `#000000` | `primary` | Absolute authority — core branding, heavy headlines, high-impact CTAs |
| **Surface** | `#faf9f5` | `surface` | "Fine Paper" base — warmer than pure white, premium tactile feel |
| **Secondary** | `#3f665d` | `secondary` | "Executive Forest" — sparingly for deep tonal backgrounds or success states |
| **Tertiary** | `#E0B771` | `tertiary_fixed_dim: #eac079` | "The Gold Standard" — reserved for exclusivity, premium features, subtle accents |
| **Error** | `#ba1a1a` | `error` | Error states only |

### Full Token Map

| Token | Hex |
|---|---|
| `background` | `#faf9f5` |
| `on_background` | `#1b1c1a` |
| `surface` | `#faf9f5` |
| `surface_bright` | `#faf9f5` |
| `surface_dim` | `#dbdad6` |
| `surface_container_lowest` | `#ffffff` |
| `surface_container_low` | `#f4f4f0` |
| `surface_container` | `#efeeea` |
| `surface_container_high` | `#e9e8e4` |
| `surface_container_highest` | `#e3e2df` |
| `surface_variant` | `#e3e2df` |
| `surface_tint` | `#5f5e5e` |
| `on_surface` | `#1b1c1a` |
| `on_surface_variant` | `#444748` |
| `primary` | `#000000` |
| `primary_container` | `#1c1b1b` |
| `primary_fixed` | `#e5e2e1` |
| `primary_fixed_dim` | `#c8c6c5` |
| `on_primary` | `#ffffff` |
| `on_primary_container` | `#858383` |
| `on_primary_fixed` | `#1c1b1b` |
| `on_primary_fixed_variant` | `#474746` |
| `secondary` | `#3f665d` |
| `secondary_container` | `#bee8de` |
| `secondary_fixed` | `#c1ebe1` |
| `secondary_fixed_dim` | `#a5cfc5` |
| `on_secondary` | `#ffffff` |
| `on_secondary_container` | `#436a62` |
| `on_secondary_fixed` | `#00201b` |
| `on_secondary_fixed_variant` | `#264d46` |
| `tertiary` | `#000000` |
| `tertiary_container` | `#271900` |
| `tertiary_fixed` | `#ffdea9` |
| `tertiary_fixed_dim` | `#eac079` |
| `on_tertiary` | `#ffffff` |
| `on_tertiary_container` | `#a27e3e` |
| `on_tertiary_fixed` | `#271900` |
| `on_tertiary_fixed_variant` | `#5e4204` |
| `error` | `#ba1a1a` |
| `error_container` | `#ffdad6` |
| `on_error` | `#ffffff` |
| `on_error_container` | `#93000a` |
| `outline` | `#747878` |
| `outline_variant` | `#c4c7c7` |
| `inverse_surface` | `#2f312e` |
| `inverse_on_surface` | `#f2f1ed` |
| `inverse_primary` | `#c8c6c5` |

### The "No-Line" Rule

**Designers are strictly prohibited from using 1px solid borders for sectioning.** Structural boundaries must be defined through:
1. **Background Shifts:** Transitioning from `surface` to `surface_container_low` to define a new content area
2. **Negative Space:** Using large, intentional gaps from the spacing scale to create natural "mental breaks" between content blocks

### Glass & Texture

- Use **Glassmorphism** for floating navigational elements or cards: semi-transparent `surface` colors with `backdrop-blur (20px-40px)`
- Main CTAs should use a subtle gradient from `primary` to `primary_container` to give black elements "soul" and three-dimensional weight

---

## 4. Typography

| Level | Font Family | Usage |
|---|---|---|
| **Display** | **Space Grotesk** | Large, punchy editorial headlines. Hero sections and impact statements. |
| **Headline** | **Space Grotesk** | Section titles. Bold weight, tight letter-spacing for aggressive, modern look. |
| **Title** | **Inter** | Card headers and sub-sections. Clean, functional counterpoint to the display face. |
| **Body** | **Inter** | Long-form reading. High legibility with generous line height (1.6+). |
| **Label** | **Work Sans** | Caps-locked, tracked-out metadata and small UI elements. |

---

## 5. Elevation & Depth — Tonal Layering

No structural lines for hierarchy. Use **Tonal Layering** instead.

- **The Layering Principle:** UI as stacked sheets of fine paper. Place `surface_container_lowest` card on `surface_container_low` background for soft, natural lift.
- **Ambient Shadows:** For floating elements (modals, primary action buttons), use extra-diffused shadow:
  - Spec: `Blur: 40px, Y: 20px, Opacity: 6%`
  - Color: Tinted version of `on_surface` (not pure grey)
- **"Ghost Border" Fallback:** If a border is required for accessibility, use `outline_variant` at **15% opacity**. It should be felt, not seen.

---

## 6. Components

### Buttons

- **Primary:** Solid `primary` (Black) with `on_primary` (White) text. Sharp corners or minimal rounding (0.125rem max) for executive edge.
- **Secondary (Outline):** 2px solid `primary` border, transparent background.
- **Hover Interaction:** Primary button inverts — shifts to `surface` fill with `primary` border.

### Cards & Lists

- **"No-Divider" Mandate:** Lists must never use horizontal lines. Separate items using `surface_container` shifts or vertical padding.
- **Cards:** Use `surface_container_low` with `0.25rem` radius. No heavy shadows — rely on background color shift.

### Input Fields

- Use "Bottom-Line Only" or "Ghost Box" styling. Avoid standard 4-sided boxes.
- Active state: solid `primary` bottom border at 2px thickness.
- Error states use `error` color but maintain the high-contrast ethos.

---

## 7. Do's and Don'ts

### Do

- Use intentional asymmetry — align headline left, CTA far right, significant white space between
- Use large-scale imagery that overlaps background color shifts for layered depth
- Prioritize typography over iconography — if an icon is used, it must be ultra-thin and minimal

### Don't

- Use standard drop shadows (e.g., `0px 4px 10px Black 25%`) — looks cheap and dated
- Use dividers or "boxes within boxes" — if cluttered, add more white space, not more lines
- Use rounded corners above `0.5rem (lg)` — executive design favors sharp, architectural edges

---

## 8. Signature Elements

### Vertical Typography

For high-impact editorial sections, use `label-md` (Work Sans) rotated 90 degrees as a sidebar marker. Breaks horizontal "web" flow, introduces print-media feel.

### The Marquee Motion

Slow-moving horizontal text marquee for secondary brand messaging (e.g., "Power starts here • Live your potential"). `primary` background with `on_primary` text for bold, high-contrast visual break in long-scroll pages.
