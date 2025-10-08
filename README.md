# PATCH'D - Project Division


### File 1: **Models.swift**
**Purpose:** All data models and structures for the application

**Contains:**
- `User` model
- `CollageSession` model  
- `CollagePhoto` model
- `Theme` model
- `Invite` model
- `Collage` model (with Codable/Decodable)
- Helper extensions and enums

---

### File 2: **DatabaseManager.swift**
**Purpose:** All Supabase database operations and API calls

**Contains:**
- `SupabaseManager` class (client setup, auth)
- `CollageDBManager` class (CRUD operations)
- Authentication methods
- Collage CRUD operations
- Photo metadata storage
- Real-time subscriptions setup
- Invite code generation/validation

---

### File 3: **PhotoManager.swift**
**Purpose:** Camera, image processing, and photo placement logic

**Contains:**
- `CameraManager` class
- `PhotoProcessor` class (cropping, compression)
- `CollageLayoutManager` class (position calculation, collision detection)
- Camera capture view controller wrapper
- Image upload to Supabase Storage
- Random crop logic
- Photo positioning algorithms

---

### File 4: **AppState.swift + Views**
**Purpose:** Application state management and all SwiftUI views

**Contains:**
- `AppState` class (ObservableObject)
- `ContentView` (root navigation)
- `AuthenticationView`
- `DashboardView`
- `CollageView`
- `JoinCollageView`
- `CameraView`
- `ProfileView` (optional)
- `SettingsView` (optional)

---

## ✅ 2-Week Sprint Task Breakdown

### 🗓️ Week 1: Foundation & Core Features

#### **Teammate 1 - Models (Days 1-7)**

**Part 1: Core Models**
- [ ] Create `User` model with all properties (id, email, username, createdAt, profileImageUrl)
- [ ] Create `CollageSession` model with relationships (id, theme, startTime, endTime, createdBy, participants array, photos array, inviteCode)
- [ ] Create `CollagePhoto` model (id, userId, username, imageUrl, position, size, rotation, aspectRatio, uploadedAt)
- [ ] Add Codable conformance to all models for Supabase JSON parsing

**Part 2: Supporting Models**
- [ ] Create `Theme` model (id, text, category, isActive)
- [ ] Create `Invite` model (code, collageId, createdBy, expiresAt, maxUses, currentUses)
- [ ] Create `Collage` model as main database representation
- [ ] Add computed properties for time remaining, isExpired, participantCount

**Part 3: Enums & Extensions**
- [ ] Create `CollageStatus` enum (active, expired, cancelled)
- [ ] Create `PhotoUploadStatus` enum (uploading, processing, completed, failed)
- [ ] Add Date extensions for ISO8601 formatting
- [ ] Add UUID extensions for validation
- [ ] Create model validation methods
- [ ] Write unit tests for models

---

#### **Database Manager (Week 1)**

**Part 1: Supabase Setup**
- [ ] Set up Supabase project and get credentials
- [ ] Configure `SupabaseManager` singleton with URL and anon key
- [ ] Implement `signUp(email:password:)` method
- [ ] Implement `signIn(email:password:)` method
- [ ] Implement `signOut()` method
- [ ] Implement `getCurrentUser()` method
- [ ] Add session persistence handling

**Part 2: Collage Operations**
- [ ] Implement `fetchRandomTheme()` with proper error handling
- [ ] Implement `createCollage(theme:duration:)` with user as creator
- [ ] Implement `joinCollage(collageId:)` with validation
- [ ] Implement `fetchCollage(collageId:)` with relationships
- [ ] Implement `fetchActiveSessions(for:)` filtering by user
- [ ] Add `leaveCollage(collageId:)` method

**Part 3: Photo & Storage Operations**
- [ ] Implement `uploadPhotoToStorage(image:collageId:)` to Supabase Storage
- [ ] Implement `insertPhotoMetadata(photo:)` to photos table
- [ ] Implement `fetchPhotosForCollage(collageId:)` query
- [ ] Implement `deletePhoto(photoId:)` with storage cleanup
- [ ] Add photo URL generation with signed URLs

**Part 4: Invite System & Polish**
- [ ] Implement `generateInviteCode(collageId:)` with unique codes
- [ ] Implement `validateInviteCode(code:)` with expiry checking
- [ ] Implement `getCollageIdFromInvite(code:)` lookup
- [ ] Add real-time subscription setup for collage updates
- [ ] Add error handling and retry logic
- [ ] Write integration tests

---

#### **Photo Manager (Week 1)**

** Camera Integration**
- [ ] Create `CameraManager` class with AVFoundation setup
- [ ] Implement camera permission request handling
- [ ] Create camera preview layer
- [ ] Implement photo capture functionality
- [ ] Add front/back camera switching
- [ ] Add flash control
- [ ] Handle camera session lifecycle

