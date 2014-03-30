//
//  EasyLinkMainViewController.m
//  EMW ToolBox
//
//  Created by William Xu on 13-7-28.
//  Copyright (c) 2013年 MXCHIP Co;Ltd. All rights reserved.
//

#import "EasyLinkMainViewController.h"
#import "APManager.h"
#import "PulsingHaloLayer.h"
#import "EasyLinkFTCTableViewController.h"

#define MOVE_UP_ON_3_5_INCH   (-65)

extern BOOL newModuleFound;
BOOL configTableMoved = NO;


@interface EasyLinkMainViewController (){
    PulsingHaloLayer *halo[3];
}

@property (nonatomic, retain, readwrite) NSThread* waitForAckThread;

@end

@interface EasyLinkMainViewController (Private)

/* button action, where we need to start or stop the request 
 @param: button ... tag value defines the action 
 */

- (IBAction)easyLinkV1ButtonAction:(UIButton*)button;
- (IBAction)easyLinkV2ButtonAction:(UIButton*)button;

/* 
 Prepare a cell that is created with respect to the indexpath 
 @param cell is an object of UITableViewcell which is newly created 
 @param indexpath  is respective indexpath of the cell of the row. 
*/
-(UITableViewCell *) prepareCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

/* 
 Notification method handler when app enter in forground
 @param the fired notification object
 */
- (void)appEnterInforground:(NSNotification*)notification;

/* 
 Notification method handler when app enter in background
 @param the fired notification object
 */
- (void)appEnterInBackground:(NSNotification*)notification;

/* 
 Notification method handler when status of wifi changes 
 @param the fired notification object
 */
- (void)wifiStatusChanged:(NSNotification*)notification;


/* enableUIAccess
  * enable / disable the UI access like enable / disable the textfields 
  * and other component while transmitting the packets.
  * @param: vbool is to validate the controls.
 */
-(void) enableUIAccess:(BOOL) isEnable;


@end

@implementation EasyLinkMainViewController
@synthesize foundModules;
@synthesize waitForAckThread;

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle -

