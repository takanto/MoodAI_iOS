//
//  SeconfViewController.swift
//  MoodAI
//  Takato Kan


import UIKit
import TensorFlowLite

class SecondViewController: UIViewController {

    @IBOutlet weak var Angry: UIButton!
    @IBOutlet weak var Disgust: UIButton!
    @IBOutlet weak var Fear: UIButton!
    @IBOutlet weak var Happy: UIButton!
    @IBOutlet weak var Sad: UIButton!
    @IBOutlet weak var Surprise: UIButton!
    @IBOutlet weak var Neutral: UIButton!
    
    var Emotion = ""
    var Emoji = ""
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var resultView2: UIView!

    var image: UIImage?
    var icon: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultView2.isUserInteractionEnabled = false
        resultView2.isHidden = true
        
        Angry.layer.cornerRadius = 15
        Angry.layer.masksToBounds = true
        
        Disgust.layer.cornerRadius = 15
        Disgust.layer.masksToBounds = true
        
        Fear.layer.cornerRadius = 15
        Fear.layer.masksToBounds = true
        
        Happy.layer.cornerRadius = 15
        Happy.layer.masksToBounds = true
        
        Sad.layer.cornerRadius = 15
        Sad.layer.masksToBounds = true
        
        Surprise.layer.cornerRadius = 15
        Surprise.layer.masksToBounds = true
        
        Neutral.layer.cornerRadius = 15
        Neutral.layer.masksToBounds = true
        
        Angry.titleLabel?.font=UIFont.boldSystemFont(ofSize: 18)
        Disgust.titleLabel?.font=UIFont.boldSystemFont(ofSize: 18)
        Fear.titleLabel?.font=UIFont.boldSystemFont(ofSize: 18)
        Happy.titleLabel?.font=UIFont.boldSystemFont(ofSize: 18)
        Sad.titleLabel?.font=UIFont.boldSystemFont(ofSize: 18)
        Surprise.titleLabel?.font=UIFont.boldSystemFont(ofSize: 18)
        Neutral.titleLabel?.font=UIFont.boldSystemFont(ofSize: 18)
        
        // Do any additional setup after loading the view.
        //resultView.contentMode = .scaleAspectFit
        
        image = self.image?.rotate(radians: .pi/2)
        //resultView.image = image
        //resultView.transform = CGAffineTransformMakeScale(-1, 1)
        self.icon = resizeImage(image: image!, size: 90)
        image = resizeImage(image: image!, size:48)
        image = image?.noir
        //image = image?.rotate(radians: (.pi*3) / 2)
        
        
        runModel()
    }
    
    func runModel() {
        
        let modelPath = Bundle.main.path(forResource: "fer13_v2", ofType: "tflite")
        
        // image preprocessing
        if image == nil {
            print("selfie not set")
        }
        let selfie: CGImage! = image?.cgImage
        if selfie == nil {
            print("nil")
        }
        let context = CGContext(
          data: nil,
          width: 48, height: 48,
          bitsPerComponent: 8, bytesPerRow: 48 * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        // preprocessing image
        context!.draw(selfie, in: CGRect(x: 0, y: 0, width: 48, height: 48))
        let imageData = context!.data
        
        var inputData = Data()
        
        for row in 0..<48
        {
            for col in 0..<48
            {
                let offset = 2 * (row * context!.width + col)
                // (Ignore offset 0, the unused alpha channel)
                let gray = imageData!.load(fromByteOffset: offset+1, as: UInt8.self)

                // Normalize channel values to [-1.0, 1.0].
                var normalizedGray = (Float32(gray) / 255.0)*2 - 1

                // Append normalized values to Data object in Grayscale
                let elementSize = MemoryLayout.size(ofValue: normalizedGray)
                var bytes = [UInt8](repeating: 0, count: elementSize)
                memcpy(&bytes, &normalizedGray, elementSize)
                inputData.append(&bytes, count: elementSize)
          }
        }
        
        // Selfie ML predictions
        do {
            let interpreter = try Interpreter(modelPath: modelPath!)
            try interpreter.allocateTensors()
            try interpreter.copy(inputData, toInputAt: 0)
            try interpreter.invoke()
            let outputTensor = try interpreter.output(at: 0)
            
            let selfie_result = outputTensor.data.toArray(type: Float32.self)
            print("Selfie: \(selfie_result)")
            Angry.setTitle("Angry😡: \(String(format: "%.2f", selfie_result[0]*100))%", for: .normal)
            Disgust.setTitle("Disgust🤢: \(String(format: "%.2f", selfie_result[1]*100))%", for: .normal)
            Fear.setTitle("Fear😱: \(String(format: "%.2f", selfie_result[2]*100))%", for: .normal)
            Happy.setTitle("Happy😍: \(String(format: "%.2f", selfie_result[3]*100))%", for: .normal)
            Sad.setTitle("Sad🥺: \(String(format: "%.2f", selfie_result[4]*100))%", for: .normal)
            Surprise.setTitle("Surprise😧: \(String(format: "%.2f", selfie_result[5]*100))%", for: .normal)
            Neutral.setTitle("Neutral😐: \(String(format: "%.2f", selfie_result[6]*100))%", for: .normal)
            //if (error != nil) {/* Error */}
        }
        catch {
            print(error)
        }
    }
    
    func resizeImage (image: UIImage, size: Int) -> UIImage? {
        
        var newsize : CGSize
        
        newsize = CGSize(width: size, height: size)
        
        
        let rect = CGRect(origin: .zero, size: newsize)
        
        UIGraphicsBeginImageContextWithOptions(newsize, false, 1.0)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage
    }

    @IBAction func colorSelected(_ sender: UIButton) {
        
        updateColorButton(tag: sender.tag)
        
        switch sender.tag {
        case 1:
            Emotion = "Angry😡"
            Emoji = "😡"
        case 2:
            Emotion = "Disgust🤢"
            Emoji = "🤢"
        case 3:
            Emotion = "Fear😱"
            Emoji = "😱"
        case 4:
            Emotion = "Happy😍"
            Emoji = "😍"
        case 5:
            Emotion = "Sad🥺"
            Emoji = "🥺"
        case 6:
            Emotion = "Surprise😧"
            Emoji = "😧"
        default:
            Emotion = "Neutral😐"
            Emoji = "😐"
        }
        
        resultLabel.text = "Proceed with " + Emotion
        resultView2.isUserInteractionEnabled = true
        resultView2.isHidden = false
        
    }
    
    func updateColorButton (tag: Int) {
        for i in stride(from: 0, to: 8, by: 1) {
            if let button = self.view.viewWithTag(i) as? UIButton {
                button.backgroundColor = UIColor.tertiarySystemFill
            }
        }
        if let button = self.view.viewWithTag(tag) as? UIButton {
            button.backgroundColor = UIColor.gray
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if (segue.identifier == "showMap") {
          let newVC = segue.destination as! MapViewController
          newVC.image = self.icon
          newVC.Emoji = self.Emoji
      }
    }
}

extension Data {

    init<T>(fromArray values: [T]) {
        self = values.withUnsafeBytes { Data($0) }
    }

    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = Array<T>(repeating: 0, count: self.count/MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { copyBytes(to: $0) }
        return array
    }
}

extension UIImage {
    var noir: UIImage? {
        let context = CIContext(options: nil)
        guard let currentFilter = CIFilter(name: "CIPhotoEffectNoir") else { return nil }
        currentFilter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        if let output = currentFilter.outputImage,
            let cgImage = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
