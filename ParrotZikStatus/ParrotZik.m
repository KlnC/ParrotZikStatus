//
//  ParrotZikProtocol.m
//  ParrotZikStatus
//
//  Created by Keelan Cumming on 2014-07-13.
//  Copyright (c) 2014 KeelanCumming. All rights reserved.
//

#import "ParrotZik.h"

@interface ParrotZik () <NSXMLParserDelegate>

// Bluetooth connection properties
@property (nonatomic, retain) IOBluetoothDevice *btDevice;
@property (nonatomic, retain) IOBluetoothRFCOMMChannel *rfcommChannel;

@property (nonatomic, retain) NSDictionary *argsDictionary;
@property (nonatomic, retain) NSDictionary *reverseArgsDictionary;
@property (nonatomic, retain) NSDictionary *batteryStatusDictionary;
@property (nonatomic, retain) NSArray *concertHallRoomSizesZik;

@end

@implementation ParrotZik

#pragma Initialization of Zik device

- (id)initWithBluetoothDevice:(IOBluetoothDevice*)device {
    
    self = [super init];
    if (self) {
        
        _btDevice = device;
        
        [self initializeDefaultProperties];
        [self connectToDevice];
    }
    
    return self;
}

- (void)initializeDefaultProperties {
    
    // For translating between Zik strings and internal data
    self.argsDictionary = @{@YES: @"true", @NO: @"false"};
    self.reverseArgsDictionary = @{@"true": @YES, @"invalid_on": @YES, @"false": @NO, @"invalid_off": @NO};
    self.batteryStatusDictionary = @{@"in_use": @"In Use", @"charging": @"Charging", @"charged": @"Charged"};
    
    // List options presented externally
    self.concertHallRoomSizes = @[@"Silent Room", @"Living Room", @"Jazz Club", @"Concert Hall"];
    self.concertHallAngles = @[@"30", @"60", @"90", @"120", @"150", @"180"];
    self.equalizerPresets = @[@"Vocal", @"Pop", @"Club", @"Punchy", @"Deep", @"Crystal", @"User"];
    
    // Zik formatted list options
    self.concertHallRoomSizesZik = @[@"silent", @"living", @"jazz", @"concert"];
}

#pragma Getter and Setter methods

- (void)setNoiseCancelingEnabled:(NSNumber*)isEnabled {
    [self setRequest:@"/api/audio/noise_cancellation/enabled/set" withArgs:self.argsDictionary[isEnabled]];
    _noiseCancelingEnabled = isEnabled;
}

- (void)setLouReedEnabled:(NSNumber*)isEnabled {
    [self setRequest:@"/api/audio/specific_mode/enabled/set" withArgs:self.argsDictionary[isEnabled]];
    _louReedEnabled = isEnabled;
}

- (void)setConcertHallEnabled:(NSNumber*)isEnabled {
    [self setRequest:@"/api/audio/sound_effect/enabled/set" withArgs:self.argsDictionary[isEnabled]];
    _concertHallEnabled = isEnabled;
}

- (void)setConcertHallCurrentRoomSize:(NSNumber *)concertHallCurrentRoomSize {
    [self setRequest:@"/api/audio/sound_effect/room_size/set" withArgs:[self.concertHallRoomSizesZik objectAtIndex:concertHallCurrentRoomSize.integerValue]];
    _concertHallCurrentRoomSize = concertHallCurrentRoomSize;
}

- (void)setConcertHallCurrentAngle:(NSNumber *)concertHallCurrentAngle {
    [self setRequest:@"/api/audio/sound_effect/angle/set" withArgs:[self.concertHallAngles objectAtIndex:concertHallCurrentAngle.integerValue]];
    _concertHallCurrentAngle = concertHallCurrentAngle;
}

- (void)setEqualizerEnabled:(NSNumber*)isEnabled {
    [self setRequest:@"/api/audio/equalizer/enabled/set" withArgs:self.argsDictionary[isEnabled]];
    _equalizerEnabled = isEnabled;
}