//- (void)instantiateViewControllerWithIdentifier{
//    
//}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    if( easylink_config == nil){
        easylink_config = [[EASYLINK alloc]init];
        [easylink_config startFTCServerWithDelegate:self];
    }
    if( self.foundModules == nil)
        self.foundModules = [[NSMutableArray alloc]initWithCapacity:10];

    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    if( screenBounds.size.height == 480.0){
        imagePhoneView.center = CGPointMake(imagePhoneView.center.x, imagePhoneView.center.y+MOVE_UP_ON_3_5_INCH/2);
        imagePhoneView.transform =  CGAffineTransformMakeTranslation(0, MOVE_UP_ON_3_5_INCH);
        
         
        imageEMW3161View.center = CGPointMake(imageEMW3161View.center.x, imageEMW3161View.center.y+MOVE_UP_ON_3_5_INCH/2);
        imageEMW3161View.transform =  CGAffineTransformMakeTranslation(0, MOVE_UP_ON_3_5_INCH);

        imageEMW3162View.center = CGPointMake(imageEMW3162View.center.x, imageEMW3162View.center.y+MOVE_UP_ON_3_5_INCH/2);
        imageEMW3162View.transform =  CGAffineTransformMakeTranslation(0, MOVE_UP_ON_3_5_INCH);
        
        backgroundImage.transform =  CGAffineTransformMakeTranslation(0, 200.0);

    }
    
    halo[0] = [PulsingHaloLayer layer];
    halo[0].position = CGPointMake(imageEMW3161View.center.x, imageEMW3161View.center.y);
    halo[0].backgroundColor = [UIColor colorWithRed:0 green:122.0/255 blue:1.0 alpha:1.0].CGColor;
    [self.view.layer insertSublayer:halo[0] above:imagePhoneView.layer];
    halo[0].radius = 100;
    
    halo[1] = [PulsingHaloLayer layer];
    halo[1].position = CGPointMake(imagePhoneView.center.x+20, imagePhoneView.center.y-25);
    [self.view.layer insertSublayer:halo[1] above:imagePhoneView.layer];
    halo[1].radius = 200;
    halo[1].backgroundColor = [UIColor colorWithRed:0 green:122.0/255 blue:1.0 alpha:1.0].CGColor;
    
    halo[2] = [PulsingHaloLayer layer];
    halo[2].position = CGPointMake(imageEMW3162View.center.x, imageEMW3162View.center.y);
    [self.view.layer insertSublayer:halo[2] above:imagePhoneView.layer];
    halo[2].radius = 100;
    halo[2].backgroundColor = [UIColor colorWithRed:0 green:122.0/255 blue:1.0 alpha:1.0].CGColor;

    //按钮加边框
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef colorref = CGColorCreate(colorSpace,(CGFloat[]){ 0, 122.0/255, 1, 1 });
    [EasylinkV1Button.layer setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1].CGColor];
    [EasylinkV1Button.layer setCornerRadius:50.0];
    [EasylinkV1Button.layer setBorderWidth:1.5];
    [EasylinkV1Button.layer setBorderColor:colorref];
    
    [EasylinkV2Button.layer setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1].CGColor];
    [EasylinkV2Button.layer setCornerRadius:10.0];
    [EasylinkV2Button.layer setBorderWidth:1.5];
    [EasylinkV2Button.layer setBorderColor:colorref];
    
    [configTableView.layer setCornerRadius:8.0];
    [configTableView.layer setBorderWidth:1.5];
    [configTableView.layer setBorderColor:colorref];
    CGColorRelease (colorref);
    CGColorSpaceRelease(colorSpace);
        
    // wifi notification when changed.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wifiStatusChanged:) name:kReachabilityChangedNotification object:nil];
    
    wifiReachability = [Reachability reachabilityForLocalWiFi];  //监测Wi-Fi连接状态
	[wifiReachability startNotifier];
    
    waitForAckThread = nil;
    
    NetworkStatus netStatus = [wifiReachability currentReachabilityStatus];	
    if ( netStatus == NotReachable ) {// No activity if no wifi
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"WiFi not available. Please check your WiFi connection" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
    }
    
    //// stoping the process in app backgroud state
    NSLog(@"regisister notificationcenter");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterInBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterInforground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    if([self.navigationController.viewControllers indexOfObject:self] == NSNotFound){
        [easylink_config stopTransmitting];
        [easylink_config closeFTCServer];
        easylink_config = nil;
        self.foundModules = nil;
    }
    
    [self stopAction];
    // Retain the UI access for the user.
    [self enableUIAccess:YES];
    [super viewWillDisappear:animated];
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    for(int idx = 0; idx<3; idx++)
        halo[idx] =nil;;
    
    [easylink_config stopTransmitting];
    [easylink_config closeFTCServer];
    easylink_config = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    NSLog(@"%s=>dealloc", __func__);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - TRASMITTING DATA -

/*
 This method begins configuration transmit
 In case of a failure the method throws an OSFailureException.
 */
-(void) sendAction{
    newModuleFound = NO;
    [easylink_config transmitSettings];
    waitForAckThread = [[NSThread alloc] initWithTarget:self selector:@selector(waitForAck:) object:nil];
    [waitForAckThread start];
}

/*
 This method stop the sending of the configuration to the remote device
  In case of a failure the method throws an OSFailureException.
 */
-(void) stopAction{
    [easylink_config stopTransmitting];
    [waitForAckThread cancel];
    waitForAckThread= nil;
}

/*
 This method waits for an acknowledge from the remote device than it stops the transmit to the remote device and returns with data it got from the remote device.
 This method blocks until it gets respond.
 The method will return true if it got the ack from the remote device or false if it got aborted by a call to stopTransmitting.
 In case of a failure the method throws an OSFailureException.
 */

- (void) waitForAck: (id)sender{
    while(![[NSThread currentThread] isCancelled])
    {
        if ( newModuleFound==YES ){
            [self stopAction];
            [self enableUIAccess:YES];
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
        }
        sleep(1);
    };
    NSLog(@"waitForAck exit");
}


/*
 This method start the transmitting the data to connected 
 AP. Nerwork validation is also done here. All exceptions from
 library is handled. 
 */
