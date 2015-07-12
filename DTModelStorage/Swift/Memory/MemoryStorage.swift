//
//  MemoryStorage.swift
//  DTModelStorageTests
//
//  Created by Denys Telezhkin on 10.07.15.
//  Copyright (c) 2015 Denys Telezhkin. All rights reserved.
//

import UIKit
import Swift

public class MemoryStorage: BaseStorage, StorageProtocol
{
    public var sections: [Section] = [SectionModel]()
    private var currentUpdate : StorageUpdate?
    
    public func objectAtIndexPath(path: NSIndexPath) -> Any? {
        let sectionModel : SectionModel
        if path.section >= self.sections.count {
            return nil
        }
        else {
            sectionModel = self.sections[path.section] as! SectionModel
            if path.item >= sectionModel.numberOfObjects {
                return nil
            }
        }
        return sectionModel.objects[path.item]
    }
    
    func startUpdate()
    {
        self.currentUpdate = StorageUpdate()
    }
    
    func finishUpdate()
    {
        if self.currentUpdate != nil {
            self.delegate?.storageDidPerformUpdate(self.currentUpdate!)
        }
        self.currentUpdate = nil
    }
    
    public func setSectionHeaderModel(model: Any?, forSectionIndex sectionIndex: Int)
    {
        assert(self.supplementaryHeaderKind != nil, "supplementaryHeaderKind property was not set before calling setSectionHeaderModel: forSectionIndex: method")
        self.sectionAtIndex(sectionIndex).setSupplementaryModel(model, forKind: self.supplementaryHeaderKind!)
    }
    
    public func setSectionFooterModel(model: Any?, forSectionIndex sectionIndex: Int)
    {
        assert(self.supplementaryFooterKind != nil, "supplementaryFooterKind property was not set before calling setSectionFooterModel: forSectionIndex: method")
        self.sectionAtIndex(sectionIndex).setSupplementaryModel(model, forKind: self.supplementaryFooterKind!)
    }
    
    public func setSupplementaries(models : [Any], forKind kind: String)
    {
        self.startUpdate()
        
        if models.count == 0 {
            for index in 0..<self.sections.count {
                let section = self.sections[index] as! SectionModel
                section.setSupplementaryModel(nil, forKind: kind)
            }
            return
        }
        
        self.getValidSection(models.count - 1)
        
        for index in 0..<models.count {
            let section = self.sections[index] as! SectionModel
            section.setSupplementaryModel(models[index], forKind: kind)
        }
        
        self.finishUpdate()
    }
    
    public func setSectionHeaderModels(models : [Any])
    {
        assert(self.supplementaryHeaderKind != nil, "Please set supplementaryHeaderKind property before setting section header models")
        self.setSupplementaries(models, forKind: self.supplementaryHeaderKind!)
    }
    
    public func setSectionFooterModels(models : [Any])
    {
        assert(self.supplementaryFooterKind != nil, "Please set supplementaryFooterKind property before setting section header models")
        self.setSupplementaries(models, forKind: self.supplementaryFooterKind!)
    }
    
    public func setItems(items: [Any], forSectionIndex index: Int)
    {
        let section = self.sectionAtIndex(index)
        section.objects.removeAll(keepCapacity: false)
        section.objects.extend(items)
        self.delegate?.storageNeedsReloading()
    }
    
    public func addItems(items: [Any], toSection index: Int = 0)
    {
        self.startUpdate()
        let section = self.getValidSection(index)
        
        for item in items {
            let numberOfItems = section.numberOfObjects
            section.objects.append(item)
            self.currentUpdate?.insertedRowIndexPaths.append(NSIndexPath(forItem: numberOfItems, inSection: index))
        }
        self.finishUpdate()
    }
    
    public func addItem(item: Any, toSection index: Int = 0)
    {
        self.startUpdate()
        let section = self.getValidSection(index)
        let numberOfItems = section.numberOfObjects
        section.objects.append(item)
        self.currentUpdate?.insertedRowIndexPaths.append(NSIndexPath(forItem: numberOfItems, inSection: index))
        self.finishUpdate()
    }
    
    public func insertItem(item: Any, toIndexPath indexPath: NSIndexPath)
    {
        self.startUpdate()
        let section = self.getValidSection(indexPath.section)
        
        if section.objects.count < indexPath.item {
            // MARK: - TODO - throw an error in Swift 2.
            return
        }
        section.objects.insert(item, atIndex: indexPath.item)
        self.currentUpdate?.insertedRowIndexPaths.append(indexPath)
        self.finishUpdate()
    }
    
    public func reloadItem<T:Equatable>(item: T)
    {
        self.startUpdate()
        if let indexPath = self.indexPathForItem(item) {
            self.currentUpdate?.updatedRowIndexPaths.append(indexPath)
        }
        self.finishUpdate()
    }
    
    public func replaceItem<T: Equatable, U:Equatable>(itemToReplace: T, replacingItem: U)
    {
        self.startUpdate()
        // MARK: TODO - Use guard and defer in Swift 2
        let originalIndexPath = self.indexPathForItem(itemToReplace)
        if originalIndexPath != nil {
            let section = self.getValidSection(originalIndexPath!.section)
            section.objects[originalIndexPath!.item] = replacingItem
        }
        else {
            // MARK: TODO - Throw an error in Swift 2
            self.finishUpdate()
            return
        }
        self.currentUpdate?.updatedRowIndexPaths.append(originalIndexPath!)
        
        self.finishUpdate()
    }
    
