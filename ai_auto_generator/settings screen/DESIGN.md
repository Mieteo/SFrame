---
name: Snap Frame
colors:
  surface: '#f9f9ff'
  surface-dim: '#cfdaf2'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3ff'
  surface-container: '#e7eeff'
  surface-container-high: '#dee8ff'
  surface-container-highest: '#d8e3fb'
  on-surface: '#111c2d'
  on-surface-variant: '#424754'
  inverse-surface: '#263143'
  inverse-on-surface: '#ecf1ff'
  outline: '#727785'
  outline-variant: '#c2c6d6'
  surface-tint: '#005ac2'
  primary: '#0058be'
  on-primary: '#ffffff'
  primary-container: '#2170e4'
  on-primary-container: '#fefcff'
  inverse-primary: '#adc6ff'
  secondary: '#505f76'
  on-secondary: '#ffffff'
  secondary-container: '#d0e1fb'
  on-secondary-container: '#54647a'
  tertiary: '#585d60'
  on-tertiary: '#ffffff'
  tertiary-container: '#707579'
  on-tertiary-container: '#fbfcff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a42'
  on-primary-fixed-variant: '#004395'
  secondary-fixed: '#d3e4fe'
  secondary-fixed-dim: '#b7c8e1'
  on-secondary-fixed: '#0b1c30'
  on-secondary-fixed-variant: '#38485d'
  tertiary-fixed: '#dfe3e7'
  tertiary-fixed-dim: '#c3c7cb'
  on-tertiary-fixed: '#171c1f'
  on-tertiary-fixed-variant: '#43474b'
  background: '#f9f9ff'
  on-background: '#111c2d'
  surface-variant: '#d8e3fb'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  button:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin: 20px
---

## Brand & Style

The visual identity of this design system is rooted in **Modern Minimalism** with a focus on utility and precision. It is designed to feel professional, airy, and dependable, evoking a sense of organized calm for users managing visual content. 

The aesthetic leverages generous white space and a "content-first" philosophy. By minimizing unnecessary decorative elements, the design system ensures that the user's focus remains on the "Frame"—the content itself. The style is optimized for one-handed mobile interaction, placing critical interactive elements within the natural reach of the thumb to ensure a frictionless ergonomic experience.

## Colors

The palette is anchored by a vibrant yet professional **Light Blue**, used purposefully for primary actions and brand signifiers. 

- **Primary:** Used for call-to-action buttons, active states, and progress indicators.
- **Background & Surfaces:** A pure white base in light mode ensures maximum contrast. In dark mode, this transitions to a deep slate to maintain depth without causing eye strain.
- **Grays:** A scale of soft grays is used for secondary text, borders, and subtle backgrounds to create a clear informational hierarchy without clutter.
- **Functional Colors:** Success, Warning, and Error states should use standard semantic tones (Green, Amber, Red) but adjusted to match the saturation of the primary blue.

## Typography

This design system utilizes **Inter** for all typographic needs. Inter’s tall x-height and clean apertures provide exceptional legibility on mobile screens, even at small sizes.

- **Scale:** A tight typographic scale is used to maintain a professional, systematic look. 
- **Hierarchy:** Use font weight rather than size alone to differentiate information levels. 
- **One-Handed Considerations:** Headlines are kept concise to prevent pushing content too far down the "fold" of the mobile device.

## Layout & Spacing

The layout follows a **Fluid Grid** model based on a 4px baseline shift. 

- **Margins:** A standard 20px side margin is maintained for all main views to provide a "breathable" frame for content.
- **One-Hand Reach:** Interactive zones are concentrated in the bottom 60% of the screen. Navigation is strictly managed through a bottom-docked tab bar.
- **Rhythm:** Vertical spacing between different sections should typically use the `lg` (24px) or `xl` (32px) units, while spacing between elements within a group uses `sm` (8px).

## Elevation & Depth

This design system uses **Tonal Layers** supplemented by low-contrast outlines to define depth, rather than heavy shadows.

- **Base Layer:** The primary background color.
- **Surface Layer:** Used for cards and input fields, elevated by a subtle 1px border (#E2E8F0) or an extremely soft ambient shadow (0px 2px 4px rgba(0, 0, 0, 0.05)).
- **Intervention Layer:** Modals and bottom sheets use a medium-diffusion shadow to clearly sit above the rest of the UI.
- **Dark Mode:** Depth is communicated through color luminance; higher elevation elements use lighter shades of slate/gray rather than shadows.

## Shapes

The shape language is defined by "Rounded" geometry to evoke friendliness and modern hardware aesthetics. 

- **Standard Elements:** Buttons, cards, and input fields use a base 8px (0.5rem) radius.
- **Large Containers:** Bottom sheets and prominent image frames use a 16px (1rem) radius.
- **Pills:** Search bars and tags may use a fully rounded/pill shape for distinct visual differentiation from primary action buttons.

## Components

- **Buttons:** Primary buttons feature a solid blue fill with white text. Secondary buttons use a light gray ghost style with blue text. All buttons have a minimum height of 48px to accommodate comfortable touch targets.
- **Navigation:** A fixed bottom tab bar with clean icon vectors. The active state is indicated by a primary blue color shift and a subtle dot indicator below the icon.
- **Cards:** Cards are used to group related content. They feature a 1px soft gray border and 16px internal padding. Avoid using shadows on cards unless they are draggable or interactive.
- **Inputs:** Input fields are outlined with a light gray border. When focused, the border transitions to primary blue with a 1px stroke increase.
- **Chips/Filters:** Used for categorization. These use a light tertiary background with medium gray text, shifting to a blue background when selected.
- **Bottom Sheets:** Used for secondary actions and filters to keep interactions within the thumb-zone. They feature a handle indicator at the top and a 16px corner radius.