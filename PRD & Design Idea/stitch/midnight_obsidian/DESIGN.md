# Design System Specification: Premium Fee Management

## 1. Overview & Creative North Star: "The Financial Luminary"

This design system moves away from the sterile, spreadsheet-like nature of traditional fintech. Our Creative North Star is **"The Financial Luminary."** We treat financial data as a high-end editorial experience—think luxury watch catalogs or private banking interfaces. 

The goal is to break the "template" look common in Material Design by utilizing **intentional asymmetry**, **tonal depth**, and **negative space**. We do not use lines to separate ideas; we use light and layering. The interface should feel like a series of obsidian glass sheets floating in a deep, digital void, illuminated by the electric glow of currency flows.

---

## 2. Color & Surface Architecture

The palette is anchored in a deep, "Deep Black" and "Charcoal" foundation, punctuated by "Electric Blue" to signify action and "Soft Purple" to signify luxury and premium features.

### Surface Hierarchy & The "No-Line" Rule
Standard UI relies on borders to define containers. In this system, **1px solid borders are strictly prohibited for sectioning.** 

Boundaries are defined through **Tonal Layering**:
- **Base Layer:** `surface_container_lowest` (#0D0D1A) - The infinite void.
- **Sectioning:** `surface_container_low` (#1a1a28) - Used for grouping content.
- **Interactive Elements:** `surface_container` (#1e1e2c) - Standard cards.
- **Elevated Prompts:** `surface_container_high` (#292937) - Floating dialogs.

### The Glass & Gradient Rule
To achieve "Dark Luxury," use Glassmorphism for floating UI elements (like bottom navigation or top app bars).
- **Glass Formula:** Background: `surface_container` at 80% opacity + `backdrop-filter: blur(16px)`.
- **Signature Gradients:** For Primary CTAs, transition from `primary_container` (#2563eb) to `secondary_container` (#571bc1) at a 135° angle. This adds a "soul" to the interface that flat colors cannot replicate.

---

## 3. Typography Scale: Editorial Authority

We use a high-contrast typographic scale to create an editorial feel. **Manrope** provides a modern, geometric authority for headings, while **Inter** ensures hyper-readability for dense financial data.

| Level | Font Family | Size | Weight | Intent |
| :--- | :--- | :--- | :--- | :--- |
| **Display-LG** | Manrope | 3.5rem | 700 | Large balance displays |
| **Headline-MD** | Manrope | 1.75rem | 600 | Section headers |
| **Title-LG** | Inter | 1.375rem | 500 | Card titles |
| **Body-LG** | Inter | 1rem | 400 | Primary data points |
| **Label-MD** | Inter | 0.75rem | 500 | Metadata / Secondary text |

*Note: Use `on_surface_variant` (#c3c6d7) for secondary text to maintain a soft contrast that reduces eye strain in dark mode.*

---

## 4. Elevation & Depth: The Layering Principle

Depth in this system is organic, not artificial. We mimic natural light interacting with dark surfaces.

- **Ambient Shadows:** Shadows should never be black. Use a tinted version of `on_surface` (at 4-8% opacity) with a large blur (24px-32px) and 0 spread. This creates a "glow" around the container rather than a harsh drop-shadow.
- **The "Ghost Border" Fallback:** If a border is required for accessibility (e.g., in high-glare environments), use `outline_variant` (#434655) at **20% opacity**. It should be felt, not seen.
- **Nesting:** Place a `surface_container_high` card inside a `surface_container_low` background. This "stacking" effect creates hierarchy without adding visual noise.

---

## 5. Component Logic

### Buttons & Interaction
- **Primary:** Gradient-filled (Electric Blue to Soft Purple) with a `xl` (1.5rem) corner radius. Use a subtle outer glow of the primary color on hover/focus.
- **Secondary:** Glass-morphic background (Surface + Blur) with a `outline_variant` Ghost Border.
- **Tertiary:** Pure text using `primary_fixed` color, reserved for low-priority actions like "Cancel" or "Learn More."

### Cards & Fee Lists
- **The "No-Divider" Rule:** Never use a horizontal rule `<hr>` to separate list items. Use 16px of vertical whitespace or a subtle background shift (`surface_container_low` vs `surface_container_lowest`).
- **Radius:** All cards must use `xl` (1.5rem) corner radius to soften the "tech" feel and make the app feel more approachable and premium.

### Input Fields
- **Floating State:** Fields should use a `surface_container_highest` background with a `sm` (0.25rem) bottom-only accent in `primary` when focused.
- **Glass Inputs:** For search bars, use the Glassmorphism formula to allow underlying content to peek through as the user scrolls.

### Specialized Components
- **The "Wealth Trend" Sparkline:** Integrated directly into the card background using a subtle gradient path (Primary to Transparent).
- **Status Pills:** Use Semantic colors (Success/Error) at 15% opacity for the background and 100% opacity for the text. This prevents "neon-clash" against the dark luxury theme.

---

## 6. Do’s and Don’ts

### Do:
- **Do** use generous whitespace (8px modular grid). If you think there is enough space, add 8px more.
- **Do** use `display-lg` typography for the primary "Hero" number on a screen (e.g., Total Fees).
- **Do** overlap elements (e.g., a card slightly overlapping a header background) to create a custom, non-grid feel.

### Don’t:
- **Don’t** use 100% white (#FFFFFF). Always use `on_surface` (#e3e0f4) to keep the "luxury" vibe.
- **Don’t** use hard shadows or 1px borders. They shatter the "glass" illusion.
- **Don’t** use standard Material 3 "Tonal Palettes" that result in muddy greys. Stick to the deep, blue-tinted darks specified in the tokens.

---

## 7. Token Summary

- **Primary CTA:** `primary_container` (#2563eb)
- **Secondary Highlight:** `secondary` (#d0bcff)
- **Background Layer 0:** `surface_container_lowest` (#0d0d1a)
- **Card Layer 1:** `surface_container` (#1e1e2c)
- **Border Radius:** `xl` (1.5rem / 24px) for cards; `full` for chips.
- **Typography:** Manrope (Headings), Inter (Body).