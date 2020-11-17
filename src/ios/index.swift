import Foundation
import NotificationCenter
import UIKit

// 包裝 swift 為 obj-c 格式
// 實作以下功能:
// 1. 開啟隱私模式 EnablePrivacyScreen
// 2. 關閉隱私模式 DisablePrivacyScreen
// 3. 註冊監聽程序
// 4. 開放自訂圖片路徑傳入 ( 本地路徑 跟 遠端路徑 )
// * 預設為模糊圖層

@objc(PrivacyScreen)
class PrivacyScreen : CDVPlugin {
    
    var window: UIWindow?            // iOS 13 支援 windowScene 層
    var appSwitcherView: UIView?   // iOS 13 以下以新圖層覆蓋
    var enable: Bool = true             // 隱私保護開關
    var imgFromApp: UIImage?       // 來自 App 端的圖片資源
    let dataURLPattern = try! NSRegularExpression(pattern: "^data:.+?;base64,", options: NSRegularExpression.Options(rawValue: 0))

    private func subscribe() {
        NSLog("SubscribePrivacyScreen")
        // 進入後台背景
        // NotificationCenter.default.addObserver(self, selector: #selector(onAppDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        // 進入非活躍狀態
        NotificationCenter.default.addObserver(self, selector: #selector(onAppWillResignActive), name: .UIApplicationWillResignActive, object: nil)
        // 進入活躍狀態
        NotificationCenter.default.addObserver(self, selector: #selector(onAppDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        // 將要進入前台
        // NotificationCenter.default.addObserver(self, selector: #selector(onAppWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    @objc private func onAppDidEnterBackground() {
        NSLog("將要進入後台")
    }
    
    @objc private func onAppWillResignActive() {
        NSLog("進入非活躍狀態")
        showPrivacyProtectionWindow()
    }
    
    @objc private func onAppDidBecomeActive() {
        NSLog("進入活躍狀態")
        hidePrivacyProtectionWindow()
    }
    
    @objc private func onAppWillEnterForeground() {
        NSLog("將要進入前台")
    }

    @objc(SetPrivacyScreen:) func SetPrivacyScreen (command: CDVInvokedUrlCommand) {
        NSLog("PrivacyScreen#SetPrivacyScreen()")
        let imgUrl = command.arguments[0] as? String

        var sourceData: Data
        do {
            sourceData = try getDataFromURL(imgUrl!)
            imgFromApp = UIImage(data: sourceData)
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "success set privacy screen image")
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        } catch {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "failed set privacy screen image")
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            return
        }
    }
    
