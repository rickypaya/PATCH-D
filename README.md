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




## ✅ 2-Week Sprint Task Breakdown

### 🗓️ Week 1: Foundation & Core Features

#### **Teammate 1 - Models (Days 1-7)**

**Part 1: Core Models**
- [x] Create `User` model with all properties (id, email, username, createdAt, profileImageUrl)
- [x] Create `CollageSession` model with relationships (id, theme, startTime, endTime, createdBy, participants array, photos array, inviteCode)
- [x] Create `CollagePhoto` model (id, userId, username, imageUrl, position, size, rotation, aspectRatio, uploadedAt)
- [x] Add Codable conformance to all models for Supabase JSON parsing

**Part 2: Supporting Models**
- [x] Create `Theme` model (id, text, category, isActive)
- [x] Create `Invite` model (code, collageId, createdBy, expiresAt, maxUses, currentUses)
- [x] Create `Collage` model as main database representation
- [x] Add computed properties for time remaining, isExpired, participantCount

**Part 3: Enums & Extensions**
- [x] Create `CollageStatus` enum (active, expired, cancelled)
- [x] Create `PhotoUploadStatus` enum (uploading, processing, completed, failed)
- [x] Add Date extensions for ISO8601 formatting
- [x] Add UUID extensions for validation
- [x] Create model validation methods
- [ ] Write unit tests for models

---

#### **Database Manager (Week 1)**

**Part 1: Supabase Setup**
- [x] Set up Supabase project and get credentials
- [x] Configure `SupabaseManager` singleton with URL and anon key
- [x] Implement `signUp(email:password:)` method
- [x] Implement `signIn(email:password:)` method
- [x] Implement `signOut()` method
- [x] Implement `getCurrentUser()` method
- [ ] Add session persistence handling

**Part 2: Collage Operations**
- [x] Implement `fetchRandomTheme()` with proper error handling
- [x] Implement `createCollage(theme:duration:)` with user as creator
- [x] Implement `joinCollage(collageId:)` with validation
- [x] Implement `fetchCollage(collageId:)` with relationships
- [x] Implement `fetchActiveSessions(for:)` filtering by user
- [x] Add `leaveCollage(collageId:)` method

**Part 3: Photo & Storage Operations**
- [] Implement `uploadPhotoToStorage(image:collageId:)` to Supabase Storage
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

--
App State Functions for use in UI (To Be implemented)

AUTHENTICATION 
Core Auth

signUpWithEmail(email:password:username:) - Create new account + collage_users entry
signInWithEmail(email:password:) - Login existing user
signOut() - Logout and clear state
isUserAuthenticated() - Check if user has active session
getCurrentUserProfile() - Get logged-in user's CollageUser profile


COLLAGE MANAGEMENT
Create Collage

fetchRandomTheme() - Get one random theme from DB
createNewCollage(duration:) - Create collage with random theme
storeActiveCollageId(collageId:) - Save current collage to app state

Join Collage

joinCollageWithCode(inviteCode:) - Join by invite code
validateInviteCode(code:) - Basic format check (8 characters)

View Collages

loadUserActiveCollages() - Fetch all user's active collages
loadCollageDetails(collageId:) - Fetch full collage with photos/members
getTimeRemaining(collageId:) - Calculate time until expiry
copyInviteCodeToClipboard(inviteCode:) - Share functionality


PHOTO MANAGEMENT
Upload Photos

openImagePicker() - Show system photo picker
selectPhotoFromLibrary(image:) - Handle selected image
uploadPhotoToCollage(collageId:image:) - Upload with default position/size
handleUploadError(error:) - Show error message

Display Photos

loadPhotosForCollage(collageId:) - Fetch all photos for display
refreshCollagePhotos(collageId:) - Pull-to-refresh photos


ERROR HANDLING 
Basic Error Management

handleNetworkError(error:) - No internet message
handleAuthError(error:) - Login/signup errors
showErrorAlert(message:) - Generic error display


UI STATE
Navigation & Display

navigateToCollage(collageId:) - Navigate to collage detail
showLoadingIndicator() - Show/hide loading states
refreshView() - Pull-to-refresh functionality
