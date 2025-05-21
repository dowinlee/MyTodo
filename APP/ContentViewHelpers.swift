import SwiftUI

// TodoListView的辅助视图和方法
extension TodoListView {
    // 为新创建的任务设置提醒的视图
    var newTaskReminderPickerView: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("为新任务设置提醒时间")
                    .font(.headline)
                    .padding(.top)
                
                // 日期时间选择器
                DatePicker(
                    "选择提醒时间",
                    selection: $selectedReminderDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding()
                
                // 快捷选择按钮
                Text("快速设置")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 20) {
                    quickSetButton(minutes: 5)
                    quickSetButton(minutes: 15)
                    quickSetButton(minutes: 30)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                Spacer()
            }
            .navigationTitle("设置新任务提醒")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("稍后设置") {
                        showReminderPicker = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        if let taskId = showingReminderForNewTaskId, 
                           let item = viewModel.items.first(where: { $0.id.uuidString == taskId }) {
                            viewModel.setReminder(for: item, at: selectedReminderDate)
                        }
                        showReminderPicker = false
                    }
                }
            }
        }
    }
    
    // 快速设置按钮
    func quickSetButton(minutes: Int) -> some View {
        Button(action: {
            selectedReminderDate = Date().addingTimeInterval(Double(minutes * 60))
        }) {
            VStack {
                Text("\(minutes)")
                    .font(.headline)
                Text("分钟")
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    // 简化的TodoItemRow
    func todoItemRow(_ item: TodoItem) -> some View {
        Group {
            if #available(iOS 15.0, *) {
                // iOS 15+ 支持拖拽
                draggableTodoRow(item)
            } else {
                // 旧版iOS不支持拖拽
                simpleTodoRow(item)
            }
        }
    }
    
    // iOS 15+ 支持拖拽的行
    @available(iOS 15.0, *)
    func draggableTodoRow(_ item: TodoItem) -> some View {
        simpleTodoRow(item)
            .draggable(item.id.uuidString) {
                Text(item.title)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
    }
    
    // 基础行视图
    func simpleTodoRow(_ item: TodoItem) -> some View {
        HStack {
            Button(action: { 
                viewModel.toggleItem(item) 
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            ItemTitleView(
                item: item,
                onUpdate: { viewModel.updateItemTitle(item, $0) }
            )
            
            Spacer()
            
            if item.isCompleted, let completedAt = item.completedAt {
                Text(formatRelativeTime(completedAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // 提醒按钮 - 仅在项目未完成时显示
            if !item.isCompleted {
                ReminderButton(
                    item: item,
                    onSetReminder: { date in viewModel.setReminder(for: item, at: date) },
                    onCancelReminder: { viewModel.cancelReminder(for: item) }
                )
                
                // 项目属性按钮 - 仅在项目未完成时显示
                ProjectAttributeButton(
                    item: item,
                    onSetProjectAttribute: { attribute, generatesNewTask in 
                        viewModel.setProjectAttribute(for: item, attribute: attribute, generatesNewTask: generatesNewTask) 
                    },
                    onRemoveProjectAttribute: { viewModel.removeProjectAttribute(for: item) }
                )
                .environmentObject(viewModel)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // 确保整行都可点击
    }
    
    // 简化的时间格式化
    func formatRelativeTime(_ date: Date) -> String {
        let hours = Int(Date().timeIntervalSince(date) / 3600)
        if hours < 24 {
            return "约\(24 - hours)小时后归档"
        } else {
            return "即将归档"
        }
    }
}

// 提醒按钮组件
struct ReminderButton: View {
    let item: TodoItem
    let onSetReminder: (Date) -> Void
    let onCancelReminder: () -> Void
    
    @State var showingDatePicker = false
    @State var selectedDate = Date()
    
    var body: some View {
        Image(systemName: item.hasNotification ? "bell.fill" : "bell")
            .foregroundColor(item.hasNotification ? .accentColor : .gray)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            // 单击打开设置界面
            .onTapGesture {
                selectedDate = Date().addingTimeInterval(3600) // 默认1小时后
                showingDatePicker = true
            }
            // 双击取消提醒
            .onTapGesture(count: 2) {
                if item.hasNotification {
                    onCancelReminder()
                }
            }
            .padding(.leading, 8)
            .sheet(isPresented: $showingDatePicker) {
                reminderPickerView
            }
    }
    
    var reminderPickerView: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 日期时间选择器
                DatePicker(
                    "选择提醒时间",
                    selection: $selectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding()
                
                // 快捷选择按钮
                Text("快速设置")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // 分钟快捷选择
                HStack(spacing: 20) {
                    quickSetButton(minutes: 5)
                    quickSetButton(minutes: 15)
                    quickSetButton(minutes: 30)
                }
                .padding(.horizontal)
                
                // 日期快捷选择
                HStack(spacing: 20) {
                    dateQuickSetButton(title: "明天", daysToAdd: 1)
                    dateQuickSetButton(title: "后天", daysToAdd: 2)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                Spacer()
            }
            .navigationTitle("设置提醒")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingDatePicker = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSetReminder(selectedDate)
                        showingDatePicker = false
                    }
                }
            }
        }
    }
    
    // 快速设置按钮（分钟）
    func quickSetButton(minutes: Int) -> some View {
        Button(action: {
            // 设置提醒时间并立即确认关闭
            let newDate = Date().addingTimeInterval(Double(minutes * 60))
            onSetReminder(newDate)
            showingDatePicker = false
        }) {
            VStack {
                Text("\(minutes)")
                    .font(.headline)
                Text("分钟")
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    // 快速设置按钮（日期）
    func dateQuickSetButton(title: String, daysToAdd: Int) -> some View {
        Button(action: {
            // 获取当前日期并添加天数
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            dateComponents.day! += daysToAdd
            dateComponents.hour = 9 // 早上9点
            dateComponents.minute = 0
            
            if let newDate = Calendar.current.date(from: dateComponents) {
                // 设置提醒时间并立即确认关闭
                onSetReminder(newDate)
                showingDatePicker = false
            }
        }) {
            VStack {
                Text(title)
                    .font(.headline)
                Text("9:00")
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

// 项目属性按钮组件
struct ProjectAttributeButton: View {
    let item: TodoItem
    let onSetProjectAttribute: (String, Bool) -> Void
    let onRemoveProjectAttribute: () -> Void
    
    @State var showingProjectAttributeSheet = false
    @State var projectAttribute = ""
    @State var generatesNewTask = false
    // 添加获取已有项目属性的环境对象
    @EnvironmentObject var viewModel: TodoListViewModel
    
    var body: some View {
        Button(action: {
            // 修改: 始终打开属性设置界面，而不是直接取消
            if item.projectAttribute != nil {
                projectAttribute = item.projectAttribute ?? ""
                generatesNewTask = item.generatesNewTask
            } else {
                projectAttribute = ""
                generatesNewTask = false
            }
            showingProjectAttributeSheet = true
        }) {
            Image(systemName: item.projectAttribute != nil ? "tag.fill" : "tag")
                .foregroundColor(item.projectAttribute != nil ? .accentColor : .gray)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(BorderlessButtonStyle())
        .padding(.leading, 8)
        .sheet(isPresented: $showingProjectAttributeSheet) {
            projectAttributePickerView
        }
    }
    
    var projectAttributePickerView: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("项目属性")) {
                        TextField("输入项目属性", text: $projectAttribute)
                    }
                    
                    Section {
                        Toggle("完成后生成新任务", isOn: $generatesNewTask)
                    }
                    
                    // 添加删除项目属性的选项
                    if item.projectAttribute != nil {
                        Section {
                            Button(action: {
                                onRemoveProjectAttribute()
                                showingProjectAttributeSheet = false
                            }) {
                                HStack {
                                    Image(systemName: "tag.slash")
                                    Text("移除项目属性")
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                // 已有项目属性的快速选择部分
                if !viewModel.uniqueProjectAttributes.isEmpty {
                    VStack(alignment: .leading) {
                        Text("快速选择")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.uniqueProjectAttributes, id: \.self) { attribute in
                                    attributeQuickSelectButton(attribute)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle(item.projectAttribute != nil ? "编辑项目属性" : "设置项目属性")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingProjectAttributeSheet = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        if !projectAttribute.isEmpty {
                            onSetProjectAttribute(projectAttribute, generatesNewTask)
                        }
                        showingProjectAttributeSheet = false
                    }
                    .disabled(projectAttribute.isEmpty)
                }
            }
        }
    }
    
    // 项目属性快速选择按钮
    func attributeQuickSelectButton(_ attribute: String) -> some View {
        Button(action: {
            projectAttribute = attribute
        }) {
            Text(attribute)
                .font(.system(size: 14))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(projectAttribute == attribute ? Color.accentColor : Color.accentColor.opacity(0.1))
                .foregroundColor(projectAttribute == attribute ? .white : .accentColor)
                .cornerRadius(10)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

// 可编辑的项目标题视图
struct ItemTitleView: View {
    let item: TodoItem
    let onUpdate: (String) -> Void
    
    @State var isEditing = false
    @State var editedTitle = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 标题部分
            if isEditing {
                TextField("待办事项", text: $editedTitle)
                    .submitLabel(.done)
                    .onSubmit {
                        if !editedTitle.isEmpty {
                            onUpdate(editedTitle)
                        }
                        isEditing = false
                    }
                    .onAppear {
                        // 自动获取焦点
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
            } else {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .gray : .primary)
                    .onTapGesture(count: 2) {
                        if !item.isCompleted { // 只允许编辑未完成的项目
                            editedTitle = item.title
                            isEditing = true
                        }
                    }
            }
            
            // 提醒信息部分
            if item.hasNotification, let reminderDate = item.reminderDate {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.accentColor)
                        .font(.caption)
                    
                    Text("提醒: \(formatDate(reminderDate))")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            
            // 项目属性部分
            if let projectAttribute = item.projectAttribute {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.accentColor)
                        .font(.caption)
                    
                    Text("项目: \(projectAttribute)")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    
                    if item.generatesNewTask {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    // 简单的日期格式化函数
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// ArchiveView
struct ArchiveView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @State var showingClearAlert = false
    @State var showingDeleteAlert = false
    @State var itemToDelete: TodoItem?
    @State var showingEmptyTrashAlert = false
    @State var isTrashExpanded = false
    
    // 存储每个分组是否展开的状态
    @State private var expandedDateGroups: [UUID: Bool] = [:]
    @State private var expandedProjectGroups: [String: Bool] = [:]
    
    var body: some View {
        NavigationView {
            List {
                // 归档项目分类显示
                if viewModel.archiveGroupMethod == .byDate {
                    // 按日期分类显示
                    ForEach(viewModel.dateGroups) { group in
                        DisclosureGroup(
                            isExpanded: expandedBinding(for: group.id),
                            content: {
                                ForEach(group.items) { item in
                                    archivedItemRow(item)
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                viewModel.restoreFromArchive(item)
                                            } label: {
                                                Label("恢复", systemImage: "arrow.counterclockwise")
                                            }
                                            .tint(.blue)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                itemToDelete = item
                                                showingDeleteAlert = true
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                }
                            },
                            label: {
                                HStack {
                                    Text(group.title)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("\(group.items.count)项")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        )
                    }
                } else {
                    // 按项目分类显示
                    ForEach(viewModel.projectGroups) { group in
                        DisclosureGroup(
                            isExpanded: projectExpandedBinding(for: group.title),
                            content: {
                                ForEach(group.items) { item in
                                    archivedItemRow(item)
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                viewModel.restoreFromArchive(item)
                                            } label: {
                                                Label("恢复", systemImage: "arrow.counterclockwise")
                                            }
                                            .tint(.blue)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                itemToDelete = item
                                                showingDeleteAlert = true
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                }
                            },
                            label: {
                                HStack {
                                    // 为不同的项目使用不同的图标
                                    Image(systemName: group.title == "未分类" ? "tag.slash" : "tag.fill")
                                        .foregroundColor(group.title == "未分类" ? .gray : .accentColor)
                                    
                                    Text(group.title)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("\(group.items.count)项")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        )
                    }
                }
                
                // 无归档项目时显示提示
                if (viewModel.archiveGroupMethod == .byDate && viewModel.dateGroups.isEmpty) ||
                   (viewModel.archiveGroupMethod == .byProject && viewModel.projectGroups.isEmpty) {
                    Text("暂无归档项目")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                
                // 回收站部分
                Section {
                    DisclosureGroup(
                        isExpanded: $isTrashExpanded,
                        content: {
                            if viewModel.trashItems.isEmpty {
                                Text("回收站为空")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 8)
                            } else {
                                // 显示回收站中的项目
                                ForEach(viewModel.trashItems) { item in
                                    trashItemRow(item)
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                viewModel.restoreFromTrash(item)
                                            } label: {
                                                Label("恢复", systemImage: "arrow.uturn.backward")
                                            }
                                            .tint(.blue)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                viewModel.permanentlyDeleteFromTrash(item)
                                            } label: {
                                                Label("永久删除", systemImage: "trash.slash")
                                            }
                                        }
                                }
                                
                                // 清空回收站按钮
                                Button(action: {
                                    showingEmptyTrashAlert = true
                                }) {
                                    Text("清空回收站")
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .padding(.vertical, 8)
                            }
                        },
                        label: {
                            HStack(spacing: 4) {
                                Label("回收站", systemImage: "trash")
                                    .foregroundColor(.gray)
                                
                                if viewModel.trashItems.count > 0 {
                                    Text("\(viewModel.trashItems.count)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    )
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("归档")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 每次视图出现时重新分组归档项目
                viewModel.refreshArchivedGroups()
            }
            .toolbar {
                // 归档分类方式切换
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("分类方式", selection: $viewModel.archiveGroupMethod) {
                            ForEach(ArchiveGroupMethod.allCases) { method in
                                Text(method.rawValue).tag(method)
                            }
                        }
                        
                        Divider()
                        
                        Button(action: { toggleAllGroups(expanded: true) }) {
                            Label("全部展开", systemImage: "chevron.down")
                        }
                        
                        Button(action: { toggleAllGroups(expanded: false) }) {
                            Label("全部折叠", systemImage: "chevron.right")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.accentColor)
                    }
                    .onChange(of: viewModel.archiveGroupMethod) { newMethod in
                        viewModel.changeArchiveGroupMethod(to: newMethod)
                        // 重置所有分组的展开状态
                        expandedDateGroups.removeAll()
                        expandedProjectGroups.removeAll()
                    }
                }
                
                // 清空归档按钮
                if !viewModel.archivedItems.filter({ !$0.isDeleted }).isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingClearAlert = true
                        } label: {
                            Text("清空归档")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("确认清空归档", isPresented: $showingClearAlert) {
                Button("取消", role: .cancel) { }
                Button("清空", role: .destructive) {
                    viewModel.clearArchive()
                }
            } message: {
                Text("此操作将删除所有归档的待办事项，且不可恢复")
            }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { 
                    itemToDelete = nil
                }
                Button("删除", role: .destructive) {
                    if let item = itemToDelete {
                        viewModel.deleteArchivedItem(item)
                    }
                    itemToDelete = nil
                }
            } message: {
                if let item = itemToDelete {
                    // 修复字符串插值
                    Text("确定要删除\"" + item.title + "\"吗？此操作将移入回收站，30天后自动删除。")
                } else {
                    Text("确定要删除这个项目吗？此操作将移入回收站，30天后自动删除。")
                }
            }
            .alert("确认清空回收站", isPresented: $showingEmptyTrashAlert) {
                Button("取消", role: .cancel) { }
                Button("清空", role: .destructive) {
                    viewModel.emptyTrash()
                }
            } message: {
                Text("此操作将永久删除回收站中的所有项目，无法恢复。")
            }
        }
    }
    
    // 简化的归档项目行
    func archivedItemRow(_ item: TodoItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .strikethrough(true)
                .foregroundColor(.gray)
            
            if let completedAt = item.completedAt {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text("完成于: \(formatDate(completedAt))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // 显示项目属性
            if let projectAttribute = item.projectAttribute {
                HStack(spacing: 4) {
                    Image(systemName: "tag")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text("项目: \(projectAttribute)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // 回收站项目行
    func trashItemRow(_ item: TodoItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .strikethrough(true)
                .foregroundColor(.gray)
            
            HStack(spacing: 4) {
                Image(systemName: "trash.circle")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                if let deletedAt = item.deletedAt {
                    Text("删除于: \(formatDate(deletedAt))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // 显示自动删除剩余时间
                    Text(formatDaysRemaining(deletedAt))
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // 计算并格式化剩余天数
    func formatDaysRemaining(_ deletedDate: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let deletionDate = deletedDate.addingTimeInterval(30 * 24 * 60 * 60) // 30天后自动删除
        
        let components = calendar.dateComponents([.day], from: now, to: deletionDate)
        if let days = components.day, days > 0 {
            return "\(days)天后自动删除"
        } else {
            return "即将删除"
        }
    }
    
    // 简化的日期格式化
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // 辅助函数：返回绑定到每个分组是否展开的状态
    private func expandedBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { expandedDateGroups[id] ?? false },
            set: { expandedDateGroups[id] = $0 }
        )
    }
    
    private func projectExpandedBinding(for title: String) -> Binding<Bool> {
        Binding(
            get: { expandedProjectGroups[title] ?? false },
            set: { expandedProjectGroups[title] = $0 }
        )
    }
    
    // 全部折叠或展开
    private func toggleAllGroups(expanded: Bool) {
        if viewModel.archiveGroupMethod == .byDate {
            // 为所有日期分组设置折叠状态
            for group in viewModel.dateGroups {
                expandedDateGroups[group.id] = expanded
            }
        } else {
            // 为所有项目分组设置折叠状态
            for group in viewModel.projectGroups {
                expandedProjectGroups[group.title] = expanded
            }
        }
    }
    

}
