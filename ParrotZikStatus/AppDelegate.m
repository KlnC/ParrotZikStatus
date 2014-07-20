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

@property (nonatomic, retain) NSMenuItem *firstSeparatorMenuItem;
@property (nonatomic, retain) NSMenuItem *secondSeparatorMenuItem;

// Status menu items
@property (nonatomic, retain) NSMenuItem *friendlyNameMenuItem;
@property (nonatomic, retain) NSMenuItem *firmwareVersionMenuItem;
@property (nonatomic, retain) NSMenuItem *batteryStatusMenuItem;

// Enable/disable menu items
@property (nonatomic, retain) NSMenuItem *noiseCancelingMenuItem;
@property (nonatomic, retain) NSMenuItem *equalizerMenuItem;
@property (nonatomic, retain) NSMenuItem *concertHallMenuItem;
@property (nonatomic, retain) NSMenuItem *louReedMenuItem;

// Dropdown list menu items
@property (nonatomic, retain) NSMenuItem *equalizerPresetMenuItem;
@property (nonatomic, retain) NSMenuItem *concertHallRoomSizeMenuItem;
@property (nonatomic, retain) NSMenuItem *concertHallAngleMenuItem;

// Zik object reference
@property (nonatomic, retain) ParrotZik *zik;

@end

@implementation AppDelegate

- (void)setDefaultProperties
{
    // TODO get this from somewhere!
    self.macAddress = @"90:03:B7:AE:7A:4C";
}

- (void)zikReady {
    [self refreshMenuData];
}

- (void)zikDataChanged {
    [self refreshMenuData];
}

- (void)zikDisconnected {
    [self hideUnhideMenuItems:YES];
    [self.friendlyNameMenuItem setTitle:@"Connecting..."];
    
    // New Parrot Zik object
    ParrotZik *newZik = [[ParrotZik alloc] initWithMacAddress:self.macAddress];
    self.zik = newZik;
    self.zik.delegate = self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setDefaultProperties];

    // Set up status bar
    [self initializeStatusBar];
    
    // New Parrot Zik object
    ParrotZik *newZik = [[ParrotZik alloc] initWithMacAddress:self.macAddress];
    self.zik = newZik;
    self.zik.delegate = self;
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
    
    [self initializeMenuItems];
    [self hideUnhideMenuItems:YES];
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
        
        // Unhide all
        [self hideUnhideMenuItems:NO];
        
        // Update everything
        self.friendlyNameMenuItem.title = [self formatFriendlyName];
        self.firmwareVersionMenuItem.title = [self formatFirmware];
        self.batteryStatusMenuItem.title = [self formatBattery];
        self.noiseCancelingMenuItem.state = self.zik.noiseCancelingEnabled.boolValue ? NSOnState : NSOffState;
        self.equalizerMenuItem.state = self.zik.equalizerEnabled.boolValue ? NSOnState : NSOffState;
        self.concertHallMenuItem.state = self.zik.concertHallEnabled.boolValue ? NSOnState : NSOffState;
        self.louReedMenuItem.state = self.zik.louReedEnabled.boolValue ? NSOnState : NSOffState;
        
        [self initializePresetsMenus];
        
        if (self.zik.louReedEnabled.boolValue) {
            [self.equalizerMenuItem setAction:nil];
            [self.concertHallMenuItem setAction:nil];
        } else {
            [self.equalizerMenuItem setAction:@selector(toggleEqualizer)];
            [self.concertHallMenuItem setAction:@selector(toggleConcertHall)];
        }
    }
}

- (void)initializePresetsMenus {
    
    // Initialize presets menu
    self.equalizerPresetMenu = [[NSMenu alloc] init];
    for (int i = 0; i < self.zik.equalizerPresets.count; i++) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[self.zik.equalizerPresets objectAtIndex:i] action:@selector(selectEqualizerPreset:) keyEquivalent:@""];
        [menuItem setRepresentedObject:@(i)];
        menuItem.state = (self.zik.equalizerCurrentPreset.integerValue == i) ? NSOnState : NSOffState;
        [self.equalizerPresetMenu insertItem:menuItem atIndex:i];
    }
    [self.equalizerPresetMenuItem setSubmenu:self.equalizerPresetMenu];
    
    // Initialize room sizes menu
    self.concertHallRoomSizeMenu = [[NSMenu alloc] init];
    
    for (int i = 0; i < self.zik.concertHallRoomSizes.count; i++) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[self.zik.concertHallRoomSizes objectAtIndex:i] action:@selector(selectConcertHallRoomSize:) keyEquivalent:@""];
        [menuItem setRepresentedObject:@(i)];
        menuItem.state = (self.zik.concertHallCurrentRoomSize.integerValue == i) ? NSOnState : NSOffState;
        [self.concertHallRoomSizeMenu insertItem:menuItem atIndex:i];
    }
    [self.concertHallRoomSizeMenuItem setSubmenu:self.concertHallRoomSizeMenu];
    
    // Initialize room sizes menu
    self.concertHallAngleMenu = [[NSMenu alloc] init];
    for (int i = 0; i < self.zik.concertHallAngles.count; i++) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@", [self.zik.concertHallAngles objectAtIndex:i]] action:@selector(selectConcertHallAngle:) keyEquivalent:@""];
        [menuItem setRepresentedObject:@(i)];
        menuItem.state = (self.zik.concertHallCurrentAngle.integerValue == i) ? NSOnState : NSOffState;
        [self.concertHallAngleMenu insertItem:menuItem atIndex:i];
    }
    [self.concertHallAngleMenuItem setSubmenu:self.concertHallAngleMenu];
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