    @objc(SubscribePrivacyScreen:) func SubscribePrivacyScreen (command: CDVInvokedUrlCommand) {
        subscribe()
        NSLog("PrivacyScreen#SubscribePrivacyScreen()")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "success subscribe privacy screen service")
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(EnablePrivacyScreen:) func EnablePrivacyScreen (command: CDVInvokedUrlCommand) {
        NSLog("PrivacyScreen#EnablePrivacyScreen()")
        enable = true
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "success enable privacy screen service")
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(DisablePrivacyScreen:) func DisablePrivacyScreen (command: CDVInvokedUrlCommand) {
        NSLog("PrivacyScreen#DisablePrivacyScreen()")
        enable = false
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "success disable privacy screen service")
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }
    
    fileprivate func getDataFromURL(_ url: String) throws -> Data {
            if url.hasPrefix("data:") {

                guard let match = self.dataURLPattern.firstMatch(in: url, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, url.characters.count)) else { // TODO: firstMatchInString seems to be slow for unknown reason
                    throw PrivacyScreenError.error(description: "The dataURL could not be parsed")
                }
                let dataPos = match.range(at: 0).length
                let base64 = (url as NSString).substring(from: dataPos)
                guard let decoded = Data(base64Encoded: base64, options: NSData.Base64DecodingOptions(rawValue: 0)) else {
                    throw PrivacyScreenError.error(description: "The dataURL could not be decoded")
                }

                return decoded

            } else {
                // 本地圖檔走這兒
                guard let nsURL = URL(string: url) else {
                    throw PrivacyScreenError.error(description: "The url could not be decoded: \(url)")
                }
                guard let fileContent = try? Data(contentsOf: nsURL) else {
                    throw PrivacyScreenError.error(description: "The url could not be read: \(url)")
                }

                return fileContent

            }
        }
    
    // MARK: Privacy Protection
    private var privacyProtectionWindow: UIWindow?

    private func showPrivacyProtectionWindow() {
        print(enable)
        if (!enable) {
            return
        }
       
        if (imgFromApp?.imageAsset == nil) {
            let blurredImage = applyGaussianBlur(on: createScreenshotOfCurrentContext() ?? UIImage(), withBlurFactor: 4.5)
            appSwitcherView = UIImageView(image: blurredImage)
            if #available(iOS 13.0, *) {
                guard let windowScene = self.viewController.view.window?.windowScene else {
                    return
                }
                privacyProtectionWindow = UIWindow(windowScene: windowScene)
                let controller = PrivacyProtectionViewController()
                controller.view.addSubview(appSwitcherView!)
                privacyProtectionWindow?.rootViewController = controller
                privacyProtectionWindow?.windowLevel = UIWindowLevelAlert + 1
                privacyProtectionWindow?.makeKeyAndVisible()
            } else {
                self.viewController.view.window?.addSubview(appSwitcherView!)
            }
            
        } else {

            let dataImageView = UIImageView(image: imgFromApp)
            let screenSize: CGRect = UIScreen.main.bounds
            let screenWidth = screenSize.width
            let screenHeight = screenSize.height
            dataImageView.backgroundColor = .white
            dataImageView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
            dataImageView.contentMode = .scaleAspectFit
            appSwitcherView = dataImageView
            if #available(iOS 13.0, *) {
                guard let windowScene = self.viewController.view.window?.windowScene else {
                    return
                }
                privacyProtectionWindow = UIWindow(windowScene: windowScene)
                let controller = PrivacyProtectionViewController()
                controller.view.addSubview(dataImageView)
                privacyProtectionWindow?.rootViewController = controller
                privacyProtectionWindow?.windowLevel = UIWindowLevelAlert + 1
                privacyProtectionWindow?.makeKeyAndVisible()
            } else {
                self.viewController.view.window?.addSubview(appSwitcherView!)
            }
        }
}

    private func hidePrivacyProtectionWindow() {
        if #available(iOS 13.0, *) {
            privacyProtectionWindow?.isHidden = true
            privacyProtectionWindow = nil
        } else {
            appSwitcherView?.removeFromSuperview()
        }
    }
    
    private func createScreenshotOfCurrentContext() -> UIImage? {
        UIGraphicsBeginImageContext(self.viewController.view.window?.screen.bounds.size ?? CGSize())
        guard let currentContext = UIGraphicsGetCurrentContext() else {
            return nil
        }
            
        self.viewController.view.window?.layer.render(in: currentContext)
            
        let image = UIGraphicsGetImageFromCurrentImageContext()
            
        UIGraphicsEndImageContext()
            
        return image
    }
    
    private func applyGaussianBlur(on image: UIImage, withBlurFactor blurFactor : CGFloat) -> UIImage? {
        guard let inputImage = CIImage(image: image) else {
            return nil
        }
            
        // Add a comment where to find documentation for that
        let gaussianFilter = CIFilter(name: "CIGaussianBlur")
            gaussianFilter?.setValue(inputImage, forKey: kCIInputImageKey)
            gaussianFilter?.setValue(blurFactor, forKey: kCIInputRadiusKey)
            
        guard let outputImage = gaussianFilter?.outputImage else {
            return nil
        }
            
        return UIImage(ciImage: outputImage)
    }
}

/// iOS 13 windowScene 解法
class PrivacyProtectionViewController: UITableViewController {

    init() {
        super.init(style: .grouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum PrivacyScreenError: Error, CustomStringConvertible {
    case error(description: String)

    var description: String {
        switch self {
        case .error(let description): return description
        }
    }
}
