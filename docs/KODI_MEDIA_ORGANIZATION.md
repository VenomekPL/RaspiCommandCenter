# Kodi Media Library Organization Guide

## 📁 Pre-Configured Media Folder Structure

Your Kodi setup automatically creates and configures these media folders:

```
~/Videos/
├── Movies/
│   ├── Action/     ├── Comedy/     ├── Drama/
│   ├── Horror/     ├── Sci-Fi/     ├── Animation/
│   └── Foreign/
├── TV Shows/
│   ├── Anime/      ├── Drama/      ├── Comedy/
│   ├── Documentary/ └── Kids/
└── Documentaries/

~/Music/
├── Albums/         ├── Artists/     ├── Genres/
│   │                   │               ├── Rock/
│   │                   │               ├── Pop/
│   │                   │               ├── Hip-Hop/
│   │                   │               ├── Electronic/
│   │                   │               ├── Classical/
│   │                   │               ├── Jazz/
│   │                   │               └── ...
├── Soundtracks/    ├── Podcasts/    └── Playlists/

~/Downloads/Elementum/
├── Movies/         ├── TV Shows/    ├── Music/
└── Completed/

~/Pictures/
```

## 🎬 Movie Organization

### Naming Convention
```
~/Videos/Movies/[Genre]/Movie Title (Year).ext
```

### Examples
```
~/Videos/Movies/Action/The Matrix (1999).mkv
~/Videos/Movies/Action/John Wick (2014).mp4
~/Videos/Movies/Comedy/Groundhog Day (1993).mkv
~/Videos/Movies/Animation/Spirited Away (2001).mkv
~/Videos/Movies/Sci-Fi/Blade Runner 2049 (2017).mkv
```

### Supported Formats
- **Video**: MP4, MKV, AVI, MOV, FLV, WMV, M4V
- **Subtitles**: SRT, ASS, SSA, VTT (place alongside video files)

## 📺 TV Show Organization

### Naming Convention
```
~/Videos/TV Shows/[Category]/Show Name (Year)/Season ##/S##E## - Episode Title.ext
```

### Examples
```
~/Videos/TV Shows/Drama/Breaking Bad (2008)/Season 01/S01E01 - Pilot.mkv
~/Videos/TV Shows/Drama/Breaking Bad (2008)/Season 01/S01E02 - Cat's in the Bag.mkv

~/Videos/TV Shows/Anime/One Piece (1999)/Season 01/S01E001 - I'm Luffy.mkv
~/Videos/TV Shows/Anime/One Piece (1999)/Season 01/S01E002 - The Great Swordsman.mkv

~/Videos/TV Shows/Comedy/The Office (2005)/Season 01/S01E01 - Pilot.mp4
~/Videos/TV Shows/Kids/Avatar The Last Airbender (2005)/Season 01/S01E01 - The Boy in the Iceberg.mkv
```

### Season Folder Examples
```
Season 01/   # Standard seasons
Season 02/
Season 03/
Specials/    # For special episodes, movies, OVAs
```

## 🤖 Automatic Kodi Features

### Library Sources (Pre-configured)
- **Movies**: `~/Videos/Movies/` - Set to "Movies" content type
- **TV Shows**: `~/Videos/TV Shows/` - Set to "TV Shows" content type  
- **Documentaries**: `~/Videos/Documentaries/` - Set to "Movies" content type
- **Music Library**: `~/Music/` - Set to "Music" content type with multiple sources:
  - Albums, Artists, Genres, Soundtracks, Podcasts subfolders
- **Elementum Downloads**: `~/Downloads/Elementum/` - Set to "Mixed" content type

### Metadata Scrapers (Auto-enabled)
- **Movies**: The Movie Database (TMDB)
- **TV Shows**: The TVDB (TheTVDB.com)
- **Music**: MusicBrainz + Last.fm + AllMusic

### What Kodi Does Automatically
✅ **Scans for new media** when files are added  
✅ **Downloads posters, fanart, and metadata** from online databases  
✅ **Organizes content** in beautiful library views  
✅ **Tracks watched status** and resume points  
✅ **Downloads subtitles** when available  
✅ **Creates collections** for movie series  
✅ **Shows next episodes** for TV shows  
✅ **Generates recommendations** based on viewing history  

## 🔄 Elementum Integration

