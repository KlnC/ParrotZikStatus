//
//  AppDelegate.m
//  ParrotZikStatus
//
//  Created by Keelan Cumming on 2014-07-13.
//  Copyright (c) 2014 KeelanCumming. All rights reserved.
//

#import "AppDelegate.h"
#import "ParrotZik.h"

@interface AppDelegate () <ParrotZikDelegate>

@property (nonatomic, retain) NSString *macAddress;

@property (nonatomic, retain) NSStatusItem *statusItem;
@property (nonatomic, retain) NSMenu *menu;
@property (nonatomic, retain) NSMenu *equalizerPresetMenu;
@property (nonatomic, retain) NSMenu *concertHallRoomSizeMenu;
@property (nonatomic, retain) NSMenu *concertHallAngleMenu;

@property (nonatomic, retain) NSMenuItem *friendlyNameMenuItem;
@property (nonatomic, retain) NSMenuItem *firmwareVersionMenuItem;
@property (nonatomic, retain) NSMenuItem *batteryStatusMenuItem;
@property (nonatomic, retain) NSMenuItem *batteryLevelMenuItem;

@property (nonatomic, retain) NSMenuItem *noiseCancelingMenuItem;
@property (nonatomic, retain) NSMenuItem *equalizerMenuItem;
@property (nonatomic, retain) NSMenuItem *concertHallMenuItem;
@property (nonatomic, retain) NSMenuItem *louReedMenuItem;

@property (nonatomic, retain) NSTimer *updateTimer;

@property (nonatomic, retain) ParrotZik *zik;

@end

@implementation AppDelegate

- (void)setDefaultProperties
{
    // TODO get this from somewhere!
    self.macAddress = @"90:03:B7:AE:7A:4C";
}

- (void)zikReady {
    [self initializeMenuItems];
}

- (void)zikDataChanged {
    [self refreshMenuData];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setDefaultProperties];
    
    // New Parrot Zik object
    self.zik = [[ParrotZik alloc] initWithMacAddress:self.macAddress];
    self.zik.delegate = self;
    
    [self initializeStatusBar];
    
    // TODO now using timer, however this could be done with delegate methods from Zik object when stuff changes
//    self.updateTimer = [NSTimer
//                    scheduledTimerWithTimeInterval:(15.0)
//                    target:self
//                    selector:@selector(refreshMenuData)
//                    userInfo:nil
//                    repeats:YES];
//    
//    [self.updateTimer fire];
}

- (void)initializeStatusBar {
    
    // Initialize a status item (menu header)
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setTitle:@"Zik"];
    [self.statusItem setEnabled:YES];
    [self.statusItem setToolTip:@"WTLP Parrot Zik Status App"];
    
    self.menu = [[NSMenu alloc] init];
    
    [self.statusItem setMenu:self.menu];
    
    // Initialize a connecting item
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


#pragma Triggered events

- (void)refreshMenuData {
    
    // If we have a connection
    if (self.zik.friendlyName != nil) {
        
        // Update everything
        self.friendlyNameMenuItem.title = [self formatFriendlyName];
        self.firmwareVersionMenuItem.title = [self formatFirmware];
        self.batteryStatusMenuItem.title = [self formatBattery];
        self.noiseCancelingMenuItem.state = self.zik.noiseCancelingEnabled.boolValue ? NSOnState : NSOffState;
        self.equalizerMenuItem.state = self.zik.equalizerEnabled.boolValue ? NSOnState : NSOffState;
        self.concertHallMenuItem.state = self.zik.concertHallEnabled.boolValue ? NSOnState : NSOffState;
        self.louReedMenuItem.state = self.zik.louReedEnabled.boolValue ? NSOnState : NSOffState;
        
        if (self.zik.louReedEnabled.boolValue) {
            [self.equalizerMenuItem setAction:nil];
            [self.concertHallMenuItem setAction:nil];
        } else {
            [self.equalizerMenuItem setAction:@selector(toggleEqualizer)];
            [self.concertHallMenuItem setAction:@selector(toggleConcertHall)];
        }
    }
}

