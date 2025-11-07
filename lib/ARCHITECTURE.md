# Clean Architecture Structure

This project follows Clean Architecture principles with clear separation of concerns.

## 📁 **Project Structure**

```
lib/
├── core/                           # Core functionality
│   ├── constants/                  # App-wide constants
│   │   ├── app_colors.dart        # Color constants
│   │   └── app_constants.dart     # General constants
│   ├── errors/                     # Error handling
│   │   └── failures.dart         # Failure classes
│   ├── usecases/                   # Base use case interface
│   │   └── usecase.dart          # UseCase abstract class
│   └── utils/                      # Utility functions
│       └── event_category_utils.dart  # Category helper functions
│
├── data/                           # Data Layer
│   ├── datasources/               # Data sources (API, Local DB)
│   │   └── event_local_datasource.dart  # Local data source
│   ├── models/                    # Data models (extends entities)
│   │   └── event_model.dart      # Event data model
│   └── repositories/              # Repository implementations
│       └── event_repository_impl.dart  # Event repository implementation
│
├── domain/                         # Domain Layer (Business Logic)
│   ├── entities/                  # Business entities
│   │   ├── event.dart            # Event entity
│   │   ├── event_category.dart   # Category enums
│   │   ├── event_host.dart       # Host entity
│   │   └── event_location.dart   # Location entity
│   ├── repositories/              # Repository interfaces
│   │   └── event_repository.dart # Event repository interface
│   └── usecases/                  # Business use cases
│       ├── create_event.dart     # Create event use case
│       ├── get_events.dart       # Get events use case
│       └── get_events_by_category.dart  # Filter events use case
│
├── presentation/                   # Presentation Layer (UI)
│   ├── bloc/                      # State management
│   │   └── events/               # Events BLoC
│   │       ├── events_bloc.dart  # BLoC implementation
│   │       ├── events_event.dart # BLoC events
│   │       └── events_state.dart # BLoC states
│   ├── pages/                     # Screen pages
│   │   ├── create_event/         # Create event screen
│   │   ├── discover/             # Discover screen
│   │   ├── event_detail/         # Event detail screen
│   │   └── onboarding/           # Onboarding screen
│   └── widgets/                   # Reusable widgets
│       ├── common/               # Common widgets
│       ├── event_card/           # Event card widgets
│       └── category_selector/    # Category selector widgets
│
├── injection_container.dart        # Dependency injection setup
└── main.dart                       # App entry point
```

## 🏗️ **Architecture Layers**

### **1. Domain Layer**
- **Entities**: Core business objects (Event, EventHost, EventLocation)
- **Repositories**: Abstract interfaces for data access
- **Use Cases**: Business logic operations (GetEvents, CreateEvent, etc.)

### **2. Data Layer**
- **Models**: Data representations that extend entities
- **Data Sources**: Local/remote data access (LocalDataSource, ApiDataSource)
- **Repositories**: Concrete implementations of domain repositories

### **3. Presentation Layer**
- **BLoC**: State management using flutter_bloc
- **Pages**: Screen implementations
- **Widgets**: Reusable UI components

### **4. Core Layer**
- **Constants**: App-wide constants (colors, strings, etc.)
- **Errors**: Error handling and failure classes
- **Utils**: Utility functions and helpers
- **Use Cases**: Base classes for business logic

## 🔧 **Key Dependencies**

```yaml
# Clean Architecture
get_it: ^7.6.0           # Dependency injection
dartz: ^0.10.1           # Functional programming (Either)
equatable: ^2.0.7        # Value comparison

# State Management
bloc: ^9.0.0             # Business logic component
flutter_bloc: ^9.1.1     # Flutter integration for BLoC
```

## 🚀 **How to Use**

### **Adding a New Feature**

1. **Create Entity** in `domain/entities/`
2. **Create Use Cases** in `domain/usecases/`
3. **Create Repository Interface** in `domain/repositories/`
4. **Create Data Model** in `data/models/`
5. **Implement Repository** in `data/repositories/`
6. **Create BLoC** in `presentation/bloc/`
7. **Register Dependencies** in `injection_container.dart`
8. **Create UI** in `presentation/pages/`

### **Example: Adding a User Feature**

```dart
// 1. Domain Entity
class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});
}

// 2. Use Case
class GetUser implements UseCase<User, GetUserParams> {
  final UserRepository repository;

  GetUser(this.repository);

  @override
  Future<Either<Failure, User>> call(GetUserParams params) {
    return repository.getUser(params.userId);
  }
}

// 3. Repository Interface
abstract class UserRepository {
  Future<Either<Failure, User>> getUser(String id);
}

// 4. BLoC
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUser getUser;

  UserBloc({required this.getUser}) : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
  }
}
```

## 📋 **Benefits**

- **Separation of Concerns**: Each layer has a single responsibility
- **Testability**: Easy to unit test business logic
- **Maintainability**: Changes in one layer don't affect others
- **Scalability**: Easy to add new features
- **Clean Code**: Following SOLID principles

## 🧪 **Testing Strategy**

- **Unit Tests**: Test use cases and entities
- **Widget Tests**: Test UI components
- **Integration Tests**: Test complete user flows

Each layer can be tested independently thanks to dependency injection and interfaces.