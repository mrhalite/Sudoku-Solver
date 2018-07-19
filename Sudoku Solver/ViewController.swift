//
//  ViewController.swift
//  Sudoku Solver
//
//  Created by 남상규 on 2018. 7. 3..
//  Copyright © 2018년 NeoLogic. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var processedImageView: UIImageView!
    
    @IBOutlet weak var infoLabel: UILabel!
    var terminateFlag: Bool = false
    var pauseStatus: Bool = false
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
//    var capturedImage: UIImage?
//    var sudokuRectImage: UIImage?
    
//    var processingTimer: Timer?
//    let model = model_64()
    
    var sudokuSolvingWorkItem: DispatchWorkItem?
    var sudokuSolvingStart: NSDate?

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("memroy")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // processedImageView가 touch 됐을 때의 처리
        processedImageView.isUserInteractionEnabled = true
        processedImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.processedImageViewTouched(_:))))
            
        // camera capture를 준비
        prepareCapture()
        // camera capture 시작
        startCapture()
    }

    func prepareCapture() {
        // setup device
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        do {
            // setup input
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            
            // setup session
            captureSession = AVCaptureSession()
            captureSession?.sessionPreset = AVCaptureSession.Preset.hd1280x720
            captureSession?.addInput(input)
            
            // setup output
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
            
            // setup session queue
            let sessionQueue = DispatchQueue(label: "VideoQueue")
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            captureSession?.addOutput(videoOutput)
            
            // setup preview layer
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            videoPreviewLayer?.frame = cameraImageView.layer.bounds
            cameraImageView.layer.addSublayer(videoPreviewLayer!)
        } catch {
            print(error)
        }
    }
    
    func startCapture() {
        captureSession?.startRunning()
    }
    
    func stopCapture() {
        captureSession?.stopRunning()
    }
    
//    func startTimer() {
//        processingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
//    }
    
//    @objc func timerTick() {
//        // process sudoku solving
//        if let img = self.capturedImage {
//            doSudokuSolving(sourceImage: img)
//        }
//    }
    
