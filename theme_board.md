## Technex Theme Board

### 1. Brand Palette (Dual Tone)

- **Dark Tone (Primary Background)**
  - Hex: `#171614`
  - Role: App background, scaffold background, base for dark surfaces.
  - Usage: `scaffoldBackgroundColor`, `ColorScheme.background`, dark surfaces.

- **Accent Tone**
  - Hex: `#9A8873`
  - Role: Primary accent for actions, highlights, borders.
  - Usage: `ColorScheme.primary`, buttons, active borders, icons.

- **Surface Dark**
  - Hex: `#1F1E1B`
  - Role: Cards, tiles, input backgrounds.
  - Usage: `ColorScheme.surface`, card backgrounds, list tiles.

- **On Dark / On Surface Text**
  - Primary text: `#F5F3EE`
  - Secondary text: `#E0DDD7`
  - Subtle / hint: `#8A857D`

- **Error**
  - Hex: `#CF6679`
  - Role: Error states, validation messages.

### 2. Global Theme (Flutter `ThemeData`)

- **Brightness**
  - `Brightness.dark` – overall dark, minimal aesthetic.

- **ColorScheme (core mapping)**
  - `primary`: Accent tone `#9A8873`
  - `onPrimary`: Dark tone `#171614`
  - `secondary`: Accent tone `#9A8873`
  - `onSecondary`: Dark tone `#171614`
  - `background`: Dark tone `#171614`
  - `onBackground`: `#F5F3EE`
  - `surface`: Dark surface `#1F1E1B`
  - `onSurface`: `#F5F3EE`
  - `error`: `#CF6679`
  - `onError`: Dark tone `#171614`

### 3. Typography

- **Global Font Family**
  - **Plus Jakarta Sans** (via Google Fonts, `google_fonts` package).
  - Applied app-wide through `GoogleFonts.plusJakartaSansTextTheme` so all text styles (headings, body, buttons) inherit this modern sans serif.

- **AppBar Title / Screen Title**
  - Size: 20
  - Weight: 600 (semi-bold)
  - Color: `#F5F3EE`

- **Headline (Section headings)**
  - `headlineMedium`
  - Size: 24
  - Weight: 600
  - Color: `#F5F3EE`

- **Body Text**
  - `bodyMedium`
  - Size: 14
  - Color: `#E0DDD7`

- **Button Text**
  - Size: 16
  - Weight: 500
  - Color: `onPrimary` (dark tone) on accent buttons.

### 4. App Bar

- **Style**
  - Background: Transparent over dark backdrop.
  - Elevation: 0 (flat, minimal).
  - Centered title.
  - Title style: See "Typography → AppBar Title".

### 5. Buttons

- **Primary Elevated Button**
  - Background: Accent `#9A8873`
  - Foreground (text/icon): Dark tone `#171614`
  - Elevation: 0 (no shadows).
  - Shape: RoundedRectangle, radius 10.
  - Border: 1px, accent with ~0.8 opacity.
  - Text style: 16, weight 500.
  - Usage: Main actions (e.g., "Customer", "Service Provider", primary CTAs).

### 6. Cards & Tiles

- **Card / Tile Base**
  - Background: Surface dark `#1F1E1B`
  - Elevation: 0 (flat).
  - Radius: 12.
  - Border: Very subtle, white with ~0.05 opacity.
  - Margin: Vertical 8, horizontal 0.

- **List Tiles (Suggestions, service rows)**
  - Tile color: `#1F1E1B`
  - Padding: Horizontal 16, vertical 8.
  - Shape: Same as cards (radius 12, subtle border).
  - Icon color: Accent `#9A8873`
  - Text color: `#F5F3EE`

### 7. Inputs (For Future Forms)

- **Text Fields**
  - Filled: true.
  - Fill color: Surface dark `#1F1E1B`
  - Border radius: 12.
  - Enabled border: 1px, white with ~0.06 opacity.
  - Focused border: 1.2px, accent `#9A8873`.
  - Hint style: Color `#8A857D`.

### 8. Layout & Spacing Guidelines

- **Screen Padding**
  - Standard: 24px horizontal padding on main screens.

- **Vertical Rhythm**
  - Between major blocks (e.g., title and buttons): 24–32px.
  - Between related controls (e.g., stacked buttons): 12–16px.

- **Component Proportions**
  - Primary buttons: Height ~48px.
  - Tiles / cards: Minimum height ~64px with comfortable padding.

### 9. Usage Notes

- Always maintain a clear hierarchy: dark background, slightly lighter surfaces, accent for actions.
- Avoid extra shadows; rely on **borders, contrast, and spacing** for structure.
- Prefer tiles/cards for grouped information (e.g., service suggestions, bookings) to keep the UI consistent.


