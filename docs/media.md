# Media — Daily Applications

## Image Viewer — imv
Minimal Wayland-native image viewer.
```
imv image.png           # view single image
imv *.png               # view multiple images
imv -f directory/       # view all images in directory
```
**Default app for:** png, jpeg, gif, webp

---

## Video & Audio — mpv
Plays everything. Lightweight and powerful.
```
mpv video.mp4                   # play video
mpv audio.mp3                   # play audio
mpv https://youtube.com/...     # play from URL
mpv --fullscreen video.mp4      # fullscreen
mpv --loop video.mp4            # loop
mpv --speed 1.5 video.mp4      # 1.5x speed
```

### Keybindings (during playback)
| Key | Action |
|---|---|
| `Space` | Play/pause |
| `Left/Right` | Seek 5s |
| `Up/Down` | Seek 60s |
| `[/]` | Speed down/up |
| `f` | Toggle fullscreen |
| `9/0` | Volume down/up |
| `s` | Screenshot |
| `q` | Quit |
| `j/J` | Switch subtitle |
| `#` | Switch audio track |

**Default app for:** mp4, mkv, webm, mpeg, flac

---

## Media Control — playerctl
Control media playback from terminal.
```
playerctl play              # play
playerctl pause             # pause
playerctl next              # next
playerctl previous          # previous
playerctl volume 0.5        # set volume
playerctl status            # show status
playerctl metadata title    # show title
```

---

## PDF Viewer — zathura
Vim-like PDF viewer.
```
zathura document.pdf
```

### Keybindings
| Key | Action |
|---|---|
| `j/k` | Scroll |
| `J/K` | Next/prev page |
| `gg/G` | First/last page |
| `/` | Search |
| `n/N` | Next/prev match |
| `+/-` | Zoom |
| `W` | Fit width |
| `d` | Dual page |
| `q` | Quit |

**Default app for:** PDF

---

## Markdown Viewer — inlyne
GUI markdown renderer in terminal.
```
inlyne README.md
```

---

## Note Taking — joplin
Lightweight markdown notes with sync support.
```
joplin                  # open GUI
```

---

## Camera — cheese
Webcam application — photos, videos, effects.
```
cheese                  # open camera
```

---

## Archive Tools
| Tool | Create | Extract |
|---|---|---|
| **zip** | `zip archive.zip file1 file2` | `unzip archive.zip` |
| **7z** | `7z a archive.7z file1` | `7z x archive.7z` |
| **unrar** | — | `unrar x archive.rar` |

---

## Mount & Notifications
| Tool | Purpose | Usage |
|---|---|---|
| **udiskie** | Auto-mount USB | Runs automatically |
| **libnotify** | Desktop notifications | `notify-send "title" "body"` |

---

## Media Processing

### ffmpeg — All-in-one media converter
```
ffmpeg -i video.mp4 video.avi           # convert format
ffmpeg -i video.mp4 -ss 00:01:00 -t 10 clip.mp4  # cut 10s from 1min
ffmpeg -i video.mp4 -vf "scale=1280:720" hd.mp4   # resize
ffmpeg -i video.mp4 -vn audio.mp3       # extract audio
ffmpeg -i video.mp4 -r 30 output.mp4    # set fps
```

### yt-dlp — Download from YouTube and 1000+ sites
```
yt-dlp "https://youtube.com/watch?v=..."         # download video
yt-dlp -x "https://youtube.com/watch?v=..."      # audio only
yt-dlp --format mp4 "url"                        # specific format
yt-dlp --playlist "url"                          # download playlist
yt-dlp -o "%(title)s.%(ext)s" "url"             # custom filename
```

### imagemagick — Image processing
```
convert input.png -resize 50% output.png         # resize 50%
convert input.png -resize 800x600 output.png     # resize to 800x600
convert input.jpg output.webp                    # convert format
montage *.png -geometry 200x200+5+5 grid.png     # create grid
```

---

## Wayland Tools
| Tool | Purpose | Usage |
|---|---|---|
| **grim** | Screenshot | `grim screenshot.png` |
| **slurp** | Region select | `slurp \| grim -g - screenshot.png` |
| **wl-screenrec** | Screen record | `wl-screenrec output.mp4` |
| **brightnessctl** | Brightness | `brightnessctl set 50%` |
| **pamixer** | Volume | `pamixer --set-volume 50` |
| **bluetui** | Bluetooth TUI | `bluetui` |
| **wl-clipboard** | Clipboard | `wl-copy`, `wl-paste` |