- (void)toggleNoiseCancelling {
    self.zik.noiseCancelingEnabled = self.zik.noiseCancelingEnabled.boolValue ? @NO : @YES;
    [self refreshMenuData];
}
- (void)toggleEqualizer {
    self.zik.equalizerEnabled = self.zik.equalizerEnabled.boolValue ? @NO : @YES;
    [self refreshMenuData];
}
- (void)toggleConcertHall {
    self.zik.concertHallEnabled = self.zik.concertHallEnabled.boolValue ? @NO : @YES;
    [self refreshMenuData];
}
- (void)toggleLouReed {
    self.zik.louReedEnabled = self.zik.louReedEnabled.boolValue ? @NO : @YES;
    [self refreshMenuData];
}

- (void)initializeMenuItems
{
    // Initialize menu items if not already initialized
    self.firmwareVersionMenuItem = [[NSMenuItem alloc] initWithTitle:[self formatFirmware] action:nil keyEquivalent:@""];
    [self.firmwareVersionMenuItem setTarget:self];
    [self.menu insertItem:self.firmwareVersionMenuItem atIndex:1];

    self.batteryStatusMenuItem = [[NSMenuItem alloc] initWithTitle:[self formatBattery] action:nil keyEquivalent:@""];
    [self.batteryStatusMenuItem setTarget:self];
    [self.menu insertItem:self.batteryStatusMenuItem atIndex:2];

    self.noiseCancelingMenuItem = [[NSMenuItem alloc] initWithTitle:@"Noise Canceling" action:@selector(toggle:) keyEquivalent:@""];
    [self.noiseCancelingMenuItem setRepresentedObject:self.zik.noiseCancelingEnabled];
    [self.noiseCancelingMenuItem setTarget:self];
    [self.menu insertItem:self.noiseCancelingMenuItem atIndex:3];

    self.equalizerMenuItem = [[NSMenuItem alloc] initWithTitle:@"Equalizer" action:@selector(toggleEqualizer) keyEquivalent:@""];
    [self.equalizerMenuItem setTarget:self];
    [self.menu insertItem:self.equalizerMenuItem atIndex:4];

    self.concertHallMenuItem = [[NSMenuItem alloc] initWithTitle:@"Concert Hall" action:@selector(toggleConcertHall) keyEquivalent:@""];
    [self.concertHallMenuItem setTarget:self];
    [self.menu insertItem:self.concertHallMenuItem atIndex:5];

    self.louReedMenuItem = [[NSMenuItem alloc] initWithTitle:@"Lou Reed" action:@selector(toggleLouReed) keyEquivalent:@""];
    [self.louReedMenuItem setTarget:self];
    [self.menu insertItem:self.louReedMenuItem atIndex:6];
    
//    self.equalizerPresetMenuItem = [[NSMenuItem alloc] initWithTitle:@"Equalizer Preset" action:nil keyEquivalent:@""];
//    [self.equalizerPresetMenuItem setTarget:self];
//    [self.menu insertItem:self.equalizerPresetMenuItem atIndex:7];
//    [self.equalizerPresetMenuItem setMenu:self.equalizerPresetMenu];
//    
//    self.concertHallMenuItem = [[NSMenuItem alloc] initWithTitle:@"Concert Hall Room Size" action:nil keyEquivalent:@""];
//    [self.concertHallMenuItem setTarget:self];
//    [self.menu insertItem:self.concertHallMenuItem atIndex:8];
//    
//    self.louReedMenuItem = [[NSMenuItem alloc] initWithTitle:@"Concert Hall Angle" action:nil keyEquivalent:@""];
//    [self.louReedMenuItem setTarget:self];
//    [self.menu insertItem:self.louReedMenuItem atIndex:9];
    
    [self refreshMenuData];
}

@end
