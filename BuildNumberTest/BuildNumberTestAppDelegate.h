//
//  BuildNumberTestAppDelegate.h
//  BuildNumberTest
//
//  Created by Scott Densmore on 7/19/11.
//  Copyright 2011 Scott Densmore. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BuildNumberTestAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
