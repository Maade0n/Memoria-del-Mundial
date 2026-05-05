# CONTEXTO.md — Proyecto Memoria del Mundial

> **Para Claude Code en otra máquina:** Este archivo contiene todo el contexto necesario para retomar el proyecto. Léelo primero antes de modificar nada.

---

## 1. Identidad y Contexto

- **Estudiante:** Gael Rodríguez Jiménez
- **Email:** gaelrodriguezjimenez@gmail.com
- **Cuenta GitHub:** [Maade0n](https://github.com/Maade0n)
- **Proyecto:** *Aula Inclusiva Tecmilenio Las Torres*
- **CAM objetivo:** Macro Centro Independencia (Gustavo A. Madero, CDMX)
- **Materia:** Servicio Social — Desarrollo iOS
- **Repositorio:** https://github.com/Maade0n/Memoria-del-Mundial

## 2. Qué es la App

**Memoria del Mundial** es un juego de memoria iOS con temática del Mundial 2026 y mascota Quetzal. Diseñada para entrenar memoria de trabajo, atención y motricidad fina en niños del CAM con TEA, síndrome de Down, hipoacusia y baja visión.

Características clave:
- **3 niveles de dificultad:** Fácil (4 parejas), Medio (6), Difícil (8)
- **Persistencia de récord** por nivel con `UserDefaults`
- **Mascota Quetzal** con mensajes motivacionales rotativos
- **Accesibilidad completa:** VoiceOver, Dynamic Type, Reduce Motion, áreas de toque amplias
- **Retroalimentación multimodal:** visual + háptica + sonora
- **Idioma:** Español (México)

## 3. Stack Técnico

| Capa | Detalle |
|---|---|
| Lenguaje | Swift 5 |
| UI | SwiftUI (no UIKit puro) |
| Patrón | MVVM |
| Persistencia | UserDefaults via `ScorePersistence` |
| Hapticos | UIKit (`UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`) con guardas `#if os(iOS)` |
| Audio | AudioToolbox `AudioServicesPlaySystemSound` |
| Plataforma destino | iOS 17+ / iPadOS 17+ |

## 4. Estructura de Archivos

```
Memorizwift/
├── MemorizwiftApp.swift          # @main, lanza MundialGameView
├── MundialGameView.swift         # PRINCIPAL: vista raíz, ViewModel, modelo de carta, dificultad, persistencia
├── CardView.swift                # Tarjeta para EmojiMemoryGame (Halloween, secundario)
├── Cardify.swift                 # ViewModifier de volteo 3D (Animatable)
├── Pie.swift                     # Forma decorativa (sector circular)
├── FlyingNumber.swift            # Texto que muestra cambio de puntuación
├── AspectVGrid.swift             # Cuadrícula adaptable con GeometryReader
├── EmojiMemoryGame.swift         # ViewModel del juego Halloween
├── EmojiMemoryGameView.swift     # Vista del juego Halloween
├── MemoryGame.swift              # Modelo genérico MemoryGame<CardContent>
├── Assets.xcassets/              # Iconos y colores
├── Preview Content/              # Assets para SwiftUI Previews
├── README.md
└── CONTEXTO.md                   # Este archivo
```

⚠️ **No existe `Memorizwift.xcodeproj`** — debe crearse en Xcode al abrir el proyecto en una Mac.

## 5. MundialGameView.swift — Mapa Interno

Es el archivo más grande (~540 líneas). Contiene:

| Tipo | Líneas aprox. | Descripción |
|---|---|---|
| `enum GameConstants` | 22-40 | Constantes (sounds, layout, timing) |
| `enum GameDifficulty` | 44-72 | Niveles fácil / medio / difícil |
| `struct ScorePersistence` | 76-105 | Persistencia con UserDefaults |
| `struct MundialGameView` | 109-122 | Vista raíz, navega entre menú y juego |
| `struct DifficultySelectionView` | 126-167 | Pantalla de selección de nivel |
| `struct DifficultyButton` (privada) | 170-200 | Botón individual de nivel |
| `struct GameSessionView` | 204-360 | Pantalla de juego (con 6 subvistas privadas) |
| `struct StatBadge` (privada) | 365-385 | Badge de Movimientos/Parejas |
| `var mexicanFlagGradient` | 387-396 | Degradado de fondo |
| `struct MundialCardView` | 400-432 | Vista de una tarjeta individual |
| `struct MundialGameCard` | 436-441 | Modelo de carta |
| `class MundialMemoryGame` | 445-540 | ViewModel `ObservableObject` |

## 6. Tareas del Servicio Social — Estado

| Tarea | Estado | Documento generado |
|---|---|---|
| **Tarea 1** — Investigación inclusiva | ✅ Entregada | `Tarea1_MemoriaDelMundial.docx` |
| **Tarea 2** — Propuesta conceptual | ✅ Entregada | `Tarea2_PropuestaAppInclusiva.docx` |
| **Tarea 3** — Prototipo funcional | ✅ Entregada | `Tarea3_PrototipoFuncional.docx` |
| **Tarea 4** — Implementación en CAM | ✅ Lista (con placeholders `[EDITAR]` para datos reales) | `Tarea4_ImplementacionCAM.docx` |
| **Tarea 5** — Optimización y escalabilidad | ✅ Lista | `Tarea5_OptimizacionEscalabilidad.docx` |

⚠️ Los `.docx` **no están en el repo de GitHub** (excluidos por `.gitignore`). Quedan localmente en el equipo Windows. Solo el código está en GitHub.

## 7. Cambios Hechos en la Tarea 5 (último commit relevante)

Commit `39a0ae3` — "Tarea 5: refactorizacion completa, accesibilidad y 2 funcionalidades nuevas"

- Eliminado `typealias Card = CardView.Card` circular en `CardView.swift`
- Constantes extraídas a `enum GameConstants`
- Guardas `#if os(iOS)` para hapticos UIKit (compatibilidad macOS Catalyst)
- VoiceOver completo: `accessibilityLabel`, `accessibilityHint`, `accessibilityAddTraits`, `.accessibilityHidden(true)` en decorativos
- Soporte de Reduce Motion con `@Environment(\.accessibilityReduceMotion)`
- **Nueva funcionalidad 1:** `enum GameDifficulty` + `DifficultySelectionView`
- **Nueva funcionalidad 2:** `struct ScorePersistence` + indicador "¡Nuevo récord!"
- Vista de 215 líneas modularizada en 6 subvistas privadas
- Race condition corregida en `handleCardTap`

## 8. Lo Que Falta Por Hacer

### Inmediato (próxima sesión en Mac)
1. **Crear el proyecto `.xcodeproj` en Xcode** y arrastrar los `.swift` adentro
2. **Compilar y verificar** que todo corre sin errores
3. **Probar en simulador** (iPhone 15 Pro / iPad)
4. **Activar VoiceOver y Reduce Motion** para validar accesibilidad
5. **Tomar capturas reales** del simulador para reemplazar los mockups HTML

### Antes de entregar la Tarea 4
- Llenar los `[EDITAR]` con datos reales de la visita al CAM
- Insertar fotos reales (con consentimiento) en los placeholders amarillos
- Convertir el `.docx` a PDF

### Antes de entregar la Tarea 5
- (Opcional) Grabar video demostrativo del simulador
- Convertir el `.docx` a PDF

## 9. Mejoras Propuestas a Futuro (documentadas en Tarea 5)

- Síntesis de voz para Quetzal con `AVSpeechSynthesizer`
- Mazos temáticos adicionales: animales, frutas, colores, emociones
- Modo facilitador con código de acceso (gesto largo) + estadísticas detalladas
- iCloud sync con CloudKit
- Pruebas unitarias (XCTest) para `MemoryGame` y `ScorePersistence`
- Localización (i18n) — náhuatl, maya

## 10. Cómo Retomar en una Mac Nueva

```bash
# 1. Clonar el repo
cd ~/Desktop
mkdir -p Gael-ServicioSocial
cd Gael-ServicioSocial
git clone https://github.com/Maade0n/Memoria-del-Mundial.git
cd Memoria-del-Mundial

# 2. Verificar que llegaron todos los archivos Swift
ls *.swift

# 3. Abrir Xcode y crear un proyecto nuevo SwiftUI llamado "Memorizwift"
#    (Xcode no acepta abrir Swift sueltos sin .xcodeproj)
# 4. Borrar los archivos por defecto de Xcode y arrastrar nuestros .swift
# 5. Compilar (Cmd+R) y verificar
```

## 11. Decisiones de Diseño Importantes (no romper)

- **No usar UIKit fuera de hapticos.** Toda la UI es SwiftUI puro.
- **Mantener español-MX** en todos los strings de UI. Los comentarios pueden estar en español sin acentos por compatibilidad cross-platform.
- **MVVM estricto.** La vista nunca muta el modelo directamente; siempre vía métodos del ViewModel.
- **Accessibility first.** Cualquier elemento nuevo debe tener `accessibilityLabel` o `.accessibilityHidden(true)` desde el inicio.
- **Constantes en `GameConstants`.** No hardcodear nuevos números mágicos.

## 12. Notas para Claude Code

- El usuario prefiere **respuestas concisas** (no sobreexplicar).
- Los documentos siempre se generan en **español de México**.
- Cuando hagas cambios al código, **commitea y pushea** a GitHub al final con email `gaelrodriguezjimenez@gmail.com` y nombre `Gael Rodriguez`.
- **Ubicación de la conversación previa:** Esta sesión empezó en Windows (`C:\Users\maqui\OneDrive\Escritorio\Memorizwift`) y se traslada a la Mac.