- (void)setEqualizerCurrentPreset:(NSNumber *)equalizerCurrentPreset {
    [self setRequest:@"/api/audio/equalizer/preset_id/set" withArgs:[NSString stringWithFormat:@"%@", equalizerCurrentPreset]];
    _equalizerCurrentPreset = equalizerCurrentPreset;
}


#pragma Specific Parrot Zik requests

- (void)refreshAllData {
    
    // Get device type and software version
    [self getRequest:@"/api/system/device_type/get"];
    [self getRequest:@"/api/software/version/get"];
    
    // Get Lou Reed enabled
    [self getRequest:@"/api/audio/specific_mode/enabled/get"];
    
    // Get Noise Cancelation enabled
    [self getRequest:@"/api/audio/noise_cancellation/enabled/get"];
    
    // Get Concert Hall enabled and settings
    [self getRequest:@"/api/audio/sound_effect/get"];
    
    // Get Equalizer enabled and settings
    [self getRequest:@"/api/audio/equalizer/get"];
    
    // Get name and battery level/status
    [self getRequest:@"/api/bluetooth/friendlyname/get"];
    [self getRequest:@"/api/system/battery/get"];
}


#pragma Generic Parrot Zik request handling/formatting

- (NSMutableData*)generateRequest:(NSString*)requestString {
    
    // Request is composed of header and message data
    NSMutableData *message = [[NSMutableData alloc] initWithData:[self generateHeader:requestString]];
    [message appendData:[requestString dataUsingEncoding:NSUTF8StringEncoding]];
    return message;
}

- (NSMutableData*)generateHeader:(NSString*)requestString {
    
    // New header is composed of 3 bytes
    NSMutableData *header = [[NSMutableData alloc] init];
    
    // First 0x00
    unsigned char firstByte[1] = {0x00};
    [header appendBytes:firstByte length:1];
    
    // Then length of request to be passed
    unsigned char secondByte[1] = {requestString.length + 3};
    [header appendBytes:secondByte length:1];
    
    // Finally 0x80
    unsigned char thirdByte[1] = {0x80};
    [header appendBytes:thirdByte length:1];
    
    return header;
}

- (NSMutableData*)getRequest:(NSString*)apiString {
    
    // Get request is prefaced by GET
    NSMutableData *data = [self generateRequest:[NSString stringWithFormat:@"GET %@", apiString]] ;
    [self.rfcommChannel writeSync:(void*)[data bytes] length:[data length]];
    return data;
}

- (NSMutableData*)setRequest:(NSString*)apiString withArgs:(NSString*)args {
    
    // Set request is prefaced by SET, followed by ?arg=
    NSMutableData *data = [self generateRequest:[NSString stringWithFormat:@"SET %@?arg=%@", apiString, args]];
    [self.rfcommChannel writeSync:(void*)[data bytes] length:[data length]];
    return data;
}


#pragma Bluetooth connection stuff

- (void)connectToDevice {
    BluetoothRFCOMMChannelID rfCommChan;
    [ParrotZik findRfCommChannelOnDevice:self.btDevice withChannel:&rfCommChan];
    
    if (rfCommChan)
        [self openConnection:&rfCommChan];
}

+ (void)findRfCommChannelOnDevice:(IOBluetoothDevice*)device withChannel:(BluetoothRFCOMMChannelID*)newChan {

    NSArray* services = [device services];
    for (IOBluetoothSDPServiceRecord* service in services) {
        if ([[service getServiceName] isEqualToString:@"Parrot RFcomm service"]) {
            [service getRFCOMMChannelID:newChan];
        }
    }
}

-(BOOL) openConnection:(BluetoothRFCOMMChannelID *) chanId{
    IOBluetoothRFCOMMChannel *channel;
    if ([_btDevice openRFCOMMChannelAsync:&channel withChannelID:*chanId delegate:self] != kIOReturnSuccess) {
        NSLog(@"Couldn't open channel!");
        [[self delegate] zikDisconnected];
        return NO;
    }
    [channel setSerialParameters: 9600 dataBits: 8 parity: kBluetoothRFCOMMParityTypeNoParity stopBits: 2];
    [channel closeChannel];
    return YES;
}

