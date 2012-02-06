//
//  OCMapView.m
//  openClusterMapView
//
//  Created by Botond Kis on 14.07.11.
//

#import "OCMapView.h"

@interface OCMapView (private)
- (void)initSetUp;
@end

@implementation OCMapView
@synthesize clusteringEnabled;
@synthesize annotationsToIgnore;
@synthesize clusteringMethod;
@synthesize clusterSize;
@synthesize minLongitudeDeltaToCluster;

- (id)init
{
    self = [super init];
    if (self) {
        // call acutal constructor
        [self initSetUp];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];    
    if (self) {
        // call acutal constructor
        [self initSetUp];
    }
    return self;
}

- (void)initSetUp{
    allAnnotations = [[NSMutableSet alloc] init];
    annotationsToIgnore = [[NSMutableSet alloc] init];
    clusteringMethod = OCClusteringMethodBubble;
    clusterSize = 0.05;
    minLongitudeDeltaToCluster = 0.0018;
    clusteringEnabled = YES;
    backgroundClusterQueue = dispatch_queue_create("com.OCMapView.clustering", NULL);  
}

- (void)dealloc{
    [allAnnotations release];
    [annotationsToIgnore release];
    dispatch_release(backgroundClusterQueue);
    
    [super dealloc];
}

// ======================================
#pragma mark - MKMapView implementation

- (void)addAnnotation:(id < MKAnnotation >)annotation{
    [allAnnotations addObject:annotation];
    [self doClustering];
}

- (void)addAnnotations:(NSArray *)annotations{
    [allAnnotations addObjectsFromArray:annotations];
    [self doClustering];
}

- (void)removeAnnotation:(id < MKAnnotation >)annotation{
    [allAnnotations removeObject:annotation];
    [self doClustering];
}

- (void)removeAnnotations:(NSArray *)annotations{
    [annotations retain];
    for (id<MKAnnotation> annotation in annotations) {
        [allAnnotations removeObject:annotation];
    }
    [annotations release];
    [self doClustering];
}


// ======================================
#pragma mark - Properties
//
// Returns, like the original method,
// all annotations in the map unclustered.
- (NSArray *)annotations{
    return [allAnnotations allObjects];
}

//
// Returns all annotations which are actually displayed on the map. (clusters)
- (NSArray *)displayedAnnotations{
    return super.annotations;    
}

//
// enable or disable clustering
- (void)setClusteringEnabled:(BOOL)enabled{
    clusteringEnabled = enabled;
    [self doClustering];
}

// ======================================
#pragma mark - Clustering

- (void)doClustering{
    
    // Remove the annotation which should be ignored
    NSMutableArray *bufferArray = [[NSMutableArray alloc] initWithArray:[allAnnotations allObjects]];
    [bufferArray removeObjectsInArray:[annotationsToIgnore allObjects]];
    NSMutableArray *annotationsToCluster = [[NSMutableArray alloc] initWithArray:[self filterAnnotationsForVisibleMap:bufferArray]];
    [bufferArray release];
    
    //calculate cluster radius
    CLLocationDistance clusterRadius = self.region.span.longitudeDelta * clusterSize;
    
    // Do clustering
    NSArray *clusteredAnnotations;
    
    // Check if clustering is enabled and map is above the minZoom
    if (clusteringEnabled && (self.region.span.longitudeDelta > minLongitudeDeltaToCluster)) {
        // switch to selected algoritm
        switch (clusteringMethod) {
            case OCClusteringMethodBubble:{
                clusteredAnnotations = [[NSArray alloc] initWithArray:[OCAlgorithms bubbleClusteringWithAnnotations:annotationsToCluster andClusterRadius:clusterRadius]];
                break;
            }
            case OCClusteringMethodGrid:{
                clusteredAnnotations =[[NSArray alloc] initWithArray:[OCAlgorithms gridClusteringWithAnnotations:annotationsToCluster andClusterRect:MKCoordinateSpanMake(clusterRadius, clusterRadius)]];
                break;
            }
            default:{
                clusteredAnnotations = [annotationsToCluster retain];
                break;
            }
        }
    }
    // pass through without when not
    else{
        clusteredAnnotations = [annotationsToCluster retain];
    }
    
    // Clear map but leave Userlcoation
    NSMutableArray *annotationsToRemove = [[NSMutableArray alloc] initWithArray:self.displayedAnnotations];
    [annotationsToRemove removeObject:self.userLocation];
    
    // add clustered and ignored annotations to map
    [super addAnnotations: clusteredAnnotations];
    [super addAnnotations: [annotationsToIgnore allObjects]];
    
    // fix for flickering
    [annotationsToRemove removeObjectsInArray: clusteredAnnotations];
    [super removeAnnotations:annotationsToRemove];
    
    // memory
    [clusteredAnnotations release];
    [annotationsToCluster release];
    [annotationsToRemove release];
}

// ======================================
#pragma mark - Helpers

- (NSArray *)filterAnnotationsForVisibleMap:(NSArray *)annotationsToFilter{
    // return array
    NSMutableArray *filteredAnnotations = [[NSMutableArray alloc] initWithCapacity:[annotationsToFilter count]];
    
    // border calculation
    CLLocationDistance a = self.region.span.latitudeDelta/2.0;
    CLLocationDistance b = self.region.span.longitudeDelta /2.0;
    CLLocationDistance radius = sqrt(a*a + b*b);
    
    for (id<MKAnnotation> annotation in annotationsToFilter) {
        // if annotation is not inside the coordinates, kick it
        if (isLocationNearToOtherLocation(annotation.coordinate, self.centerCoordinate, radius)) {
            [filteredAnnotations addObject:annotation];
        }
    }
    
    return [filteredAnnotations autorelease];
}

@end
