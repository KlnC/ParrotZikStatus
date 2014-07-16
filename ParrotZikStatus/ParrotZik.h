//
//  ParrotZikProtocol.h
//  ParrotZikStatus
//
//  Created by Keelan Cumming on 2014-07-13.
//  Copyright (c) 2014 KeelanCumming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

@interface ParrotZik : NSObject

// Bluetooth address
@property (nonatomic, retain) NSString *macAddress;

// Zik read properties
@property (nonatomic, retain) NSString *friendlyName;
@property (nonatomic, retain) NSString *firmwareVersion;
@property (nonatomic, retain) NSString *batteryLevel; // Out of 100
@property (nonatomic, retain) NSString *batteryStatus; // Charging, In Use

// Zik read/write properties
@property (nonatomic, retain) NSNumber *noiseCancelingEnabled; // Boolean
@property (nonatomic, retain) NSNumber *louReedEnabled; // Boolean
@property (nonatomic, retain) NSNumber *concertHallEnabled; // Boolean
@property (nonatomic, retain) NSNumber *equalizerEnabled; // Boolean

// Custom initialization
- (id)initWithMacAddress:(NSString*)macAddress;

@end