// Delegate method called once rfcomm channel is open
- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel
                           status:(IOReturn)error {
    if (error != kIOReturnSuccess) {
        NSLog(@"Failed to open channel, error %d", error);
        [[self delegate] zikDisconnected];
        return;
    }
    
    NSLog(@"Channel MTU: %hu", [rfcommChannel getMTU]);
    
    self.rfcommChannel = rfcommChannel;
    
    // Initial command to open connection
    uint8_t bytes[] = { 0x00, 0x03, 0x00 };
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:bytes length:sizeof(bytes)];
    [rfcommChannel writeSync:(char*)[data bytes] length:[data length]];
    
    // Now that we have a connection opened, refresh all data
    [self refreshAllData];
}

- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel*)rfcommChannel {
    NSLog(@"Channel closed!");
    [[self delegate] zikDisconnected];
}


# pragma Delegate function called whenever we receive data from Zik

// This is called when data is read
- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength {
    
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:dataPointer length:dataLength];
    
    // Trim first 8 bytes for some reason
    if (dataLength > 6)
        [data replaceBytesInRange:NSMakeRange(0, 7) withBytes:nil length:0];
    
    // Log received data
    NSLog(@"Received: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    // Parse received data, where the parser function will figure out what to do with it
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    parser.delegate = self;
    [parser parse];
}


#pragma XML Parser stuff which figures out what to do with any returned data

- (void) parserDidStartDocument:(NSXMLParser *)parser {
    // Unused for now
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    // This is the function where we grab the element and figure out what ivar to change
    // Access ivars directly, since we don't want to trigger setting these properties on the device
    
#warning Some of these dictionaries may not contain all possible options! Error handling required probably...
    if ([elementName isEqualToString:@"battery"]) {
        _batteryStatus = self.batteryStatusDictionary[attributeDict[@"state"]];
        _batteryLevel = attributeDict[@"level"];
    } else if ([elementName isEqualToString:@"specific_mode"]) {
        _louReedEnabled = self.reverseArgsDictionary[attributeDict[@"enabled"]];
    } else if ([elementName isEqualToString:@"device_type"]) {
        _deviceType = attributeDict[@"value"];
    } else if ([elementName isEqualToString:@"software"]) {
        _firmwareVersion = attributeDict[@"version"];
    } else if ([elementName isEqualToString:@"bluetooth"]) {
        _friendlyName = attributeDict[@"friendlyname"];
    } else if ([elementName isEqualToString:@"noise_cancellation"]) {
        _noiseCancelingEnabled = self.reverseArgsDictionary[attributeDict[@"enabled"]];
    } else if ([elementName isEqualToString:@"sound_effect"]) {
        _concertHallEnabled = self.reverseArgsDictionary[attributeDict[@"enabled"]];
        _concertHallCurrentRoomSize = @([self.concertHallRoomSizesZik indexOfObject:attributeDict[@"room_size"]]);
        _concertHallCurrentAngle = @([self.concertHallAngles indexOfObject:attributeDict[@"angle"]]);
    } else if ([elementName isEqualToString:@"equalizer"]) {
        _equalizerEnabled = self.reverseArgsDictionary[attributeDict[@"enabled"]];
        _equalizerCurrentPreset = attributeDict[@"preset_id"];
    } else if ([elementName isEqualToString:@"notify"]) {
        // This is a period battery notification, in this case, update battery levels/status
        [self getRequest:@"/api/system/battery/get"];
    }
    [self checkIfReady];
}

- (void)checkIfReady
{
    if (self.batteryStatus &&
        self.batteryLevel &&
        self.louReedEnabled &&
        self.noiseCancelingEnabled &&
        self.concertHallEnabled &&
        self.equalizerEnabled &&
        self.friendlyName &&
        self.deviceType &&
        self.firmwareVersion &&
        self.concertHallCurrentRoomSize &&
        self.concertHallCurrentAngle &&
        self.equalizerCurrentPreset) {
        
        if (!self.isReady.boolValue) {
            self.isReady = @YES;
            [[self delegate] zikReady];
        }
        
        [[self delegate] zikDataChanged];
    }
}

@end
