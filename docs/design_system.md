# Design System - Rwanda Pet Lovers Mobile App

This document outlines the design language, components, and patterns used in the Rwanda Pet Lovers application, based on the analyzed 35 UI mockups.

## 🎨 Color Palette

| Name | Hex Code | Usage |
|------|----------|-------|
| **Main/Primary** | `#1E293B` | Dark Slate. Used for headers, active tab backgrounds, and "Get Started" button. |
| **Secondary** | `#3B82F6` | Bright Blue. Used for accents, buttons, and base for linear gradients. |
| **Surface/White** | `#FFFFFF` | Core background and whitespace. |
| **Success** | `#3DB25E` | Positive actions, availability dots, confirmed states. |
| **Failure/Danger** | `#F63B3B` | Error messages, cancel/delete buttons. |
| **Neutral Button** | `#475569` | Secondary buttons and inactive tab icons. |

## ✨ Navigation Logic (Task List/Pill Bar)
- **Inactive State**: Only the icon is displayed. Icon color: `#475569`.
- **Active State**: Pill-style background (`#1E293B`), white icon, and white text label.
- **Shared Tab**: Every portal's bottom navigation must include a "Profile" tab.

### 2. Cards & Lists
- **Service Cards**: Horizontal cards with "Available" status dots.
- **Product/Pet Grids**: Large rounded cards with info overlays.

### 3. Forms
- **Modern Inputs**: Rounded grey containers with icons.
- **Persona Picker**: Large selection cards with animal artwork.

## 📈 Analytics & Charts
- Uses bar charts for sales reports and sparklines for top-selling items.
