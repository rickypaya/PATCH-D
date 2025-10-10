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
## App State Functions for use in UI (To Be implemented)

## AUTHENTICATION 
Core Auth

signUpWithEmail(email:password:username:) - Create new account + collage_users entry
signInWithEmail(email:password:) - Login existing user
signOut() - Logout and clear state
isUserAuthenticated() - Check if user has active session
getCurrentUserProfile() - Get logged-in user's CollageUser profile


## COLLAGE MANAGEMENT
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


## PHOTO MANAGEMENT
Upload Photos

openImagePicker() - Show system photo picker
selectPhotoFromLibrary(image:) - Handle selected image
uploadPhotoToCollage(collageId:image:) - Upload with default position/size
handleUploadError(error:) - Show error message

Display Photos

loadPhotosForCollage(collageId:) - Fetch all photos for display
refreshCollagePhotos(collageId:) - Pull-to-refresh photos


## ERROR HANDLING 
Basic Error Management

handleNetworkError(error:) - No internet message
handleAuthError(error:) - Login/signup errors
showErrorAlert(message:) - Generic error display


## UI STATE
Navigation & Display

navigateToCollage(collageId:) - Navigate to collage detail
showLoadingIndicator() - Show/hide loading states
refreshView() - Pull-to-refresh functionality
