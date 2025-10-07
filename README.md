# PATCH'D - Project Division & 2-Week Sprint Plan

## 📁 File Structure & Team Assignments

### File 1: **Models.swift** (Teammate 1)
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

### File 2: **DatabaseManager.swift** (Teammate 2)
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

### File 3: **PhotoManager.swift** (Teammate 3)
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

### File 4: **AppState.swift + Views** (Teammate 4)
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

**Days 1-2: Core Models**
- [ ] Create `User` model with all properties (id, email, username, createdAt, profileImageUrl)
- [ ] Create `CollageSession` model with relationships (id, theme, startTime, endTime, createdBy, participants array, photos array, inviteCode)
- [ ] Create `CollagePhoto` model (id, userId, username, imageUrl, position, size, rotation, aspectRatio, uploadedAt)
- [ ] Add Codable conformance to all models for Supabase JSON parsing

**Days 3-4: Supporting Models**
- [ ] Create `Theme` model (id, text, category, isActive)
- [ ] Create `Invite` model (code, collageId, createdBy, expiresAt, maxUses, currentUses)
- [ ] Create `Collage` model as main database representation
- [ ] Add computed properties for time remaining, isExpired, participantCount

**Days 5-7: Enums & Extensions**
- [ ] Create `CollageStatus` enum (active, expired, cancelled)
- [ ] Create `PhotoUploadStatus` enum (uploading, processing, completed, failed)
- [ ] Add Date extensions for ISO8601 formatting
- [ ] Add UUID extensions for validation
- [ ] Create model validation methods
- [ ] Write unit tests for models

---

#### **Teammate 2 - Database Manager (Days 1-7)**

**Days 1-2: Supabase Setup**
- [ ] Set up Supabase project and get credentials
- [ ] Configure `SupabaseManager` singleton with URL and anon key
- [ ] Implement `signUp(email:password:)` method
- [ ] Implement `signIn(email:password:)` method
- [ ] Implement `signOut()` method
- [ ] Implement `getCurrentUser()` method
- [ ] Add session persistence handling

**Days 3-4: Collage Operations**
- [ ] Implement `fetchRandomTheme()` with proper error handling
- [ ] Implement `createCollage(theme:duration:)` with user as creator
- [ ] Implement `joinCollage(collageId:)` with validation
- [ ] Implement `fetchCollage(collageId:)` with relationships
- [ ] Implement `fetchActiveSessions(for:)` filtering by user
- [ ] Add `leaveCollage(collageId:)` method

**Days 5-6: Photo & Storage Operations**
- [ ] Implement `uploadPhotoToStorage(image:collageId:)` to Supabase Storage
- [ ] Implement `insertPhotoMetadata(photo:)` to photos table
- [ ] Implement `fetchPhotosForCollage(collageId:)` query
- [ ] Implement `deletePhoto(photoId:)` with storage cleanup
- [ ] Add photo URL generation with signed URLs

**Day 7: Invite System & Polish**
- [ ] Implement `generateInviteCode(collageId:)` with unique codes
- [ ] Implement `validateInviteCode(code:)` with expiry checking
- [ ] Implement `getCollageIdFromInvite(code:)` lookup
- [ ] Add real-time subscription setup for collage updates
- [ ] Add error handling and retry logic
- [ ] Write integration tests

---

#### **Teammate 3 - Photo Manager (Days 1-7)**

**Days 1-2: Camera Integration**
- [ ] Create `CameraManager` class with AVFoundation setup
- [ ] Implement camera permission request handling
- [ ] Create camera preview layer
- [ ] Implement photo capture functionality
- [ ] Add front/back camera switching
- [ ] Add flash control
- [ ] Handle camera session lifecycle

**Days 3-4: Image Processing**
- [ ] Create `PhotoProcessor` class
- [ ] Implement random crop logic (choose random portrait/landscape section)
- [ ] Implement manual crop with draggable frame
- [ ] Add image compression for upload optimization
- [ ] Implement aspect ratio calculations
- [ ] Add image orientation correction
- [ ] Create crop preview UI

**Days 5-6: Collage Layout System**
- [ ] Create `CollageLayoutManager` class
- [ ] Implement random position generation within bounds
- [ ] Add collision detection to prevent photo overlap
- [ ] Implement drag-and-drop photo repositioning
- [ ] Add pinch-to-zoom for photo resizing
- [ ] Implement rotation gestures
- [ ] Add snap-to-grid optional feature

**Day 7: Photo Upload Pipeline**
- [ ] Integrate camera → crop → compress workflow
- [ ] Connect to DatabaseManager for storage upload
- [ ] Add upload progress tracking
- [ ] Implement upload retry on failure
- [ ] Add local caching for offline support
- [ ] Optimize image loading with thumbnails
- [ ] Test full pipeline end-to-end

---

#### **Teammate 4 - AppState & Views (Days 1-7)**

**Days 1-2: App State Management**
- [ ] Create comprehensive `AppState` ObservableObject
- [ ] Add @Published properties (currentUser, activeSessions, selectedSession, etc.)
- [ ] Implement authentication state management
- [ ] Add session loading and refreshing logic
- [ ] Implement navigation state management
- [ ] Add error state handling with user-friendly messages
- [ ] Set up Combine publishers for state updates

