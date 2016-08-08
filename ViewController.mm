//
//  ViewController.m
//  SevenSegment
//
//  Created by MegamanX on 7/27/16.
//  Copyright © 2016 ScottSpencer. All rights reserved.
//

#import "ViewController.h"
#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>
#import <opencv2/highgui/ios.h>
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include <iostream>
#include <stdio.h>

using namespace std;
using namespace cv;

@interface ViewController ()<CvVideoCameraDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) UIImage * image;
@property (nonatomic, strong) CvVideoCamera * videoCamera;
@end

@implementation ViewController

Mat img;
Mat templ[10];
Mat result;

int match_method;
int max_Trackbar;






- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // max_Trackbar = 5;
    match_method = 5;
    
    self.image = [UIImage imageNamed:@"sample2.png"];//self.image = [UIImage imageNamed:@"original.png"];
    img = [self cvMatFromUIImage:self.image];
    cv::cvtColor(img, img, cv::COLOR_BGR2GRAY);
    cv::adaptiveThreshold(img, img, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY_INV, 115, 1);
    
    
//    for(int i = 0; i < 10; i++){
//        self.image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.png",i]];
//        templ[i] = [self cvMatFromUIImage:self.image];
//    
//    
//    //cv::cvtColor(templ[i], templ[i], cv::COLOR_BGR2GRAY);
//    //cv::adaptiveThreshold(templ[i], templ[i], 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY_INV, 115, 1);
//     [self MatchingMethodwithTemplateIndex:i];
//    }
    
   
    
    
    
    cout<<"done";

}

-(void)viewDidAppear:(BOOL)animated{
    
    
    for(int i = 9; i > 0; i--){
        self.image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.png",i]];
        templ[i] = [self cvMatFromUIImage:self.image];
        
        
        cv::cvtColor(templ[i], templ[i], cv::COLOR_BGR2GRAY);
        cv::adaptiveThreshold(templ[i], templ[i], 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY_INV, 115, 1);
        [self MatchingMethodwithTemplateIndex:i];
    }
    
}

-(void)processImage:(cv::Mat &)image{
  
    [self.videoCamera start];

}

- (void)MatchingMethodwithTemplateIndex:(int)index
{
    /// Source image to display
    Mat img_display;
    
    img.copyTo( img_display );
    const double threshold = 1.0;
    /// Create the result matrix
    int result_cols =  img.cols - templ[index].cols + 1;
    int result_rows = img.rows - templ[index].rows + 1;
    
    result.create( result_rows, result_cols, CV_32FC1 );
    //cv::cvtColor(img_display, img_display, cv::COLOR_BGR2GRAY);
    //cv::cvtColor(templ, templ, cv::COLOR_BGR2GRAY);
    
    //cv::adaptiveThreshold(img_display, img_display, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY_INV, 115, 1);
    
    /// Do the Matching and Normalize
    matchTemplate( img_display, templ[index], result, match_method );
    normalize( result, result, 0, 1, NORM_MINMAX, -1, Mat() );
    
    
    /// Localizing the best match with minMaxLoc
    double minVal; double maxVal; cv::Point minLoc; cv::Point maxLoc;
    cv::Point matchLoc;
    
    

    
    while(true){
        minMaxLoc( result, &minVal, &maxVal, &minLoc, &maxLoc, Mat() );
        /// For SQDIFF and SQDIFF_NORMED, the best matches are lower values. For all the other methods, the higher the better
        if( match_method  == CV_TM_SQDIFF || match_method == CV_TM_SQDIFF_NORMED )
        { matchLoc = minLoc; }
        else
        { matchLoc = maxLoc; }
    
        if(maxVal >= threshold){
        /// Show me what you got
            rectangle( img, matchLoc, cv::Point( matchLoc.x + templ[index].cols , matchLoc.y + templ[index].rows ), Scalar(0,255,0), 10, 8, 0 );
            //cv::cvtColor(img_display, img_display, cv::COLOR_BGRA2BGR);
    
            cv::floodFill(result, maxLoc, cv::Scalar(0),0, cv::Scalar(0.1), cvScalar(1.0));
            //rectangle( result, matchLoc, cv::Point( matchLoc.x + templ.cols , matchLoc.y + templ.rows ), Scalar(0,255,0), 2, 8, 0 );
            
            UIImage * retImg = [self UIImageFromCVMat:img];
            
            [self.imageView setImage: retImg];
    
        }
        else{
            break;
        }
            
    }
    
    
    
    return;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data, // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}




@end
