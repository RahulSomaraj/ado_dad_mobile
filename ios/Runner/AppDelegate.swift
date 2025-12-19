import Flutter
import UIKit
import PhotosUI
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NSLog("🚀 [iOS] AppDelegate.application didFinishLaunchingWithOptions called")
    
    // FlutterAppDelegate automatically registers plugins via GeneratedPluginRegistrant
    // No manual registration needed
    NSLog("📞 [iOS] Calling super.application...")
    
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    // Register storage platform channel to get documents directory
    // This is needed for file-based storage on iOS
    DispatchQueue.main.async {
      self.registerStorageChannel()
      self.registerImagePickerChannel()
      self.registerUrlLauncherChannel()
      self.registerLocationChannel()
    }
    
    NSLog("✅ [iOS] AppDelegate.application returning: \(result)")
    
    // Check window creation - FlutterAppDelegate should create it
    NSLog("🔍 [iOS] Checking window after super.application...")
    NSLog("🔍 [iOS] self.window: \(String(describing: self.window))")
    NSLog("🔍 [iOS] UIApplication.shared.windows.count: \(UIApplication.shared.windows.count)")
    
    // If window wasn't created, try to create it manually from storyboard
    if self.window == nil {
      NSLog("⚠️ [iOS] No window found - attempting to create from storyboard...")
      
      // Try to load from storyboard
      let storyboard = UIStoryboard(name: "Main", bundle: nil)
      if let flutterVC = storyboard.instantiateInitialViewController() as? FlutterViewController {
        NSLog("✅ [iOS] Created FlutterViewController from storyboard")
        
        // Create window manually
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = flutterVC
        self.window?.makeKeyAndVisible()
        
        NSLog("✅ [iOS] Window created and made key and visible")
      } else {
        NSLog("❌ [iOS] Failed to create FlutterViewController from storyboard")
        NSLog("❌ [iOS] This means Flutter framework is NOT available!")
        NSLog("❌ [iOS] You MUST run 'flutter build ios' or use 'flutter run' first")
      }
    }
    
    // Check if Flutter engine is available
    if let window = self.window {
      NSLog("🪟 [iOS] Window exists: \(window)")
      NSLog("🪟 [iOS] Window frame: \(window.frame)")
      if let rootViewController = window.rootViewController {
        NSLog("🎯 [iOS] Root view controller: \(type(of: rootViewController))")
        if let flutterVC = rootViewController as? FlutterViewController {
          NSLog("✅ [iOS] FlutterViewController found!")
          NSLog("🔧 [iOS] Flutter engine: \(String(describing: flutterVC.engine))")
        } else {
          NSLog("⚠️ [iOS] Root view controller is NOT FlutterViewController, it's: \(type(of: rootViewController))")
        }
      } else {
        NSLog("⚠️ [iOS] No root view controller found in window")
      }
    } else {
      NSLog("❌ [iOS] Window still doesn't exist after manual creation attempt")
      NSLog("❌ [iOS] Flutter framework is NOT properly linked or embedded")
    }
    
    // Add a small delay and check if Flutter main is called
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      NSLog("⏰ [iOS] Checking at 0.5s after launch")
      if let window = self.window {
        NSLog("🪟 [iOS] Window exists at 0.5s")
        if let rootVC = window.rootViewController {
          NSLog("🎯 [iOS] Root VC at 0.5s: \(type(of: rootVC))")
          if let flutterVC = rootVC as? FlutterViewController {
            NSLog("✅ [iOS] FlutterViewController found at 0.5s!")
          }
        } else {
          NSLog("⚠️ [iOS] No root VC at 0.5s")
        }
      } else {
        NSLog("⚠️ [iOS] No window at 0.5s")
      }
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      NSLog("⏰ [iOS] Checking at 2.0s after launch")
      if let window = self.window {
        NSLog("🪟 [iOS] Window exists at 2.0s")
        if let rootVC = window.rootViewController {
          NSLog("🎯 [iOS] Root VC at 2.0s: \(type(of: rootVC))")
        } else {
          NSLog("⚠️ [iOS] No root VC at 2.0s")
        }
      } else {
        NSLog("⚠️ [iOS] No window at 2.0s - Flutter is NOT initializing!")
      }
    }
    
    return result
  }
  
  /// Register storage platform channel to get documents directory
  private func registerStorageChannel() {
    guard let window = self.window,
          let rootVC = window.rootViewController as? FlutterViewController else {
      NSLog("⚠️ [iOS] FlutterViewController not found, retrying storage channel registration...")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.registerStorageChannel()
      }
      return
    }
    
    let channel = FlutterMethodChannel(
      name: "com.ado_dad_user/storage",
      binaryMessenger: rootVC.binaryMessenger
    )
    
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getDocumentsDirectory" {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""
        NSLog("📁 [iOS Storage] Documents directory: \(documentsPath)")
        result(documentsPath)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    NSLog("✅ [iOS] Storage platform channel registered successfully")
  }
  
  /// Register native image picker channel (bypasses pigeon channel issues)
  private func registerImagePickerChannel() {
    guard let window = self.window,
          let rootVC = window.rootViewController as? FlutterViewController else {
      NSLog("⚠️ [iOS] FlutterViewController not found, retrying image picker channel registration...")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.registerImagePickerChannel()
      }
      return
    }
    
    let channel = FlutterMethodChannel(
      name: "com.ado_dad_user/image_picker",
      binaryMessenger: rootVC.binaryMessenger
    )
    
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "pickImage" {
        self?.pickImage(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    NSLog("✅ [iOS] Native image picker channel registered successfully")
  }
  
  /// Register native URL launcher channel (bypasses pigeon channel issues)
  private func registerUrlLauncherChannel() {
    guard let window = self.window,
          let rootVC = window.rootViewController as? FlutterViewController else {
      NSLog("⚠️ [iOS] FlutterViewController not found, retrying URL launcher channel registration...")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.registerUrlLauncherChannel()
      }
      return
    }
    
    let channel = FlutterMethodChannel(
      name: "com.ado_dad_user/url_launcher",
      binaryMessenger: rootVC.binaryMessenger
    )
    
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "launchUrl" {
        guard let urlString = call.arguments as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "URL string is required", details: nil))
          return
        }
        
        NSLog("🔗 [iOS URL Launcher] Attempting to open URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
          NSLog("❌ [iOS URL Launcher] Invalid URL: \(urlString)")
          result(FlutterError(code: "INVALID_URL", message: "Invalid URL format", details: nil))
          return
        }
        
        DispatchQueue.main.async {
          if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
              if success {
                NSLog("✅ [iOS URL Launcher] URL opened successfully")
                result(true)
              } else {
                NSLog("❌ [iOS URL Launcher] Failed to open URL")
                result(FlutterError(code: "LAUNCH_FAILED", message: "Failed to open URL", details: nil))
              }
            }
          } else {
            NSLog("❌ [iOS URL Launcher] Cannot open URL: \(urlString)")
            result(FlutterError(code: "CANNOT_OPEN", message: "Cannot open this URL", details: nil))
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    NSLog("✅ [iOS] Native URL launcher channel registered successfully")
  }
  
  /// Register native location permission channel (bypasses pigeon channel issues)
  private func registerLocationChannel() {
    guard let window = self.window,
          let rootVC = window.rootViewController as? FlutterViewController else {
      NSLog("⚠️ [iOS] FlutterViewController not found, retrying location channel registration...")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.registerLocationChannel()
      }
      return
    }
    
    let channel = FlutterMethodChannel(
      name: "com.ado_dad_user/location",
      binaryMessenger: rootVC.binaryMessenger
    )
    
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "requestPermission" {
        self?.requestLocationPermission(result: result)
      } else if call.method == "checkPermission" {
        self?.checkLocationPermission(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    NSLog("✅ [iOS] Native location channel registered successfully")
  }
  
  // Store location manager to prevent deallocation
  private var locationManager: CLLocationManager?
  private var locationPermissionResult: FlutterResult?
  
  /// Request location permission using native CLLocationManager
  private func requestLocationPermission(result: @escaping FlutterResult) {
    NSLog("📍 [iOS Location] Requesting location permission...")
    
    // Check authorization status first
    let status = CLLocationManager.authorizationStatus()
    
    if status == .authorizedWhenInUse || status == .authorizedAlways {
      NSLog("📍 [iOS Location] Permission already granted: \(status.rawValue)")
      result("granted")
      return
    }
    
    if status == .denied || status == .restricted {
      NSLog("📍 [iOS Location] Permission denied or restricted: \(status.rawValue)")
      result("denied")
      return
    }
    
    // Create location manager and request permission
    let manager = CLLocationManager()
    manager.delegate = self
    self.locationManager = manager
    self.locationPermissionResult = result
    
    // Request when-in-use authorization
    manager.requestWhenInUseAuthorization()
    
    NSLog("📍 [iOS Location] Permission request sent to user")
  }
  
  /// Check current location permission status
  private func checkLocationPermission(result: @escaping FlutterResult) {
    let status = CLLocationManager.authorizationStatus()
    
    switch status {
    case .notDetermined:
      result("notDetermined")
    case .restricted:
      result("restricted")
    case .denied:
      result("denied")
    case .authorizedWhenInUse, .authorizedAlways:
      result("granted")
    @unknown default:
      result("notDetermined")
    }
    
    NSLog("📍 [iOS Location] Permission status: \(status.rawValue)")
  }
  
  // Store delegate to prevent deallocation
  private var imagePickerDelegate: Any?
  private var imagePickerDelegateLegacy: Any?
  
  /// Native image picker using PHPickerViewController (iOS 14+)
  private func pickImage(result: @escaping FlutterResult) {
    guard let window = self.window,
          let rootVC = window.rootViewController else {
      DispatchQueue.main.async {
        result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller available", details: nil))
      }
      return
    }
    
    NSLog("📸 [iOS] Starting image picker...")
    
    if #available(iOS 14.0, *) {
      var configuration = PHPickerConfiguration()
      configuration.filter = .images
      configuration.selectionLimit = 1
      
      let picker = PHPickerViewController(configuration: configuration)
      let delegate = ImagePickerDelegate(result: result)
      picker.delegate = delegate
      
      // Retain delegate to prevent deallocation
      self.imagePickerDelegate = delegate
      
      // Make it dismissible
      picker.modalPresentationStyle = .pageSheet
      if #available(iOS 15.0, *) {
        if let sheet = picker.sheetPresentationController {
          sheet.detents = [.large()]
          sheet.prefersGrabberVisible = true
        }
      }
      
      DispatchQueue.main.async {
        rootVC.present(picker, animated: true) {
          NSLog("✅ [iOS] Image picker presented")
        }
      }
    } else {
      // Fallback to UIImagePickerController for iOS 13 and below
      let picker = UIImagePickerController()
      picker.sourceType = .photoLibrary
      let delegate = ImagePickerDelegateLegacy(result: result)
      picker.delegate = delegate
      
      // Retain delegate to prevent deallocation
      self.imagePickerDelegateLegacy = delegate
      
      DispatchQueue.main.async {
        rootVC.present(picker, animated: true)
      }
    }
  }
}

