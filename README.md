# PATCH'D  - Overview
Patched is a mobile-first social application that reimagines digital collage-making as a playful, real-time, and collaborative creative experience. Designed for iPhone, Patched enables users to co-create visual compositions using photos, videos, and media cutouts with friends — transforming a traditionally solo creative act into a shared, dynamic, and interactive process.

At its core, Patched combines computational visual design, social interaction, and real-time collaboration. Users can start by signing in with their email to instantly create or join collage “sessions.” Each session acts as a shared creative canvas, where participants can contribute visual elements — from freshly captured photos to library images or precise cutouts extracted from photos using iOS’s built-in subject isolation tools.

## Key Features
- Real-Time Collaboration: Multiple users can work simultaneously on the same collage. Each addition, movement, or transformation is synchronized in real-time, creating a sense of presence and shared creativity.
- Media Cutouts and Layering: Users can import visual assets as cutouts, leveraging native iOS clipboard and visual lookup tools. These elements can be freely arranged, layered, and resized to form intricate visual narratives.
- Dynamic Canvas: The collage canvas updates instantly as participants move, rotate, and scale images, making the process feel like a living, breathing artwork that evolves with every gesture.
- Thematic Collage Sessions: Each session can be guided by a prompt or theme (e.g., “Weekend Memories,” “Moodboard for a Short Film,” “Dream Cityscape”) — fostering structured creativity and communal storytelling.
- Time-Bound Collaboration: Collages can be ephemeral, with countdown timers or expiration windows that encourage spontaneous creation and participation — blending the immediacy of social media with the depth of artistic co-creation.
- Instant Sharing & Archiving: Once a collage is complete or the session expires, users can export their creations or share them directly to social platforms, celebrating collective visual expression.

### MVP 1 - 10/16 Beta
- Prototype application and database setup
Features:
- signup, logging in
- dashboard
   - create new collage
  - join collage with invite code
- User profile
  - avatar image upload
  - sign out
- Collage Detail View
  - Users list (not real time)
  - Countdown timer (realtime)
  - Collage Preview
  - Launch Fullscreen
- Full Screen View
- - Exit button (Updates collage preview)
  - Collage Photos (realtime)
  - Drag (WIP) - Move
  - Pinch - Scale
  - Rotate - scale (NF)
 
### MVP 2 Goals: 
- "Active Users" real-time data
- Smooth collaging experience
- App aesthetics, branding
- Auth Notification, Input verification
- Archive for viewing expired collages
- Friends list

### Stretch Goals:
- Widget for viewing the archive

## Oct 16th Meeting Tasks
- [x]  Onboarding (Sign up & Sign in flow) - UI design Yvette Code @Janice
   - [x]    Include validation messages
- [x] Create a Collage @Janice
   - [x]        Custom theme name
   - [x]        Collage Duration / Expiration
- [ ] Canvas View
   - [x]        Remove the layer of Canvas Detail view Ricky
   - [x]            Go straight to the Canvas from Collages
   - [x]        Collaborators icon Ricky
   - [x]            Add collaborators on bottom corner of canvas to see who’s collaborating on that collage
   - [x]        Add collaborator’s icon on the corner of the image to show who’s moving the image
   - [x]        Image movement Ricky
   - [x]            Positioning (Local vs Global) - fix
   - [x]            Rotate image around
   - [x]        Trash bin icon Ricky
   - [x]        Sticker png (transparent BG correction)
- [ ] Invite Friends Page or Friends list - UI design Yvette Code @Janice
- [ ] Download & Share collage flow
- [ ] Add transitions / animations between screens — low priority

## Oct 14th Meeting Tasks
- [x] realtime dashboard - med
- [x] implement collaging - Camera/Library add, paste from photos app, add stickers from library - high
- [x] populate stickers bucket, add stickers library to collage - high
- [x] photo gestures (moving, scaling, rotating) - high
- [x] realtime countdown - low
- [x] Auto auth, remember me, reset password, confirm email - med
- [x] Archive view (Expired collages) - med
- [x] finished collage view (save, share button) - med

### Hail Mary
- [ ] Homescreen widget with Archived Collages (?)
      



