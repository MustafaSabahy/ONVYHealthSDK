# Quick Start - Run Demo App

## 🚀 Run on iOS Simulator

### Option 1: Expo Web (Fastest - Works Now)

```bash
cd demo-app
npx expo start --web
```

This will open in your browser and show the demo with mock data.

### Option 2: iOS Simulator (Requires Development Build)

Since HealthKit doesn't work on Simulator, the app uses mock data automatically.

```bash
cd demo-app
npx expo prebuild
npx expo run:ios
```

### Option 3: Physical Device (Full HealthKit Support)

```bash
cd demo-app
npx expo prebuild
# Connect iOS device
npx expo run:ios --device
```

---

## 📱 Current Status

The app is configured to:
- ✅ Use mock data on Simulator
- ✅ Show all features (steps, heart rate, sleep)
- ✅ Display weekly trends
- ✅ Show AI suggestions
- ✅ Allow source switching
- ✅ Animated live updates

---

## 🎯 What You'll See

1. **Dashboard** with color-coded cards
2. **Source Selector** to switch between sources
3. **Animated Counters** for live updates
4. **Weekly Trends** card
5. **AI Suggestions** card
6. **Backend Integration** button

---

## ⚠️ Note

- HealthKit requires physical device
- Simulator uses mock data automatically
- All features work with mock data for demo

---

**The app is ready to run! 🚀**
