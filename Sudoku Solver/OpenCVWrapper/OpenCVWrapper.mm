//
//  OpenCVWrapper.m
//  cam_test
//
//  Created by 남상규 on 2018. 6. 28..
//  Copyright © 2018년 NeoLogic. All rights reserved.
//

#import "OpenCVWrapper.h"

#ifdef __cplusplus
#undef NO
#undef YES
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#endif

#import <cmath>

@implementation OpenCVWrapper

// swift source code에서 cv namespace나 std namespace를 직접 보지 않도록 하기 위해
// std::vector<cv::Point>를 NSArray로 변환해 보낸다.
NSArray *getArrayOfPoint(std::vector<cv::Point> vect) {
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < vect.size(); i++) {
        NSValue *val = [NSValue valueWithCGPoint:CGPointMake(vect[i].x, vect[i].y)];
        [resultArray addObject:val];
    }
    return resultArray;
}

+ (NSMutableArray *) getSukokuImage: (UIImage *)sourceImage {
    @try {
        // UIImage를 cv::Mat로 변환
        cv::Mat sourceMat;
        UIImageToMat(sourceImage, sourceMat);
        
        //--------------------------------------------------------------------------------
        // 입력 이미지로부터 sudoku rect 찾기
        //--------------------------------------------------------------------------------
        
        // gray
        cv::Mat grayMat;
        cv::cvtColor(sourceMat, grayMat, CV_BGR2GRAY);

    //    // histogram equalize
    //    cv::Mat eqHistoMat;
    //    cv::equalizeHist(grayMat, eqHistoMat);

        // threshold
        cv::Mat threshMat;
        cv::adaptiveThreshold(grayMat, threshMat, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY_INV, 31, 31);

        // find contours
        std::vector<std::vector<cv::Point>> contours;
        std::vector<cv::Vec4i> hierarchy;
        cv::findContours(threshMat, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
        if (contours.size() < 1) {
            // no contours found
            return nil;
        }

        // find max contour
        double maxArea = 0;
        int maxContourIndex = 0;
        for (int i = 0; i < contours.size(); i++) {
            double area = cv::contourArea(contours[i]);
            if (area > maxArea) {
                maxArea = area;
                maxContourIndex = i;
            }
        }
        std::vector<cv::Point> maxContour = contours[maxContourIndex];

        // find rect points from max contour
        std::vector<int> sumv, diffv;
        for (int i = 0; i < maxContour.size(); i++) {
            cv::Point p = maxContour[i];
            sumv.push_back(p.x + p.y);
            diffv.push_back(p.x - p.y);
        }
        auto mins = std::distance(std::begin(sumv), std::min_element(std::begin(sumv), std::end(sumv)));
        auto maxs = std::distance(std::begin(sumv), std::max_element(std::begin(sumv), std::end(sumv)));
        auto mind = std::distance(std::begin(diffv), std::min_element(std::begin(diffv), std::end(diffv)));
        auto maxd = std::distance(std::begin(diffv), std::max_element(std::begin(diffv), std::end(diffv)));
        std::vector<cv::Point> maxRect;
        maxRect.push_back(maxContour[mins]); // top left
        maxRect.push_back(maxContour[mind]); // top right
        maxRect.push_back(maxContour[maxs]); // bottom right
        maxRect.push_back(maxContour[maxd]); // bottom left
        
        // get width, height of transformed image
        cv::Point tl = maxRect[0];
        cv::Point tr = maxRect[1];
        cv::Point br = maxRect[2];
        cv::Point bl = maxRect[3];
        double widthA = sqrt(pow((br.x - bl.x), 2) + pow((br.y - bl.y), 2));
        double widthB = sqrt(pow((tr.x - tl.x), 2) + pow((tr.y - tl.y), 2));
        double heightA = sqrt(pow((tr.x - br.x), 2) + pow((tr.y - br.y), 2));
        double heightB = sqrt(pow((tl.x - bl.x), 2) + pow((tl.y - bl.y), 2));
        double maxWidth = fmax(int(widthA), int(widthB));
        double maxHeight = fmax(int(heightA), int(heightB));

        // get transformation matrix & transformed image
        cv::Point2f dst[4] = {
            cv::Point2f(0, 0),
            cv::Point2f(maxWidth, 0),
            cv::Point2f(maxWidth, maxHeight),
            cv::Point2f(0, maxHeight)
        };
        cv::Point2f src[4] = { tl, bl, br, tr };
        cv::Mat M = cv::getPerspectiveTransform(src, dst);
        cv::Mat warpMat;
        cv::warpPerspective(sourceMat, warpMat, M, cv::Size(maxWidth, maxHeight));

        NSMutableArray *result = [[NSMutableArray alloc] init];
        [result addObject:getArrayOfPoint(maxRect)];
        [result addObject:MatToUIImage(warpMat)];
        
        grayMat.release();
        threshMat.release();
        sourceMat.release();
        warpMat.release();
        
        return result;
    }
    @catch (...) {
        return nil;
    }
}

+ (NSMutableArray *) getSlicedSukokuNumImages: (UIImage *)sourceImage imageSize: (int)imageSize cutOffset: (int)cutOffset {
    //--------------------------------------------------------------------------------
    // sudoku rect로부터 9x9 slice 만들기
    //--------------------------------------------------------------------------------

    // UIImage를 cv::Mat로 변환
    cv::Mat sourceMat;
    UIImageToMat(sourceImage, sourceMat);

    std::vector<UIImage *> slicedImages;
    cv::Mat numImageMat = cv::Mat(imageSize * 9, imageSize * 9, CV_8UC4);

    double dx = (sourceMat.size()).width / 9.0;
    double dy = (sourceMat.size()).height / 9.0;
    if (dx < 1.0 || dy < 1.0) {
        // 입력 이미지가 너무 작은 경우는 처리하지 않음
        return nil;
    }
    for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
            int x = (int)(col * dx);
            int y = (int)(row * dy);
            cv::Rect r = cv::Rect(x + cutOffset, y + cutOffset, dx - cutOffset, dy - cutOffset);
            cv::Mat sliced = sourceMat(r);
            cv::Mat resized;
            cv::resize(sliced, resized, cv::Size(imageSize, imageSize));

            slicedImages.push_back(MatToUIImage(resized));

            // slice 된 것들을 모아 하나의 이미지로 만든다
            x = col * imageSize;
            y = row * imageSize;
            r = cv::Rect(x, y, imageSize, imageSize);
            resized.copyTo(numImageMat(r));
            
            resized.release();
        }
    }

    // sliced image를 NSArray로 변경
    NSArray *numImages = [NSArray arrayWithObjects:&slicedImages[0] count:slicedImages.size()];
