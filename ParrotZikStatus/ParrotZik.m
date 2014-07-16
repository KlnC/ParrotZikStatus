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
@property (nonatomic) BOOL connectionOpened;

@property (nonatomic, retain) NSDictionary *argsDictionary;
@property (nonatomic, retain) NSDictionary *reverseArgsDictionary;
@property (nonatomic, retain) NSDictionary *batteryStatusDictionary;

@end

@implementation ParrotZik

#pragma Initialization of Zik device

- (id)initWithMacAddress:(NSString*)macAddress {
    
    self = [super init];
    if (self) {
        
        _macAddress = macAddress;
        
        [self initializeDefaultProperties];
        [self setUpBluetoothConnection];
    }
    
    return self;
}

- (void)initializeDefaultProperties {
    self.argsDictionary = @{[NSNumber numberWithBool:true]: @"true", [NSNumber numberWithBool:false]: @"false"};
    self.reverseArgsDictionary = @{@"true": [NSNumber numberWithBool:true], @"false": [NSNumber numberWithBool:false]};
    self.batteryStatusDictionary = @{@"in_use": @"in use", @"charging": @"charging"};
}

#pragma Getter and Setter methods

- (NSString*)getFriendlyName {
    
    return _friendlyName;
}

- (NSString*)getFirmwareVersion {
    
    return _firmwareVersion;
}

- (NSNumber*)getNoiseCancelingEnabled {
    
    return _noiseCancelingEnabled;
}
- (void)setNoiseCancelingEnabled:(NSNumber*)isEnabled {
    
    // Create set command
    [self setRequest:@"/api/audio/noise_cancellation/enabled/set" withArgs:self.argsDictionary[isEnabled]];
    
    // TODO in the future we should only change this once Zik device has verified it's been done
    _noiseCancelingEnabled = isEnabled;
}

- (NSNumber*)getLouReedEnabled {
    
    return _louReedEnabled;
}
- (void)setLouReedEnabled:(NSNumber*)isEnabled {
#warning TODO
}

- (NSNumber*)getConcertHallEnabled {
    
    return _concertHallEnabled;
}
- (void)setConcertHallEnabled:(NSNumber*)isEnabled {
#warning TODO
}

- (NSNumber*)getEqualizerEnabled {
    
    return _equalizerEnabled;
}
- (void)setEqualizerEnabled:(NSNumber*)isEnabled {
#warning TODO
}

- (NSString*)getBatteryLevel {
    
    return _batteryLevel;
}

- (NSString*)getBatteryStatus {
    
    return _batteryStatus;
}


#pragma Specific Parrot Zik requests

- (void)refreshAllData {
    
    // Send multiple requests for data
    [self getRequest:@"/api/system/battery/get"];
    [self getRequest:@"/api/software/version/get"];
    [self getRequest:@"/api/bluetooth/friendlyname/get"];
    
    [self getRequest:@"/api/audio/noise_cancellation/enabled/get"];
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

- (void)setUpBluetoothConnection {
    _btDevice = nil;
    self.connectionOpened = false;
    _btDevice = [IOBluetoothDevice deviceWithAddressString:self.macAddress];
    if(_btDevice != nil) {
        [self connectToDevice];
    } else {
        NSLog(@"Could not connect to device!");
    }
}

- (void)connectToDevice {
    if(_btDevice != nil) {
        
        // Perform query on device
        IOReturn ret = [_btDevice performSDPQuery:self];
        if (ret != kIOReturnSuccess) {
            NSLog(@"Something went wrong!");
            return;
        }
        
        BluetoothRFCOMMChannelID rfCommChan;
        
        // Check if device has rfcomm channel
        if([self findRfCommChannel:&rfCommChan] != kIOReturnSuccess)
            return;
        
        NSLog(@"Found rfcomm channel on device: %d",rfCommChan);
        self.connectionOpened = [self openConnection:&rfCommChan];
        
    } else {
        NSLog(@"Bluetooth device not Found!");
    }
}

-(IOReturn) findRfCommChannel:(BluetoothRFCOMMChannelID *) rfChan{
    
    if(self.btDevice == nil)
        return kIOReturnNotFound;
    
    IOReturn ret;
    
    NSArray* services = [_btDevice services];
    BluetoothRFCOMMChannelID newChan;
    for (IOBluetoothSDPServiceRecord* service in services) {
        NSLog(@"Service: %@", [service getServiceName]);
        ret = [service getRFCOMMChannelID:&newChan];
        if (ret == kIOReturnSuccess) {
            *rfChan = newChan;
            NSLog(@"ChannelID FOUND %d %d", newChan, *rfChan);
            return kIOReturnSuccess;
        }
    }
    
    return kIOReturnNotFound;
}

-(BOOL) openConnection:(BluetoothRFCOMMChannelID *) chanId{
    IOBluetoothRFCOMMChannel *channel;
    if ([_btDevice openRFCOMMChannelAsync:&channel withChannelID:*chanId delegate:self] != kIOReturnSuccess) {
        NSLog(@"Couldn't open channel!");
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
    // TODO make this more structured perhaps?
    
#warning Some of these dictionaries may not contain all possible options! Error handling required probably...
    if ([elementName isEqualToString:@"battery"]) {
        
        self.batteryStatus = self.batteryStatusDictionary[attributeDict[@"state"]];
        self.batteryLevel = attributeDict[@"level"];
        
    } else if ([elementName isEqualToString:@"software"]) {
        
        self.firmwareVersion = attributeDict[@"version"];
        
    } else if ([elementName isEqualToString:@"bluetooth"]) {
        
        self.friendlyName = attributeDict[@"friendlyname"];
        
    } else if ([elementName isEqualToString:@"noise_cancellation"]) {
        
        // Access ivar directly, since we don't want to trigger setting this property on the device
        _noiseCancelingEnabled = self.reverseArgsDictionary[attributeDict[@"enabled"]];
       
    } else if ([elementName isEqualToString:@"notify"]) {
        
        // This is a period battery notification, in this case, update battery levels/status
        [self getRequest:@"/api/system/battery/get"];
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    // Unused for now
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    // Unused for now
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    // Unused for now
}



@end
