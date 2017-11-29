//
//  LF_opencvStaticLib.hpp
//  smartIDCardCropper
//
//  Created by slimdy on 2017/11/6.
//  Copyright © 2017年 slimdy. All rights reserved.
//

//#ifdef __cplusplus
//#include <opencv2/opencv.hpp>
//#include <TesseractOCR/baseapi.h>
//#include <stdio.h>
//#endif
//#include <opencv2/opencv.hpp>
#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#else
#import <opencv2/opencv.hpp>
#endif
//#include <TesseractOCR/baseapi.h>
#include <tesseract/baseapi.h>
#include <stdio.h>






typedef std::pair<int, std::vector<cv::Point>::size_type> PAIR;
typedef std::pair<int, int> YPair;
bool checkImageIsRight(cv::Mat &image,std::vector<cv::Mat> &rightImages,int Width,int Height, float x,float y,float width,float height);
int getTheIDInfoFrom(std::vector<cv::Mat> &images,std::vector<std::string>&infomation,const char * path);
std::vector<cv::Mat> cutIntoPieces(cv::Mat &Image);
std::vector<cv::Mat> getAllProcessedImage(cv::Mat &image);
struct cmpByValue{
    bool operator()(const PAIR& a ,const PAIR& b){
        return a.second > b.second;
    }
};
struct cmp{
    bool operator()( YPair a , YPair b){
        return a.second > b.second;
    }
};
struct reCmp{
    bool operator()( std::pair<int,int> a , std::pair<int,int> b){
        return a.second < b.second;
    }
};
