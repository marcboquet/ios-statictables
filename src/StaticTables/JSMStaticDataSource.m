//
// Copyright © 2014 Daniel Farrelly
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// *	Redistributions of source code must retain the above copyright notice, this list
//		of conditions and the following disclaimer.
// *	Redistributions in binary form must reproduce the above copyright notice, this
//		list of conditions and the following disclaimer in the documentation and/or
//		other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "JSMStaticDataSource.h"
#import "JSMStaticSection.h"
#import "JSMStaticRow.h"

@interface JSMStaticDataSource ()

@property (nonatomic, strong) NSMutableArray *mutableSections;

@end

@interface JSMStaticSection (JSMStaticDataSource)

- (void)setDataSource:(JSMStaticDataSource *)dataSource;

- (void)setDirty:(BOOL)dirty;

@end

@interface JSMStaticRow (JSMStaticDataSource)

- (void)prepareCell:(UITableViewCell *)cell;

@end

@implementation JSMStaticDataSource

@synthesize mutableSections = _mutableSections;

- (id)init {
    if( ( self = [super init] ) ) {
        self.cellClass = [JSMStaticDataSource cellClass];
        self.mutableSections = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Creating Table View Cells

static Class _staticCellClass = nil;

+ (Class)cellClass {
    if( _staticCellClass == nil ) {
        return [UITableViewCell class];
    }
    return _staticCellClass;
}

+ (void)setCellClass:(Class)cellClass {
    _staticCellClass = cellClass;
}

#pragma mark - Managing the Sections

- (NSArray *)sections {
    return self.mutableSections.copy;
}

- (void)setSections:(NSArray *)sections {
    _mutableSections = sections.mutableCopy;
    // Update the data source for all the added sections
    for( NSInteger i=0; i<_mutableSections.count; i++ ) {
        [(JSMStaticSection *)[_mutableSections objectAtIndex:i] setDataSource:self];
    }
    // Notify the delegate
    if( self.delegate != nil && [self.delegate respondsToSelector:@selector(dataSource:sectionsDidChange:)] ) {
        _mutableSections = [[self.delegate dataSource:self sectionsDidChange:_mutableSections.copy] mutableCopy];
    }
}

- (NSUInteger)numberOfSections {
    return self.mutableSections.count;
}

- (JSMStaticSection *)createSection {
    JSMStaticSection *section = [JSMStaticSection section];
    [self addSection:section];
    return section;
}

- (JSMStaticSection *)createSectionAtIndex:(NSUInteger)index {
    JSMStaticSection *section = [JSMStaticSection section];
    [self insertSection:section atIndex:index];
    return section;
}

- (void)addSection:(JSMStaticSection *)section {
    // Update the section's data source
    section.dataSource = self;
    // Add the section to the end
    [self.mutableSections addObject:section];
    // Notify the delegate
    if( self.delegate != nil && [self.delegate respondsToSelector:@selector(dataSource:sectionsDidChange:)] ) {
        self.mutableSections = [[self.delegate dataSource:self sectionsDidChange:self.mutableSections.copy] mutableCopy];
    }
}

- (void)insertSection:(JSMStaticSection *)section atIndex:(NSUInteger)index {
    // Update the section's data source
    section.dataSource = self;
    // No inserting outside the bounds, default to the appropriate end
    if( index >= self.mutableSections.count ) {
        [self.mutableSections addObject:section];
    }
    // Otherwise add at the specified index
    else {
        [self.mutableSections insertObject:section atIndex:index];
    }
    // Notify the delegate
    if( self.delegate != nil && [self.delegate respondsToSelector:@selector(dataSource:sectionsDidChange:)] ) {
        self.mutableSections = [[self.delegate dataSource:self sectionsDidChange:self.mutableSections.copy] mutableCopy];
    }
}

- (JSMStaticSection *)sectionAtIndex:(NSUInteger)index {
    // We won't find anything outside the bounds
    if( index >= self.mutableSections.count ) {
        return nil;
    }
    // Fetch the object
    return (JSMStaticSection *)[self.mutableSections objectAtIndex:index];
}

- (NSUInteger)indexForSection:(JSMStaticSection *)section {
    return [self.mutableSections indexOfObject:section];
}

- (BOOL)containsSection:(JSMStaticSection *)section {
    return [self.mutableSections containsObject:section];
}

- (void)removeSectionAtIndex:(NSUInteger)index {
    // Update the section's data source
    [self sectionAtIndex:index].dataSource = nil;
    // Remove the section
    [self.mutableSections removeObjectAtIndex:index];
    // Notify the delegate
    if( self.delegate != nil && [self.delegate respondsToSelector:@selector(dataSource:sectionsDidChange:)] ) {
        self.mutableSections = [[self.delegate dataSource:self sectionsDidChange:self.mutableSections.copy] mutableCopy];
    }
}

- (void)removeSection:(JSMStaticSection *)section {
    // Update the section's data source
    section.dataSource = nil;
    // Remove the section
    [self.mutableSections removeObject:section];
    // Notify the delegate
    if( self.delegate != nil && [self.delegate respondsToSelector:@selector(dataSource:sectionsDidChange:)] ) {
        self.mutableSections = [[self.delegate dataSource:self sectionsDidChange:self.mutableSections.copy] mutableCopy];
    }
}

#pragma mark - Managing the Rows

- (JSMStaticRow *)createRowAtIndexPath:(NSIndexPath *)indexPath {
    JSMStaticSection *section = [self sectionAtIndex:(NSUInteger)indexPath.section];
    return [section createRow];
}

- (void)insertRow:(JSMStaticRow *)row atIndexPath:(NSIndexPath *)indexPath {
    JSMStaticSection *section = [self sectionAtIndex:(NSUInteger)indexPath.section];
    [section createRowAtIndex:(NSUInteger)indexPath.row];
}

- (JSMStaticRow *)rowAtIndexPath:(NSIndexPath *)indexPath {
    JSMStaticSection *section = [self sectionAtIndex:(NSUInteger)indexPath.section];
    return [section rowAtIndex:(NSUInteger)indexPath.row];
}

- (NSIndexPath *)indexPathForRow:(JSMStaticRow *)row {
    JSMStaticSection *section = row.section;
    if( section == nil ) {
        return nil;
    }
    NSInteger sectionIndex = (NSInteger)[self indexForSection:section];
    NSInteger rowIndex = (NSInteger)[section indexForRow:row];
    return [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
}

- (void)removeRowAtIndexPath:(NSIndexPath *)indexPath {
    JSMStaticSection *section = [self sectionAtIndex:(NSUInteger)indexPath.section];
    return [section removeRowAtIndex:(NSUInteger)indexPath.row];
}

- (void)removeRow:(JSMStaticRow *)row {
    NSIndexPath *indexPath = [self indexPathForRow:row];
    [self removeRowAtIndexPath:indexPath];
}

#pragma mark - Refreshing the Contents

- (void)requestReloadForSection:(JSMStaticSection *)section {
    // Ensure we own the section first
    if( ! [self containsSection:section] ) {
        return;
    }
    // All we do is notify the delegate
    if( self.delegate != nil && [self.delegate respondsToSelector:@selector(dataSource:sectionNeedsReload:atIndex:)] ) {
        [self.delegate dataSource:self sectionNeedsReload:section atIndex:[self indexForSection:section]];
    }
}

- (void)requestReloadForRow:(JSMStaticRow *)row {
    // Ensure we own the row first
    NSIndexPath *indexPath = [self indexPathForRow:row];
    if( indexPath == nil ) {
        return;
    }
    // All we do is notify the delegate
    if( self.delegate != nil && [self.delegate respondsToSelector:@selector(dataSource:rowNeedsReload:atIndexPath:)] ) {
        [self.delegate dataSource:self rowNeedsReload:row atIndexPath:indexPath];
    }
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    JSMStaticSection *sectionObject = [self sectionAtIndex:(NSUInteger)section];
    [sectionObject setDirty:NO];
    return sectionObject.numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self sectionAtIndex:(NSUInteger)section] headerText];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return [[self sectionAtIndex:(NSUInteger)section] footerText];
}

- (UITableViewCell *)tableView:(UITableView *)tableView dequeueReusableCellWithStyle:(UITableViewCellStyle)style {
    id cell;
    // Get the cell style
    switch( style ) {
        case UITableViewCellStyleDefault: {
            static NSString *JSMStaticDataSourceDefaultReuseIdentifier = @"JSMStaticDataSourceDefaultReuseIdentifier";
            if( ( cell = [tableView dequeueReusableCellWithIdentifier:JSMStaticDataSourceDefaultReuseIdentifier] ) == nil ) {
                cell = [[self.cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:JSMStaticDataSourceDefaultReuseIdentifier];
            }
            break;
        }
        case UITableViewCellStyleValue1:
        default: {
            static NSString *JSMStaticDataSourceValue1ReuseIdentifier = @"JSMStaticDataSourceValue1ReuseIdentifier";
            if( ( cell = [tableView dequeueReusableCellWithIdentifier:JSMStaticDataSourceValue1ReuseIdentifier] ) == nil ) {
                cell = [[self.cellClass alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:JSMStaticDataSourceValue1ReuseIdentifier];
            }
            break;
        }
        case UITableViewCellStyleValue2: {
            static NSString *JSMStaticDataSourceValue2ReuseIdentifier = @"JSMStaticDataSourceValue2ReuseIdentifier";
            if( ( cell = [tableView dequeueReusableCellWithIdentifier:JSMStaticDataSourceValue2ReuseIdentifier] ) == nil ) {
                cell = [[self.cellClass alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:JSMStaticDataSourceValue2ReuseIdentifier];
            }
            break;
        }
        case UITableViewCellStyleSubtitle: {
            static NSString *JSMStaticDataSourceSubtitleReuseIdentifier = @"JSMStaticDataSourceSubtitleReuseIdentifier";
            if( ( cell = [tableView dequeueReusableCellWithIdentifier:JSMStaticDataSourceSubtitleReuseIdentifier] ) == nil ) {
                cell = [[self.cellClass alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:JSMStaticDataSourceSubtitleReuseIdentifier];
            }
            break;
        }
    }
    // Return the cell
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Get the row for this particular index path
    JSMStaticRow *row = [self rowAtIndexPath:indexPath];
    // Get a cell
    UITableViewCell *cell = [self tableView:tableView dequeueReusableCellWithStyle:row.style];
    // Apply the content from the row
    cell.textLabel.text = row.text;
    cell.detailTextLabel.text = row.detailText;
    cell.imageView.image = row.image;
    // Reset some basics
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    // Configure the cell using the row's configuration block
    [row prepareCell:cell];
    // Return the cell
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

@end
