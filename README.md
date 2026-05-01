# Memoria del Mundial 🐉⚽

Aplicación iOS inclusiva desarrollada en **SwiftUI** como parte del proyecto **Aula Inclusiva Tecmilenio Las Torres** para el **CAM Macro Centro Independencia** (Ciudad de México).

Es un juego de memoria con temática del Mundial 2026 y la mascota *Quetzal*, diseñado para entrenar memoria de trabajo, atención y motricidad fina en niños con discapacidades múltiples (TEA, síndrome de Down, hipoacusia y baja visión).

## Características de Accesibilidad

- **VoiceOver** y `accessibilityLabel` en todos los elementos interactivos
- **Dynamic Type** con tipografía escalable
- **Alto contraste** WCAG AA (>4.5:1) en cartas y fondo
- **Haptic Feedback** (`UIImpactFeedbackGenerator` y `UINotificationFeedbackGenerator`)
- **Botones grandes** con `.contentShape(Rectangle())` para áreas tocables amplias
- **Refuerzo positivo inmediato** vía mensajes rotativos de la mascota Quetzal

## Arquitectura

Patrón **MVVM** con SwiftUI:

| Capa | Archivos |
|------|----------|
| Modelo | `MemoryGame.swift` (genérico), `MundialGameCard` |
| ViewModel | `MundialMemoryGame` (`ObservableObject`) |
| Vista | `MundialGameView`, `MundialCardView` |
| Componentes UI | `AspectVGrid`, `Cardify`, `Pie`, `FlyingNumber`, `CardView` |

## Cómo ejecutar

1. Abrir `Memorizwift.xcodeproj` en Xcode 15 o superior
2. Seleccionar un simulador (iPhone SE / iPhone 15 Pro / iPad)
3. Presionar **Run** (▶)

Para instalar en un iPad físico: conectar por cable, iniciar sesión con Apple ID en Xcode y presionar Run.

## Pruebas de Accesibilidad

- **Accessibility Inspector**: Xcode > Open Developer Tool > Accessibility Inspector
- **Filtros de daltonismo**: Simulator > Features > Color Filters (Protanopia, Deuteranopia, Tritanopia)
- **Previews multidispositivo**: iPhone SE (3.a gen), iPhone 15 Pro, iPad (10.a gen)

## Autor

Gael Rodriguez Jimenez · Servicio Social · Tecmilenio Las Torres · 2026