- (void)startTransmitting: (int)version {
    NetworkStatus netStatus = [wifiReachability currentReachabilityStatus];
    if ( netStatus == NotReachable ){// No activity if no wifi
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"WiFi not available. Please check your WiFi connection" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        return;
    }
    
    if([userInfoField.text length]>0&&version == EASYLINK_V1){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Custom information cannot be delivered by EasyLink V1" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
    }

    NSString *ssid = [ssidField.text length] ? ssidField.text : nil;
    NSString *passwordKey = [passwordField.text length] ? passwordField.text : nil;
    NSString *userInfo = [userInfoField.text length]? userInfoField.text : nil;
    
    
    if(version == EASYLINK_V1)
        [easylink_config prepareEasyLinkV1:ssid password:passwordKey];
    else if(version == EASYLINK_V2){
        if(userInfo!=nil){
            const char *temp = [userInfo cStringUsingEncoding:NSUTF8StringEncoding];
            [easylink_config prepareEasyLinkV2_withFTC:ssid password:passwordKey info:[NSData dataWithBytes:temp length:strlen(temp)]];
        }else{
            [easylink_config prepareEasyLinkV2_withFTC:ssid password:passwordKey info:nil];
        }
    }
    
    [self sendAction];

    [self enableUIAccess:NO];
}

/*!!!!!!
  This is the button action, where we need to start or stop the request 
 @param: button ... tag value defines the action !!!!!!!!!
 !!!*/
