//
//  TSQCalendarState.m
//  TimesSquare
//
//  Created by Jim Puls on 11/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "TSQCalendarView.h"
#import "TSQCalendarMonthHeaderCell.h"
#import "TSQCalendarRowCell.h"
#import "DateButton.h"
#import "OSHighlightedDate.h"

@interface TSQCalendarView () <UITableViewDataSource, UITableViewDelegate>
{
    NSMutableArray* highlightedDates;
}
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) TSQCalendarMonthHeaderCell *headerView; // nil unless pinsHeaderToTop == YES

@end


@implementation TSQCalendarView


#pragma mark -
#pragma mark Highlighted date management

-(void)highlightDateRangeFrom:(NSDate*)from toDate:(NSDate*)to withColour:(CalendarHighlightColour)colour
{
    OSHighlightedDate* existing = [self highlightedDateForDateRangeFrom:from toDate:to];
    
    
    if (existing)
    {
        [NSException raise:@"Overlapping range" format:@"Cannot highlight that range because there is an existing range: %@",existing];
    }
    
    OSHighlightedDate* date = [[OSHighlightedDate alloc] init];
    
    date.dateFrom = from;
    date.dateTo = to;
    date.colour = colour;
 
    if (!highlightedDates)
        highlightedDates = [[NSMutableArray alloc] init];
    [highlightedDates addObject:date];
    
    [self highlightOrDehighlightDatesStartDate:from toFinishDate:to highlightColour:colour];
    
    
}


-(NSString*)dateStringFromDate:(NSDate*)date
{
    NSDate *localDate = date;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"dd/MM/yy";
    
    NSString *dateString = [dateFormatter stringFromDate: localDate];
    
    return dateString;
}


-(OSHighlightedDate*)highlightedDateForDateRangeFrom:(NSDate*)startDate1 toDate:(NSDate*)endDate1
{
    for (OSHighlightedDate* date in highlightedDates)
    {
        NSTimeInterval startDate1MS = [startDate1 timeIntervalSince1970];

        NSTimeInterval endDate1MS = [endDate1 timeIntervalSince1970];
        
        NSTimeInterval startDate2MS = [date.dateFrom timeIntervalSince1970];

        NSTimeInterval endDate2MS = [date.dateTo timeIntervalSince1970];
        
        if (startDate1MS <= endDate2MS && endDate1MS >=startDate2MS)
        {
//            NSLog(@"Matched");
//            NSLog(@"Highlighted Date: %@ - %@", [self dateStringFromDate:date.dateFrom],[self dateStringFromDate:date.dateTo]);
//            NSLog(@"Range check Date: %@ - %@\n\n", [self dateStringFromDate:startDate1],[self dateStringFromDate:endDate1]);

            return date;
        }
        
//        NSLog(@"Highlighted Date: %@ - %@", [self dateStringFromDate:date.dateFrom],[self dateStringFromDate:date.dateTo]);
//        NSLog(@"Range check Date: %@ - %@\n\n", [self dateStringFromDate:startDate1],[self dateStringFromDate:endDate1]);

    }
    
    
    return nil;
}

-(void)clearAllHighlights
{
    [highlightedDates removeAllObjects];
    
    [self.tableView reloadData];
    
}

#pragma mark -
#pragma mark Init


- (id)initWithCoder:(NSCoder *)aDecoder;
{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }

    [self _TSQCalendarView_commonInit];

    return self;
}

- (id)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    [self _TSQCalendarView_commonInit];
    
    return self;
}

- (void)_TSQCalendarView_commonInit;
{
    _tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self addSubview:_tableView];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM dd, yyyy"];
    NSDate *date = [dateFormatter dateFromString:@"January 01, 2014"];
    
    NSDate* endDate = [date dateByAddingTimeInterval:60*60*24*30];
    [self highlightDateRangeFrom:date toDate:endDate withColour:CalendarHighlightColourThree];
    
    date = [endDate dateByAddingTimeInterval:60*60*24];
    endDate = [date dateByAddingTimeInterval:60*60*24*30];
    [self highlightDateRangeFrom:date toDate:endDate withColour:CalendarHighlightColourFour];
}

- (void)dealloc;
{
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
}

- (NSCalendar *)calendar;
{
    if (!_calendar) {
        self.calendar = [NSCalendar currentCalendar];
    }
    return _calendar;
}

- (Class)headerCellClass;
{
    if (!_headerCellClass) {
        self.headerCellClass = [TSQCalendarMonthHeaderCell class];
    }
    return _headerCellClass;
}