// MARK: - PHPickerViewControllerDelegate (iOS 14+)
@available(iOS 14.0, *)
class ImagePickerDelegate: NSObject, PHPickerViewControllerDelegate {
  private let result: FlutterResult
  private var hasCalledResult = false
  
  init(result: @escaping FlutterResult) {
    self.result = result
    super.init()
  }
  
  private func callResultOnce(_ value: Any?) {
    guard !hasCalledResult else {
      NSLog("⚠️ [iOS] Result already called, ignoring")
      return
    }
    hasCalledResult = true
    result(value)
  }
  
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    NSLog("📸 [iOS] didFinishPicking called with \(results.count) results")
    
    // Dismiss picker immediately
    picker.dismiss(animated: true) {
      NSLog("✅ [iOS] Picker dismissed")
    }
    
    // Check if user cancelled (empty results)
    if results.isEmpty {
      NSLog("📸 [iOS] User cancelled (empty results)")
      DispatchQueue.main.async {
        self.callResultOnce(nil) // User cancelled
      }
      return
    }
    
    guard let itemProvider = results.first?.itemProvider else {
      NSLog("📸 [iOS] User cancelled (no itemProvider)")
      DispatchQueue.main.async {
        self.callResultOnce(nil) // User cancelled
      }
      return
    }
    