**Image Processing**
- [ ] Create `PhotoProcessor` class
- [ ] Implement random crop logic (choose random portrait/landscape section)
- [ ] Implement manual crop with draggable frame
- [ ] Add image compression for upload optimization
- [ ] Implement aspect ratio calculations
- [ ] Add image orientation correction
- [ ] Create crop preview UI

**Collage Layout System**
- [ ] Create `CollageLayoutManager` class
- [ ] Implement random position generation within bounds
- [ ] Add collision detection to prevent photo overlap
- [ ] Implement drag-and-drop photo repositioning
- [ ] Add pinch-to-zoom for photo resizing
- [ ] Implement rotation gestures
- [ ] Add snap-to-grid optional feature

**Photo Upload Pipeline**
- [ ] Integrate camera → crop → compress workflow
- [ ] Connect to DatabaseManager for storage upload
- [ ] Add upload progress tracking
- [ ] Implement upload retry on failure
- [ ] Add local caching for offline support
- [ ] Optimize image loading with thumbnails
- [ ] Test full pipeline end-to-end

---

#### **AppState & Views (Week 1)**

**App State Management**
- [ ] Create comprehensive `AppState` ObservableObject
- [ ] Add @Published properties (currentUser, activeSessions, selectedSession, etc.)
- [ ] Implement authentication state management
- [ ] Add session loading and refreshing logic
- [ ] Implement navigation state management
- [ ] Add error state handling with user-friendly messages
- [ ] Set up Combine publishers for state updates

**Authentication & Onboarding**
- [ ] Design and implement `AuthenticationView` UI
- [ ] Add email/password validation
- [ ] Create sign-up flow with username selection
- [ ] Add loading states and error messages
- [ ] Implement "Remember Me" functionality
- [ ] Create onboarding tutorial (optional)
- [ ] Add password reset flow

**Dashboard & Navigation**
- [ ] Design and implement `DashboardView` with collage list
- [ ] Add "Create Collage" button with loading state
- [ ] Add "Join Collage" button with code input
- [ ] Implement pull-to-refresh for session list
- [ ] Show countdown timers for each active collage
- [ ] Add empty state when no collages exist
- [ ] Implement navigation to CollageView

**Core Views**
- [ ] Create `JoinCollageView` with code input validation
- [ ] Build basic `CollageView` canvas structure
- [ ] Add camera button integration
- [ ] Implement photo display with blur logic
- [ ] Add share button for invite codes
- [ ] Create navigation bar with theme title
- [ ] Add logout functionality

---

### 🗓️ Week 2: Polish, Integration & Testing

#### **Models (Week 2)**

**Advanced Features**
- [ ] Add pagination support to models
- [ ] Create `CollageStats` model (photoCount, participantCount, etc.)
- [ ] Add `Notification` model for push notifications
- [ ] Create `UserPreferences` model for settings
- [ ] Implement model caching strategies
- [ ] Add model versioning for migrations

**Data Validation & Edge Cases**
- [ ] Add comprehensive input validation
- [ ] Handle nil/optional values gracefully
- [ ] Create mock data generators for testing
- [ ] Add sample data for previews
- [ ] Test Codable with real Supabase responses
- [ ] Document all model properties and relationships

**Testing & Documentation**
- [ ] Write unit tests for all models
- [ ] Test edge cases (expired sessions, invalid data)
- [ ] Create model documentation
- [ ] Help other teammates integrate models
- [ ] Code review and refactoring

---

#### ** Database Manager (Week 2)**

**Real-time Features**
- [ ] Implement real-time photo updates using Supabase Realtime
- [ ] Add real-time participant list updates
- [ ] Implement collage expiration notifications
- [ ] Add connection status monitoring
- [ ] Handle reconnection logic

**Performance & Optimization**
- [ ] Add database query optimization
- [ ] Implement pagination for large photo sets
- [ ] Add caching layer for frequently accessed data
- [ ] Optimize image upload with concurrent uploads
- [ ] Add request queuing for offline support

**Error Handling & Edge Cases**
- [ ] Add comprehensive error handling
- [ ] Implement retry logic with exponential backoff
- [ ] Handle network disconnections gracefully
- [ ] Add conflict resolution for concurrent edits
- [ ] Test with poor network conditions

**Testing & Documentation**
- [ ] Write integration tests
- [ ] Test all CRUD operations
- [ ] Load test with multiple users
- [ ] Create API documentation
- [ ] Help team with database integration

---

#### **Photo Manager (Days 8-14)**

**Advanced Camera Features**
- [ ] Add photo filters/effects
- [ ] Implement timer for delayed capture
- [ ] Add burst mode for multiple photos
- [ ] Implement photo gallery selection (pick from library)
- [ ] Add video thumbnail extraction (bonus feature)

**Enhanced Layout System**
- [ ] Implement smart auto-layout algorithms
- [ ] Add layout templates (grid, spiral, random)
- [ ] Implement photo clustering by user
- [ ] Add animation for photo appearance
- [ ] Implement z-index management for overlapping

