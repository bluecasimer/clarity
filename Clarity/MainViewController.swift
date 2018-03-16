//
//  MainViewController.swift
//  Clarity
//
//  Copyright © 2018 Clarifai. All rights reserved.
//

import UIKit
import AVFoundation
import Clarifai_Apple_SDK

class MainViewController: UIViewController, FrameExtractorDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var conceptTextField: UITextField!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet weak var predictionsTableView: UITableView!
    @IBOutlet weak var showAllConceptsButton: UIButton!
    @IBOutlet weak var predictionsTableHeight: NSLayoutConstraint!
    
    var frameExtractor: FrameExtractor!
    var generalModel: Model!
    var generalModelIsReady = false
    var isProcessingImage = false
    var isFreezeFrame = false
    var predictions: [Concept] = []

    override func viewWillAppear(_ animated: Bool) {
        conceptTextField.isHidden = true
        conceptTextField.alpha = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleModelDidBecomeAvailable(notification:)), name: NSNotification.Name.CAIModelDidBecomeAvailable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleImageProcessingDidComplete(notification:)), name: ImageProcessingDidFinish, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.viewDidRotate(notification:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

        // Begin extracting video frames to predict on
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self;

        // Set up video preview view
        previewView.session = frameExtractor.captureSession
        DispatchQueue.main.async {
            let statusBarOrientation = UIApplication.shared.statusBarOrientation
            var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
            if statusBarOrientation != .unknown {
                if let videoOrientation = AVCaptureVideoOrientation(rawValue: statusBarOrientation.rawValue) {
                    initialVideoOrientation = videoOrientation
                }
            }
            self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
            self.previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill;
        }

        generalModel = Clarifai.sharedInstance().generalModel

        predictionsTableView.dataSource = self          
        predictionsTableView.delegate = self

        let cellNib = UINib(nibName: "PredictionTableViewCell", bundle: nil)
        predictionsTableView.register(cellNib, forCellReuseIdentifier: "PredictionCell")

        showAllConceptsButton.layer.cornerRadius = 2.0

        conceptTextField.delegate = self
    }

    @objc func viewDidRotate(notification: Notification) {
        // Ensure the video preview feed also rotates with device
        DispatchQueue.main.async {
            let statusBarOrientation = UIApplication.shared.statusBarOrientation
            var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
            if statusBarOrientation != .unknown {
                if let videoOrientation = AVCaptureVideoOrientation(rawValue: statusBarOrientation.rawValue) {
                    initialVideoOrientation = videoOrientation
                }
            }
            self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
            self.previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill;
        }
    }

    // MARK: FrameExtractorDelegate Methods
    func capturedVideoFrame(image: UIImage) {
        guard generalModelIsReady else { return }

        if isProcessingImage {
            return
        }
        isProcessingImage = true;

        let dataAsset = DataAsset.init(image: Image.init(image: image))
        let input = Input.init(dataAsset: dataAsset)

        generalModel.predict([input]) { (outputs, error) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                NotificationCenter.default.post(name: ImageProcessingDidFinish, object: self)
            }

            if error != nil {
                print(error.debugDescription)
                return
            }

            if let output:Output = outputs?[0] {
                // update table view with new predicted concepts
                guard let concepts = output.dataAsset.concepts else { return }
                self.predictions = Array(self.filterConcepts(concepts:concepts).prefix(5))
                let range = NSMakeRange(0, self.predictionsTableView.numberOfSections)
                let sections = NSIndexSet(indexesIn: range)
                self.predictionsTableView.reloadSections(sections as IndexSet, with: .none)
                self.predictionsTableHeight?.constant = self.predictionsTableView.contentSize.height
                UIView.animate(withDuration: 0.4) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

    func capturedImage(image: UIImage) {
        // train model with new image and concept.
        print("welwle")
    }

    override func viewWillLayoutSubviews() {
        super.updateViewConstraints()
        self.predictionsTableHeight?.constant = self.predictionsTableView.contentSize.height
        UIView.animate(withDuration: 0.4) {
            self.view.layoutIfNeeded()
        }
    }

    func filterConcepts(concepts: [Concept]) -> [Concept] {
        // Remove any unwanted concepts
        let filteredConcepts = concepts.filter { (concept) -> Bool in
            if concept.name == "no person" {
                return false
            } else {
                return true
            }
        }

        return filteredConcepts
    }

    @objc func handleImageProcessingDidComplete(notification: Notification) {
        isProcessingImage = false;
    }

    @objc func handleModelDidBecomeAvailable(notification: Notification) {
        if let userInfo = notification.userInfo {
            let modelId = userInfo[CAIModelUniqueIdentifierKey] as? String
            if modelId == "aaa03c23b3724a16a56b629203edc62c" {
                generalModelIsReady = true
            }
        }
    }

    // MARK: NotificationHandlers
    @objc func handleKeyboardWillHide(notification: Notification) {
        conceptTextField.alpha = 0
        frameExtractor.startFrameExtraction()

    }

    @objc func handleKeyboardWillShow(notification: Notification) {
        conceptTextField.isHidden = false 
        UIView.animate(withDuration: 0.4) {
            self.conceptTextField.alpha = 1
        }
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            conceptTextField.frame = CGRect(x: conceptTextField.frame.origin.x, y: keyboardSize.height, width: conceptTextField.frame.width, height: conceptTextField.frame.height)
        }
    }

    @IBAction func addConcept(_ sender: AnyObject) {
        conceptTextField.becomeFirstResponder();

        // pause video feed and grab current frame (or better yet 3-5 frames)
        frameExtractor.beginCaptureImage()
        frameExtractor.stopFrameExtraction()
    }

    func trainNewConcept(concept: Concept) {
        // get current frame as uiimage, convety to
    }

    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return predictions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PredictionCell") as! PredictionTableViewCell
        cell.nameLabel.text = predictions[indexPath.row].name
        cell.setScoreValue(score: predictions[indexPath.row].score)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        conceptTextField.resignFirstResponder()

        if let text = textField.text {
            let newConcept = Concept(id: text, name: text, score: 1.0)
            trainNewConcept(concept: newConcept)
        }
        return true
    }
}
