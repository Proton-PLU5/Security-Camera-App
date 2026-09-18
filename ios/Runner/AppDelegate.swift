import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let galleryChannel = FlutterMethodChannel(
      name: "camera_application/gallery",
      binaryMessenger: engineBridge.binaryMessenger
    )
    galleryChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "saveImageToGallery":
        guard let arguments = call.arguments as? [String: Any],
              let typedBytes = arguments["bytes"] as? FlutterStandardTypedData,
              let image = UIImage(data: typedBytes.data) else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Image bytes are required", details: nil))
          return
        }
        self.saveImageToPhotos(image: image, result: result)

      case "openImageInPhotos":
        guard let url = URL(string: "photos-redirect://") else {
          result(FlutterError(code: "GALLERY_OPEN_FAILED", message: "Photos URL is unavailable", details: nil))
          return
        }
        UIApplication.shared.open(url) { opened in
          opened ? result(nil) : result(FlutterError(code: "GALLERY_OPEN_FAILED", message: "Could not open Photos", details: nil))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func saveImageToPhotos(image: UIImage, result: @escaping FlutterResult) {
    let save: () -> Void = {
      var assetIdentifier: String?
      PHPhotoLibrary.shared().performChanges({
        let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
        assetIdentifier = request.placeholderForCreatedAsset?.localIdentifier
      }) { success, error in
        DispatchQueue.main.async {
          if success, let assetIdentifier {
            result("photos-asset://\(assetIdentifier)")
          } else {
            result(FlutterError(code: "GALLERY_SAVE_FAILED", message: error?.localizedDescription, details: nil))
          }
        }
      }
    }

    let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    if status == .authorized || status == .limited {
      save()
    } else {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
        DispatchQueue.main.async {
          if newStatus == .authorized || newStatus == .limited {
            save()
          } else {
            result(FlutterError(code: "GALLERY_PERMISSION_DENIED", message: "Photos permission was denied", details: nil))
          }
        }
      }
    }
  }
}
