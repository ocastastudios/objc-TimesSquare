//
//  OSHighlightColour.h
//  TimesSquare
//
//  Created by Chris Birch on 24/01/2014.
//  Copyright (c) 2014 Square. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum
{
    CalendarHighlightColourNone,
    CalendarHighlightColourOne,
    CalendarHighlightColourTwo,
    CalendarHighlightColourThree,
    CalendarHighlightColourFour,
    CalendarHighlightColourFive
    
} CalendarHighlightColour;


#define CAL_COLOUR_NONE [UIColor clearColor]
#define CAL_COLOUR_1 [UIColor redColor]
#define CAL_COLOUR_2 [UIColor greenColor]
#define CAL_COLOUR_3 [UIColor orangeColor]
#define CAL_COLOUR_4 [UIColor yellowColor]
#define CAL_COLOUR_5 [UIColor blueColor]