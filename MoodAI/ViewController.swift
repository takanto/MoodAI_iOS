//
//  ViewController.swift
//  MoodAI
//  Takato Kan

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {

  // MARK: - Variables
  
  private var drawings: [CAShapeLayer] = []
  
    
    @IBOutlet weak var selfiePromptView: UIView!
    @IBOutlet weak var resultView: UIView!
    @IBOutlet weak var imageTaken: UIImageView!
    @IBOutlet weak var buttonView: UIView!
  private let videoDataOutput = AVCaptureVideoDataOutput()
  private let captureSession = AVCaptureSession()
    var photoOutput: AVCapturePhotoOutput?
    var face: UIImage?
    var captured = false
  
  /// Using `lazy` keyword because the `captureSession` needs to be loaded before we can use the preview layer.
  private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.

      buttonView.layer.cornerRadius = buttonView.frame.width / 2
      buttonView.layer.masksToBounds = true
      
      captureSession.sessionPreset = AVCaptureSession.Preset.photo
      
      self.resultView.isUserInteractionEnabled = false
      self.resultView.isHidden = true
      self.selfiePromptView.isHidden = true
      
      addCameraInput()
      showCameraFeed()
        
      getCameraFrames()
      DispatchQueue.global(qos: .background).async {
              self.captureSession.startRunning()
      }
  }
    
  override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      captureSession.stopRunning()
  }
  
  /// The account for when the container's `view` changes.
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    previewLayer.frame = view.frame
  }
  
  // MARK: - Helper Functions
  
  private func addCameraInput() {
    
    guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: .front).devices.first else {
      fatalError("No camera detected. Please use a real camera, not a simulator.")
    }
    
    // ⚠️ You should wrap this in a `do-catch` block, but this will be good enough for the demo.
    let cameraInput = try! AVCaptureDeviceInput(device: device)
    captureSession.addInput(cameraInput)
  }
  
  private func showCameraFeed() {
    previewLayer.videoGravity = .resizeAspectFill
    view.layer.addSublayer(previewLayer)
    previewLayer.frame = view.frame
  }
  
  private func getCameraFrames() {
    videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
    
    videoDataOutput.alwaysDiscardsLateVideoFrames = true
    // You do not want to process the frames on the Main Thread so we off load to another thread
    videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
    
    captureSession.addOutput(videoDataOutput)
    photoOutput = AVCapturePhotoOutput()
    photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format:[AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
    captureSession.addOutput(photoOutput!)
    
    guard let connection = videoDataOutput.connection(with: .video), connection.isVideoOrientationSupported else {
      return
    }
    
    connection.videoOrientation = .portrait
  }
  
  private func detectFace(image: CVPixelBuffer) {
    let faceDetectionRequest = VNDetectFaceLandmarksRequest { vnRequest, error in
      DispatchQueue.main.async {
        if let results = vnRequest.results as? [VNFaceObservation], results.count > 0 {
            self.view.bringSubviewToFront(self.buttonView)
            self.selfiePromptView.isHidden = true
            if self.captured == false {
              self.buttonView.isHidden = false
              self.handleFaceDetectionResults(observedFaces: results)
            }
            else {
                self.buttonView.isHidden = true
              self.clearDrawings()
            }
          
        } else {
            if self.captured == true {
                self.selfiePromptView.isHidden = true
            }
            else {
                self.selfiePromptView.isHidden = false
            }
            self.view.bringSubviewToFront(self.selfiePromptView)
            self.buttonView.isHidden = true
          self.clearDrawings()
        }
      }
    }
    
    let imageResultHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
    try? imageResultHandler.perform([faceDetectionRequest])
  }
  
  private func handleFaceDetectionResults(observedFaces: [VNFaceObservation]) {
    clearDrawings()
    
    // Create the boxes
    let facesBoundingBoxes: [CAShapeLayer] = observedFaces.map({ (observedFace: VNFaceObservation) -> CAShapeLayer in
      
      let faceBoundingBoxOnScreen = previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
      let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen, transform: nil)
      let faceBoundingBoxShape = CAShapeLayer()
      
      // Set properties of the box shape
      faceBoundingBoxShape.path = faceBoundingBoxPath
      faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
      faceBoundingBoxShape.strokeColor = UIColor.green.cgColor
      
      return faceBoundingBoxShape
    })
    
    // Add boxes to the view layer and the array
    facesBoundingBoxes.forEach { faceBoundingBox in
      view.layer.addSublayer(faceBoundingBox)
      drawings = facesBoundingBoxes
    }
  }
  
  private func clearDrawings() {
    drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
  }
  
  @IBAction func buttonTap(_ sender: Any) {
      
      let seconds = 1.0
      DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
          self.resultView.isUserInteractionEnabled = true
          self.resultView.isHidden = false
      }
      self.selfiePromptView.isHidden = true
      self.resultView.contentMode = .scaleAspectFill
      self.view.bringSubviewToFront(self.resultView)
        self.buttonView.isUserInteractionEnabled = false
        self.buttonView.isHidden = true
      
    let settings = AVCapturePhotoSettings()
    photoOutput?.capturePhoto(with: settings, delegate: self)
      
      self.captured = true
  }
    
  @IBAction func retakeTap(_ sender: Any) {
    self.resultView.isUserInteractionEnabled = false
    self.resultView.isHidden = true
      self.buttonView.isUserInteractionEnabled = true
      self.buttonView.isHidden = false
      
      self.captured = false
  }
    
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if (segue.identifier == "showPhoto") {
        let newVC = segue.destination as! SecondViewController
        faceCenterImage(imageTaken.image!)
        newVC.image = self.face
    }
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
    guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      debugPrint("Unable to get image from the sample buffer")
      return
    }
    
    detectFace(image: frame)
  }
  
}

