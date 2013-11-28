//
//  VCKiBarcodeViewController.m
//  VinDecode
//
//  Created by VenCKi on 10/30/13.
//  Copyright (c) 2013 VenCKi. All rights reserved.
//

#import "VCKiBarcodeViewController.h"
#import "VCKiVehicleBasicDataEntity.h"
#import "VCKiTaxonomyViewController.h"

@interface VCKiBarcodeViewController ()

@end

@implementation VCKiBarcodeViewController

VCKiVehicleBasicDataEntity *vehicle;

//@synthesize imagePicker = _imagePicker;
@synthesize imageView = _imageView;
VCKiVehicleBasicDataEntity *basicDataAccess;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.serviceCallStatus stopAnimating];
    self.imagePicker = [[UIImagePickerController alloc]init];
	self.imagePicker.delegate = self;
    
    self.textboxResult.delegate = self;
    vehicle = [[VCKiVehicleBasicDataEntity alloc]init];
    
    [self.buttonPerformCameraAction setTitle:@"Unavilable" forState:UIControlStateDisabled];
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else{
        self.buttonPerformCameraAction.enabled = NO;
    }
    
    basicDataAccess = [[VCKiVehicleBasicDataEntity alloc]initWithObject:self];
#warning "need to integrate with decoded barcode"
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.textboxResult resignFirstResponder];
    return YES;
}


-(void) postOcrData: (NSData *) imageData and: (NSString *) postData
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]init];
    NSString *url = [NSString stringWithFormat:@"%@/%@",[[NSUserDefaults standardUserDefaults] stringForKey:@"baseApiUrl"],[[NSUserDefaults standardUserDefaults] stringForKey:@"barcodeApiPostfix"]];
    
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"-----------------------------7dd38a1060692";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request addValue:@"text/html, application/xhtml+xml, */*" forHTTPHeaderField:@"Accept"];
    [request addValue:@"no-cache" forHTTPHeaderField:@"Pragma"];
    
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\nContent-Disposition: form-data; name=\"caption\"" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat: @"\r\n\r\n%@",postData] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\nContent-Disposition: form-data; name=\"image1\"; filename=\"ipodfile.png\""dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\nContent-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:imageData]];
    [body appendData:[@"\r\n-------------------------------7dd38a1060692--\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc]init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        @try {
            
            if (data.length > 0 && !connectionError) {
                if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                    vehicle.vin = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    [self.textboxResult setText:vehicle.vin];
                    self.textControlsSection.hidden = NO;
                    [self.serviceCallStatus stopAnimating];
                }
                else{
                    @throw [NSException exceptionWithName:@"ServerError" reason:[NSString stringWithFormat:@"Status code from server is %ld", (long)[(NSHTTPURLResponse *)response statusCode]]  userInfo:nil];
                }
            }
            else if(connectionError){
                @throw [NSException exceptionWithName:@"ConnectionError" reason:[NSString stringWithFormat:@"%@", connectionError]  userInfo:nil];
            }
            else
            {
                @throw [NSException exceptionWithName:@"UnknownError" reason:@"Invalid Response" userInfo:nil];
            }
        }
        @catch (NSException *exception) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Gosh Error!" message:@"Error while trying to decode" delegate:nil cancelButtonTitle:@"Okay !" otherButtonTitles:nil];
            [alert show];
        }
        @finally {
            [self.serviceCallStatus stopAnimating];
        }
        
        
    }];
}



- (IBAction)useCamera:(id)sender {
    self.textControlsSection.hidden = YES;
    [self presentViewController:self.imagePicker animated:YES completion:nil];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    @try{
        _imageView.image = info[UIImagePickerControllerOriginalImage];
        [self postOcrData: UIImageJPEGRepresentation(_imageView.image, 1.0) and:@"ocr image"];
        [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
        [self.serviceCallStatus startAnimating];
    }
    @catch (NSException *exception) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Gosh Error!" message:@"Error while trying to decode" delegate:nil cancelButtonTitle:@"Got It!" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cameraLIbrarySwap:(id)sender {
    if ([self.segmentControl selectedSegmentIndex] == 0){
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            self.buttonPerformCameraAction.enabled = YES;
            [self.buttonPerformCameraAction setTitle:@"Tap to start camera" forState:UIControlStateNormal];
            
        }
        else{
            self.buttonPerformCameraAction.enabled = NO;
        }
        
    }
    else
    {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
        {
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            self.buttonPerformCameraAction.enabled = YES;
            [self.buttonPerformCameraAction setTitle:@"Tap to go to Photo Library" forState:UIControlStateNormal];
        }
        else{
            self.buttonPerformCameraAction.enabled = NO;
        }
    }
}

// This message used for successfull data returned from network operation.
-(void)returnDataObject:(id)returnData
{
    //self.buttonGoToTaxonomy.hidden = NO;
    [_serviceCallStatus stopAnimating];
    VCKiVehicleBasicDataEntity* lVehicle = (VCKiVehicleBasicDataEntity *)returnData;
    vehicle.year = lVehicle.year;
    vehicle.make = lVehicle.make;
    vehicle.model = lVehicle.model;
    self.labelYearMakeModel.text = [NSString stringWithFormat:@"%@ - %@ - %@",vehicle.year, vehicle.make, vehicle.model ];
    [self performSegueWithIdentifier:@"segueToTaxonomy2" sender:self];
}

// This message used for notifying user on error.
-(void) showErrorMessage: (NSString *) errorMessage
{
    [_serviceCallStatus stopAnimating];
#warning Need to show error in the interface.
    NSLog(@"error - %@", errorMessage);
}

- (IBAction)buttonGoToTaxonomyClick:(id)sender {
    vehicle.vin = self.textboxResult.text;
    [self.serviceCallStatus startAnimating];
    [basicDataAccess getVehicleBasicDataForVin:vehicle.vin];
    
  /*  if(self.textControlsSection.hidden == NO && ![self.textboxResult.text  isEqual: @""])
    {
        
    } */
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if(vehicle)
    {
        VCKiTaxonomyViewController *taxonomyVC = [segue destinationViewController];
        taxonomyVC.vehicleData = vehicle;
        taxonomyVC.vehicleTitle = self.labelYearMakeModel.text;
    }
}

@end