- (IBAction)easyLinkV1ButtonAction:(UIButton*)button{

    if(button.selected == NO){
        [EasylinkV1Button setBackgroundColor:[UIColor colorWithRed:0 green:122.0/255 blue:1 alpha:1]];
        [EasylinkV1Button setSelected:YES];
        [EasylinkV2Button setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [EasylinkV2Button setSelected:NO];
        [self startTransmitting: EASYLINK_V1];
    }
    else{
        [button setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [EasylinkV1Button setSelected:NO];
        [self stopAction];
        // Retain the UI access for the user.
        [self enableUIAccess:YES];
    }
}

- (IBAction)easyLinkV2ButtonAction:(UIButton*)button{
    
    if(button.selected == NO) {
        [EasylinkV2Button setBackgroundColor:[UIColor colorWithRed:0 green:122.0/255 blue:1 alpha:1]];
        [EasylinkV2Button setSelected:YES];
        [EasylinkV1Button setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [EasylinkV1Button setSelected:NO];
        [self startTransmitting: EASYLINK_V2];
    }
    else{
        [button setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [EasylinkV2Button setSelected:NO];
        //[NSThread detachNewThreadSelector:@selector(waitForAckThread:) toTarget:self withObject:nil];
        [self stopAction];
        // Retain the UI access for the user.
        [self enableUIAccess:YES];
    }
}


#pragma mark - UITableview Delegate -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
        return 1;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *tableCellIdentifier;
    UITableViewCell *cell = nil;
    
    if(tableView == configTableView){
        tableCellIdentifier = @"APInfo";
   
        cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
        if ( cell == nil ) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell setBackgroundColor:[UIColor colorWithRed:0.100 green:0.478 blue:1.000 alpha:0.1]];
            cell = [self prepareCell:cell atIndexPath:indexPath];
        }
    }else{
        tableCellIdentifier = @"New Module";
        
        cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
        [cell setBackgroundColor:[UIColor colorWithRed:0.100 green:0.478 blue:1.000 alpha:0.4]];
        [cell setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6]];
        cell.textLabel.text = [[self.foundModules objectAtIndex:indexPath.row] objectForKey:@"N"];
        
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(tableView == configTableView)
        return 3;
    else
        return [self.foundModules count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(tableView == foundModuleTableView)
        return @"UNCONFIGURED DEVICE LIST";
    else
        return nil;
}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([self.foundModules count])
        view.hidden = false;
    else
        view.hidden = true;
}

#pragma mark - UITextfiled delegate -

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - EasyLink delegate -

- (void)onFoundByFTC:(NSNumber *)ftcClientTag currentConfig: (NSData *)config;
{
    NSError *err;
    NSIndexPath* indexPath;
    NSMutableDictionary *foundModule = nil;
    
    foundModule = [NSJSONSerialization JSONObjectWithData:config
                                                  options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves
                                                    error:&err];

    if (err) {
        NSLog(@"Unpackage JSON data failed:%@", [err localizedDescription]);
    }
    
    [foundModule setValue:ftcClientTag forKey:@"client"];
    
    /*Reloace an old device*/
    for( NSDictionary *object in self.foundModules){
        if ([[object objectForKey:@"N"] isEqualToString:[foundModule objectForKey:@"N"]] ){
            [self.foundModules replaceObjectAtIndex:[self.foundModules indexOfObject:object]
                                         withObject:foundModule];
            return;
        }
    }
    /*Add a new device*/
    if([self.foundModules count]==0){
        UIView *sectionHead =  [foundModuleTableView headerViewForSection:0];
        sectionHead.hidden = NO;
        [sectionHead setNeedsDisplay];
    }

    [self.foundModules addObject:foundModule];
    indexPath = [NSIndexPath indexPathForRow:[self.foundModules indexOfObject:foundModule] inSection:0];
    [foundModuleTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                withRowAnimation:UITableViewRowAnimationRight];


}

#pragma mark - EasyLinkFTCTableViewController delegate-

- (void)onConfigured:(NSMutableDictionary *)configData
{
    NSLog(@"configured");
}

#pragma mark - Private Methods -

/* enableUIAccess
 * enable / disable the UI access like enable / disable the textfields 
 * and other component while transmitting the packets.
 * @param: vbool is to validate the controls.
 */
-(void) enableUIAccess:(BOOL) isEnable{
    ssidField.userInteractionEnabled = isEnable;
    passwordField.userInteractionEnabled = isEnable;
    userInfoField.userInteractionEnabled = isEnable;
    
    for(int idx = 0; idx<3; idx++){
//        if(isEnable == NO)
//            halo[idx].radius = 200;
//        else
//            halo[idx].radius = 60;
        [halo[idx] startAnimation: !isEnable];
    }
}

/* 
 Prepare a cell that is created with respect to the indexpath 
 @param cell is an object of UITableViewcell which is newly created 
 @param indexpath  is respective indexpath of the cell of the row. 
 */
-(UITableViewCell *) prepareCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.row == SSID_ROW ){/// this is SSID row 
        ssidField = [[UITextField alloc] initWithFrame:CGRectMake(CELL_IPHONE_FIELD_X,
                                                                  CELL_iPHONE_FIELD_Y,
                                                                  CELL_iPHONE_FIELD_WIDTH,
                                                                  CELL_iPHONE_FIELD_HEIGHT)];
        [ssidField setDelegate:self];
        [ssidField setClearButtonMode:UITextFieldViewModeNever];
        [ssidField setPlaceholder:@"SSID"];
        [ssidField setBackgroundColor:[UIColor clearColor]];
        [ssidField setReturnKeyType:UIReturnKeyDone];
        [ssidField setText:[EASYLINK ssidForConnectedNetwork]];
        [cell addSubview:ssidField];
        [ssidField setText:@"901"];
        
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
        cell.textLabel.text = @"SSID";
    }else if(indexPath.row == PASSWORD_ROW ){// this is password field 
        passwordField = [[UITextField alloc] initWithFrame:CGRectMake(CELL_IPHONE_FIELD_X,
                                                                      CELL_iPHONE_FIELD_Y,
                                                                      CELL_iPHONE_FIELD_WIDTH,
                                                                      CELL_iPHONE_FIELD_HEIGHT)];
        [passwordField setDelegate:self];
        [passwordField setClearButtonMode:UITextFieldViewModeNever];
        [passwordField setPlaceholder:@"Password"];
        [passwordField setReturnKeyType:UIReturnKeyDone];
        [passwordField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [passwordField setAutocorrectionType:UITextAutocorrectionTypeNo];
        [passwordField setBackgroundColor:[UIColor clearColor]];
        [cell addSubview:passwordField];
        [passwordField setText:@"xuweixuwei"];

        
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
        cell.textLabel.text = @"Password";
    }
    else if ( indexPath.row == USER_INFO_ROW){
        /// this is Gateway Address field
        userInfoField = [[UITextField alloc] initWithFrame:CGRectMake(CELL_IPHONE_FIELD_X,
                                                                       CELL_iPHONE_FIELD_Y,
                                                                       CELL_iPHONE_FIELD_WIDTH,
                                                                       CELL_iPHONE_FIELD_HEIGHT)];
        [userInfoField setDelegate:self];
        [userInfoField setClearButtonMode:UITextFieldViewModeNever];
        [userInfoField setPlaceholder:@"Device name"];
        [userInfoField setReturnKeyType:UIReturnKeyDone];
        [userInfoField setBackgroundColor:[UIColor clearColor]];
        [userInfoField setText:@"Hello"];
        
        [cell addSubview:userInfoField];
        
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
        cell.textLabel.text = @"User Info";
    }
    else if ( indexPath.row == GATEWAY_ADDRESS_ROW){
        /// this is Gateway Address field
        gatewayAddress = [[UITextField alloc] initWithFrame:CGRectMake(CELL_IPHONE_FIELD_X,
                                                                  CELL_iPHONE_FIELD_Y,
                                                                  CELL_iPHONE_FIELD_WIDTH,
                                                                  CELL_iPHONE_FIELD_HEIGHT)];
        [gatewayAddress setDelegate:self];
        [gatewayAddress setClearButtonMode:UITextFieldViewModeNever];
        [gatewayAddress setPlaceholder:@"Gateway IP Address"];
        [gatewayAddress setReturnKeyType:UIReturnKeyDone];
        [gatewayAddress setBackgroundColor:[UIColor clearColor]];
        [gatewayAddress setUserInteractionEnabled:NO];
        [gatewayAddress setText:[EASYLINK getGatewayAddress]];

        [cell addSubview:gatewayAddress];
        
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
        cell.textLabel.text = @"Gateway";
    }
    return cell;
}