//    func stopTimer() {
//        processingTimer?.invalidate()
//        processingTimer = nil
//    }
    
    // 화면 회전에 따라 preview의 방향도 바꿔준다
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        videoPreviewLayer?.frame = cameraImageView.bounds
        videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)!
        
        if (UIDevice.current.orientation == .portrait) {
            infoLabel.numberOfLines = 1
        } else {
            infoLabel.numberOfLines = 0
        }
        infoLabel.lineBreakMode = .byCharWrapping
    }
    
    // video capture processing function
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 화면 회전에 따라 얻어지는 이미지의 방향도 바꿔준다
        connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)!

        // image 얻기
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bitsPerComponent = 8
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)!
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let newContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space:  colorSpace, bitmapInfo: bitmapInfo)
        if let context = newContext {
            let cameraFrame = context.makeImage()
            DispatchQueue.main.async {
                // create UIImage
                let img = UIImage(cgImage: cameraFrame!)
                // crop
                let w = img.size.width
                let y = (img.size.height - w) / 2
                let r = CGRect(x: 0, y: y, width: w, height: w)
                let imgRef = img.cgImage?.cropping(to: r)
                let capturedImage = UIImage(cgImage: imgRef!)
                
                self.doGetSudokuRect(capturedImage)
            }
        }
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    }
 
    func doGetSudokuRect(_ capturedImage: UIImage) {
        if let r1 = OpenCVWrapper.getSukokuImage(capturedImage) {
            processedImageView.image = r1[1] as? UIImage
        }
    }
    
    // sudoku solver
    func doSudokuSolving(sudokuImage: UIImage) {
        // get sudoku number images
        var sudokuArray:[[Int]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        if let r2 = OpenCVWrapper.getSlicedSukokuNumImages(sudokuImage, imageSize: 64, cutOffset: 0) {
            // r2[0]는 sudoku 영역을 9x9로 자르고 각각의 이미지를 64x64 크기로 변환한 UIImage array
            // r2[1]은 디버깅 목적의 9x9로 자른 이미지를 다시 하나에 합쳐 놓은 이미지(제대로 잘렸는지 보기 위한 용도)
            let numImages = r2[0] as! NSArray
            let predStartTime = NSDate()
            for i in 0..<numImages.count {
                let numimg = numImages[i]
                let col = i % 9
                let row = Int(i / 9)
                let img = numimg as! UIImage
                if let r3 = OpenCVWrapper.getNumImage(img, imageSize: 64) {
                    // r3[0]는 64x64 크기의 이미지 내에 숫자가 있으면 true, 없으면 false 이다
                    let numExist = (r3[0] as! NSNumber).boolValue
                    if numExist == true {
                        // 숫자가 존재 하는 경우 처리
                        let buf = img.pixelBuffer()
                        
                        // predict
                        let model = model_64()
                        guard let pred = try? model.prediction(x: buf!) else {
                            print("prediction exception")
                            break
                        }
                        
                        let length = pred.y.count
                        let doublePtr =  pred.y.dataPointer.bindMemory(to: Double.self, capacity: length)
                        let doubleBuffer = UnsafeBufferPointer(start: doublePtr, count: length)
                        let output = Array(doubleBuffer)
                        let maxVal = output.max()
                        let maxIdx = output.index(of: maxVal!)
                        sudokuArray[row][col] = maxIdx!
                    } else {
                        sudokuArray[row][col] = 0
                    }
                } else {
                    sudokuArray[row][col] = 0
                }
            }
            let predEndTime = NSDate()
            let predTime = predEndTime.timeIntervalSince(predStartTime as Date)

            // sudoku 풀이
            let solveStartTime = NSDate()
            var solvedSudokuArray = sudokuArray
            _ = sudoku_solver(&solvedSudokuArray, 0, 0);
            let solveEndTime = NSDate()
            let solveTime = solveEndTime.timeIntervalSince(solveStartTime as Date)
            
            // 풀어진 sudoku 표시
            drawSudoku(solvedSudokuArray, sudokuArray, sudokuImage)
            let label = String(format: "Pred: %.3f sec | Solve: %02.3f sec", predTime, solveTime)
            infoLabel.text = label
        }
    }
    
    func drawSudoku(_ sudoku: [[Int]], _ orgSudoku: [[Int]], _ sudokuImage: UIImage) {
        UIGraphicsBeginImageContext(processedImageView.bounds.size)
        sudokuImage.draw(in: CGRect(origin: CGPoint.zero, size: processedImageView.bounds.size))
        let dx = processedImageView.bounds.size.width / 9
        let dy = processedImageView.bounds.size.height / 9
        let w = Int(dx)
        let h = Int(dy)
        for row in 0..<9 {
            let y = Int(CGFloat(row) * dy)
            for col in 0..<9 {
                let x = Int(CGFloat(col) * dx)
                // sudoku에서 인식되지 않은 숫자는 풀어야하는 숫자로 빨간색 큰 글씨로 표시
                var c: UIColor = UIColor.red
                var fsz: CGFloat = 32
                // 9x9로 구분한 각 cell의 rect를 row, col에 따라 만들어냄
                var rect: CGRect = CGRect(x: x, y: y, width: w, height: h)
                // sudoku 내에 인식된 숫자가 있으면 작은 초록색 글씨로 표시
                if (orgSudoku[row][col] != 0) {
                    c = UIColor.green
                    fsz = 14
                }
                let num = String(sudoku[row][col])
                // 그릴 숫자의 밑에 shade를 넣어 잘 보이게 한다
                let shadow = NSShadow()
                shadow.shadowOffset = CGSize(width: 3, height: 3)
                shadow.shadowBlurRadius = 5.0
                shadow.shadowColor = UIColor.black
                let textFontAttributes = [
                    NSAttributedStringKey.font: UIFont(name: "Arial", size: fsz)!,
                    NSAttributedStringKey.foregroundColor: c,
                    NSAttributedStringKey.shadow: shadow,
                    ] as [NSAttributedStringKey : Any]
                let sz = num.size(withAttributes: textFontAttributes)
                // 풀어야하는 숫자의 경우 cell의 중간에 표시하고,
                // 인식된 숫자는 왼쪽위 귀퉁이에 표시한다
                if (orgSudoku[row][col] == 0) {
                    rect = CGRect(x: x + Int((dx - sz.width) / 2), y: y + Int((dy - sz.height) / 2), width: w, height: h)
                }
                num.draw(in: rect, withAttributes: textFontAttributes)
            }
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        processedImageView.image = newImage
    }
    
    @objc func processedImageViewTouched(_ sender: UITapGestureRecognizer) {
        if pauseStatus == false {
            // 현재 camera capture 중인 상태
            pauseStatus = true
            stopCapture()
            
            // sudoku 풀이 queue 생성
            sudokuSolvingWorkItem = DispatchWorkItem(block: self.sudokuSolvingQueue)
            sudokuSolvingStart = NSDate()
            DispatchQueue.main.async(execute: sudokuSolvingWorkItem!)
        } else {
            // 현재 camera capture 멈춘 상태
            // camera capture를 다시 시작
            pauseStatus = false
            startCapture()
            
            infoLabel.text = ""
        }
    }
    
    func sudokuSolvingQueue() {
        self.doSudokuSolving(sudokuImage: self.processedImageView.image!)
    }
}

extension UIImage {
    func pixelBuffer() -> CVPixelBuffer? {
        
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}

// 참고
// video capture, 처리
// https://stijnoomes.com/access-camera-pixels-with-av-foundation/

