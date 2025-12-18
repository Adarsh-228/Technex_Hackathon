# Local Sure - Service Provider Platform

A Flutter-based digital platform that connects users with verified local service providers. The app features service discovery, booking, real-time status tracking, and service management dashboards.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [File Structure](#file-structure)
- [APIs and Integrations](#apis-and-integrations)
- [Location Services](#location-services)
- [Local Database](#local-database)
- [Map and Routing](#map-and-routing)
- [Navigation Flow](#navigation-flow)
- [Dependencies](#dependencies)
- [Setup Instructions](#setup-instructions)

---

## 🎯 Project Overview

**Local Sure** is a mobile application built with Flutter that enables:
- **Customers** to discover, search, and book local services
- **Service Providers** to manage their profiles and view orders
- Real-time order tracking with map visualization
- AI-powered chatbot for service queries
- Persistent local data storage

### Key Features
- ✅ Dual-tone minimalistic UI design
- ✅ Location-based service discovery
- ✅ Service booking with cost estimation
- ✅ Order tracking with interactive maps
- ✅ FastAPI-powered chatbot
- ✅ Offline-first with SQLite database
- ✅ Service provider admin panel

---

## 🏗️ Architecture

The app follows a clean architecture pattern with separation of concerns:

```
lib/
├── main.dart                    # App entry point, theme, location initialization
├── data/                        # Data layer
│   ├── local_db.dart           # SQLite database operations
│   └── service_repository.dart  # CSV data loading and parsing
├── services/                    # Business logic services
│   └── location_store.dart     # Location caching singleton
└── screens/                     # UI layer
    ├── customer_details_screen.dart
    ├── customer_profile_screen.dart
    ├── customer_survey_screen.dart
    ├── home_screen.dart
    ├── chatbot_screen.dart
    ├── order_tracking_screen.dart
    └── service_provider_profile_screen.dart
```

---

## 📁 File Structure

### Core Files

#### `lib/main.dart`
- **Purpose**: Application entry point and root configuration
- **Key Responsibilities**:
  - Theme configuration (dual-tone: `#171614`, `#9A8873`)
  - Google Fonts integration (Plus Jakarta Sans)
  - Location initialization on app startup
  - Role selection screen routing
- **Location Flow**:
  - Requests location permission on app launch
  - Fetches current GPS position using `geolocator`
  - Performs reverse geocoding using `geocoding` package
  - Stores location in `LocationStore` singleton
- **Database Warm-up**: Initializes database connection in background

#### `lib/data/local_db.dart`
- **Purpose**: SQLite database management
- **Database Name**: `local_sure.db`
- **Version**: 2
- **Tables**:
  1. **`service_provider_profile`**
     - `id` (PRIMARY KEY)
     - `full_name`, `mobile`, `service_category`, `years_experience`
     - `photo`, `location`
  2. **`customer_profile`**
     - `id` (PRIMARY KEY)
     - `name`, `email`, `phone`, `location`
  3. **`orders`**
     - `id` (PRIMARY KEY)
     - `title`, `description`, `status`, `created_at`
- **Key Methods**:
  - `getCustomerProfile()`: Retrieves customer data
  - `upsertCustomerProfile()`: Creates or updates customer profile
  - `getServiceProviderProfile()`: Retrieves service provider data
  - `createOrder()`: Creates new order entry
  - `getCurrentOrders()`: Retrieves all orders sorted by date
  - `deleteOrder()`: Deletes order by ID
  - `clearCustomerProfile()`: Clears customer data (logout)

#### `lib/data/service_repository.dart`
- **Purpose**: Loads and parses service provider data from CSV
- **Data Source**: `assets/data/nagpur_service_providers.csv`
- **Caching**: In-memory cache after first load
- **ServiceProvider Model**:
  ```dart
  - providerName
  - serviceName
  - serviceCategory
  - primarySkill
  - locationArea
  - serviceRadiusKm
  - experienceYears
  - availabilityStatus
  - emergencySupport
  ```
- **Parsing**: Uses `LineSplitter` to parse CSV rows

#### `lib/services/location_store.dart`
- **Purpose**: Singleton pattern for in-memory location storage
- **Storage**:
  - `Position? _position`: GPS coordinates
  - `String? _placeName`: Human-readable location name
- **Methods**:
  - `setPosition()`: Stores location and place name
  - `formattedLocation`: Returns place name or coordinates as string
- **Usage**: Accessed throughout app to avoid re-fetching location

### Screen Files

#### `lib/screens/customer_details_screen.dart`
- **Purpose**: Customer login/profile creation
- **Features**:
  - Form validation (name, email, phone, location)
  - Auto-fills location from `LocationStore`
  - Manual location fetch button (📍)
  - Saves to `LocalDb.customer_profile` table
- **Navigation**: 
  - On save → `CustomerSurveyScreen` (pushReplacement)
  - Back button → `RoleSelectionScreen` (pushAndRemoveUntil)

#### `lib/screens/customer_survey_screen.dart`
- **Purpose**: Service category selection
- **Categories**: Home, Services, Healthcare, Personal Care, Events & Occasions
- **Requirement**: Minimum 3 selections
- **Navigation**: On confirm → `HomeScreen` (pushAndRemoveUntil)

#### `lib/screens/home_screen.dart`
- **Purpose**: Main customer dashboard
- **Features**:
  - Service listing from CSV (7-8 per page, pagination)
  - Search functionality (filters by name, category, location, skill)
  - Expandable service tiles
  - Booking dialog with cost estimation
  - Bottom navigation: Services | Your Orders | Chatbot
- **Order Management**:
  - Displays orders from `LocalDb.orders` table
  - Delete order functionality
  - Track order button → `OrderTrackingScreen`
- **Booking Flow**:
  - Click service → Expand details
  - Click "Book Service" → Dialog
  - Enter requirements → View Cost (random ₹100-₹900)
  - Confirm → Saves to database

#### `lib/screens/customer_profile_screen.dart`
- **Purpose**: Customer profile view
- **Features**:
  - Displays saved customer data
  - Shows location as place name (not coordinates)
  - Logout button (clears profile, redirects to login)
- **Navigation**: Back button → `HomeScreen`

#### `lib/screens/chatbot_screen.dart`
- **Purpose**: AI-powered service query interface
- **API Integration**: FastAPI backend
- **Endpoints**:
  - `POST /query`: Query services
  - `POST /book`: Book service
- **Features**:
  - Chat interface with message bubbles
  - Service detection from API responses
  - "Book Service" button when services are mentioned
  - Booking dialog with cost estimation
  - Order confirmation messages
- **API URL**: `https://rolland-unbribed-valentino.ngrok-free.dev`
- **Response Parsing**: Handles various JSON formats, extracts service names

#### `lib/screens/order_tracking_screen.dart`
- **Purpose**: Real-time order tracking with map
- **Features**:
  - Interactive map showing customer and provider locations
  - Route polyline connecting both points
  - Service provider details card
  - Payment button (placeholder)
- **Map Implementation**: Uses `flutter_map` with OpenStreetMap tiles
- **Location Sources**:
  - Customer: From `LocationStore.instance.position`
  - Provider: Geocoded from CSV `locationArea` field
- **Route Generation**: Creates 5 intermediate waypoints with slight curves

#### `lib/screens/service_provider_profile_screen.dart`
- **Purpose**: Service provider profile management
- **Features**:
  - Profile form (name, mobile, category, experience, photo, location)
  - Admin Panel tab (currently shows orders)
  - Saves to `LocalDb.service_provider_profile` table
- **Navigation**: Back button → `RoleSelectionScreen`

---

## 🔌 APIs and Integrations

### FastAPI Backend

**Base URL**: `https://rolland-unbribed-valentino.ngrok-free.dev`

#### 1. Query Services Endpoint
- **Method**: `POST`
- **Path**: `/query`
- **Request Body**:
  ```json
  {
    "query": "I need a plumber"
  }
  ```
- **Response Format**: JSON with service information
- **Usage**: `lib/screens/chatbot_screen.dart` → `_sendMessage()`
- **Response Parsing**: 
  - Extracts service names from JSON
  - Handles nested objects and arrays
  - Formats numbers and text properly
- **Output**: Displays in chat bubble, shows "Book Service" button if service detected

#### 2. Book Service Endpoint
- **Method**: `POST`
- **Path**: `/book`
- **Request Body**:
  ```json
  {
    "service_name": "Plumbing Service",
    "requirements": "Fix leaking pipe in kitchen"
  }
  ```
- **Response**: Success message or error details
- **Usage**: `lib/screens/chatbot_screen.dart` → `_bookService()`
- **Side Effects**: 
  - Saves order to `LocalDb.orders` table
  - Shows confirmation message in chat
  - Updates "Your Orders" screen

### API Configuration

**File**: `lib/screens/chatbot_screen.dart`

```dart
static String get _apiBaseUrl {
  // Currently uses ngrok URL for all platforms
  return 'https://rolland-unbribed-valentino.ngrok-free.dev';
}
```

**Platform Detection** (for future use):
- Android Emulator: `10.0.2.2:8000` (maps to host localhost)
- iOS Simulator/Desktop: `127.0.0.1:8000`
- Physical Device: Computer's local IP (e.g., `192.168.x.x:8000`)

---

## 📍 Location Services

### Location Flow

#### 1. App Startup (`lib/main.dart` → `LocationInitializer`)
```
App Launch
  ↓
Request Location Permission (geolocator)
  ↓
Get Current Position (GPS coordinates)
  ↓
Reverse Geocoding (geocoding package)
  ↓
Extract Place Name (locality, subAdministrativeArea, administrativeArea)
  ↓
Store in LocationStore.instance
```

#### 2. Location Packages

**`geolocator: ^13.0.1`**
- **Purpose**: GPS location fetching and permission handling
- **Usage**:
  - `Geolocator.checkPermission()`: Check permission status
  - `Geolocator.requestPermission()`: Request permission
  - `Geolocator.getCurrentPosition()`: Get GPS coordinates
  - `Geolocator.distanceBetween()`: Calculate distance between points
- **Files Using**:
  - `lib/main.dart`: Initial location fetch
  - `lib/screens/customer_details_screen.dart`: Manual location fetch
  - `lib/screens/order_tracking_screen.dart`: Distance calculation

**`geocoding: ^3.0.0`**
- **Purpose**: Reverse geocoding (coordinates → place names)
- **Usage**:
  - `placemarkFromCoordinates()`: Convert lat/lng to placemark
  - Extracts: `locality`, `subAdministrativeArea`, `administrativeArea`
- **Files Using**:
  - `lib/main.dart`: Initial reverse geocoding
  - `lib/screens/customer_details_screen.dart`: Manual location fetch
  - `lib/screens/order_tracking_screen.dart`: Provider location geocoding

#### 3. LocationStore Singleton

**File**: `lib/services/location_store.dart`

**Purpose**: In-memory cache to avoid repeated location fetches

**Storage**:
```dart
Position? _position        // GPS coordinates
String? _placeName         // Human-readable name
```

**Access Pattern**:
- Set once at app startup
- Accessed throughout app via `LocationStore.instance.formattedLocation`
- Used in: Customer login screen, order tracking, profile screen

**Benefits**:
- Fast access (no async calls)
- Consistent location across app
- Reduces battery drain from repeated GPS calls

---

## 💾 Local Database

### Database Schema

**File**: `lib/data/local_db.dart`
**Database**: SQLite (`local_sure.db`)
**Version**: 2

#### Table 1: `service_provider_profile`
```sql
CREATE TABLE service_provider_profile (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  full_name TEXT NOT NULL,
  mobile TEXT NOT NULL,
  service_category TEXT NOT NULL,
  years_experience INTEGER NOT NULL,
  photo TEXT,
  location TEXT
)
```

**Operations**:
- `getServiceProviderProfile()`: SELECT with `ORDER BY id DESC LIMIT 1`
- `upsertServiceProviderProfile()`: INSERT or UPDATE based on existence

#### Table 2: `customer_profile`
```sql
CREATE TABLE customer_profile (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  location TEXT
)
```

**Operations**:
- `getCustomerProfile()`: SELECT with `ORDER BY id DESC LIMIT 1`
- `upsertCustomerProfile()`: INSERT or UPDATE based on existence
- `clearCustomerProfile()`: DELETE all records (logout)

#### Table 3: `orders`
```sql
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL
)
```

**Operations**:
- `createOrder()`: INSERT with current timestamp (ISO8601)
- `getCurrentOrders()`: SELECT with `ORDER BY created_at DESC`
- `deleteOrder(id)`: DELETE WHERE `id = ?`

### Database Operations Flow

**Initialization**:
- Database created on first access
- Tables created via `onCreate` callback
- Connection cached in `_db` field (singleton pattern)

**Usage Pattern**:
```dart
final db = LocalDb.instance;
await db.database;  // Lazy initialization
await db.getCustomerProfile();
```

**Performance**:
- Database warmed up at app startup (`lib/main.dart`)
- Lazy initialization (only when needed)
- Connection pooling (single instance)

---

## 🗺️ Map and Routing

### Map Implementation

**File**: `lib/screens/order_tracking_screen.dart`
**Package**: `flutter_map: ^7.0.2` with `latlong2: ^0.9.1`

#### Map Components

1. **Tile Layer**
   - **Source**: OpenStreetMap
   - **URL Template**: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
   - **User Agent**: `com.example.technex`

2. **Markers**
   - **Customer Marker**: Blue circle with person icon
   - **Provider Marker**: Accent color circle with location icon
   - **Size**: 50x50 pixels
   - **Border**: White, 3px width

3. **Route Polyline**
   - **Color**: Theme primary color
   - **Width**: 4.0 pixels
   - **Points**: Generated route with 5 intermediate waypoints

#### Route Generation Algorithm

**File**: `lib/screens/order_tracking_screen.dart` → `_generateRoutePoints()`

```dart
1. Start with customer location
2. Generate 5 intermediate points:
   - Calculate ratio (i / numPoints)
   - Interpolate latitude and longitude
   - Add random offset (±0.01 degrees) for realism
3. End with provider location
```

**Route Calculation**:
- Uses linear interpolation between start and end
- Adds slight curves via random offsets
- Creates realistic-looking path (not straight line)

#### Location Sources for Map

**Customer Location**:
- Source: `LocationStore.instance.position`
- Fallback: Nagpur center coordinates `(21.1458, 79.0882)`
- Used directly as `LatLng` for marker

**Provider Location**:
- Source: CSV `locationArea` field (e.g., "Dharampeth", "Sadar")
- Process:
  1. Lookup in `_nagpurAreaCoordinates` map (predefined coordinates)
  2. If not found, use geocoding: `locationFromAddress('${area}, Nagpur, India')`
  3. Fallback: Generate nearby location with random offset
- Used as `LatLng` for marker

#### Map View Configuration

**Center Point**: Midpoint between customer and provider
```dart
centerLat = (customerLat + providerLat) / 2
centerLng = (customerLng + providerLng) / 2
```

**Zoom Level**: Calculated based on distance
```dart
distance = Geolocator.distanceBetween(...)
zoom = distance > 10000 ? 12.0 
     : distance > 5000 ? 13.0 
     : 14.0
```

**Bounds**: 
- Min Zoom: 10
- Max Zoom: 18

---

## 🧭 Navigation Flow

### Complete User Journey

#### Customer Flow (New User)
```
1. App Launch
   └─> LocationInitializer
       ├─> Request Permission
       ├─> Fetch GPS Location
       ├─> Reverse Geocode
       └─> Store in LocationStore

2. RoleSelectionScreen
   └─> Click "Customer"
       └─> Check LocalDb for existing profile
           └─> No profile found
               └─> CustomerDetailsScreen (push)

3. CustomerDetailsScreen
   ├─> Pre-fill location from LocationStore
   ├─> User fills form
   └─> Click "Save Details"
       └─> Save to LocalDb.customer_profile
       └─> CustomerSurveyScreen (pushReplacement)

4. CustomerSurveyScreen
   ├─> Select 3+ service categories
   └─> Click "Confirm"
       └─> HomeScreen (pushAndRemoveUntil)

5. HomeScreen
   ├─> Load services from CSV
   ├─> Search/filter services
   ├─> Click service → Expand details
   ├─> Click "Book Service" → Dialog
   │   ├─> Enter requirements
   │   ├─> View Cost (random ₹100-₹900)
   │   └─> Confirm → Save to LocalDb.orders
   ├─> "Your Orders" tab → View orders
   │   ├─> "Track Order" → OrderTrackingScreen
   │   └─> Delete order
   └─> "Chatbot" tab → Query services via FastAPI
```

#### Customer Flow (Returning User)
```
1. App Launch → LocationInitializer (same as above)

2. RoleSelectionScreen
   └─> Click "Customer"
       └─> Check LocalDb for existing profile
           └─> Profile found
               └─> HomeScreen (pushAndRemoveUntil, clears stack)
```

#### Service Provider Flow
```
1. RoleSelectionScreen
   └─> Click "Service Provider"
       └─> ServiceProviderProfileScreen (push)

2. ServiceProviderProfileScreen
   ├─> "Profile" tab → Fill form → Save to LocalDb
   └─> "Admin Panel" tab → View orders (future feature)
```

### Navigation Methods

**`push`**: Adds screen to stack, allows back navigation
- Customer → CustomerDetailsScreen
- HomeScreen → CustomerProfileScreen
- HomeScreen → OrderTrackingScreen

**`pushReplacement`**: Replaces current screen, no back
- CustomerDetailsScreen → CustomerSurveyScreen

**`pushAndRemoveUntil`**: Clears stack, sets new root
- CustomerSurveyScreen → HomeScreen
- CustomerProfileScreen (logout) → CustomerDetailsScreen
- CustomerDetailsScreen (back) → RoleSelectionScreen
- RoleSelectionScreen (returning customer) → HomeScreen

---

## 📦 Dependencies

### Core Dependencies

```yaml
# Location Services
geolocator: ^13.0.1          # GPS location and permissions
geocoding: ^3.0.0            # Reverse geocoding (coordinates → names)

# Database
sqflite: ^2.3.3              # SQLite database
path: ^1.9.0                 # Path utilities

# UI/Design
google_fonts: ^6.2.1         # Plus Jakarta Sans font

# Networking
http: ^1.2.2                 # HTTP client for FastAPI

# Maps
flutter_map: ^7.0.2         # Map widget
latlong2: ^0.9.1             # Lat/Lng coordinates
```

### Package Usage

| Package | Used In | Purpose |
|---------|---------|---------|
| `geolocator` | `main.dart`, `customer_details_screen.dart`, `order_tracking_screen.dart` | Location fetching, permissions, distance calculation |
| `geocoding` | `main.dart`, `customer_details_screen.dart`, `order_tracking_screen.dart` | Reverse geocoding |
| `sqflite` | `local_db.dart` | Database operations |
| `google_fonts` | `main.dart` | Typography |
| `http` | `chatbot_screen.dart` | FastAPI requests |
| `flutter_map` | `order_tracking_screen.dart` | Map display |
| `latlong2` | `order_tracking_screen.dart` | Coordinate handling |

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK (3.9.2+)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- FastAPI backend running (for chatbot)

### Installation Steps

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd technex
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Add Assets**
   - Ensure `assets/data/nagpur_service_providers.csv` exists
   - CSV format: `provider_name,service_name,service_category,primary_skill,location_area,service_radius_km,experience_years,availability_status,emergency_support`

4. **Configure Permissions**

   **Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.INTERNET" />
   <application android:usesCleartextTraffic="true">
   ```

   **iOS** (`ios/Runner/Info.plist`):
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We use your location to show you nearby service providers.</string>
   ```

5. **Configure API URL** (if needed)
   - Edit `lib/screens/chatbot_screen.dart`
   - Update `_apiBaseUrl` getter with your FastAPI endpoint

6. **Run App**
   ```bash
   flutter run
   ```

### Database Initialization

The database is automatically created on first app launch:
- Location: Platform-specific app data directory
- File: `local_sure.db`
- Tables created via `onCreate` callback

### CSV Data Format

**File**: `assets/data/nagpur_service_providers.csv`

**Header**:
```
provider_name,service_name,service_category,primary_skill,location_area,service_radius_km,experience_years,availability_status,emergency_support
```

**Example Row**:
```
Rajesh Kumar,Plumbing Service,Home Services,Pipe Repair,Dharampeth,5,8,Available,Yes
```

---

## 🎨 Theme and Design

### Color Palette
- **Dark Tone**: `#171614` (background, primary text)
- **Accent Tone**: `#9A8873` (buttons, highlights)
- **Surface**: `#1F1E1B` (cards, inputs)
- **On Surface**: `#F5F3EE` (text on dark)

### Typography
- **Font Family**: Plus Jakarta Sans (via `google_fonts`)
- **Headline**: 24px, weight 600
- **Body**: 14px, weight 400

### Design Principles
- Minimalistic dual-tone design
- Slight borders on cards (0.05 opacity)
- Rounded corners (12px radius)
- Consistent spacing (8px, 16px, 24px)

---

## 🔍 Key Implementation Details

### Location Fetching Strategy
1. **App Startup**: Fetch once, store in `LocationStore`
2. **Customer Login**: Use cached location (instant)
3. **Manual Fetch**: Button available if needed
4. **Order Tracking**: Use cached customer location

### Database Performance
- **Warm-up**: Database initialized at app startup
- **Lazy Loading**: Profile data loads in background
- **Caching**: Service data cached after first CSV load

### Map Route Generation
- **Algorithm**: Linear interpolation with random offsets
- **Waypoints**: 5 intermediate points for realism
- **Fallback**: Predefined coordinates for Nagpur areas

### API Error Handling
- **Timeout**: 15 seconds
- **Error Messages**: User-friendly snackbars
- **Fallback**: Graceful degradation if API unavailable

---

## 📝 Notes

- **Location Permission**: Required for app functionality
- **Offline Support**: Database and CSV data work offline
- **API Dependency**: Chatbot requires FastAPI backend
- **Map Tiles**: Uses OpenStreetMap (requires internet)
- **Platform Support**: Android, iOS (configured), Web (partial)

---

## 🤝 Contributing

This is a private project. For questions or issues, contact the development team.

---

## 📄 License

[Specify your license here]

---

**Last Updated**: [Current Date]
**Version**: 1.0.0