    public func removeItem<T:Equatable>(item: T)
    {
        self.startUpdate()
        
        // MARK: TODO - Use guard and defer in Swift 2
        let indexPath = self.indexPathForItem(item)
        if indexPath != nil {
            self.getValidSection(indexPath!.section).objects.removeAtIndex(indexPath!.item)
        }
        else {
            // MARK: TODO - Throw an error in Swift 2
            return
        }
        self.currentUpdate?.deletedRowIndexPaths.append(indexPath!)
        self.finishUpdate()
    }
    
    public func removeItems<T:Equatable>(items: [T])
    {
        self.startUpdate()
        let indexPaths = self.indexPathArrayForItems(items)
        for item in items
        {
            if let indexPath = self.indexPathForItem(item) {
                self.getValidSection(indexPath.section).objects.removeAtIndex(indexPath.item)
            }
        }
        self.currentUpdate?.deletedRowIndexPaths.extend(indexPaths)
        self.finishUpdate()
    }
    
    public func removeItemsAtIndexPaths(indexPaths : [NSIndexPath])
    {
        self.startUpdate()
        
        let reverseSortedIndexPaths = self.dynamicType.sortedArrayOfIndexPaths(indexPaths, ascending: false)
        for indexPath in reverseSortedIndexPaths
        {
            if let object = self.objectAtIndexPath(indexPath)
            {
                self.getValidSection(indexPath.section).objects.removeAtIndex(indexPath.item)
                self.currentUpdate?.deletedRowIndexPaths.append(indexPath)
            }
        }
        
        self.finishUpdate()
    }
    
    public func deleteSections(sections : NSIndexSet)
    {
        self.startUpdate()

        for var i = sections.lastIndex; i != NSNotFound; i = sections.indexLessThanIndex(i) {
            self.sections.removeAtIndex(i)
        }
        self.currentUpdate?.deletedSectionIndexes.addIndexes(sections)
        
        self.finishUpdate()
    }
}

// MARK: - Searching in storage
extension MemoryStorage
{
    public func itemsInSection(section: Int) -> [Any]?
    {
        if self.sections.count > section {
            return self.sections[section].objects
        }
        return nil
    }
    
    public func itemAtIndexPath(indexPath: NSIndexPath) -> Any?
    {
        let sectionObjects : [Any]
        if indexPath.section < self.sections.count
        {
            sectionObjects = self.itemsInSection(indexPath.section)!
        }
        else {
            return nil
        }
        if indexPath.row < sectionObjects.count {
            return sectionObjects[indexPath.row]
        }
        return nil
    }
    
    public func indexPathForItem<T: Equatable>(searchableItem : T) -> NSIndexPath?
    {
        for sectionIndex in 0..<self.sections.count
        {
            let rows = self.sections[sectionIndex].objects
            
            for rowIndex in 0..<rows.count {
                if let item = rows[rowIndex] as? T {
                    if item == searchableItem {
                        return NSIndexPath(forItem: rowIndex, inSection: sectionIndex)
                    }
                }
            }
            
        }
        return nil
    }
    
    public func sectionAtIndex(sectionIndex : Int) -> SectionModel
    {
        self.startUpdate()
        let section = self.getValidSection(sectionIndex)
        self.finishUpdate()
        return section
    }
    
    private func getValidSection(sectionIndex : Int) -> SectionModel
    {
        if sectionIndex < self.sections.count
        {
            return self.sections[sectionIndex] as! SectionModel
        }
        else {
            for i in self.sections.count...sectionIndex {
                self.sections.append(SectionModel())
                self.currentUpdate?.insertedSectionIndexes.addIndex(i)
            }
        }
        return self.sections.last as! SectionModel
    }
    
    func indexPathArrayForItems<T:Equatable>(items:[T]) -> [NSIndexPath]
    {
        var indexPaths = [NSIndexPath]()
        
        for index in 0..<items.count {
            if let indexPath = self.indexPathForItem(items[index])
            {
                indexPaths.append(indexPath)
            }
        }
        return indexPaths
    }
    
    class func sortedArrayOfIndexPaths(indexPaths: [NSIndexPath], ascending: Bool) -> [NSIndexPath]
    {
        var unsorted = NSMutableArray(array: indexPaths)
        let descriptor = NSSortDescriptor(key: "self", ascending: ascending)
        return unsorted.sortedArrayUsingDescriptors([descriptor]) as! [NSIndexPath]
    }
}

extension MemoryStorage : HeaderFooterStorageProtocol
{
    public func headerModelForSectionIndex(index: Int) -> Any? {
        assert(self.supplementaryHeaderKind != nil, "supplementaryHeaderKind property was not set before calling headerModelForSectionIndex: method")
        return self.supplementaryModelOfKind(self.supplementaryHeaderKind!, sectionIndex: index)
    }
  
    public func footerModelForSectionIndex(index: Int) -> Any? {
        assert(self.supplementaryFooterKind != nil, "supplementaryFooterKind property was not set before calling footerModelForSectionIndex: method")
        return self.supplementaryModelOfKind(self.supplementaryFooterKind!, sectionIndex: index)
    }
}

extension MemoryStorage : SupplementaryStorageProtocol
{
    public func supplementaryModelOfKind(kind: String, sectionIndex: Int) -> Any? {
        let sectionModel : SectionModel
        if sectionIndex >= self.sections.count {
            return nil
        }
        else {
            sectionModel = self.sections[sectionIndex] as! SectionModel
        }
        return sectionModel.supplementaryModelOfKind(kind)
    }
}