/* 
 Notification method handler when app enter in forground
 @param the fired notification object
 */
- (void)appEnterInforground:(NSNotification*)notification{
    NSLog(@"%s", __func__);
    if( easylink_config == nil){
        easylink_config = [[EASYLINK alloc]init];
        [easylink_config startFTCServerWithDelegate:self];
    }
    if( self.foundModules == nil)
        self.foundModules = [[NSMutableArray alloc]initWithCapacity:10];
    [foundModuleTableView reloadData];
    ssidField.text = [EASYLINK ssidForConnectedNetwork];
    gatewayAddress.text = [EASYLINK getGatewayAddress];
}

/*
 Notification method handler when app enter in background
 @param the fired notification object
 */
- (void)appEnterInBackground:(NSNotification*)notification{
    NSLog(@"%s", __func__);
    
    [easylink_config stopTransmitting];
    [easylink_config closeFTCServer];
    easylink_config = nil;
    self.foundModules = nil;
    
    if ( EasylinkV1Button.selected )
        [self easyLinkV1ButtonAction:EasylinkV1Button]; /// Simply revert the state
    if ( EasylinkV2Button.selected )
        [self easyLinkV2ButtonAction:EasylinkV2Button]; /// Simply revert the state
    
    //[self.navigationController popToRootViewControllerAnimated:NO];
}

/*
 Notification method handler when status of wifi changes
 @param the fired notification object
 */
- (void)wifiStatusChanged:(NSNotification*)notification{
    NSLog(@"%s", __func__);
    Reachability *verifyConnection = [notification object];	
    NSAssert(verifyConnection != NULL, @"currentNetworkStatus called with NULL verifyConnection Object");
    NetworkStatus netStatus = [verifyConnection currentReachabilityStatus];	
    if ( netStatus == NotReachable ){
        if ( EasylinkV1Button.selected )
            [self easyLinkV1ButtonAction:EasylinkV1Button]; /// Simply revert the state
        if ( EasylinkV2Button.selected )
            [self easyLinkV2ButtonAction:EasylinkV2Button]; /// Simply revert the state
        // The operation couldn’t be completed. No route to host
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"EMW ToolBox Alert" message:@"Wifi Not available. Please check your wifi connection" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        ssidField.text = @"";
        gatewayAddress.text = @"";
    }else {
        ssidField.text = [EASYLINK ssidForConnectedNetwork];
        gatewayAddress.text = [EASYLINK getGatewayAddress];
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"First Time Configuration"]) {
        NSIndexPath *indexPath = [foundModuleTableView indexPathForSelectedRow];
        [foundModuleTableView deselectRowAtIndexPath:indexPath animated:YES];
        NSMutableDictionary *object = [self.foundModules objectAtIndex:indexPath.row];
        
        //[easylink_config stopTransmitting];
        //easylink_config = nil;
        if ( EasylinkV1Button.selected )
            [self easyLinkV1ButtonAction:EasylinkV1Button]; /// Simply revert the state
        if ( EasylinkV2Button.selected )
            [self easyLinkV2ButtonAction:EasylinkV2Button]; /// Simply revert the state
        
        [[segue destinationViewController] setConfigData:object];
        [[segue destinationViewController] setDelegate:self];
        
    }
}



@end