### Download Behavior
- **Stream + Download**: Content streams while downloading to `~/Downloads/Elementum/`
- **Library Integration**: Downloaded content automatically appears in Kodi library
- **Organization**: Move completed downloads to proper media folders for permanent library

### Elementum to Library Workflow
1. **Stream via Elementum**: Watch content while it downloads
2. **Auto-detection**: Kodi detects completed downloads
3. **Manual Organization**: Use `~/manage-media.sh` to move files to proper folders
4. **Library Update**: Kodi automatically scans and adds to library with metadata

## 🛠️ Management Tools

### Media Management Script
```bash
~/manage-media.sh
```

Features:
- View folder structure and sizes
- Set up new movie/TV show folders
- Clean up Elementum downloads
- Organize files into proper library structure
- Scan Kodi library
- Show library statistics

### CLI Library Management
```bash
# Update video library
python3 ~/kodi-cli.py library update --type video

# Update music library  
python3 ~/kodi-cli.py library update --type music

# Clean library (remove missing files)
python3 ~/kodi-cli.py library clean --type video
```

## 📱 Remote Library Browsing

### Kore Mobile App
- Browse your entire library from your phone
- Search and filter content
- Remote control playback
- Add items to playlists

### Web Interface
Visit `http://YOUR_PI_IP:8080` to:
- Browse library via web browser
- Control playback remotely
- Manage files and folders
- View download progress

## 🔍 Library Optimization Tips

### File Naming Best Practices
1. **Include year** in movie titles for accurate matching
2. **Use standard episode numbering** (S##E##) for TV shows  
3. **Keep original release names** when possible
4. **Place subtitle files** alongside video files with same name

### Folder Organization Tips
1. **Genre-based movie folders** help with browsing
2. **Category-based TV folders** organize by content type
3. **Season folders** keep TV shows organized
4. **Avoid special characters** in folder/file names

### Performance Optimization
1. **Use wired network** for large file transfers
2. **External SSD storage** for better performance
3. **Regular library cleaning** removes orphaned entries
4. **Limit concurrent downloads** in Elementum settings

## 🏠 Home Assistant Integration

### Library Statistics in HA
```yaml
sensor:
  - platform: rest
    name: "Kodi Movie Count"
    resource: "http://YOUR_PI_IP:8080/jsonrpc"
    method: POST
    payload: '{"jsonrpc":"2.0","method":"VideoLibrary.GetMovies","id":1}'
    value_template: "{{ value_json.result.limits.total }}"
    
  - platform: rest
    name: "Kodi TV Episode Count"  
    resource: "http://YOUR_PI_IP:8080/jsonrpc"
    method: POST
    payload: '{"jsonrpc":"2.0","method":"VideoLibrary.GetEpisodes","id":1}'
    value_template: "{{ value_json.result.limits.total }}"
```

### Automation Examples
```yaml
automation:
  - alias: "Update Kodi Library Daily"
    trigger:
      platform: time
      at: "04:00:00"
    action:
      service: rest_command.kodi_update_library

rest_command:
  kodi_update_library:
    url: "http://YOUR_PI_IP:8080/jsonrpc"
    method: POST
    payload: '{"jsonrpc":"2.0","method":"VideoLibrary.Scan","id":1}'
```

## 🚀 Quick Start Workflow

### Adding a New Movie
1. **Download/Stream** via Elementum or place file manually
2. **Organize** into appropriate genre folder:
   ```bash
   # Example: Action movie
   mv "Movie.File.2024.mkv" "~/Videos/Movies/Action/Movie File (2024).mkv"
   ```
3. **Scan Library** (automatic or manual):
   ```bash
   python3 ~/kodi-cli.py library update
   ```
4. **Enjoy** - Movie appears in Kodi with full metadata!

### Adding a TV Show
1. **Create show structure**:
   ```bash
   mkdir -p "~/Videos/TV Shows/Drama/New Show (2024)/Season 01"
   ```
2. **Add episodes** with proper naming:
   ```bash
   # Example episodes
   mv "episode1.mkv" "~/Videos/TV Shows/Drama/New Show (2024)/Season 01/S01E01 - Pilot.mkv"
   mv "episode2.mkv" "~/Videos/TV Shows/Drama/New Show (2024)/Season 01/S01E02 - Episode 2.mkv"
   ```
3. **Library scan** picks up the show automatically
4. **Track progress** - Kodi shows next episodes and watched status

Your Kodi media center is now a fully organized, automatically managed smart TV experience! 🎬✨
