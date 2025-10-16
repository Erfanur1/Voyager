Voyager is a comprehensive iOS travel planning application that helps users organize terminaltrips, track expenses, view real-time destination information, and manage travel itineraries. The app integrates local data persistence, cloud synchronization, external REST APIs, and location services to provide a complete travel management experience.

Key Features:

Trip Management

- Create and organize multiple trips with cover photos
- Add detailed itineraries for each trip
- Mark trips as favorites or completed
- Search and filter trips by status
- View trip statistics (duration, expenses, status)

Expense Tracking

- Add expenses to trips by category
- Multi-currency support with real-time conversion
- Track expenses across all trips
- View expenses by category
- Calculate total trip costs

Real-Time Weather

- Current weather conditions for destinations
- Temperature, humidity, wind speed, and pressure
- Weather icons and descriptions
- Mini weather widgets on trip cards

Destination Information

- Country information including flag, capital, population
- Currency and language information
- Timezone data
- Integration with RestCountries API

Maps & Location

- Interactive maps showing trip destinations
- Geocoding for address-to-coordinate conversion
- Location pins for all destinations
- User location tracking (with permission)

Cloud Synchronization

- Automatic cloud sync using Firebase Firestore
- Anonymous authentication for secure, user-isolated data
- Real-time synchronization when creating or editing trips
- Manual sync option for bulk updates

Error Handling & Reporting

Comprehensive Error System
Implementation: VoyagerError.swift

Features:

Network Layer:

HTTP status code validation for all API responses
Specific error types for different failure scenarios (404, timeout, no internet)
Network connectivity detection using NSURLError codes
Automatic error type conversion for consistent handling

Data Layer:

Change detection before save operations
Automatic rollback on CoreData failures
Transaction-based operations preventing partial saves
Logging for debugging without exposing errors to users

User Presentation:

User-friendly error messages via LocalizedError protocol
Consistent alert presentation using custom ViewModifier
Recovery suggestions for common issues
Retry options for temporary failures

Example Error Flow:

User action triggers API call
Network failure occurs
Error caught with specific type
User shown clear message: "No internet connection. Check your network settings."
Retry option provided

