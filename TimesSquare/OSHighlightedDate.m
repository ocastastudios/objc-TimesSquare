//
//  OSHighlightedDate.m
//  TimesSquare
//
//  Created by Chris Birch on 24/01/2014.
//  Copyright (c) 2014 Square. All rights reserved.
//

#import "OSHighlightedDate.h"

@implementation OSHighlightedDate


-(NSString *)description
{
    return [[NSString alloc] initWithFormat:@"Highlighted Date Range: %@ - %@", _dateFrom, _dateTo];
}
@end