    NSLog("📸 [iOS] Image selected, processing...")
    
    if itemProvider.canLoadObject(ofClass: UIImage.self) {
      itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
        guard let self = self else {
          NSLog("❌ [iOS] ImagePickerDelegate deallocated")
          return
        }
        
        if let error = error {
          NSLog("❌ [iOS] Error loading image: \(error.localizedDescription)")
          DispatchQueue.main.async {
            self.callResultOnce(FlutterError(code: "LOAD_ERROR", message: error.localizedDescription, details: nil))
          }
          return
        }
        
        guard let uiImage = image as? UIImage else {
          NSLog("❌ [iOS] Failed to cast to UIImage")
          DispatchQueue.main.async {
            self.callResultOnce(FlutterError(code: "INVALID_IMAGE", message: "Failed to load image", details: nil))
          }
          return
        }
        
        NSLog("📸 [iOS] Image loaded, converting to JPEG...")
        
        // Resize image if needed (max 1200px width)
        let maxWidth: CGFloat = 1200
        let resizedImage: UIImage
        if uiImage.size.width > maxWidth {
          let scale = maxWidth / uiImage.size.width
          let newHeight = uiImage.size.height * scale
          let newSize = CGSize(width: maxWidth, height: newHeight)
          
          UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
          uiImage.draw(in: CGRect(origin: .zero, size: newSize))
          resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? uiImage
          UIGraphicsEndImageContext()
        } else {
          resizedImage = uiImage
        }
        
        // Convert UIImage to JPEG data
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.88) else {
          NSLog("❌ [iOS] Failed to convert image to JPEG")
          DispatchQueue.main.async {
            self.callResultOnce(FlutterError(code: "CONVERSION_ERROR", message: "Failed to convert image to data", details: nil))
          }
          return
        }
        
