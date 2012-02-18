//
//  MapTabController.m
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import "MapTabController.h"
#import "UIImageView+WebCache.h"
#import "MissionAnnotation.h"
#import "UserAnnotation.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "UserListTableViewController.h"
#import "SignupController.h"
#import "MapDataSet.h"
#import "CPUIHelper.h"
#import "UserProfileCheckedInViewController.h"

#define qHideTopNavigationBarOnMapView			0
#define logoutMenuIndex 3
#define menuWidthPercentage 0.8

@interface MapTabController() 
-(void)zoomTo:(CLLocationCoordinate2D)loc;

@property (nonatomic, strong) NSTimer *reloadTimer;
@property (nonatomic, retain) NSArray *menuStringsArray;
@property (nonatomic, retain) NSArray *menuSegueIdentifiersArray;
-(void)refreshLocationsIfNeeded;

@end

@implementation MapTabController 
@synthesize mapView;
@synthesize dataset;
@synthesize fullDataset;
@synthesize reloadTimer;
@synthesize mapHasLoaded;
@synthesize isMenuShowing;
@synthesize menuStringsArray;
@synthesize menuSegueIdentifiersArray;
@synthesize mapAndButtonsView;
@synthesize tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)initMenu 
{
    // Setup the menu strings and seque identifiers
    self.menuStringsArray = [NSArray arrayWithObjects:
                             @"Face To Face", 
                             @"Balance",
                             @"Settings",
                             @"Logout",
                             nil];
    
    self.menuSegueIdentifiersArray = [NSArray arrayWithObjects:
                                      @"ShowFaceToFaceFromMenu", 
                                      @"ShowBalanceFromMenu",
                                      @"ShowSettingsFromMenu",
                                      @"ShowLogoutFromMenu",
                                      nil];
    
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Title view styling
    [CPUIHelper addDarkNavigationBarStyleToViewController:self];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]];
    self.navigationItem.title = @"C&P"; // TODO: Remove once back button with mug logo is added to pushed views
    
    [self initMenu];
    
    self.mapHasLoaded = NO;

    // Initialize the fullDataset array to keep track of all checked in users, even outside of current map bounds
    fullDataset = [[MapDataSet alloc] init];
    
    self.navigationController.delegate = self;
	hasUpdatedUserLocation = false;
	
	// every 10 seconds, see if it's time to refresh the data
	// (the data invalidates every 2 minutes, but we check more often)
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
												   target:self
												 selector:@selector(refreshLocationsIfNeeded)
												 userInfo:nil
												  repeats:YES];
    
	// center on the last known user location
	if([AppDelegate instance].settings.hasLocation)
	{
		//[mapView setCenterCoordinate:[AppDelegate instance].settings.lastKnownLocation.coordinate];
		NSLog(@"MapTab: viewDidLoad zoomto (lat %f, lon %f)", [AppDelegate instance].settings.lastKnownLocation.coordinate.latitude, [AppDelegate instance].settings.lastKnownLocation.coordinate.longitude);
		[self zoomTo: [AppDelegate instance].settings.lastKnownLocation.coordinate];
	}

	NSOperationQueue *queue = [NSOperationQueue mainQueue];
	//NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	//BOOL wasSuspended = queue.isSuspended;
	[queue setSuspended: NO];
}

- (void)viewDidUnload
{
	[self setMapView:nil];
    [self setMapAndButtonsView:nil];
    [self setTableView:nil];
    [super viewDidUnload];
	[reloadTimer invalidate];
	reloadTimer = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.mapHasLoaded = YES;
	// show the loading screen but only the first time
	if(!hasShownLoadingScreen)
	{
		[SVProgressHUD showWithStatus:@"Loading..."];
		hasShownLoadingScreen = true;
	}
    
    [[AppDelegate instance] showCheckInButton];

    [self refreshLocationsIfNeeded];
    // Update for login name in header field
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)refreshButtonClicked:(id)sender
{
    [mapView removeAnnotations: mapView.annotations];
    [self refreshLocations];
}

-(void)refreshLocationsIfNeeded
{
	MKMapRect mapRect = mapView.visibleMapRect;

    // prevent the refresh of locations when we have a valid dataset or the map is not yet loaded
	if(self.mapHasLoaded && (!dataset || ![dataset isValidFor:mapRect]))
	{
		[self refreshLocations];
	}
}