- (void)hideUnhideMenuItems:(BOOL)hidden {
    [self.firmwareVersionMenuItem setHidden:hidden];
    [self.batteryStatusMenuItem setHidden:hidden];
    [self.firmwareVersionMenuItem setHidden:hidden];
    
    [self.noiseCancelingMenuItem setHidden:hidden];
    [self.louReedMenuItem setHidden:hidden];
    [self.equalizerMenuItem setHidden:hidden];
    [self.concertHallMenuItem setHidden:hidden];
    
    [self.equalizerPresetMenuItem setHidden:hidden];
    [self.concertHallRoomSizeMenuItem setHidden:hidden];
    [self.concertHallAngleMenuItem setHidden:hidden];
    
    [self.firstSeparatorMenuItem setHidden:hidden];
    [self.secondSeparatorMenuItem setHidden:hidden];
}

- (void)initializeMenuItems
{
    // Status Menu Items
    self.firmwareVersionMenuItem = [[NSMenuItem alloc] initWithTitle:[self formatFirmware] action:nil keyEquivalent:@""];
    [self.firmwareVersionMenuItem setTarget:self];
    [self.menu insertItem:self.firmwareVersionMenuItem atIndex:1];

    self.batteryStatusMenuItem = [[NSMenuItem alloc] initWithTitle:[self formatBattery] action:nil keyEquivalent:@""];
    [self.batteryStatusMenuItem setTarget:self];
    [self.menu insertItem:self.batteryStatusMenuItem atIndex:2];

    // Separator
    self.firstSeparatorMenuItem = [NSMenuItem separatorItem];
    [self.menu insertItem:self.firstSeparatorMenuItem atIndex:3];
    
    // Enable/disable settings
    self.noiseCancelingMenuItem = [[NSMenuItem alloc] initWithTitle:@"Noise Canceling" action:@selector(toggleNoiseCancelling) keyEquivalent:@""];
    [self.noiseCancelingMenuItem setTarget:self];
    [self.menu insertItem:self.noiseCancelingMenuItem atIndex:4];
    
    self.louReedMenuItem = [[NSMenuItem alloc] initWithTitle:@"Lou Reed" action:@selector(toggleLouReed) keyEquivalent:@""];
    [self.louReedMenuItem setTarget:self];
    [self.menu insertItem:self.louReedMenuItem atIndex:5];
    
    self.equalizerMenuItem = [[NSMenuItem alloc] initWithTitle:@"Equalizer" action:@selector(toggleEqualizer) keyEquivalent:@""];
    [self.equalizerMenuItem setTarget:self];
    [self.menu insertItem:self.equalizerMenuItem atIndex:6];

    self.concertHallMenuItem = [[NSMenuItem alloc] initWithTitle:@"Concert Hall" action:@selector(toggleConcertHall) keyEquivalent:@""];
    [self.concertHallMenuItem setTarget:self];
    [self.menu insertItem:self.concertHallMenuItem atIndex:7];

    // Separator
    self.secondSeparatorMenuItem = [NSMenuItem separatorItem];
    [self.menu insertItem:self.secondSeparatorMenuItem atIndex:8];
    
    // Dropdown submenus
    self.equalizerPresetMenuItem = [[NSMenuItem alloc] initWithTitle:@"Equalizer Preset" action:nil keyEquivalent:@""];
    [self.equalizerPresetMenuItem setTarget:self];
    [self.menu insertItem:self.equalizerPresetMenuItem atIndex:9];
    
    self.concertHallRoomSizeMenuItem = [[NSMenuItem alloc] initWithTitle:@"Concert Hall Room Size" action:nil keyEquivalent:@""];
    [self.concertHallRoomSizeMenuItem setTarget:self];
    [self.menu insertItem:self.concertHallRoomSizeMenuItem atIndex:10];
    
    self.concertHallAngleMenuItem = [[NSMenuItem alloc] initWithTitle:@"Concert Hall Angle" action:nil keyEquivalent:@""];
    [self.concertHallAngleMenuItem setTarget:self];
    [self.menu insertItem:self.concertHallAngleMenuItem atIndex:11];
    
    [self refreshMenuData];
}

- (void)selectEqualizerPreset:(id)menuItem {
    self.zik.equalizerCurrentPreset = [menuItem representedObject];
    [self refreshMenuData];
}

- (void)selectConcertHallRoomSize:(id)menuItem {
    self.zik.concertHallCurrentRoomSize = [menuItem representedObject];
    [self refreshMenuData];
}

- (void)selectConcertHallAngle:(id)menuItem {
    self.zik.concertHallCurrentAngle = [menuItem representedObject];
    [self refreshMenuData];
}

@end