- (Class)rowCellClass;
{
    if (!_rowCellClass) {
        self.rowCellClass = [TSQCalendarRowCell class];
    }
    return _rowCellClass;
}

- (Class)cellClassForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.row == 0 && !self.pinsHeaderToTop) {
        return [self headerCellClass];
    } else {
        return [self rowCellClass];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor;
{
    [super setBackgroundColor:backgroundColor];
    [self.tableView setBackgroundColor:backgroundColor];
}

- (void)setPinsHeaderToTop:(BOOL)pinsHeaderToTop;
{
    _pinsHeaderToTop = pinsHeaderToTop;
    [self setNeedsLayout];
}

- (void)setFirstDate:(NSDate *)firstDate;
{
    // clamp to the beginning of its month
    _firstDate = [self clampDate:firstDate toComponents:NSMonthCalendarUnit|NSYearCalendarUnit];
}

- (void)setLastDate:(NSDate *)lastDate;
{
    // clamp to the end of its month
    NSDate *firstOfMonth = [self clampDate:lastDate toComponents:NSMonthCalendarUnit|NSYearCalendarUnit];
    
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    offsetComponents.month = 1;
    offsetComponents.day = -1;
    _lastDate = [self.calendar dateByAddingComponents:offsetComponents toDate:firstOfMonth options:0];
}

- (void)setSelectedDate:(NSDate *)newSelectedDate;
{
    // clamp to beginning of its day
    NSDate *startOfDay = [self clampDate:newSelectedDate toComponents:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit];
    
 
    
    if ([self.delegate respondsToSelector:@selector(calendarView:shouldSelectDate:)] && ![self.delegate calendarView:self shouldSelectDate:startOfDay]) {
        return;
    }
    
    [[self cellForRowAtDate:_selectedDate] selectColumnForDate:nil];
    [[self cellForRowAtDate:startOfDay] selectColumnForDate:startOfDay];
    NSIndexPath *newIndexPath = [self indexPathForRowAtDate:startOfDay];
    CGRect newIndexPathRect = [self.tableView rectForRowAtIndexPath:newIndexPath];
    CGRect scrollBounds = self.tableView.bounds;
    
    if (self.pagingEnabled) {
        CGRect sectionRect = [self.tableView rectForSection:newIndexPath.section];
        [self.tableView setContentOffset:sectionRect.origin animated:YES];
    } else {
        if (CGRectGetMinY(scrollBounds) > CGRectGetMinY(newIndexPathRect)) {
            [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else if (CGRectGetMaxY(scrollBounds) < CGRectGetMaxY(newIndexPathRect)) {
            [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }
    
    _selectedDate = startOfDay;
    
    if ([self.delegate respondsToSelector:@selector(calendarView:didSelectDate:)]) {
        [self.delegate calendarView:self didSelectDate:startOfDay];
    }
}

- (void)scrollToDate:(NSDate *)date animated:(BOOL)animated
{
  NSInteger section = [self sectionForDate:date];
  [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:animated];
}

- (TSQCalendarMonthHeaderCell *)makeHeaderCellWithIdentifier:(NSString *)identifier;
{
    TSQCalendarMonthHeaderCell *cell = [[[self headerCellClass] alloc] initWithCalendar:self.calendar reuseIdentifier:identifier];
    cell.backgroundColor = self.backgroundColor;
    cell.calendarView = self;
    return cell;
}




-(void)highlightOrDehighlightDatesStartDate:(NSDate*)startDate toFinishDate:(NSDate*)endDate highlightColour:(CalendarHighlightColour)colour
{
    NSDate* start =  [self clampDate:startDate toComponents:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit];
    NSDate* end = [self clampDate:endDate toComponents:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit];
    
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:NSDayCalendarUnit
                                               fromDate:start
                                                 toDate:end
                                                options:0];
    
    NSInteger daysBetween = components.day;
    NSInteger incDays = 1;
    NSDate* date = nil;
    
    TSQCalendarRowCell* previousRow=nil;
    
    while(daysBetween > 0)
    {
        if (!date)
        {
            date = start;
            
        }
        else
        {
            daysBetween -= incDays;
            
            if (daysBetween < 0)
                incDays = daysBetween + incDays;
            
            date = [date dateByAddingTimeInterval:60*60*24*incDays];
            
        }
        
        TSQCalendarRowCell* row = [self cellForRowAtDate:date];

        if (previousRow != row && row != nil)
        {
            NSLog(@"%@",row);
          
            [row setColourOfDatesFrom:start toDate:end toColour:colour];

            
        }
        
        previousRow = row;
        
    }
    
}

//
//-(void)highlightDaysFromStartDate:(NSDate*)startDate toFinishDate:(NSDate*)endDate
//{
//    //check whether we need to dehighlight
//    if (_highlightedDateStart != nil && _highlightedDateEnd != nil)
//    {
//        [self highlightOrDehighlightDatesStartDate:_highlightedDateStart toFinishDate:_highlightedDateEnd shouldHighlight:NO];
//    }
//    
//    // clamp to beginning of its day
//    _highlightedDateStart = [self clampDate:startDate toComponents:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit];
//    _highlightedDateEnd = [self clampDate:endDate toComponents:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit];
//    
//    
//    //Now highlight the new rows
//    [self highlightOrDehighlightDatesStartDate:_highlightedDateStart toFinishDate:_highlightedDateEnd shouldHighlight:YES];
//    
//}
//



#pragma mark Calendar calculations

- (NSDate *)firstOfMonthForSection:(NSInteger)section;
{
    NSDateComponents *offset = [NSDateComponents new];
    offset.month = section;
    return [self.calendar dateByAddingComponents:offset toDate:self.firstDate options:0];
}

- (TSQCalendarRowCell *)cellForRowAtDate:(NSDate *)date;
{
    @try {
        NSIndexPath* path = [self indexPathForRowAtDate:date];
        int numRows = [self tableView:self.tableView numberOfRowsInSection:path.section];
        
        int row = path.row;
        if (row < numRows )
            return (TSQCalendarRowCell *)[self.tableView cellForRowAtIndexPath:path];
        else
            return nil;
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
   return nil;
}

- (NSInteger)sectionForDate:(NSDate *)date;
{
  return [self.calendar components:NSMonthCalendarUnit fromDate:self.firstDate toDate:date options:0].month;
}

- (NSIndexPath *)indexPathForRowAtDate:(NSDate *)date;
{
    if (!date) {
        return nil;
    }
    
    NSInteger section = [self sectionForDate:date];
    NSDate *firstOfMonth = [self firstOfMonthForSection:section];
    
    NSInteger firstWeek = [self.calendar components:NSWeekOfMonthCalendarUnit fromDate:firstOfMonth].weekOfMonth;
    NSInteger targetWeek = [self.calendar components:NSWeekOfMonthCalendarUnit fromDate:date].weekOfMonth;
    
    return [NSIndexPath indexPathForRow:(self.pinsHeaderToTop ? 0 : 1) + targetWeek - firstWeek inSection:section];
}

#pragma mark UIView

- (void)layoutSubviews;
{
    if (self.pinsHeaderToTop) {
        if (!self.headerView) {
            self.headerView = [self makeHeaderCellWithIdentifier:nil];
            if (self.tableView.visibleCells.count > 0) {
                self.headerView.firstOfMonth = [self.tableView.visibleCells[0] firstOfMonth];
            } else {
                self.headerView.firstOfMonth = self.firstDate;
            }
            [self addSubview:self.headerView];
        }
        CGRect bounds = self.bounds;
        CGRect headerRect;
        CGRect tableRect;
        CGRectDivide(bounds, &headerRect, &tableRect, [[self headerCellClass] cellHeight], CGRectMinYEdge);
        self.headerView.frame = headerRect;
        self.tableView.frame = tableRect;
    } else {
        if (self.headerView) {
            [self.headerView removeFromSuperview];
            self.headerView = nil;
        }
        self.tableView.frame = self.bounds;
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return 1 + [self.calendar components:NSMonthCalendarUnit fromDate:self.firstDate toDate:self.lastDate options:0].month;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    NSDate *firstOfMonth = [self firstOfMonthForSection:section];
    NSRange rangeOfWeeks = [self.calendar rangeOfUnit:NSWeekCalendarUnit inUnit:NSMonthCalendarUnit forDate:firstOfMonth];
    return (self.pinsHeaderToTop ? 0 : 1) + rangeOfWeeks.length;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.row == 0 && !self.pinsHeaderToTop) {
        // month header
        static NSString *identifier = @"header";
        TSQCalendarMonthHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [self makeHeaderCellWithIdentifier:identifier];
        }
        return cell;
    } else {
        static NSString *identifier = @"row";
        TSQCalendarRowCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[[self rowCellClass] alloc] initWithCalendar:self.calendar reuseIdentifier:identifier];
            cell.backgroundColor = self.backgroundColor;
            cell.calendarView = self;
        }
        return cell;
    }
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSDate *firstOfMonth = [self firstOfMonthForSection:indexPath.section];
    [(TSQCalendarCell *)cell setFirstOfMonth:firstOfMonth];
    if (indexPath.row > 0 || self.pinsHeaderToTop) {
        NSInteger ordinalityOfFirstDay = [self.calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSWeekCalendarUnit forDate:firstOfMonth];
        NSDateComponents *dateComponents = [NSDateComponents new];
        dateComponents.day = 1 - ordinalityOfFirstDay;
        dateComponents.week = indexPath.row - (self.pinsHeaderToTop ? 0 : 1);
        NSDate* rowBeginDate =[self.calendar dateByAddingComponents:dateComponents toDate:firstOfMonth options:0];
        [(TSQCalendarRowCell *)cell setBeginningDate:rowBeginDate];
        [(TSQCalendarRowCell *)cell selectColumnForDate:self.selectedDate];
        
        BOOL isBottomRow = (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - (self.pinsHeaderToTop ? 0 : 1));
        [(TSQCalendarRowCell *)cell setBottomRow:isBottomRow];
        
        TSQCalendarRowCell* row = (TSQCalendarRowCell *)cell;
        
        NSDate* rowStart = [row firstDateThisMonth];
        NSDate* rowEnd = [row lastDateThisMonth];
        
//        if ([rowStart timeIntervalSince1970] > [rowEnd timeIntervalSince1970])
//        {
//            for (DateButton* button in row.dayButtons)
//            {
//                NSLog(@"Button: %@",button.date);
//            }
//            rowStart = [row firstDateThisMonth];
//            rowEnd = [row lastDateThisMonth];
//        }
        
        OSHighlightedDate* highlight = [self highlightedDateForDateRangeFrom:rowStart toDate:rowEnd];
        
        if (highlight)
        {
            
            while(true)
            {
                [row setColourOfDatesFrom:highlight.dateFrom toDate:highlight.dateTo toColour:highlight.colour];
                
                //Since not all cells of this row might have been coloured, check the re
                NSArray* datesNotHighlightedByPreviousOperation = [row dateRangeThatAreNotContainedWithinFromDate:highlight.dateFrom toDate:highlight.dateTo];
                
               
                //check if there wwere any cells that werent highlighted
                if (datesNotHighlightedByPreviousOperation.count == 1)
                {
                    rowStart = rowEnd = datesNotHighlightedByPreviousOperation[0];
                    
                }
                else if(datesNotHighlightedByPreviousOperation.count ==2)
                {
                    rowStart = datesNotHighlightedByPreviousOperation[0];
                    rowEnd = datesNotHighlightedByPreviousOperation[1];
                }
                else
                    break;
                
                
                //we need to another check
                if (rowStart)
                {
                    highlight = [self highlightedDateForDateRangeFrom:rowStart toDate:rowEnd];
                    
                    if (!highlight)
                    {
                        [row setColourOfDatesFrom:rowStart toDate:rowEnd toColour:CalendarHighlightColourNone];
                        break;
                    }
                }
            }
            
        }
        else
        {
            
            NSArray* buttons =  row.dayButtons;//[row dateButtonsFromDate:_highlightedDateStart toDate:_highlightedDateEnd];
            
            for (DateButton* button in buttons)
            {
                button.backgroundColor = CalendarHighlightColourNone;
            }

        }

        
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return [[self cellClassForRowAtIndexPath:indexPath] cellHeight];
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset;
{
    if (self.pagingEnabled) {
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:*targetContentOffset];
        // If the target offset is at the third row or later, target the next month; otherwise, target the beginning of this month.
        NSInteger section = indexPath.section;
        if (indexPath.row > 2) {
            section++;
        }
        CGRect sectionRect = [self.tableView rectForSection:section];
        *targetContentOffset = sectionRect.origin;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
{
    if (self.pinsHeaderToTop && self.tableView.visibleCells.count > 0) {
        TSQCalendarCell *cell = self.tableView.visibleCells[0];
        self.headerView.firstOfMonth = cell.firstOfMonth;
    }
}

- (NSDate *)clampDate:(NSDate *)date toComponents:(NSUInteger)unitFlags
{
    NSDateComponents *components = [self.calendar components:unitFlags fromDate:date];
    return [self.calendar dateFromComponents:components];
}

@end
