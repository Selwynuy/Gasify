# Gasify

A Flutter mobile app for learning Gas Laws through interactive simulations—Boyle's Law, Charles Law, and the Combined Gas Law.

## Getting Started

### Prerequisites

- Flutter SDK >= 3.0.0
- Dart >= 3.0.0

### Run

```bash
flutter pub get
flutter run
```

### Build APK

```bash
flutter build apk
```

## Project Structure

### Directory Structure

```
lib/
├── main.dart                          # Application entry point
├── app/                               # Application-level configuration
│   ├── app.dart                       # Root MaterialApp widget
│   └── routes.dart                    # Route definitions and navigation
├── core/                              # Core functionality shared across features
│   ├── constants/
│   │   └── app_constants.dart         # Application-wide constants
│   ├── services/
│   │   ├── sound_service.dart         # Audio playback (just_audio)
│   │   └── settings_service.dart      # Settings persistence (shared_preferences)
│   ├── theme/
│   │   └── app_theme.dart             # Theme configuration
│   └── utils/
│       └── unit_converter.dart        # Unit conversion utilities
├── features/                          # Gas Law-based modules
│   ├── boyles_law/                    # Boyle's Law activities
│   │   ├── activities/
│   │   │   ├── syringe_test/          # Syringe Test activity
│   │   │   │   └── syringe_test_activity.dart
│   │   │   └── scuba_diving/          # Scuba Diving activity
│   │   │       ├── models/
│   │   │       │   └── diving_state.dart
│   │   │       ├── services/
│   │   │       │   └── diving_physics_service.dart
│   │   │       ├── widgets/
│   │   │       │   ├── action_buttons.dart
│   │   │       │   ├── diver_widget.dart
│   │   │       │   ├── graph_widgets.dart
│   │   │       │   ├── instruction_strip.dart
│   │   │       │   ├── lungs_widget.dart
│   │   │       │   └── underwater_background.dart
│   │   │       └── dialogs/
│   │   │           ├── gas_law_calculator_dialog.dart
│   │   │           └── unit_conversion_dialog.dart
│   │   ├── quiz/
│   │   │   └── drag_drop_quiz_screen.dart
│   │   └── screens/
│   │       └── boyles_law_activities_screen.dart
│   ├── charles_law/                   # Charles Law activities
│   │   ├── activities/
│   │   │   ├── balloon_bottle/
│   │   │   │   └── balloon_bottle_activity.dart
│   │   │   └── rubber_boat/
│   │   │       └── rubber_boat_activity.dart
│   │   ├── quiz/
│   │   │   └── drag_drop_quiz_screen.dart
│   │   └── screens/
│   │       └── charles_law_activities_screen.dart
│   ├── combined_gas_law/              # Combined Gas Law activities
│   │   ├── activities/
│   │   │   ├── cryo_sim/
│   │   │   │   └── cryo_sim_activity.dart
│   │   │   └── true_false/
│   │   │       └── true_false_activity.dart
│   │   └── screens/
│   │       └── combined_gas_law_activities_screen.dart
│   ├── settings/
│   │   └── screens/
│   │       └── settings_screen.dart
│   └── start/
│       └── screens/
│           ├── start_screen.dart
│           └── gas_law_selection_screen.dart
└── shared/                            # Shared across features
    ├── dialogs/
    │   └── quiz_unlock_dialog.dart
    └── services/
        ├── activity_unlock_service.dart
        └── quiz_questions.dart
```

## Gas Laws

### 1. Boyle's Law (P∝1/V)
- **Syringe Test**: Interactive syringe experiment for pressure-volume relationship
- **Scuba Diving**: Diving simulation with lungs, depth, and pressure-volume graph
- **Drag and Drop Quiz**: Interactive quiz for Boyle's Law

### 2. Charles Law (V∝T)
- **Balloon and Bottle**: Temperature-volume demonstration
- **Rubber Boat**: Charles Law experiment
- **Drag and Drop Quiz**: Interactive quiz for Charles Law

### 3. Combined Gas Law (PV/T = k)
- **Cryo-sim**: Cryogenic simulation
- **True or False**: Quiz activity

## Key Improvements

1. **Law-Based Organization**: Code organized by gas law (`boyles_law`, `charles_law`, `combined_gas_law`) for easier maintenance.

2. **Activity Structure**: Each activity has its own directory with:
   - Activity screen file
   - Activity-specific models, services, widgets, dialogs (as needed)

3. **Separation of Concerns**:
   - `activities/`: Individual experiment/activity screens
   - `quiz/`: Quiz screens per law
   - `screens/`: Activity selection screens
   - `models/`: Data models (activity-specific)
   - `services/`: Business logic (activity-specific + core + shared)
   - `widgets/`: UI components (activity-specific)
   - `dialogs/`: Dialog widgets (activity-specific + shared)

4. **Core**: Constants, theme, utils, sound, and settings in `core/`.

5. **Shared**: Quiz questions, unlock service, and shared dialogs in `shared/`.

6. **Routes**: Centralized in `app/routes.dart`. Charles Law and Combined Gas Law activities are navigated from their selection screens (not via top-level routes).

## Dependencies

- `fl_chart` — Volume vs pressure charts
- `just_audio` — Audio playback
- `shared_preferences` — Settings persistence
- `flutter_svg` — SVG graphics

## File Naming

- Activity screens: `{activity_name}_activity.dart` (e.g., `syringe_test_activity.dart`)
- Activity selection: `{law_name}_activities_screen.dart` (e.g., `boyles_law_activities_screen.dart`)
- Models: `{model_name}.dart` (e.g., `diving_state.dart`)
- Services: `{service_name}_service.dart` (e.g., `diving_physics_service.dart`)

## Import Paths

- Activity-specific: relative paths within the activity
- Core: `import '../../../core/...'`
- Shared: `import '../../../shared/...'`
- Cross-law: `import '../../other_law/...'`