-(void)refreshLocations
{
    MKMapRect mapRect = mapView.visibleMapRect;
    [MapDataSet beginLoadingNewDataset:mapRect
                            completion:^(MapDataSet *newDataset, NSError *error) {
                                if(newDataset)
                                {
                                    NSSet *visiblePins = [mapView annotationsInMapRect: mapView.visibleMapRect];
                                    
                                    for (CandPAnnotation *ann in visiblePins) {
                                        if ([[newDataset annotations] containsObject: ann]) {
                                            [[newDataset annotations] removeObject: ann];
                                        } else {
                                            [mapView removeAnnotation:ann];
                                        }
                                    }
                                    
                                    [mapView addAnnotations: [newDataset annotations]];
                                    dataset = newDataset;

                                    // Load all users (even outside of map bounds) into fullDataset for List view
                                    for (CandPAnnotation *ann2 in newDataset.annotations) {
                                        if (![fullDataset.annotations containsObject: ann2]) {
                                            [fullDataset.annotations addObject: ann2];
                                        }
                                    }
                                }
                                
                                [SVProgressHUD dismiss];
                            }];
    
}

- (IBAction)locateMe:(id)sender
{
    [self zoomTo: [[mapView userLocation] coordinate]];
}

- (void)showMenu:(BOOL)showMenu {
    // Animate the reveal of the menu
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:0.3];
    
    float shift = menuWidthPercentage * [UIScreen mainScreen].bounds.size.width;
    if (showMenu) {
        // shift to the right, hiding buttons 
        CGRect menuFrame = CGRectMake(0, 0, shift, CGRectGetHeight(self.view.frame));
        self.mapAndButtonsView.frame = CGRectOffset(self.view.bounds, CGRectGetWidth(menuFrame), 0);
        [[AppDelegate instance] hideCheckInButton];
    } else {
        // shift to the left, restoring the buttons
        self.mapAndButtonsView.frame = self.view.frame;
        [[AppDelegate instance] showCheckInButton];
    }
    [UIView commitAnimations];
    isMenuShowing = showMenu ? 1 : 0;
}

- (IBAction)revealButtonPressed:(id)sender {
    [self showMenu: !self.isMenuShowing];
}

- (MKUserLocation *)currentUserLocationInMapView
{
    return mapView.userLocation;
}

// called just before a controller pops us
- (void)navigationController:(UINavigationController *)navigationControllerArg willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
#if qHideTopNavigationBarOnMapView
	if(viewController == self)
	{
		// we're about to be revealed
		// (happens after a pop back, but also on initial appearance)
		navigationControllerArg.navigationBarHidden = YES;
	}
	else
	{
		navigationControllerArg.navigationBarHidden = NO;
	}
#endif
	
}

-(void)loginButtonTapped
{
	SignupController *controller = [[SignupController alloc]initWithNibName:@"SignupController" bundle:nil];
	[self.navigationController pushViewController:controller animated:YES];
}

-(void)logoutButtonTapped
{
	// logout of *all* accounts
	[[AppDelegate instance] logoutEverything];
	
}

- (void) mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView *view in views) {
        if ([[view annotation] isKindOfClass:[CandPAnnotation class]]) {
            CandPAnnotation *ann = (CandPAnnotation *)view.annotation;
            if (ann.checkedIn) {   
                [[view superview] bringSubviewToFront:view];
            } else {
                [[view superview] sendSubviewToBack:view];
            }
        }
    }
}

// mapView:viewForAnnotation: provides the view for each annotation.
// This method may be called for all or some of the added annotations.
// For MapKit provided annotations (eg. MKUserLocation) return nil to use the MapKit provided annotation view.
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{   
	MKAnnotationView *pinToReturn = nil;
	if([annotation isKindOfClass:[CandPAnnotation class]])
	{ 
		CandPAnnotation *candpanno = (CandPAnnotation*)annotation;
        NSString *reuseId = [NSString stringWithFormat: @"pin-%d", candpanno.checkinId];

		if (!candpanno.checkedIn) 
		{
            reuseId = @"pin";
        }
        
		MKPinAnnotationView *pin = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: reuseId];
		if (pin == nil)
		{
			pin = [[MKPinAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: reuseId];
		}
		else
		{
			pin.annotation = annotation;
		}
		pinToReturn = pin;
        
		if (candpanno.checkedIn) 
		{
            UIImage *frame = [UIImage imageNamed:@"pin-frame"];
            UIImage *profileImage;
            
            if (candpanno.imageUrl == nil)
			{
				profileImage = [UIImage imageNamed:@"defaultAvatar50.png"];
			} 
			else 
			{  profileImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString: candpanno.imageUrl]]];
            }
            UIGraphicsBeginImageContext(CGSizeMake(38, 43));
            [profileImage drawInRect:CGRectMake(3, 3, 32, 32)];
            [frame drawInRect: CGRectMake(0, 0, 38, 43)];
            pin.image = UIGraphicsGetImageFromCurrentImageContext();
			
		} 
		else
		{
			pin.pinColor = MKPinAnnotationColorRed;
		}
        
		pin.animatesDrop = NO;
		pin.canShowCallout = YES;
		
		// make the left callout image view
		UIImageView *leftCallout = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
		leftCallout.contentMode = UIViewContentModeScaleAspectFill;
		if (candpanno.imageUrl)
		{
			[leftCallout setImageWithURL:[NSURL URLWithString:candpanno.imageUrl]
                        placeholderImage:[UIImage imageNamed:@"63-runner.png"]];
		}
		else
		{
			leftCallout.image = [UIImage imageNamed:@"63-runner.png"];			
		}
		pin.leftCalloutAccessoryView = 	leftCallout;
		// make the right callout
		UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		button.frame =CGRectMake(0, 0, 32, 32);
		button.tag = [dataset.annotations indexOfObject:candpanno];
		pin.rightCalloutAccessoryView = button;
	}
	
	return pinToReturn;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    [self performSegueWithIdentifier:@"ShowUserProfileCheckedInFromMap" sender:view];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender 
{
    if (self.isMenuShowing) { [self showMenu:NO]; }
    if ([[segue identifier] isEqualToString:@"ShowUserProfileCheckedInFromMap"]) {
        // figure out which element was tapped
        UserAnnotation *tappedObj = [sender annotation];
        // setup a user object with the info we have from the pin and callout
        // so that this information can already be in the resume without having to load it
        User *selectedUser = [[User alloc] init];
        selectedUser.nickname = tappedObj.nickname;
        selectedUser.userID = [tappedObj.objectId intValue];
        selectedUser.location = CLLocationCoordinate2DMake(tappedObj.lat, tappedObj.lon);
        selectedUser.status = tappedObj.status;
        selectedUser.skills = tappedObj.skills;
        selectedUser.checkedIn = tappedObj.checkedIn;
        
        // set the user object on the UserProfileCheckedInVC to the user we just created
        [[segue destinationViewController] setUser:selectedUser];
    }
    else if ([[segue identifier] isEqualToString:@"ShowUserListTable"]) {
        [[segue destinationViewController] setMissions: fullDataset.annotations];
    }
}

