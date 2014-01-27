//
//  OSHighlightedDate.h
//  TimesSquare
//
//  Created by Chris Birch on 24/01/2014.
//  Copyright (c) 2014 Square. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSHighlightColour.h"

@interface OSHighlightedDate : NSObject

@property (nonatomic,strong) NSDate* dateFrom;
@property (nonatomic,strong) NSDate* dateTo;
@property (nonatomic,assign) CalendarHighlightColour colour;

@end
