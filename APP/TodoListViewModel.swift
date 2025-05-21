import Foundation
import UIKit
import UserNotifications

// 定义排序方式的枚举
enum SortMethod: String, CaseIterable, Identifiable {
    case byReminder = "按提醒时间排序" // 按提醒时间从早到晚排序
    case byCreation = "按创建时间排序" // 按创建时间从晚到早排序
    
    var id: String { self.rawValue }
}

// 定义归档分类方式的枚举
enum ArchiveGroupMethod: String, CaseIterable, Identifiable {
    case byDate = "按日期分类"
    case byProject = "按项目分类"
    
    var id: String { self.rawValue }
}

// 日期分组项
struct DateGroup: Identifiable {
    var id = UUID()
    var title: String
    var items: [TodoItem]
}

// 项目分组项
struct ProjectGroup: Identifiable {
    var id = UUID()
    var title: String
    var items: [TodoItem]
}

class TodoListViewModel: ObservableObject {
    @Published var items: [TodoItem] = []
    @Published var archivedItems: [TodoItem] = []
    @Published var trashItems: [TodoItem] = [] // 回收站项目
    @Published var sortMethod: SortMethod = .byCreation // 默认按创建时间排序
    @Published var archiveGroupMethod: ArchiveGroupMethod = .byDate // 默认按日期分类
    
    // 分组后的归档项目
    @Published var dateGroups: [DateGroup] = []
    @Published var projectGroups: [ProjectGroup] = []
    
    // 获取唯一的项目属性列表（不包括nil）
    var uniqueProjectAttributes: [String] {
        let allAttributes = (items + archivedItems)
            .compactMap { $0.projectAttribute }
            .filter { !$0.isEmpty }
        
        return Array(Set(allAttributes)).sorted()
    }
    
    private let saveKey = "TodoItems"
    private let archiveKey = "ArchivedTodoItems"
    private let trashKey = "TrashTodoItems" // 回收站存储键
    private let sortMethodKey = "SortMethod"
    private let archiveGroupMethodKey = "ArchiveGroupMethod"
    
    // 定义自动归档的时间间隔（24小时）
    private let archiveTimeInterval: TimeInterval = 24 * 60 * 60
    // 定义回收站项目自动删除的时间间隔（30天）
    private let trashDeleteInterval: TimeInterval = 30 * 24 * 60 * 60
    
    init() {
        loadArchiveGroupMethod()
        loadSortMethod()
        loadItems()
        loadArchivedItems()
        loadTrashItems()
        sortItems()
        groupArchivedItems()
        checkItemsForArchiving()
        cleanupTrashItems() // 清理过期回收站项目
        updateBadgeCount()
    }
    
    // 检查已完成项目是否需要归档
    private func checkItemsForArchiving() {
        let now = Date()
        var itemsToArchive: [TodoItem] = []
        
        // 找出需要归档的项目
        for (index, item) in items.enumerated().reversed() {
            if item.isCompleted, 
               let completedAt = item.completedAt,
               now.timeIntervalSince(completedAt) >= archiveTimeInterval {
                var archivedItem = item
                archivedItem.isArchived = true
                itemsToArchive.append(archivedItem)
                items.remove(at: index)
            }
        }
        
        // 将需要归档的项目添加到归档列表
        if !itemsToArchive.isEmpty {
            archivedItems.append(contentsOf: itemsToArchive)
            saveItems()
            saveArchivedItems()
        }
    }
    
    func addItem(title: String) {
        let item = TodoItem(title: title)
        items.insert(item, at: 0)
        sortItems()
        saveItems()
        updateBadgeCount()
    }
    
