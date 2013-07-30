//
//  DRViewController.m
//  CBBackgroundSpike
//
//  Created by Daniel R on 7/30/13.
//  Copyright (c) 2013 Daniel R. All rights reserved.
//


#import "DRViewController.h"
#import "UIView+DRAutolayout.h"
#import "NSLayoutConstraint+DRAutolayout.h"

@interface DRViewController ()
@property UITextView* statusLogView;
@property CBCentralManager* manager;
@property CBPeripheral* peripheral;
@end

@implementation DRViewController

-(void)loadView {
    
    
    self.view = [[UIView alloc] init];
    self.view.backgroundColor = [UIColor grayColor];
    self.statusLogView = [[UITextView alloc] init];
    self.statusLogView.scrollEnabled = YES;
    self.statusLogView.editable = NO;
    self.statusLogView.bounces = YES;
    self.statusLogView.alwaysBounceHorizontal = YES;
    self.statusLogView.alwaysBounceVertical = YES;
    self.statusLogView.font = [UIFont systemFontOfSize:22];
    self.statusLogView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.statusLogView];
}


-(NSString*)stringForCBCentralManagerState:(CBCentralManagerState)state {
    if (state == CBCentralManagerStateUnknown) return @"Unknown";
    if (state == CBCentralManagerStateResetting) return @"Resetting";
    if (state == CBCentralManagerStateUnsupported) return @"Unsupported";
    if (state == CBCentralManagerStateUnauthorized) return @"Unauthorized";
    if (state == CBCentralManagerStatePoweredOff) return @"Powered Off";
    if (state == CBCentralManagerStatePoweredOn) return @"Powered On";
    
    return @"wtf";
}


-(void)viewDidLoad{
    [self.view constrainToAllEdges:self.statusLogView];
}



-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{
                                                                                   CBCentralManagerOptionRestoreIdentifierKey:@"CBBackgroundSpike",
                                                                                   CBCentralManagerOptionShowPowerAlertKey:@YES}];

}

-(void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    [self log:@"*** RESTORED!!! ***"];
    [self log:@"restored perifs: %@", dict[CBCentralManagerRestoredStatePeripheralsKey]];
    _peripheral = [dict[CBCentralManagerRestoredStatePeripheralsKey] firstItem];
    _peripheral.delegate = self;
}

-(void)log:(NSString*)formatString, ... {
    va_list args;
    va_start(args, formatString);
    NSString* statement = [[NSString alloc] initWithFormat:formatString arguments:args];
    self.statusLogView.text = [NSString stringWithFormat:@"%@\n\n\n%@", self.statusLogView.text, statement];
    NSLog(@"%@",statement);
    va_end(args);
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    NSString* output = [NSString stringWithFormat:@"Manager State: %@", [self stringForCBCentralManagerState:central.state]];
    if (central.state == CBCentralManagerStatePoweredOn) {
            [_manager scanForPeripheralsWithServices:nil options:nil];
    }
    [self log:@"%@",output];

}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI{
    [self log:@"discovered peripheral: %@ with uuid %@", [peripheral name], [peripheral identifier]];
    [_manager stopScan];
    _peripheral = peripheral;
    [_manager connectPeripheral:peripheral options:@{
                                                     CBConnectPeripheralOptionNotifyOnNotificationKey:@YES,
                                                     CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES
                                                     }];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self log:@"Disconnected %@: %@", peripheral.name, [error localizedDescription]];

    if (peripheral == _peripheral) {
        [self log:@"starting to re-connect to peripheral %@", peripheral.name];
        [_manager connectPeripheral:peripheral options:@{
                                                         CBConnectPeripheralOptionNotifyOnNotificationKey:@YES,
                                                         CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                                         CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES
                                                         }];
    }

}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self log:@"Error connecting %@: %@", peripheral.name, [error localizedDescription]];
    _peripheral = nil;
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self log:@"Peripheral connected: %@", [peripheral name]];

    peripheral.delegate = self;
    [peripheral discoverServices:nil];

}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    [self log:@"did retrieve connected peripherals: %@", peripherals];
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
     [self log:@"did retrieve peripherals: %@", peripherals];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        [self log:@"Discovered service %@ with UUID %@ on peripheral: %@", service, [service UUID], peripheral.name];
        //[peripheral discoverCharacteristics:nil forService:service];
    }
}
@end
