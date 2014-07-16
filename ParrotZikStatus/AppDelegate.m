//
//  AppDelegate.m
//  ParrotZikStatus
//
//  Created by Keelan Cumming on 2014-07-13.
//  Copyright (c) 2014 KeelanCumming. All rights reserved.
//

#import "AppDelegate.h"
#import "ParrotZik.h"

@interface AppDelegate () 

@property (nonatomic, retain) NSString *macAddress;

@property (nonatomic, retain) NSStatusItem *statusItem;
@property (nonatomic, retain) NSMenu *menu;

@property (nonatomic, retain) NSMenuItem *friendlyNameMenuItem;
@property (nonatomic, retain) NSMenuItem *firmwareVersionMenuItem;
@property (nonatomic, retain) NSMenuItem *batteryStatusMenuItem;
@property (nonatomic, retain) NSMenuItem *batteryLevelMenuItem;

@property (nonatomic, retain) NSMenuItem *noiseCancelingMenuItem;

@property (nonatomic, retain) NSTimer *updateTimer;

@property (nonatomic, retain) ParrotZik *zik;

@end

@implementation AppDelegate

- (void)setDefaultProperties
{
    // TODO get this from somewhere!
    self.macAddress = @"90:03:B7:AE:7A:4C";
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setDefaultProperties];
    
    // New Parrot Zik object
    self.zik = [[ParrotZik alloc] initWithMacAddress:self.macAddress];
    
    [self initializeStatusBar];
    
    // TODO now using timer, however this could be done with delegate methods from Zik object when stuff changes
    self.updateTimer = [NSTimer
                    scheduledTimerWithTimeInterval:(15.0)
                    target:self
                    selector:@selector(refreshMenuData)
                    userInfo:nil
                    repeats:YES];
    
    [self.updateTimer fire];
}

- (void)initializeStatusBar {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setTitle:@"Zik"];
    [self.statusItem setEnabled:YES];
    [self.statusItem setToolTip:@"WTLP Parrot Zik Status App"];
    
    self.menu = [[NSMenu alloc] init];
    
    [self.statusItem setMenu:self.menu];
    
    // TODO make these not all say connecting
    self.friendlyNameMenuItem = [[NSMenuItem alloc] initWithTitle:@"Connecting..." action:nil keyEquivalent:@""];
    [self.friendlyNameMenuItem setTarget:self];
    [self.menu insertItem:self.friendlyNameMenuItem atIndex:0];
}


#pragma Formatting methods

- (NSString*)formatFriendlyName {
    return [NSString stringWithFormat:@"%@", self.zik.friendlyName];
}

- (NSString*)formatFirmware {
    return [NSString stringWithFormat:@"Firmware %@", self.zik.firmwareVersion];
}

- (NSString*)formatBattery {
    return [NSString stringWithFormat:@"Battery %@%% (%@)", self.zik.batteryLevel, self.zik.batteryStatus];
}

- (NSString*)formatNoiseCanceling {
    return (self.zik.noiseCancelingEnabled.boolValue ? @"Turn Noise Canceling Off" : @"Turn Noise Canceling On");
}


#pragma Triggered events

- (void)refreshMenuData {
    
    // If we have a connection
    if (self.zik.friendlyName != nil) {
        
        // Initialize menu items if not already initialized
        if (nil == self.firmwareVersionMenuItem && nil != self.zik.firmwareVersion) {
            self.firmwareVersionMenuItem = [[NSMenuItem alloc] initWithTitle:[self formatFirmware] action:nil keyEquivalent:@""];
            [self.firmwareVersionMenuItem setTarget:self];
            [self.menu insertItem:self.firmwareVersionMenuItem atIndex:1];
        }
        if (nil == self.batteryStatusMenuItem && nil != self.zik.batteryStatus) {
            self.batteryStatusMenuItem = [[NSMenuItem alloc] initWithTitle:[self formatBattery] action:nil keyEquivalent:@""];
            [self.batteryStatusMenuItem setTarget:self];
            [self.menu insertItem:self.batteryStatusMenuItem atIndex:2];
        }
        if (nil == self.noiseCancelingMenuItem && nil != self.zik.noiseCancelingEnabled) {
            self.noiseCancelingMenuItem = [[NSMenuItem alloc] initWithTitle:[self formatNoiseCanceling] action:@selector(toggleNoiseCancelling) keyEquivalent:@""];
            [self.noiseCancelingMenuItem setTarget:self];
            [self.menu insertItem:self.noiseCancelingMenuItem atIndex:3];
        }
        
        // Update everything
        self.friendlyNameMenuItem.title = [self formatFriendlyName];
        self.firmwareVersionMenuItem.title = [self formatFirmware];
        self.batteryStatusMenuItem.title = [self formatBattery];
        self.noiseCancelingMenuItem.title = [self formatNoiseCanceling];
    }
}

- (void)toggleNoiseCancelling {
    if (self.zik.noiseCancelingEnabled.boolValue == YES) {
        self.zik.noiseCancelingEnabled = @NO;
        self.noiseCancelingMenuItem.title = [self formatNoiseCanceling];
    } else {
        self.zik.noiseCancelingEnabled = @YES;
        self.noiseCancelingMenuItem.title = [self formatNoiseCanceling];
    }
}

@end
