# Download Video from Gated/Embedded Sources

## Purpose
Download a video from a site that requires authentication or embeds the video in a custom player (e.g. WebinarJam, Vimeo embeds, etc.) using yt-dlp on NixOS.

---

## Step 1 — Try yt-dlp directly

```
cd ~/Downloads && nix shell nixpkgs#yt-dlp --command yt-dlp --verbose "<url>"
```

If it succeeds, done. If it redirects to a login page, proceed to Step 2.

---

## Step 2 — Export authenticated cookies

Browser extension cookie exporters miss **HttpOnly** cookies (where the session token usually lives). Use the **"Export cookies"** extension that explicitly supports HttpOnly:

- Firefox: install **"HTTP Only Cookies"** or equivalent that can export HttpOnly cookies
- Export cookies for the domain while you are logged in and can see the video
- Save as a `.txt` file in Netscape cookie format

Then retry:

```
nix shell nixpkgs#yt-dlp --command yt-dlp --verbose --cookies <cookies-file.txt> "<url>"
```

If yt-dlp now gets past login but reports "Unsupported URL", the site has a custom player with no yt-dlp extractor — proceed to Step 3.

---

## Step 3 — Extract the video URL from page source

Fetch the authenticated page and grep for the video URL:

```
curl -s --cookie <cookies-file.txt> "<url>" | grep -iE '(videoUrl|video_url|source|file|\.m3u8|\.mp4)'
```

Look for a direct `.mp4` or `.m3u8` URL in the output. On WebinarJam it appears in a JS config block like:

```
replay: {"videoUrl":"https://player.vimeo.com/progressive_redirect/..."}
```

---

## Step 4 — Download the extracted URL

Pass the direct URL to yt-dlp. Always specify `-o` with an explicit filename — CDN URLs are too long for the filesystem:

```
nix shell nixpkgs#yt-dlp --command yt-dlp -o "output-filename.mp4" "<extracted-url>"
```

---

## Sharing the downloaded file

Upload to Nextcloud at `cloud.janovitch.com`, then:

Files → right-click the file → **Share** → **Share link** → copy URL

The recipient gets a direct link (`https://cloud.janovitch.com/s/XXXXXXXXXX`) and can stream or download without logging in.

---

## Notes
- WebinarJam hosts replays on Vimeo via progressive redirect — Step 3 reliably extracts the MP4
- `--cookies-from-browser firefox` is an alternative to a cookie file but requires yt-dlp to access the Firefox profile directly (works if running as the same user)
- Always use `-o <name>.mp4` — auto-generated filenames from CDN token URLs exceed Linux's 255-byte filename limit