//    return numImages;
    
    // 여러 가지 정보를 묶어 return
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [result addObject:numImages];
    [result addObject:MatToUIImage(numImageMat)];
    
    sourceMat.release();
    numImageMat.release();
    
    return result;
}

+ (NSMutableArray *) getNumImage: (UIImage *)sourceImage imageSize: (int)imageSize {
    // UIImage를 cv::Mat로 변환
    cv::Mat sourceMat;
    UIImageToMat(sourceImage, sourceMat);
    
    // gray
    cv::Mat grayMat;
    cv::cvtColor(sourceMat, grayMat, CV_BGR2GRAY);
    
    // threshold
    cv::Mat threshMat;
    cv::adaptiveThreshold(grayMat, threshMat, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY_INV, 11, 41);
    
    // find contours
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(threshMat, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
    if (contours.size() < 1) {
        // no contours found
        return nil;
    }
    
    cv::Mat contourMat;
    cv::cvtColor(threshMat, contourMat, cv::COLOR_GRAY2RGB);
    
    int gx = (int)(sourceMat.size().width * 0.05);
    int gy = (int)(sourceMat.size().height * 0.05);
    int gw = (int)(sourceMat.size().width * 0.9);
    int gh = (int)(sourceMat.size().height * 0.9);
    cv::rectangle(contourMat, cv::Point(gx, gy), cv::Point(gx+gw, gy+gh), CV_RGB(0, 255, 0), 2);
    
    // find max contour
    int maxArea = 0;
    int maxContourIndex = -1;
    cv::Rect bRect;
    for (int i = 0; i < contours.size(); i++) {
        double area = cv::contourArea(contours[i]);
        if (area > 10) {
            cv::Rect r = cv::boundingRect(contours[i]);
            // overrap 영역 찾기
            int ox = MAX(gx, r.x);
            int oy = MAX(gy, r.y);
            int ox2 = MIN(gx+gw, r.x+r.width);
            int oy2 = MIN(gy+gh, r.y+r.height);
            int ow = ox2 - ox;
            int oh = oy2 - oy;
            int oarea = ow * oh;
            // overrap 영역의 크기가 bounding rect와 같으면 counding rect를 포함하고 있는 것
            if (oarea == r.area()) {
                // 포함되는 것 중 제일 큰 것만 남긴다
                if (area > maxArea) {
                    maxArea = area;
                    maxContourIndex = i;
                    bRect = r;
                }
            }
        }
    }
    
    // 여러 가지 정보를 묶어 return
    NSMutableArray *result = [[NSMutableArray alloc] init];

    // maxContourIndex가 0이상이면 숫자가 있는 것
    if (maxContourIndex >= 0) {
        cv::drawContours(contourMat, contours, maxContourIndex, CV_RGB(0, 255, 0), 2);
        NSNumber *t = [NSNumber numberWithBool:true]; // true를 return
        [result addObject:t];
    } else {
        NSNumber *f = [NSNumber numberWithBool:false]; // false를 return
        [result addObject:f];
    }
    
    // 디버깅을 위한 정보 제공 목적
    // contourMat는 95% box와 안의 숫자 contour가 그려진 이미지
    [result addObject:MatToUIImage(contourMat)];
    
    grayMat.release();
    threshMat.release();
    contourMat.release();
    
    return result;
}

@end