    func toggleItem(_ item: TodoItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCompleted.toggle()
            
            // 更新完成时间
            if items[index].isCompleted {
                items[index].completedAt = Date()
                
                // 如果任务完成并且有提醒，则取消提醒
                if items[index].hasNotification {
                    cancelDateReminder(for: items[index])
                }
                
                // 如果任务有项目属性并且需要生成新任务
                if items[index].generatesNewTask, let projectAttribute = items[index].projectAttribute {
                    // 创建新任务，继承项目属性
                    let newTitle = "续: \(items[index].title)"
                    let newTask = TodoItem(
                        title: newTitle,
                        projectAttribute: projectAttribute,
                        generatesNewTask: true
                    )
                    
                    // 添加新任务到列表
                    items.insert(newTask, at: 0)
                    
                    // 发送通知，让UI可以显示设置提醒的对话框
                    NotificationCenter.default.post(
                        name: Notification.Name("ShowReminderForNewTask"),
                        object: newTask.id.uuidString
                    )
                }
            } else {
                items[index].completedAt = nil
            }
            
            sortItems()
            saveItems()
            updateBadgeCount()
            
            // 检查是否有项目需要归档
            checkItemsForArchiving()
        }
    }
    
    func deleteItem(_ item: TodoItem) {
        // 如果有提醒，取消它
        if item.hasNotification {
            cancelDateReminder(for: item)
        }
        
        // 移动到回收站而不是直接删除
        moveToTrash(item)
    }
    
    func deleteArchivedItem(_ item: TodoItem) {
        // 移动到回收站而不是直接删除
        moveToTrash(item)
    }
    
    func restoreFromArchive(_ item: TodoItem) {
        if let index = archivedItems.firstIndex(where: { $0.id == item.id }) {
            var restoredItem = archivedItems[index]
            restoredItem.isArchived = false
            
            // 添加到当前列表
            items.append(restoredItem)
            
            // 从归档中移除
            archivedItems.remove(at: index)
            
            sortItems()
            saveItems()
            saveArchivedItems()
            updateBadgeCount()
        }
    }
    
    func clearArchive() {
        archivedItems.removeAll()
        saveArchivedItems()
    }
    
    // 手动归档项目
    func archiveItem(_ item: TodoItem) {
        // 只归档已完成的项目
        if item.isCompleted {
            // 删除当前列表中的项目
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                var archivedItem = items[index]
                archivedItem.isArchived = true
                
                // 添加到归档列表
                archivedItems.append(archivedItem)
                
                // 从当前列表移除
                items.remove(at: index)
                
                saveItems()
                saveArchivedItems()
                updateBadgeCount()
                
                // 重新分组归档项目
                groupArchivedItems()
            }
        }
    }
    
    func setReminder(for item: TodoItem, at date: Date) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            // 如果已有提醒，先取消
            if items[index].hasNotification {
                cancelDateReminder(for: items[index])
            }
            
            // 更新提醒时间
            items[index].reminderDate = date
            items[index].hasNotification = true
            
            // 创建时间提醒通知
            scheduleDateReminder(for: items[index])
            
            sortItems()
            saveItems()
        }
    }
    
    func cancelReminder(for item: TodoItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            cancelDateReminder(for: items[index])
            
            // 更新项目状态
            items[index].reminderDate = nil
            items[index].hasNotification = false
            
            sortItems()
            saveItems()
        }
    }
    
    // 设置项目属性
    func setProjectAttribute(for item: TodoItem, attribute: String, generatesNewTask: Bool) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].projectAttribute = attribute
            items[index].generatesNewTask = generatesNewTask
            saveItems()
        }
    }
    
    // 移除项目属性
    func removeProjectAttribute(for item: TodoItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].projectAttribute = nil
            items[index].generatesNewTask = false
            saveItems()
        }
    }
    
    func updateItemTitle(_ item: TodoItem, _ newTitle: String) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            // 更新标题
            items[index].title = newTitle
            saveItems()
        }
    }
    
    func moveItem(from source: IndexSet, to destination: Int) {
        // 使用Swift的数组方法移动元素
        items.move(fromOffsets: source, toOffset: destination)
        
        // 保存更改
        saveItems()
    }
    
    // 更改排序方式
    func changeSortMethod(to method: SortMethod) {
        sortMethod = method
        saveSortMethod()
        sortItems()
    }
    
    private func cancelDateReminder(for item: TodoItem) {
        // 移除通知
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [item.id.uuidString]
        )
    }
    
    private func scheduleDateReminder(for item: TodoItem) {
        guard let date = item.reminderDate else { return }
        
        // 创建时间触发器
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = "待办事项提醒"
        content.body = item.title
        content.sound = .default
        content.badge = NSNumber(value: items.filter { !$0.isCompleted }.count)
        
        // 创建通知请求
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        
        // 添加通知请求
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { error in
            if let error = error {
                print("添加通知失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func sortItems() {
        items.sort { (item1, item2) in
            // 先按完成状态排序（未完成的在前）
            if item1.isCompleted != item2.isCompleted {
                return !item1.isCompleted
            }
            
            // 根据选择的排序方式进行排序
            switch sortMethod {
            case .byReminder:
                // 先处理没有提醒时间的项目（放在后面）
                if item1.reminderDate == nil && item2.reminderDate == nil {
                    // 如果都没有提醒时间，则按创建时间排序（新的在前）
                    return item1.createdAt > item2.createdAt
                } else if item1.reminderDate == nil {
                    // 有提醒时间的项目排在前面
                    return false
                } else if item2.reminderDate == nil {
                    // 有提醒时间的项目排在前面
                    return true
                } else {
                    // 按提醒时间从早到晚排序
                    return item1.reminderDate! < item2.reminderDate!
                }
                
            case .byCreation:
                // 按创建时间排序（新的在前）
                return item1.createdAt > item2.createdAt
            }
        }
    }
    
    private func updateBadgeCount() {
        // 更新应用程序图标上的设置了提醒的项目数量
        let reminderCount = items.filter { $0.hasNotification }.count
        
        // 使用新API设置徽章数量
        UNUserNotificationCenter.current().setBadgeCount(reminderCount) { error in
            if let error = error {
                print("设置徽章数量失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func saveArchivedItems() {
        if let encoded = try? JSONEncoder().encode(archivedItems) {
            UserDefaults.standard.set(encoded, forKey: archiveKey)
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            // 确保所有旧项目都有正确的isDeleted标志
            items = decoded.map { item in
                var updatedItem = item
                if updatedItem.isDeleted == nil {
                    updatedItem.isDeleted = false
                }
                return updatedItem
            }
            
            // 重新安排所有未完成的提醒
            for item in items where !item.isCompleted && item.hasNotification {
                if let reminderDate = item.reminderDate {
                    // 重新设置时间提醒
                    if reminderDate > Date() {
                        scheduleDateReminder(for: item)
                    } else {
                        // 如果提醒时间已过，重置提醒状态
                        if let index = items.firstIndex(where: { $0.id == item.id }) {
                            items[index].reminderDate = nil
                            items[index].hasNotification = false
                        }
                    }
                }
            }
            
            // 保存更新后的数据
            saveItems()
        }
    }
    
    private func loadArchivedItems() {
        if let data = UserDefaults.standard.data(forKey: archiveKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            // 确保所有旧项目都有正确的isDeleted标志
            archivedItems = decoded.map { item in
                var updatedItem = item
                if updatedItem.isDeleted == nil {
                    updatedItem.isDeleted = false
                }
                if updatedItem.deletedAt == nil && updatedItem.isDeleted == true {
                    updatedItem.deletedAt = Date()
                }
                return updatedItem
            }
            
            // 保存更新后的数据
            saveArchivedItems()
        }
    }
    
    // 保存排序方式
    private func saveSortMethod() {
        UserDefaults.standard.set(sortMethod.rawValue, forKey: sortMethodKey)
    }
    
    // 加载排序方式
    private func loadSortMethod() {
        if let savedSortMethod = UserDefaults.standard.string(forKey: sortMethodKey),
           let method = SortMethod(rawValue: savedSortMethod) {
            sortMethod = method
        }
    }
    
    // 加载归档分类方式
    private func loadArchiveGroupMethod() {
        if let savedArchiveGroupMethod = UserDefaults.standard.string(forKey: archiveGroupMethodKey),
           let method = ArchiveGroupMethod(rawValue: savedArchiveGroupMethod) {
            archiveGroupMethod = method
        }
    }
    
    // 保存归档分类方式
    private func saveArchiveGroupMethod() {
        UserDefaults.standard.set(archiveGroupMethod.rawValue, forKey: archiveGroupMethodKey)
    }
    
    // 分组归档项目
    private func groupArchivedItems() {
        // 清空现有分组
        dateGroups.removeAll()
        projectGroups.removeAll()
        
        // 按日期分组
        let calendar = Calendar.current
        let nonDeletedArchiveItems = archivedItems.filter { !$0.isDeleted }
        
        if nonDeletedArchiveItems.isEmpty {
            return // 如果没有非删除的归档项目，直接返回
        }
        
        // 按日期分组
        var dateGroupsDict: [String: [TodoItem]] = [:]
        for item in nonDeletedArchiveItems {
            // 使用完成日期或创建日期
            let date = item.completedAt ?? item.createdAt
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            if let date = calendar.date(from: dateComponents) {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                let dateString = formatter.string(from: date)
                
                if dateGroupsDict[dateString] == nil {
                    dateGroupsDict[dateString] = []
                }
                dateGroupsDict[dateString]?.append(item)
            }
        }
        
        // 转换为DateGroup数组并排序
        dateGroups = dateGroupsDict.map { DateGroup(title: $0.key, items: $0.value) }
            .sorted { group1, group2 in
                // 日期较新的组排在前面
                if let date1 = dateFromGroupTitle(group1.title),
                   let date2 = dateFromGroupTitle(group2.title) {
                    return date1 > date2
                }
                return group1.title > group2.title
            }
        
        // 按项目属性分组
        var projectGroupsDict: [String: [TodoItem]] = [:]
        for item in nonDeletedArchiveItems {
            let projectKey = item.projectAttribute ?? "未分类"
            
            if projectGroupsDict[projectKey] == nil {
                projectGroupsDict[projectKey] = []
            }
            projectGroupsDict[projectKey]?.append(item)
        }
        
        // 转换为ProjectGroup数组
        projectGroups = projectGroupsDict.map { ProjectGroup(title: $0.key, items: $0.value) }
            .sorted { $0.title < $1.title } // 按项目名称字母顺序排序
        
        // 将"未分类"放到最后
        if let index = projectGroups.firstIndex(where: { $0.title == "未分类" }) {
            let unclassified = projectGroups.remove(at: index)
            projectGroups.append(unclassified)
        }
    }
    
    // 从组标题中提取日期
    private func dateFromGroupTitle(_ title: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.date(from: title)
    }
    
    // 加载回收站项目
    private func loadTrashItems() {
        if let data = UserDefaults.standard.data(forKey: trashKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            // 确保所有回收站项目都有正确的deletedAt
            trashItems = decoded.map { item in
                var updatedItem = item
                if updatedItem.deletedAt == nil {
                    updatedItem.deletedAt = Date() // 如果没有删除时间，设为当前时间
                }
                return updatedItem
            }
            // 保存更新后的数据
            saveTrashItems()
        }
    }
    
    // 保存回收站项目
    private func saveTrashItems() {
        if let encoded = try? JSONEncoder().encode(trashItems) {
            UserDefaults.standard.set(encoded, forKey: trashKey)
        }
    }
    
    // 清理过期回收站项目
    private func cleanupTrashItems() {
        let now = Date()
        var hasChanges = false
        
        // 找出需要永久删除的项目
        trashItems.removeAll { item in
            if let deletedAt = item.deletedAt,
               now.timeIntervalSince(deletedAt) >= trashDeleteInterval {
                hasChanges = true
                return true
            }
            return false
        }
        
        if hasChanges {
            saveTrashItems()
        }
    }
    
    // 更改归档分类方式
    func changeArchiveGroupMethod(to method: ArchiveGroupMethod) {
        archiveGroupMethod = method
        saveArchiveGroupMethod()
        groupArchivedItems()
    }
    
    // 刷新归档分组
    func refreshArchivedGroups() {
        // 重新加载归档项目和回收站
        loadArchivedItems()
        loadTrashItems()
        
        // 重新分组归档项目
        groupArchivedItems()
        
        // 清理过期回收站项目
        cleanupTrashItems()
    }
    
    // 修改删除方法，移动到回收站
    func moveToTrash(_ item: TodoItem) {
        var trashItem = item
        trashItem.isDeleted = true
        trashItem.deletedAt = Date()
        
        // 从原始列表中移除
        if item.isArchived {
            archivedItems.removeAll { $0.id == item.id }
            saveArchivedItems()
        } else {
            items.removeAll { $0.id == item.id }
            saveItems()
        }
        
        // 添加到回收站
        trashItems.append(trashItem)
        saveTrashItems()
        
        // 重新分组归档项目
        groupArchivedItems()
        updateBadgeCount()
        
        // 通知界面刷新
        objectWillChange.send()
    }
    
    // 从回收站恢复项目
    func restoreFromTrash(_ item: TodoItem) {
        if let index = trashItems.firstIndex(where: { $0.id == item.id }) {
            var restoredItem = trashItems[index]
            restoredItem.isDeleted = false
            restoredItem.deletedAt = nil
            
            // 根据是否归档添加到对应列表
            if restoredItem.isArchived {
                archivedItems.append(restoredItem)
                saveArchivedItems()
            } else {
                items.append(restoredItem)
                sortItems()
                saveItems()
            }
            
            // 从回收站移除
            trashItems.remove(at: index)
            saveTrashItems()
            
            // 重新分组归档项目
            groupArchivedItems()
            updateBadgeCount()
            
            // 通知界面刷新
            objectWillChange.send()
        }
    }
    
    // 永久删除回收站中的项目
    func permanentlyDeleteFromTrash(_ item: TodoItem) {
        trashItems.removeAll { $0.id == item.id }
        saveTrashItems()
        objectWillChange.send()
    }
    
    // 清空回收站
    func emptyTrash() {
        trashItems.removeAll()
        saveTrashItems()
        objectWillChange.send()
    }
} 