**Polish & Optimization**
- [ ] Optimize memory usage for large images
- [ ] Add progressive image loading
- [ ] Implement image caching
- [ ] Add haptic feedback for interactions
- [ ] Optimize collision detection performance

**Testing & Integration**
- [ ] Test camera on different devices
- [ ] Test crop accuracy and edge cases
- [ ] Test layout with 50+ photos
- [ ] Integration testing with DatabaseManager
- [ ] Performance testing and optimization

---

#### **AppState & Views (Week 2)**

**Complete CollageView**
- [ ] Implement full photo display with gestures
- [ ] Add "Reveal All" button when collage expires
- [ ] Implement photo tap to view full screen
- [ ] Add participant list sidebar
- [ ] Show upload progress for photos
- [ ] Add "Leave Collage" confirmation dialog
- [ ] Implement share sheet for invite codes

**Additional Views**
- [ ] Create `ProfileView` with user stats
- [ ] Create `SettingsView` (notifications, privacy)
- [ ] Create `ExpiredCollageView` (show all unblurred photos)
- [ ] Create `TutorialView` for first-time users
- [ ] Add `AboutView` with credits
- [ ] Implement photo detail view with zoom

**UI Polish & Animations**
- [ ] Add smooth transitions between views
- [ ] Implement loading skeletons
- [ ] Add celebration animation when collage completes
- [ ] Add shake animation for errors
- [ ] Implement pull-to-refresh animations
- [ ] Add theme-based UI customization
- [ ] Ensure dark mode support

**Final Integration & Testing**
- [ ] Integrate all components together
- [ ] End-to-end testing of all flows
- [ ] Test on multiple devices and iOS versions
- [ ] Fix any navigation bugs
- [ ] Performance testing and optimization
- [ ] Prepare demo scenarios

---

## 🔄 Integration Checkpoints

### End of Day 3
- [ ] All teammates: Sync on model structure and naming conventions
- [ ] Confirm Supabase schema matches models

### End of Day 7
- [ ] Integration meeting: Connect DatabaseManager with Models
- [ ] Integration meeting: Connect PhotoManager with DatabaseManager
- [ ] Integration meeting: Connect AppState with all managers
- [ ] Test basic flow: Auth → Create Collage → Upload Photo

### End of Day 10
- [ ] Full integration testing
- [ ] Identify blockers and reassign tasks if needed

### End of Day 14
- [ ] Final testing session
- [ ] Bug fixing sprint
- [ ] Prepare presentation/demo

---

## 🎯 Critical Path Items (Must Complete)

1. **Authentication** (Days 1-2)
2. **Create Collage** (Days 3-4)
3. **Upload Photo** (Days 5-7)
4. **Display Photos with Blur** (Days 7-9)
5. **Join Collage** (Days 8-9)
6. **Real-time Updates** (Days 10-11)
7. **Reveal Photos on Expiry** (Days 11-12)
8. **Polish & Bug Fixes** (Days 13-14)

---

## 📱 Supabase Database Schema Reminder

### Tables to Create:
- `users` (id, email, username, created_at, avatar_url)
- `collages` (id, theme, created_by, starts_at, expires_at, invite_code)
- `collage_members` (collage_id, user_id, joined_at)
- `photos` (id, collage_id, user_id, storage_path, position_x, position_y, width, height, rotation, uploaded_at)
- `themes` (id, text, category, is_active)

### Storage Buckets:
- `collage-photos` (public read, authenticated write)
- `avatars` (public read, user write own)

---

## 🚀 Success Criteria

By end of Week 2, the app should:
- ✅ Allow users to sign up/sign in
- ✅ Create a collage with random theme and timer
- ✅ Take photo, randomly crop, and upload
- ✅ Display own photos clearly, others' photos blurred
- ✅ Join existing collages via invite code
- ✅ Show all photos unblurred when timer expires
- ✅ Handle multiple active collages per user
- ✅ Work reliably with real-time updates
- ✅ Have polished UI with smooth animations
- ✅ Handle errors gracefully

## Table Relations
| Table                  | Purpose                                                          |
| ---------------------- | ---------------------------------------------------------------- |
| `users`                | Stores registered user accounts (linked to Supabase Auth).       |
| `collages`             | Represents a collage session (with theme, start/end time, etc.). |
| `collage_members`      | Many-to-many relation between users and collages.                |
| `photos`               | Stores uploaded photos placed within a collage.                  |
| `themes`               | A pool of random themes fetched when a new collage is created.   |
| `invites` *(optional)* | Stores shareable invite codes to join a collage.                 |

 Supabase storage buckets for photo uploads
| Bucket           | Path Example                            | Access                           |
| ---------------- | --------------------------------------- | -------------------------------- |
| `collage-photos` | `/collages/{collage_id}/{photo_id}.jpg` | Public read, authenticated write |

Good luck team! 🎉
