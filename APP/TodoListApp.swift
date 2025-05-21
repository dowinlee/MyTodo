import SwiftUI
import UserNotifications
import BackgroundTasks

@main
struct TodoListApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // 当应用变为活跃状态时更新图标徽章
                    updateBadgeCount()
                }
        }
    }
    
    // 更新图标徽章的函数
    private func updateBadgeCount() {
        if let data = UserDefaults.standard.data(forKey: "TodoItems"),
           let items = try? JSONDecoder().decode([TodoItem].self, from: data) {
            let reminderCount = items.filter { $0.hasNotification }.count
            
            // 使用新API设置徽章数量
            UNUserNotificationCenter.current().setBadgeCount(reminderCount) { error in
                if let error = error {
                    print("设置徽章数量失败: \(error.localizedDescription)")
                }
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 请求通知权限，包括警报、声音和徽章
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知权限获取成功")
            } else if let error = error {
                print("通知权限获取失败: \(error.localizedDescription)")
            }
        }
        
        // 设置通知中心代理
        notificationCenter.delegate = self
        
        // 如果从通知启动应用，处理它
        if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject],
           let itemId = notification["itemId"] as? String {
            handleNotificationWithItemId(itemId)
        }
        
        return true
    }
    
    // 获取当前的keyWindow，兼容iOS 15及以上版本
    static func getKeyWindow() -> UIWindow? {
        if #available(iOS 15.0, *) {
            // iOS 15以上用windowScene.windows方法
            return UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first(where: { $0 is UIWindowScene })
                .flatMap({ $0 as? UIWindowScene })?.windows
                .first(where: { $0.isKeyWindow })
        } else {
            // iOS 15以下使用旧方法
            return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        }
    }
    
    // 处理应用程序从后台恢复到前台时的行为
    func applicationWillEnterForeground(_ application: UIApplication) {
        // 当应用即将进入前台时更新图标徽章
        updateBadgeCount()
    }
    
    // 在应用处于前台时也显示通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // 处理用户点击通知的事件
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 检查通知中的项目ID
        let userInfo = response.notification.request.content.userInfo
        if let itemId = userInfo["itemId"] as? String {
            handleNotificationWithItemId(itemId)
        }
        completionHandler()
    }
    
    // 处理包含项目ID的通知
    private func handleNotificationWithItemId(_ itemId: String) {
        // 这里可以处理特定项目的通知
        // 例如，导航到特定的项目等
        print("处理项目通知: \(itemId)")
    }
    
    // 更新图标徽章的函数
    private func updateBadgeCount() {
        if let data = UserDefaults.standard.data(forKey: "TodoItems"),
           let items = try? JSONDecoder().decode([TodoItem].self, from: data) {
            let reminderCount = items.filter { $0.hasNotification }.count
            
            // 使用新API设置徽章数量
            UNUserNotificationCenter.current().setBadgeCount(reminderCount) { error in
                if let error = error {
                    print("设置徽章数量失败: \(error.localizedDescription)")
                }
            }
        }
    }
} 
