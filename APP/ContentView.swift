import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TodoListViewModel()
    @State private var selectedTab = 0  // 0: 待办事项，1: 历史归档
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodoListView(viewModel: viewModel)
                .tabItem {
                    Label("待办事项", systemImage: "checkmark.circle")
                }
                .tag(0)
            
            ArchiveView(viewModel: viewModel)
                .tabItem {
                    Label("历史归档", systemImage: "archivebox")
                }
                .tag(1)
        }
        .onChange(of: selectedTab) { newTab in
            // 当切换到归档标签时，刷新归档组
            if newTab == 1 {
                viewModel.refreshArchivedGroups()
            }
        }
    }
}

// TodoListView - 将具体实现移到 ContentViewHelpers.swift
struct TodoListView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @State var newItemTitle = ""
    @State var isAddingNewItem = false
    @State var previousSortMethod: SortMethod = .byCreation
    @State var showingReminderForNewTaskId: String? = nil
    @State var showReminderPicker = false
    @State var selectedReminderDate = Date().addingTimeInterval(3600) // 默认1小时后
    @State var showingDeleteAlert = false
    @State var itemToDelete: TodoItem?
    
    var body: some View {
        NavigationView {
            List {
                // 输入新待办项
                if isAddingNewItem {
                    newItemInputRow
                }
                
                // 项目列表
                ForEach(viewModel.items) { item in
                    todoItemRow(item)
                        .swipeActions(edge: .trailing) {
                            deleteButton(for: item)
                        }
                        .swipeActions(edge: .leading) {
                            if item.isCompleted {
                                archiveButton(for: item)
                            }
                        }
                }
                .onDelete(perform: handleDelete)
                .onMove(perform: { viewModel.moveItem(from: $0, to: $1) })
                
                // 空列表提示
                if viewModel.items.isEmpty && !isAddingNewItem {
                    emptyListView
                }
            }
            .onAppear(perform: setupListeners)
            .onChange(of: viewModel.sortMethod, perform: handleSortMethodChange)
            .sheet(isPresented: $showReminderPicker) {
                newTaskReminderPickerView
            }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { 
                    itemToDelete = nil
                }
                Button("删除", role: .destructive) {
                    if let item = itemToDelete {
                        viewModel.deleteItem(item)
                    }
                    itemToDelete = nil
                }
            } message: {
                if let item = itemToDelete {
                    Text("确定要删除\"" + item.title + "\"吗？此操作将移入回收站，30天后自动删除。")
                } else {
                    Text("确定要删除这个项目吗？此操作将移入回收站，30天后自动删除。")
                }
            }
            .navigationTitle("待办事项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }
    
    // 输入新待办项的行
    var newItemInputRow: some View {
        HStack {
            Image(systemName: "circle")
                .foregroundColor(.gray)
            
            TextField("新待办事项", text: $newItemTitle)
                .submitLabel(.done)
                .onSubmit {
                    if !newItemTitle.isEmpty {
                        viewModel.addItem(title: newItemTitle)
                        newItemTitle = ""
                    }
                    isAddingNewItem = false
                }
        }
        .padding(.vertical, 8)
    }
    
    // 空列表提示视图
    var emptyListView: some View {
        Text("暂无待办事项")
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
    
    // 删除按钮
    func deleteButton(for item: TodoItem) -> some View {
        Button(role: .destructive) {
            itemToDelete = item
            showingDeleteAlert = true
        } label: {
            Label("删除", systemImage: "trash")
        }
    }
    
    // 归档按钮
    func archiveButton(for item: TodoItem) -> some View {
        Button {
            viewModel.archiveItem(item)
        } label: {
            Label("归档", systemImage: "archivebox")
        }
        .tint(.blue)
    }
    
    // 处理删除
    func handleDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            itemToDelete = viewModel.items[index]
            showingDeleteAlert = true
        }
    }
    
    // 设置监听器
    func setupListeners() {
        previousSortMethod = viewModel.sortMethod
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ShowReminderForNewTask"),
            object: nil,
            queue: .main
        ) { notification in
            if let taskId = notification.object as? String {
                showingReminderForNewTaskId = taskId
                showReminderPicker = true
            }
        }
    }
    
    // 处理排序方式变化
    func handleSortMethodChange(_ newValue: SortMethod) {
        if previousSortMethod != newValue {
            previousSortMethod = newValue
            viewModel.changeSortMethod(to: newValue)
        }
    }
    
    // 工具栏内容
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Picker("排序方式", selection: $viewModel.sortMethod) {
                        ForEach(SortMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(.accentColor)
                }
                .onChange(of: viewModel.sortMethod) { newValue in 
                    viewModel.changeSortMethod(to: newValue) 
                }
                .onTapGesture {} // iOS 14 兼容性修复
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isAddingNewItem = true }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// 其余结构体...省略
