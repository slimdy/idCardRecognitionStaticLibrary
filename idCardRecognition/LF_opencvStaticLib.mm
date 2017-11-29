//
//  LF_opencvStaticLib.cpp
//  smartIDCardCropper
//
//  Created by slimdy on 2017/11/6.
//  Copyright © 2017年 slimdy. All rights reserved.
//

#include "LF_opencvStaticLib.hpp"

using namespace std;
using namespace cv;
int Width = 600;
int  Height = 349;
float IDtoBirthH = 175.0/Height;
float IDtoOtherH  = 220.0/Height;
float IDtoNameH = 270.0/Height;
float IDtoAddressH = 130.0/Height;
float IDtoAllW = 105.0/Width;
float nameHeight = 60.0/Height;
float yearWidth = 80.0/Width;
float mothWidth = 35.0/Width;
float dayWidth = 35.0/Width;
float otherWidth = 60.0/Width;
float numberWidth = 370.0/Width;
float otherHeight = 55.0/Height;
float numberHeight = 50.0/Height;
float addressW = 280.0/Width;
float addressH = 115.0/Height;
float birthMargin =  22.0/Width;
float otherMargin = 70.0/Width;
float longWidth =  400.0/Width;


vector<Mat>* allrightImages = new vector<Mat>;


Mat unevenLightCompensate(Mat &image,int blockSize){
    double average =  mean(image)[0];
    int newRows = static_cast<int>(ceil(static_cast<float>(image.rows) /  static_cast<float>(blockSize)));
    int newCols = static_cast<int>(ceil(static_cast<float>(image.cols) /  static_cast<float>(blockSize)));
    
    Mat blockImage = Mat::zeros(newRows, newCols,CV_32FC1);
    
    for (int i = 0; i < newRows; ++i) {
        for (int j = 0; j < newCols; ++j) {
            int rowMin = i * blockSize;
            int rowMax = (i + 1) *blockSize;
            if (rowMax > image.rows) {
                rowMax = image.rows;
            }
            int colMin = j * blockSize;
            int colMax = (j + 1) * blockSize;
            if (colMax > image.cols) {
                colMax = image.cols;
            }
            Mat imageROI = image(Range(rowMin,rowMax),Range(colMin,colMax));
            double temaver = mean(imageROI)[0];
            blockImage.at<float>(i,j) = temaver;
        }
    }
    
    blockImage = blockImage - average;
    
    resize(blockImage, blockImage, image.size(),0,0,INTER_CUBIC);
    
    image.convertTo(image, CV_32FC1);
    Mat dst = image - blockImage;
    dst.convertTo(dst, CV_8UC1);
    
    return dst;
}
Mat fixLightImage(Mat &img){
    vector<Mat> rgb;
    split(img, rgb);
    
    Mat b = rgb[0];
    Mat bGray = unevenLightCompensate(b, 16);
    return bGray;
}

