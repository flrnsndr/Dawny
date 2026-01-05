//
//  TaskCategoryTests.swift
//  DawnyTests
//
//  Unit Tests für TaskCategory Enum und Kategorie-Logik
//

import XCTest
import SwiftData
@testable import Dawny

final class TaskCategoryTests: XCTestCase {
    
    // MARK: - TaskCategory Enum Tests
    
    func testAllCasesCount() {
        XCTAssertEqual(TaskCategory.allCases.count, 6)
    }
    
    func testSortOrderIsCorrect() {
        let sorted = TaskCategory.sorted
        
        XCTAssertEqual(sorted[0], .uncategorized)
        XCTAssertEqual(sorted[1], .quickWin)
        XCTAssertEqual(sorted[2], .thisWeek)
        XCTAssertEqual(sorted[3], .thisMonth)
        XCTAssertEqual(sorted[4], .thisYear)
        XCTAssertEqual(sorted[5], .someday)
    }
    
    func testSelectableCategoriesExcludesUncategorized() {
        let selectable = TaskCategory.selectableCategories
        
        XCTAssertFalse(selectable.contains(.uncategorized))
        XCTAssertEqual(selectable.count, 5)
    }
    
    func testCategoryHasIcon() {
        for category in TaskCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "Category \(category) should have an icon")
        }
    }
    
    func testCategoryHasDisplayName() {
        for category in TaskCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "Category \(category) should have a display name")
        }
    }
    
    func testCategoryComparable() {
        XCTAssertTrue(TaskCategory.uncategorized < TaskCategory.quickWin)
        XCTAssertTrue(TaskCategory.quickWin < TaskCategory.thisWeek)
        XCTAssertTrue(TaskCategory.thisWeek < TaskCategory.thisMonth)
        XCTAssertTrue(TaskCategory.thisMonth < TaskCategory.thisYear)
        XCTAssertTrue(TaskCategory.thisYear < TaskCategory.someday)
    }
    
    func testCategoryIdentifiable() {
        for category in TaskCategory.allCases {
            XCTAssertEqual(category.id, category.rawValue)
        }
    }
    
    // MARK: - Task Category Assignment Tests
    
    func testTaskCreationWithCategory() {
        let task = Task(
            title: "Test Task",
            parentBacklogID: UUID(),
            category: .quickWin
        )
        
        XCTAssertEqual(task.category, .quickWin)
    }
    
    func testTaskCreationWithoutCategory() {
        let task = Task(
            title: "Test Task",
            parentBacklogID: UUID()
        )
        
        XCTAssertNil(task.category)
    }
    
    func testTaskCategoryOrderIndex() {
        let task = Task(
            title: "Test Task",
            parentBacklogID: UUID(),
            categoryOrderIndex: 5
        )
        
        XCTAssertEqual(task.categoryOrderIndex, 5)
    }
    
    func testTaskCategoryChange() {
        let task = Task(
            title: "Test Task",
            parentBacklogID: UUID(),
            category: .someday
        )
        
        task.category = .quickWin
        
        XCTAssertEqual(task.category, .quickWin)
    }
    
    // MARK: - Task Category with Reset
    
    func testCategoryPreservedAfterReset() {
        let task = Task(
            title: "Test Task",
            parentBacklogID: UUID(),
            category: .thisWeek
        )
        task.status = .dailyFocus
        
        task.resetToBacklog()
        
        XCTAssertEqual(task.status, .inBacklog)
        XCTAssertEqual(task.category, .thisWeek, "Category should be preserved after reset")
    }
    
    func testCategoryPreservedAfterMoveToDailyFocus() {
        let task = Task(
            title: "Test Task",
            parentBacklogID: UUID(),
            category: .quickWin
        )
        
        task.moveToDailyFocus(date: Date())
        
        XCTAssertEqual(task.status, .dailyFocus)
        XCTAssertEqual(task.category, .quickWin, "Category should be preserved after move to daily focus")
    }
}

// MARK: - AppSettings Category Tests

final class AppSettingsCategoryTests: XCTestCase {
    
    var settings: AppSettings!
    
    override func setUp() {
        super.setUp()
        // Lösche vorherige UserDefaults
        UserDefaults.standard.removeObject(forKey: "DawnyShowCategories")
        UserDefaults.standard.removeObject(forKey: "DawnyDefaultCategory")
        UserDefaults.standard.removeObject(forKey: "DawnyCollapsedCategories")
        
        settings = AppSettings()
    }
    
    override func tearDown() {
        settings = nil
        super.tearDown()
    }
    
    func testDefaultShowCategoriesIsTrue() {
        XCTAssertTrue(settings.showCategories)
    }
    
    func testDefaultCategoryIsSomeday() {
        XCTAssertEqual(settings.defaultCategory, .someday)
    }
    
    func testCollapsedCategoriesInitiallyEmpty() {
        XCTAssertTrue(settings.collapsedCategories.isEmpty)
    }
    
    func testToggleCategoryCollapsed() {
        XCTAssertFalse(settings.isCategoryCollapsed(.quickWin))
        
        settings.toggleCategoryCollapsed(.quickWin)
        XCTAssertTrue(settings.isCategoryCollapsed(.quickWin))
        
        settings.toggleCategoryCollapsed(.quickWin)
        XCTAssertFalse(settings.isCategoryCollapsed(.quickWin))
    }
    
    func testMultipleCategoriesCollapsed() {
        settings.toggleCategoryCollapsed(.quickWin)
        settings.toggleCategoryCollapsed(.thisMonth)
        
        XCTAssertTrue(settings.isCategoryCollapsed(.quickWin))
        XCTAssertTrue(settings.isCategoryCollapsed(.thisMonth))
        XCTAssertFalse(settings.isCategoryCollapsed(.someday))
    }
    
    func testShowCategoriesPersistence() {
        settings.showCategories = false
        
        let newSettings = AppSettings()
        XCTAssertFalse(newSettings.showCategories)
    }
    
    func testDefaultCategoryPersistence() {
        settings.defaultCategory = .quickWin
        
        let newSettings = AppSettings()
        XCTAssertEqual(newSettings.defaultCategory, .quickWin)
    }
}