        NSLog("📸 [iOS] Image converted, saving to temp file...")
        
        // Save to temporary directory and return path
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "picked_image_\(Date().timeIntervalSince1970).jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
          try imageData.write(to: fileURL)
          NSLog("✅ [iOS] Image saved to: \(fileURL.path)")
          DispatchQueue.main.async {
            self.callResultOnce(fileURL.path)
          }
        } catch {
          NSLog("❌ [iOS] Error saving image: \(error.localizedDescription)")
          DispatchQueue.main.async {
            self.callResultOnce(FlutterError(code: "SAVE_ERROR", message: error.localizedDescription, details: nil))
          }
        }
      }
    } else {
      NSLog("❌ [iOS] Cannot load UIImage from itemProvider")
      DispatchQueue.main.async {
        self.callResultOnce(FlutterError(code: "UNSUPPORTED_TYPE", message: "Cannot load image", details: nil))
      }
    }
  }
}

// MARK: - UIImagePickerControllerDelegate (iOS 13 and below)
class ImagePickerDelegateLegacy: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  private let result: FlutterResult
  
  init(result: @escaping FlutterResult) {
    self.result = result
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true)
    
    guard let uiImage = info[.originalImage] as? UIImage else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Failed to get image", details: nil))
      return
    }
    
    // Convert UIImage to JPEG data
    guard let imageData = uiImage.jpegData(compressionQuality: 0.88) else {
      result(FlutterError(code: "CONVERSION_ERROR", message: "Failed to convert image to data", details: nil))
      return
    }
    
    // Save to temporary directory and return path
    let tempDir = FileManager.default.temporaryDirectory
    let fileName = "picked_image_\(Date().timeIntervalSince1970).jpg"
    let fileURL = tempDir.appendingPathComponent(fileName)
    
    do {
      try imageData.write(to: fileURL)
      result(fileURL.path)
    } catch {
      result(FlutterError(code: "SAVE_ERROR", message: error.localizedDescription, details: nil))
    }
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    result(nil) // User cancelled
  }
}
// MARK: - CLLocationManagerDelegate
extension AppDelegate: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    NSLog("📍 [iOS Location] Authorization status changed: \(status.rawValue)")
    
    guard let result = locationPermissionResult else {
      return
    }
    
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      NSLog("✅ [iOS Location] Permission granted")
      result("granted")
    case .denied, .restricted:
      NSLog("❌ [iOS Location] Permission denied")
      result("denied")
    case .notDetermined:
      // Still waiting for user response
      return
    @unknown default:
      result("denied")
    }
    
    // Clear the result handler
    locationPermissionResult = nil
    locationManager = nil
  }
}