extension ViewController: AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(){
            let image = UIImage(data: imageData)
            imageTaken.image = image!
            faceCenterImage(image!)
            imageTaken.transform = CGAffineTransformMakeScale(-1, 1)
        }
    }
}

extension ViewController {
    
    func faceCenterImage(_ image: UIImage) {
        
        // 1
        guard let uncroppedCgImage = image.cgImage else {
            face = image
            return
        }

        // 2
        DispatchQueue.global(qos: .userInteractive).async {
            uncroppedCgImage.faceCrop { [weak self] result in
                switch result {
                case .success(let cgImage):
                    // 3
                    DispatchQueue.main.async { self?.face = UIImage(cgImage: cgImage) }
                case .notFound, .failure( _):
                    // 4
                    DispatchQueue.main.async { self?.face = image }
                }
            }
        }
    }
}

public extension CGImage {
    @available(iOS 11.0, *)
    func faceCrop(margin: CGFloat = 200, completion: @escaping (FaceCropResult) -> Void) {
        let req = VNDetectFaceRectanglesRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let results = request.results, !results.isEmpty else {
                completion(.notFound)
                return
            }
            
            var faces: [VNFaceObservation] = []
            for result in results {
                guard let face = result as? VNFaceObservation else { continue }
                faces.append(face)
            }
            
            // 1
            let croppingRect = self.getCroppingRect(for: faces, margin: margin)
                                                 
            // 10
            let faceImage = self.cropping(to: croppingRect)
            
            // 11
            guard let result = faceImage else {
                completion(.notFound)
                return
            }
            
            // 12
            completion(.success(result))
        }
        
        do {
            try VNImageRequestHandler(cgImage: self, options: [:]).perform([req])
        } catch let error {
            completion(.failure(error))
        }
    }
    
    @available(iOS 11.0, *)
    private func getCroppingRect(for faces: [VNFaceObservation], margin: CGFloat) -> CGRect {
        
        // 2
        var totalX = CGFloat(0)
        var totalY = CGFloat(0)
        var totalW = CGFloat(0)
        var totalH = CGFloat(0)
        
        // 3
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        let numFaces = CGFloat(faces.count)
        
        // 4
        for face in faces {
            
            // 5
            let w = face.boundingBox.width * CGFloat(width)
            let h = face.boundingBox.height * CGFloat(height)
            let x = face.boundingBox.origin.x * CGFloat(width)
            
            // 6
            let y = (1 - face.boundingBox.origin.y) * CGFloat(height) - h
            
            totalX += x
            totalY += y
            totalW += w
            totalH += h
            minX = .minimum(minX, x)
            minY = .minimum(minY, y)
        }
        
        // 7
        let avgX = totalX / numFaces
        let avgY = totalY / numFaces
        let avgW = totalW / numFaces
        let avgH = totalH / numFaces
        
        // 8
        let offset = margin + avgX - minX
        
        // 9
        return CGRect(x: avgX - offset, y: avgY - offset, width: avgW + (offset * 2), height: avgH + (offset * 2))
    }
}

public enum FaceCropResult {
    case success(CGImage)
    case notFound
    case failure(Error)
}