long int  calculateSum(vector<uchar> &vec){
    int sum = 0;
    for (auto i = vec.begin(); i != vec.end(); ++i) {
        sum += *i;
    }
    return sum;
}
int getT(Mat &image,int dt = 128){
    
    vector<uchar> low,high;
    for (int i = 0; i < image.rows; ++i) {
        const uchar *Data  = image.ptr<uchar>(i);
        for (int j = 0; j < image.cols;  ++j) {
            
            if (Data[j] > dt) {
                
                high.push_back(Data[j]);
            }else{
                low.push_back(Data[j]);
            }
        }
    }
    double highAverage = static_cast<double>(calculateSum(high)) / static_cast<double>(high.size());
    double lowAverage = static_cast<double>(calculateSum(low)) / static_cast<double>(low.size());
    double nT = (highAverage + lowAverage) / 2.0;
    if (abs(nT - dt) > 8) {
        return getT(image,nT);
    }else{
        return static_cast<int>(nT);
    }
    
}
Mat handleImage(Mat &grayImage){
    int T = getT(grayImage);
    Mat binaryedImage;
    threshold(grayImage, binaryedImage, T, 255, THRESH_OTSU);
    Mat kernel = getStructuringElement(MORPH_RECT, cv::Size(3,3));
    
    erode(binaryedImage, binaryedImage, kernel);
    return binaryedImage;
}
vector<cv::Point> findIconContour(vector<vector<cv::Point>> &contours, Mat& image){
    auto length = contours.end() - contours.begin();
    map<int, int> areaDict;
    map<int,vector<cv::Point>> contoursDic;
    
    for (int i = 0 ; i < length ; ++i){
        cv::Rect area = boundingRect(contours[i]) ;
        if (area.width*area.height < image.rows*image.cols) {
            contoursDic.insert(make_pair(i, contours[i]));
            areaDict.insert(make_pair(i, area.width*area.height));
        }

    }
    
    if(areaDict.empty()){
        vector<cv::Point> res;
        return res;
    }
    
    vector<pair<int, int>> vec(areaDict.begin(), areaDict.end());
    sort(vec.begin(), vec.end(),cmpByValue());
    
    vector<cv::Point> contour = contoursDic[vec.begin()->first];
    return contour;
}
//cutImage
vector<vector<cv::Point>> findIDcnt(vector<vector<cv::Point>> &contours,int number , Mat &image){
    map<int, int> widths;
    for (int i = 0; i < contours.size(); ++i) {
        cv::Rect rect = boundingRect(contours[i]);
        if (rect.height <= 0.35 * image.rows){
            if ( (rect.y < image.rows * 0.93) &&( rect.x > 0.28 * image.cols ) && (rect.width >= 0.5 * image.cols) ) {
                widths.insert(make_pair(i, rect.width));
            }
        }
    }
    //找出widths里面最大的一个宽度
    vector<pair<int, int>> vec(widths.begin(),widths.end());
    sort(vec.begin(),vec.end(),cmpByValue());
    vector<vector<cv::Point>> contourList;
    try {
        if(vec.size() == 0){
            const string error = "身份id提取有误";
            throw error;
        }
    } catch (string str) {
        cout << str << endl;
        return contourList;
    }
    
    for (int i = 0; i < number; ++i) {
        
        contourList.push_back(contours[vec[i].first]);
        
    }
    return contourList;
    
}
vector<vector<cv::Point>> findIDNumber(Mat &scrImage,Mat &Oimage){
    Mat kernel = getStructuringElement(MORPH_RECT, cv::Size(2,3));
    Mat closedImage;
    morphologyEx(scrImage, closedImage, MORPH_CLOSE, kernel);
    
    bitwise_not(closedImage, closedImage);
    
    Mat kernel1 = getStructuringElement(MORPH_RECT, cv::Size(16,11));

    dilate(closedImage, closedImage, kernel1,cv::Point(-1, -1),1);
    
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(closedImage, contours, hierarchy, RETR_LIST, CHAIN_APPROX_NONE);
    vector<vector<cv::Point>> wContours = findIDcnt(contours, 1, closedImage);
    return wContours;
}
Mat rotateImage(Mat &image,vector<cv::Point> &contour){
    RotatedRect rect = minAreaRect(contour);
    //    cout << rect.center << "----" << rect.size << "----"<< rect.angle << "----"<<endl;
    Mat pointsMat;
    boxPoints(rect, pointsMat);
    
    vector<Point2f> points(4);
    for (int i = 0; i < pointsMat.rows; ++i) {
        Point2f point = Point2f(pointsMat.at<float>(i,0),pointsMat.at<float>(i,1));
        points[i]=point;
    }
    //    cout << points << endl;
    double line1 =sqrt((points[1].y-points[0].y)*(points[1].y-points[0].y)+(points[1].x-points[0].x) * (points[1].x-points[0].x));
    double line2 = sqrt((points[3].y -points[0].y) *(points[3].y -points[0].y) + (points[3].x -points[0].x) *(points[3].x -points[0].x));
    float angle = rect.angle;
    if (line1 > line2){
        angle = 90 +rect.angle;
    }
    Mat M = getRotationMatrix2D(rect.center, angle, 1.0);
    Mat rotatedImage;
    warpAffine(image, rotatedImage, M, image.size());
    return rotatedImage;
}
Mat fillTheBlckToWhite(Mat Oimage){
    int h = Oimage.rows;
    int w = Oimage.cols;
    for (int i = 0;  i < h; ++i) {
        for (int j = 0; j < w; ++j) {
            if (Oimage.at<Vec3b>(i,j)[0] == 0 && Oimage.at<Vec3b>(i,j)[1] == 0 && Oimage.at<Vec3b>(i,j)[2] == 0) {
                Oimage.at<Vec3b>(i,j)[0] = 255;
                Oimage.at<Vec3b>(i,j)[1] = 255;
                Oimage.at<Vec3b>(i,j)[2] = 255;
            }
        }
    }
    return Oimage;
}
vector<cv::Rect> findAllInfo(vector<cv::Point> &IDContour){
    cv::Rect IDRect = boundingRect(IDContour);
    //    cout << IDRect << endl;
    int allX = IDRect.x - IDtoAllW*Width;
    //    cout << IDtoAllW << endl;
    cv::Rect years = cv::Rect(allX,IDRect.y-IDtoBirthH*Height,yearWidth*Width,numberHeight*Height);
    cv::Rect month = cv::Rect(allX+yearWidth*Width+birthMargin*Width,IDRect.y-IDtoBirthH*Height,mothWidth*Width,numberHeight*Height);
    cv::Rect day = cv::Rect(allX+yearWidth*Width+birthMargin*Width*2+mothWidth*Width,IDRect.y-IDtoBirthH*Height,dayWidth*Width,numberHeight*Height);
    cv::Rect sex = cv::Rect(allX,IDRect.y-IDtoOtherH*Height,otherWidth*Width,otherHeight*Height);
    cv::Rect race = cv::Rect(allX+otherWidth*Width+otherMargin*Width,IDRect.y-IDtoOtherH*Height,longWidth*Width-(IDRect.x+otherWidth*Width+otherMargin*Width),otherHeight*Height);
    cv::Rect name = cv::Rect(allX,IDRect.y-IDtoNameH*Height,longWidth*Width-allX,nameHeight*Height);
    cv::Rect address = cv::Rect(allX,IDRect.y-IDtoAddressH*Height,addressW*Width,addressH*Height);
    vector<cv::Rect> allInfo = {name,sex,race,years,month,day,address};
    return allInfo;
}
Mat getPartOfOriginImage(Mat &Oimage,cv::Rect &rect){
    return Oimage(Range(rect.y,rect.y+rect.height),Range(rect.x,rect.x+rect.width));
}
vector<Mat> cutIntoPieces(Mat &Image){
    Mat img ;
    resize(Image, img, cv::Size(Width,Height));
    
    Mat grayImage = fixLightImage(img);
    
    Mat binaryedImage = handleImage(grayImage);
    
    vector<vector<cv::Point>> wContour;
    wContour = findIDNumber(binaryedImage, img);
    vector<Mat> allCutImages ;
    if(wContour.empty()){
        return allCutImages;
    }
    Mat rotatedImage = rotateImage(img,wContour[0]);
    
    Mat newImage = fillTheBlckToWhite(rotatedImage);
    
    grayImage = fixLightImage(newImage);
    
    binaryedImage = handleImage(grayImage);
    
    wContour = findIDNumber(binaryedImage, rotatedImage);
    cv::Rect wRect = boundingRect(wContour[0]);
    vector<cv::Rect> allInfo = findAllInfo(wContour[0]);
    //    for (auto i : allInfo){
    //        cout << i.x <<"------"<< i.y <<"------"<<i.width <<"------"<< i.height <<"------"<< endl;
    //    }
    allInfo.push_back(wRect);
    
    for (cv::Rect i: allInfo){
        std::cout << i << std::endl;
        allCutImages.push_back(getPartOfOriginImage(rotatedImage, i));
    }
//    std::cout << allCutImages[0] << std::endl;
    return allCutImages;
}
bool checkImageIsRight(Mat &image, vector<Mat> &rightImages,int Width,int Height, float x,float y,float width,float height){
    Mat img = image;
    cvtColor(img, img, CV_RGBA2BGR);
    resize(img, img, cv::Size(Width,Height));
    img= fixLightImage(img);
    img = handleImage(img);
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(img, contours, hierarchy, RETR_LIST, CHAIN_APPROX_NONE);
    if (contours.size() ==0 ){
        return false;
    }
    vector<cv::Point> iconContour = findIconContour(contours,img);
    if (iconContour.empty()) {
        return false;
    }
    cv::Rect rect = boundingRect(iconContour);
//    cout << rect <<endl;
//    cout << "-----x: "<<x<< "-----y:"<<y<<"----- width :"<<width<< "-----"<< "----- height :"<<height<< "------ Width :"<<Width <<"-------- Height: " << Height <<endl;
//    cout << "-----"<<abs(x-rect.x)<< "-----"<<abs(y-rect.y)<<"-----"<<abs(width-rect.width)<< "-----"<< "-----"<<abs(height-rect.height)<<endl;
    if (abs(x-rect.x) < 5 && abs(y-rect.y) < 8 && abs(width-rect.width) < 15 && abs(height-rect.height) < 10) {
//        return true;
        //问题在这 这个图片不对 11.25
        vector<Mat> images = cutIntoPieces(image);
        if (images.empty()||images.size() != 8) {
            return false;
        }else{
            rightImages = images;
            return true;
        }
    }else{
        return false;
    }
}
Mat fixLightImage2(Mat &img){
    Mat image = img;
    cvtColor(image, image, COLOR_BGR2GRAY);
    //    imshow("image",image);
    //    waitKey();
    
    return image;
}
Mat handleImage2(Mat &img){
    Mat image = img;
    GaussianBlur(image, image, cv::Size(3, 3), 0);
    //    imshow("image",image);
    //    waitKey();
    medianBlur(image, image, 3);
    //    imshow("image",image);
    //    waitKey();
    adaptiveThreshold(image, image, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY_INV, 5, 4);
    //    imshow("image",image);
    //    waitKey();
    bitwise_not(image, image);
    Mat kernel = getStructuringElement(MORPH_RECT, cv::Size(2,2));
    dilate(image, image, kernel);
    //    imshow("image",image);
    //    waitKey();
    erode(image, image, kernel);
    //    imshow("image",image);
    //    waitKey();
    
    return image;
}
vector<Mat> cutAddressImage(Mat &binaryImage,Mat &grayImage){
    Mat dilateStruct = getStructuringElement(MORPH_CROSS,cv::Size(3,3));
    Mat erodeStruct =  getStructuringElement(MORPH_RECT,cv::Size(12,18));
    Mat dilated;
    dilate(binaryImage, dilated, dilateStruct,cv::Point(-1,-1),1);
    //    imshow("image",dilated);
    //    waitKey();
    erode(dilated, dilated, erodeStruct,cv::Point(-1,-1),1);
    //    imshow("image",eroded);
    //    waitKey();
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(dilated, contours, hierarchy, RETR_LIST, CHAIN_APPROX_NONE);
    
    auto length = contours.end() - contours.begin();
    
    map<int,int> ys;
    
    for (int i = 0 ; i < length ; ++i){
        cv::Rect area = boundingRect(contours[i]) ;
        if (area.width*area.height > 30*10) {
            ys.insert(make_pair(i,area.y));
        }
    }
    vector<YPair> vec(ys.begin(), ys.end());
    sort(vec.begin(), vec.end(),cmp());
    
    YPair bigestY = *(vec.begin());
    cv::Rect area = boundingRect(contours[vec.begin()->first]);
    cv::Rect rect = cv::Rect(0,0,grayImage.cols,area.height+bigestY.second);
    vector<Mat> res;
    Mat addressImage = getPartOfOriginImage(grayImage, rect);
    
    resize(addressImage, addressImage, cv::Size(addressImage.cols*3,addressImage.rows*3));
    //    imshow("image", addressImage);
    //    waitKey();
    res.push_back(addressImage);
    return res;
    
    
}
vector<Mat> findCutSingleChar(vector<vector<cv::Point>> &contours, Mat &image){
    auto length = contours.end() - contours.begin();
    
    map<int,int> contoursMap;
    
    for (int i = 0 ; i < length ; ++i){
        cv::Rect area = boundingRect(contours[i]) ;
        
        if (area.width*area.height < image.rows*image.cols) {
            if(area.width*area.height < 25*10){
                continue;
            }
            contoursMap.insert(make_pair(i, area.x));
        }
        
    }
    vector<Mat> res;
    if (contoursMap.empty()) {
        
        return res;
    }
    vector<pair<int, int>> vec(contoursMap.begin(), contoursMap.end());
    sort(vec.begin(), vec.end(),reCmp());
    for (auto i : vec) {
        cv::Rect rect = boundingRect(contours[i.first]);
        Mat img = getPartOfOriginImage(image, rect);
        resize(img, img, cv::Size(img.cols*4,img.rows*4));
        res.push_back(img);
    }
    return res;
    
    
}
vector<Mat> processPartImage(Mat &binaryImage,Mat &Oimage ,Mat &colorImage ,int index){
    vector<Mat> images;
    if(index == 6){
        
        images = cutAddressImage(binaryImage,Oimage);
        return images;
    }
    Mat dilateStruct = getStructuringElement(MORPH_CROSS,cv::Size(3,3));
    Mat erodeStruct =  getStructuringElement(MORPH_RECT,cv::Size(9,9));
    Mat dilated;
    dilate(binaryImage, dilated, dilateStruct,cv::Point(-1,-1),1);
    //    imshow("image",dilated);
    //    waitKey();

    erode(dilated, dilated, erodeStruct,cv::Point(-1,-1),1);
    //    imshow("image",eroded);
    //    waitKey();
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(dilated, contours, hierarchy, RETR_LIST, CHAIN_APPROX_NONE);
    //    drawContours(Oimage, contours, -1, Scalar(255));
    //    imshow("image",Oimage);
    //    waitKey();
    
    if( index != 7){
        images = findCutSingleChar(contours, Oimage);
    }else{
        resize(binaryImage, binaryImage, cv::Size(binaryImage.cols*8,binaryImage.rows*8));
        images.push_back(binaryImage);
    }
    
    return images;
    
}
string fun( char *str)
{
    int i,j;
    for (i = 0; str[i];) {
        if (str[i]=='\n'||str[i]=='\r' || str[i]=='\t' || str[i]==' ') {
            for (j=i; str[j]; j++) {
                str[j]=str[j+1];
            }
        }
        else i++;
    }
    
    return str;
}
int IncludeChinese(string strString)//返回0：无中文，返回1：有中文
{
    char *str = (char*)strString.data();
    const char sign[] = {",.!?/'\"<>\\:;!@#$%^&*()_+{}[]~|`"};//半角
    const char sign2[]={"，。！？、；：“”‘’！￥（）【】、·"};//全角
    while (*str != '\0') {
        if ((int)*str > 0) {
            return 0;
        }else{
            for (auto i : sign) {
                if (i == *str) {
                    return 0;
                }
            }
            for(int j=0;j< strlen(sign2);j+=2)
                if(sign2[j]== *str) return 0;
        }
        str++;
    }
    return 1;
}
int AllisNum(string str)
{
    for (int i = 0; i < str.size(); i++){
        int tmp1 = (int)str[i];
        if (tmp1 >= 48 && tmp1 <= 57){
            continue;
        } else {
            return 0;
        }
    }
    return 1;
}
bool isXorNumber(char c){
    if(c >='0' && c<='9') return true;
    if(c == 'X' || c== 'x') return true;
    return false;
}
std::vector<cv::Mat> getAllProcessedImage(cv::Mat &image){
    vector<Mat> images = cutIntoPieces(image);
    vector<Mat> newGrayImages;
    if (images.empty()) {
        return newGrayImages;
    }
    for (int i = 0; i < images.size(); ++i) {
        
        Mat bigImage  = images[i];
        //        resize(images[i], bigImage, cv::Size(images[i].cols*1,images[i].rows*1));
        Mat grayImage = fixLightImage2(bigImage);
        Mat grayImageForAddress = fixLightImage(bigImage);
        //        imshow("image",grayImage);
        //        waitKey();
        Mat binaryedImage = handleImage2(grayImage);
        
        
        vector<Mat> hehe =  processPartImage(binaryedImage,grayImageForAddress,bigImage,i);
        for(Mat i : hehe){
            newGrayImages.push_back(i);
        }
        
    }
    return newGrayImages;
}
int getTheIDInfoFrom(std::vector<cv::Mat> &images,vector<string>&infomation,const char * path){
    
//    vector<Mat> images = cutIntoPieces(image);
//    if (images.empty()||images.size() != 8) {
//        return 0;
//    }

    tesseract::TessBaseAPI tessEng;
    tesseract::TessBaseAPI tessChi;
    tessEng.Init(path,"eng",tesseract::OEM_DEFAULT);
    tessEng.SetPageSegMode(tesseract::PSM_SINGLE_BLOCK);

    tessChi.Init(path,"chi_sim",tesseract::OEM_TESSERACT_CUBE_COMBINED);
    tessChi.SetPageSegMode(tesseract::PSM_SINGLE_BLOCK);
    for (int i = 0; i < images.size(); ++i) {

        Mat bigImage  = images[i];
        //        resize(images[i], bigImage, cv::Size(images[i].cols*1,images[i].rows*1));
        Mat grayImage = fixLightImage2(bigImage);
        Mat grayImageForAddress = fixLightImage(bigImage);
        //        imshow("image",grayImage);
        //        waitKey();
        Mat binaryedImage = handleImage2(grayImage);


        vector<Mat> newGrayImages =  processPartImage(binaryedImage,grayImageForAddress,bigImage,i);

        int j = 0;
        string outText = "";
        for (Mat newGrayImage : newGrayImages) {
//                        imshow("image_"+to_string(j),newGrayImage);
//                        waitKey();
//                        if (i == 6) {
//                            imwrite("/Users/slimdy/Desktop/image5_"+ to_string(rand())+".jpg", newGrayImage);
//                        }


            if ((i >= 3 && i <= 5) || i == 7) {
                tessEng.SetVariable("tessedit_char_whitelist", "1234567890X");
                tessEng.SetImage((uchar*)newGrayImage.data, newGrayImage.cols, newGrayImage.rows, 1, newGrayImage.cols);
                 char *str = tessEng.GetUTF8Text();
                outText += fun(str);
                delete []str;
            }else{
                if (i == 1) {
                    tessChi.SetVariable("tessedit_char_whitelist", "男女");
                }else{
                    tessChi.SetVariable("tessedit_char_whitelist", "");
                }
                tessChi.SetImage((uchar*)newGrayImage.data, newGrayImage.cols, newGrayImage.rows, 1, newGrayImage.cols);
                char *str = tessChi.GetUTF8Text();
                outText += fun(str);
                delete []str;
            }

            j++;
        }
        
        switch (i) {
            case 0:
            {
                string name = outText;
                if (IncludeChinese(name) == 0) {
                    return 0;
                }
                infomation.push_back(name);
                outText="";
                break;
            }
            case 1:
            {
                string sex = outText;
                 if (sex.size() !=3 ||IncludeChinese(sex) == 0) {
                    return 0;
                 }
                infomation.push_back(sex);
                outText="";
                break;
            }
            case 2:
            {
                string race = outText;
                if (race.size() <3 ||IncludeChinese(race) == 0) {
                    return 0;
                }
                infomation.push_back(race);
                outText="";
                break;
            }
            case 3:{

                string year = outText;
                if (year.size() !=4 ||AllisNum(year) == 0) {
                    return 0;
                }
             
                infomation.push_back(year);
                outText="";
                break;
            }

            case 4:
            {
                string month = outText;
                if (month.size() > 2 ||AllisNum(month) == 0) {
                    return 0;
                }
                infomation.push_back(month);
                outText="";
                break;
            }
            case 5:
            {
                string day = outText;
                if (day.size() > 2 ||AllisNum(day) == 0) {
                    return 0;
                }
                infomation.push_back(day);
                outText="";
                break;
            }
            case 6:
            {
                string address = outText;
                //                 cout << outText <<endl;
                //                cout << address.size() << endl;
                if (address.size() < 9) {
                    return 0;
                }
                infomation.push_back(address);
                outText="";
                break;
            }
            case 7:
            {
                string idNum = outText;
                outText.erase(--outText.end());
                if (idNum.size() != 18 || AllisNum(outText) == 0 || !isXorNumber(*(--idNum.end()))) {
                    return 0;
                }
                infomation.push_back(idNum);
                outText="";
            }
            default:
            {
                outText = "";
                break;
            }
        }

    }
    tessChi.Clear();
    tessEng.Clear();
    tessChi.End();
    tessEng.End();
    return 1;
    
}