////// map delegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
	[self refreshLocationsIfNeeded];
}

- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
	NSLog(@"mapViewWillStartLocatingUser");
}
- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView
{
	NSLog(@"mapViewDidStopLocatingUser");
	
}
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	NSLog(@"MapTab: didUpdateUserLocation (lat %f, lon %f)", userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);
	
	if(userLocation.location.coordinate.latitude != 0 && userLocation.location.coordinate.longitude != 0)
	{
		// save the location for the next time
		[AppDelegate instance].settings.hasLocation= true;
		[AppDelegate instance].settings.lastKnownLocation = userLocation.location;
		[[AppDelegate instance] saveSettings];
		
        if (!hasUpdatedUserLocation) {
            NSLog(@"MapTab: didUpdateUserLocation a zoomto (lat %f, lon %f)", userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);
            [self zoomTo:userLocation.location.coordinate];   
            hasUpdatedUserLocation = true;
        }

	}
}
- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
	[SVProgressHUD dismiss];

}

// zoom to the location; on initial load & after updaing their pos
-(void)zoomTo:(CLLocationCoordinate2D)loc
{
    // zoom to a region 2km across
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(loc, 1000, 1000);
    [mapView setRegion:viewRegion animated:TRUE];    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return menuStringsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        // Style the cell's font and background. clear the background colors so style is not obstructed.
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20.0];
        cell.textLabel.textColor = [UIColor colorWithRed:169.0/255.0 green:169.0/255.0 blue:169.0/255.0 alpha:1];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.backgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"menu-background.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:2.0]];  
        cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"selected-menu-background.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:2.0]];
        cell.accessoryView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"accessory-arrow.png"]];
    }
    cell.textLabel.text = (NSString*)[self.menuStringsArray objectAtIndex:indexPath.row];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // Check to see if our login is valid, using the user name for the header
	if([AppDelegate instance].settings.candpUserId ||
	   [[AppDelegate instance].facebook isSessionValid])
	{
		return [AppDelegate instance].settings.userNickname;
	}
	else
	{
		return @"";
	}
}

- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section {
    float tableHeight = [self tableView:aTableView heightForHeaderInSection:section];
    NSString *headerString = [self tableView:aTableView titleForHeaderInSection:section];
    CGRect headerRect = CGRectMake(0,0,aTableView.frame.size.width,tableHeight);
    UIView *headerView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"menu-header-background.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:0.0]];  
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerRect];
    headerLabel.textAlignment = UITextAlignmentCenter;
    headerLabel.text = headerString;
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [UIColor whiteColor];
    
    [headerView addSubview:headerLabel];
    
    return headerView;
}

-(float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return  20.0;
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Handle the selected menu item, closing the menu for when we return
    if (indexPath.row == logoutMenuIndex) { 
        //TODO: Merge logout xib with storyboard, adding segue for logout
        if (self.isMenuShowing) { [self showMenu:NO]; }
        [self logoutButtonTapped];
        [self loginButtonTapped];
    } else { 
        NSString *segueName = [menuSegueIdentifiersArray objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:segueName sender:self];
    }
}

@end
