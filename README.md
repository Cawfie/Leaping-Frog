# 🐸 Froggy Leap (Leaping Frog)

A delightful, high-altitude vertical arcade jumper developed in **Godot Engine 4**. Help Froggy leap through an endless, perilous forest canopy, bouncing on mushroom springs, snagging tasty bugs, and dodging hazards as the camera rises beneath you!

---

## 📥 Direct Downloads

Download and play immediately on PC or Android:

* 🪟 **[Direct Download Windows (.exe)](builds/windows/FroggyLeap.exe?raw=true)** &nbsp; *(Standalone 64-bit Executable &bull; ~122 MB)*
* 📱 **[Direct Download Android (.apk)](builds/android/FroggyLeap.apk?raw=true)** &nbsp; *(Signed Universal APK &bull; ~72 MB)*

> **Quick Start**:
> - **Windows**: Download [FroggyLeap.exe](builds/windows/FroggyLeap.exe?raw=true) and double-click to play immediately. No installation or setup required!
> - **Android**: Download [FroggyLeap.apk](builds/android/FroggyLeap.apk?raw=true) directly to your Android device, tap to install, and launch.

---

## 🌟 Game Highlights & Features

### 🕹️ Dynamic Vertical Platforming
- **Procedural Canopy**: Randomly generated platforms that scale in difficulty as you climb higher.
- **Fair Platform Generation**: Guaranteed safe paths, wide solid logs, and minimum buffer spacing so the game remains challenging but always fair.
- **Spring Mushrooms**: Bouncy red-spotted mushrooms that launch Froggy skyward (with built-in cooldowns preventing unfair stacking).
- **Crumbling Logs**: Fragile branches that break on contact—jump quickly!

### ⚠️ Perilous Forest Hazards
- **Thorn Brambles**: Sharp spikes lining platform edges with generous safe recovery wood.
- **Patrolling Bees**: Stinging bees flying along predictable flight paths.
- **Falling Spikes (35m+)**: Telegraphed with an animated 3-frame warning indicator at the top of your screen before plummeting.
- **Rising Screen Pressure**: Camera climb speed scales dynamically with altitude, keeping the adrenaline pumping.

### 🪰 Bug Feasts & High Scores
- 🪰 **Housefly**: +10 Points (Common points boost)
- 🦋 **Butterfly**: +50 Points (Graceful, high-reward flutterer)
- 💖 **Heart Moth**: +25 Points & Heals +1 Heart (Rare life saver)
- 🎉 **500m Milestone Swarms**: Every 500 meters, celebrate with a festive feast of 5–6 bonus flies and butterflies!

### 🎵 High Quality Audio & Polish
- **Atmospheric Looped BGM**: Seamless background track (*High Above the Reeds*) featuring a 1.5s fade-in on start and 1.0s fade-out on game over.
- **Arcade Death Animation**: Expressive red hurt frog hop and tumble sequence when all hearts are lost.
- **Pixel-Perfect Alignment**: Precise hitboxes ensuring Froggy bounces directly on the bark surface.

### ⚡ Ultra-Smooth Multi-Refresh Display Optimization
- **Uncapped FPS**: Dynamically syncs with your screen's native refresh rate (**30 Hz, 60 Hz, 90 Hz, 120 Hz, 144 Hz**).
- **Physics Interpolation**: 60 Hz deterministic simulation coupled with 2D interpolation for buttery smooth movement with zero frame jitter or physics drift.

---

## 🎮 Controls

### Desktop (Windows)
| Action | Primary Key | Alternate Key |
| :--- | :--- | :--- |
| **Move Left** | A | Left Arrow |
| **Move Right** | D | Right Arrow |
| **Jump** | Space | W / Up Arrow |
| **Eat Bug** | Left Click | E |

*(Configurable in Settings: Choose between "A/D + Arrows", "A/D Only", or "Arrows Only")*

### Mobile (Android)
- **Touch Mode (Default)**: Tap or hold the left half of the screen to move left, right half to move right.
- **Tilt Mode**: Use your device's accelerometer to steer Froggy by tilting your phone.
- **Sensitivity Slider**: Custom tilt sensitivity (Low, Medium, High) in the settings menu.

---

## 🛠️ Built With
- **Godot Engine 4.7.2** (GL Compatibility Renderer)
- **GDScript**
- Compatible with Windows 10/11 & Android 5.0+
