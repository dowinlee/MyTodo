import Foundation

struct TodoItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var isArchived: Bool
    var reminderDate: Date?
    var hasNotification: Bool
    var projectAttribute: String?
    var generatesNewTask: Bool
    var isDeleted: Bool
    var deletedAt: Date?
    
    init(title: String, isCompleted: Bool = false, reminderDate: Date? = nil, projectAttribute: String? = nil, generatesNewTask: Bool = false) {
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.completedAt = isCompleted ? Date() : nil
        self.isArchived = false
        self.reminderDate = reminderDate
        self.hasNotification = reminderDate != nil
        self.projectAttribute = projectAttribute
        self.generatesNewTask = generatesNewTask
        self.isDeleted = false
        self.deletedAt = nil
    }
} 