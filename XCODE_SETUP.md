# iOS SDK Project Setup Instructions

## 🔧 Adding SupportHomeViewController to Xcode Project

The `SupportHomeViewController.swift` file was created but needs to be properly added to the Xcode project to resolve the compilation error.

## 📋 **Step-by-Step Instructions**

### **1. Open Xcode Project**
```bash
cd "/Users/superman41/Drive/AI/Widget Mobile SDK/ios-sdk/Example"
open YourGPTExample.xcodeproj
```

### **2. Add SupportHomeViewController to Project**

#### **Method A: Using Xcode GUI (Recommended)**
1. **Right-click** on the `YourGPTExample` folder in Xcode's Project Navigator
2. Select **"Add Files to 'YourGPTExample'..."**
3. Navigate to: `/Users/superman41/Drive/AI/Widget Mobile SDK/ios-sdk/Example/YourGPTExample/`
4. Select **`SupportHomeViewController.swift`**
5. Make sure these options are selected:
   - ✅ **"Add to target: YourGPTExample"**
   - ✅ **"Copy items if needed"** (if prompted)
6. Click **"Add"**

#### **Method B: Drag and Drop**
1. Open **Finder** and navigate to: `/Users/superman41/Drive/AI/Widget Mobile SDK/ios-sdk/Example/YourGPTExample/`
2. **Drag** `SupportHomeViewController.swift` into Xcode's Project Navigator
3. Drop it in the `YourGPTExample` folder
4. In the dialog that appears:
   - ✅ **"Copy items if needed"**
   - ✅ **"Add to target: YourGPTExample"**
5. Click **"Finish"**

### **3. Verify File Addition**
After adding the file, you should see:
- ✅ `SupportHomeViewController.swift` appears in Project Navigator
- ✅ File has YourGPTExample target membership
- ✅ No compilation errors when building

### **4. Update SceneDelegate (After Adding File)**
Once the file is added to the project, update `SceneDelegate.swift`:

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    window = UIWindow(windowScene: windowScene)
    
    let mainViewController: UIViewController
    if #available(iOS 13.0, *) {
        mainViewController = SupportHomeViewController()
    } else {
        mainViewController = ViewController()
    }
    
    let navigationController = UINavigationController(rootViewController: mainViewController)
    
    window?.rootViewController = navigationController
    window?.makeKeyAndVisible()
}
```

### **5. Build and Run**
1. **Clean Build Folder**: `Cmd + Shift + K`
2. **Build**: `Cmd + B`
3. **Run**: `Cmd + R`

## 🎯 **Expected Results**

After successful setup, you should see:

### **🏠 Support Home Screen**
- Professional iOS support interface
- Real-time SDK status card
- Quick action buttons (Chat, Email, Call, Search)
- FAQ section with support questions
- Modern iOS design with proper styling

### **💬 Enhanced Chat Experience**
- Tap "Chat" when status shows "✅ AI Assistant Ready"
- Modern sheet presentation (not full-screen)
- Close button (X) in top-right corner
- Automatic data injection (session, visitor, contact data)
- Enhanced event logging in console

## 🐛 **Troubleshooting**

### **Issue: File Not Found in Project**
**Solution**: Make sure file is added to the correct target
1. Select `SupportHomeViewController.swift` in Project Navigator
2. Check **Target Membership** in File Inspector (right panel)
3. Ensure **YourGPTExample** is checked

### **Issue: Build Errors After Adding File**
**Solution**: Clean and rebuild
1. `Product` → `Clean Build Folder`
2. `Product` → `Build`
3. Check for any import errors or missing dependencies

### **Issue: Runtime Crash**
**Solution**: Check iOS version availability
- `SupportHomeViewController` requires iOS 13.0+
- Falls back to original `ViewController` on older versions

## 📁 **File Locations**

### **Source File Location**
```
/Users/superman41/Drive/AI/Widget Mobile SDK/ios-sdk/Example/YourGPTExample/SupportHomeViewController.swift
```

### **Target Project Structure**
```
YourGPTExample/
├── AppDelegate.swift
├── SceneDelegate.swift
├── ViewController.swift
├── SupportHomeViewController.swift  ← Add this file
├── Main.storyboard
├── LaunchScreen.storyboard
├── Assets.xcassets/
└── Info.plist
```

## ✅ **Verification Checklist**

After completing setup:
- [ ] `SupportHomeViewController.swift` appears in Xcode Project Navigator
- [ ] File has YourGPTExample target membership
- [ ] Project builds without errors (`Cmd + B`)
- [ ] App launches with new support home screen
- [ ] SDK status card shows connection state
- [ ] Chat button works when SDK is ready
- [ ] Sheet presentation with X close button works

## 🚀 **Benefits After Setup**

### **Professional UI**
- Modern iOS support app interface
- Real SDK status monitoring
- Intuitive navigation and interactions

### **Enhanced Development**
- Rich demo data for testing
- Mobile-specific event logging
- Proper data injection examples

### **Better User Experience**
- Sheet-style modal presentation
- Clear status feedback
- Professional iOS design patterns

---

**Once you've added the file to the Xcode project, the iOS SDK will provide a complete professional support experience with modern iOS design patterns and mobile-specific functionality!**