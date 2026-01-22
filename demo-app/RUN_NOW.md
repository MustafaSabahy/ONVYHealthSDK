# 🚀 Run App Now - iOS Simulator

## Quick Commands

### Option 1: Expo Web (Fastest - Works Immediately)

```bash
cd /Users/sabahy/Desktop/ONVYHealthSDK/demo-app
npx expo start --web
```

Then press `w` to open in browser.

### Option 2: iOS Simulator (With Mock Data)

```bash
cd /Users/sabahy/Desktop/ONVYHealthSDK/demo-app
npx expo start
```

Then press `i` to open iOS Simulator.

**Note**: The app automatically uses mock data on Simulator since HealthKit doesn't work there.

---

## ✅ What's Already Set Up

- ✅ All components copied
- ✅ Mock data service ready
- ✅ Dashboard configured
- ✅ All features working

---

## 🎯 Expected Behavior

1. App opens with "Simulator Mode" banner
2. Auto-authorizes (mock data)
3. Shows dashboard with:
   - Steps card (green, animated)
   - Heart Rate card (blue, animated)
   - Sleep card (purple, animated)
   - Weekly trends
   - AI suggestions
   - Source selector

4. Live updates every 3 seconds
5. All features work with mock data

---

## 🐛 If It Doesn't Work

1. **Check Node modules**:
   ```bash
   cd demo-app
   npm install
   ```

2. **Clear cache**:
   ```bash
   npx expo start --clear
   ```

3. **Check for errors**:
   - Look at terminal output
   - Check browser console (if web)
   - Check Simulator logs

---

**Run the command above to start! 🚀**