**Days 3-4: Authentication & Onboarding**
- [ ] Design and implement `AuthenticationView` UI
- [ ] Add email/password validation
- [ ] Create sign-up flow with username selection
- [ ] Add loading states and error messages
- [ ] Implement "Remember Me" functionality
- [ ] Create onboarding tutorial (optional)
- [ ] Add password reset flow

**Days 5-6: Dashboard & Navigation**
- [ ] Design and implement `DashboardView` with collage list
- [ ] Add "Create Collage" button with loading state
- [ ] Add "Join Collage" button with code input
- [ ] Implement pull-to-refresh for session list
- [ ] Show countdown timers for each active collage
- [ ] Add empty state when no collages exist
- [ ] Implement navigation to CollageView

**Day 7: Core Views**
- [ ] Create `JoinCollageView` with code input validation
- [ ] Build basic `CollageView` canvas structure
- [ ] Add camera button integration
- [ ] Implement photo display with blur logic
- [ ] Add share button for invite codes
- [ ] Create navigation bar with theme title
- [ ] Add logout functionality

---

### 🗓️ Week 2: Polish, Integration & Testing

#### **Teammate 1 - Models (Days 8-14)**

**Days 8-9: Advanced Features**
- [ ] Add pagination support to models
- [ ] Create `CollageStats` model (photoCount, participantCount, etc.)
- [ ] Add `Notification` model for push notifications
- [ ] Create `UserPreferences` model for settings
- [ ] Implement model caching strategies
- [ ] Add model versioning for migrations

**Days 10-12: Data Validation & Edge Cases**
- [ ] Add comprehensive input validation
- [ ] Handle nil/optional values gracefully
- [ ] Create mock data generators for testing
- [ ] Add sample data for previews
- [ ] Test Codable with real Supabase responses
- [ ] Document all model properties and relationships

**Days 13-14: Testing & Documentation**
- [ ] Write unit tests for all models
- [ ] Test edge cases (expired sessions, invalid data)
- [ ] Create model documentation
- [ ] Help other teammates integrate models
- [ ] Code review and refactoring

---

#### **Teammate 2 - Database Manager (Days 8-14)**

**Days 8-9: Real-time Features**
- [ ] Implement real-time photo updates using Supabase Realtime
- [ ] Add real-time participant list updates
- [ ] Implement collage expiration notifications
- [ ] Add connection status monitoring
- [ ] Handle reconnection logic

**Days 10-11: Performance & Optimization**
- [ ] Add database query optimization
- [ ] Implement pagination for large photo sets
- [ ] Add caching layer for frequently accessed data
- [ ] Optimize image upload with concurrent uploads
- [ ] Add request queuing for offline support

**Days 12-13: Error Handling & Edge Cases**
- [ ] Add comprehensive error handling
- [ ] Implement retry logic with exponential backoff
- [ ] Handle network disconnections gracefully
- [ ] Add conflict resolution for concurrent edits
- [ ] Test with poor network conditions

**Day 14: Testing & Documentation**
- [ ] Write integration tests
- [ ] Test all CRUD operations
- [ ] Load test with multiple users
- [ ] Create API documentation
- [ ] Help team with database integration

---

#### **Teammate 3 - Photo Manager (Days 8-14)**

**Days 8-9: Advanced Camera Features**
- [ ] Add photo filters/effects
- [ ] Implement timer for delayed capture
- [ ] Add burst mode for multiple photos
- [ ] Implement photo gallery selection (pick from library)
- [ ] Add video thumbnail extraction (bonus feature)

**Days 10-11: Enhanced Layout System**
- [ ] Implement smart auto-layout algorithms
- [ ] Add layout templates (grid, spiral, random)
- [ ] Implement photo clustering by user
- [ ] Add animation for photo appearance
- [ ] Implement z-index management for overlapping

**Days 12-13: Polish & Optimization**
- [ ] Optimize memory usage for large images
- [ ] Add progressive image loading
- [ ] Implement image caching
- [ ] Add haptic feedback for interactions
- [ ] Optimize collision detection performance

**Day 14: Testing & Integration**
- [ ] Test camera on different devices
- [ ] Test crop accuracy and edge cases
- [ ] Test layout with 50+ photos
- [ ] Integration testing with DatabaseManager
- [ ] Performance testing and optimization

---

#### **Teammate 4 - AppState & Views (Days 8-14)**

**Days 8-9: Complete CollageView**
- [ ] Implement full photo display with gestures
- [ ] Add "Reveal All" button when collage expires
- [ ] Implement photo tap to view full screen
- [ ] Add participant list sidebar
- [ ] Show upload progress for photos
- [ ] Add "Leave Collage" confirmation dialog
- [ ] Implement share sheet for invite codes

**Days 10-11: Additional Views**
- [ ] Create `ProfileView` with user stats
- [ ] Create `SettingsView` (notifications, privacy)
- [ ] Create `ExpiredCollageView` (show all unblurred photos)
- [ ] Create `TutorialView` for first-time users
- [ ] Add `AboutView` with credits
- [ ] Implement photo detail view with zoom

**Days 12-13: UI Polish & Animations**
- [ ] Add smooth transitions between views
- [ ] Implement loading skeletons
- [ ] Add celebration animation when collage completes
- [ ] Add shake animation for errors
- [ ] Implement pull-to-refresh animations
- [ ] Add theme-based UI customization
- [ ] Ensure dark mode support

**Day 14: Final Integration & Testing**
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

Good luck team! 🎉
