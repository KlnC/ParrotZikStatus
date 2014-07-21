//
//  ParrotZikProtocol.h
//  ParrotZikStatus
//
//  Created by Keelan Cumming on 2014-07-13.
//  Copyright (c) 2014 KeelanCumming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

@protocol ParrotZikDelegate <NSObject>

- (void)zikReady;
- (void)zikDisconnected;
- (void)zikDataChanged;

@end

@interface ParrotZik : NSObject {
    id <ParrotZikDelegate> delegate;
}

@property (retain) id delegate;

// Bluetooth address
@property (nonatomic, retain) NSString *macAddress;
@property (nonatomic, retain) NSNumber *isReady; // Boolean

// Zik read properties
@property (nonatomic, retain) NSNumber *deviceType;
@property (nonatomic, retain) NSString *friendlyName;
@property (nonatomic, retain) NSString *firmwareVersion;
@property (nonatomic, retain) NSString *batteryLevel; // Out of 100
@property (nonatomic, retain) NSString *batteryStatus; // Charging, In Use

// Zik read/write properties
@property (nonatomic, retain) NSNumber *noiseCancelingEnabled; // Boolean
@property (nonatomic, retain) NSNumber *louReedEnabled; // Boolean

@property (nonatomic, retain) NSNumber *concertHallEnabled; // Boolean
@property (nonatomic, retain) NSNumber *concertHallCurrentRoomSize; // Index
@property (nonatomic, retain) NSNumber *concertHallCurrentAngle; // Index

@property (nonatomic, retain) NSNumber *equalizerEnabled; // Boolean
@property (nonatomic, retain) NSNumber *equalizerCurrentPreset; // Index

// List tables
@property (nonatomic, retain) NSArray *equalizerPresets;
@property (nonatomic, retain) NSArray *concertHallRoomSizes;
@property (nonatomic, retain) NSArray *concertHallAngles;

// Custom initialization
- (id)initWithBluetoothDevice:(IOBluetoothDevice*)device;
+ (void)findRfCommChannelOnDevice:(IOBluetoothDevice*)device withChannel:(BluetoothRFCOMMChannelID*)newChan;

@end
