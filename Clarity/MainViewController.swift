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

    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet private weak var predictionsTableView: UITableView!
    @IBOutlet private weak var showAllConceptsButton: UIButton!
    @IBOutlet private weak var predictionsTableHeight: NSLayoutConstraint!
    
    private var frameExtractor: FrameExtractor!
    private var generalModel: Model!
    private var generalModelIsReady = false
    private var isProcessingImage = false
    private var generalPredictions: [Concept] = []
    private var showAllConcepts = false
    private var cellHeight: CGFloat = 55.0

    // Adjust the rate at which concepts are refreshed.
    private var refreshRate = 0.4

    // Filter out any unneeded concepts.
    private var blacklistedConcepts = ["no person","indoors"]

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleModelDidBecomeAvailable(notification:)), name: NSNotification.Name.CAIModelDidBecomeAvailable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleImageProcessingDidComplete(notification:)), name: ImageProcessingDidFinish, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.viewDidRotate(notification:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        frameExtractor.startExtracting()

        // Set up video preview view
        previewView.session = frameExtractor.captureSession
        alignVideoPreviewOrientation()

        // Load Clarifai's general model to use for predicting tags
        generalModel = Clarifai.sharedInstance().generalModel

        predictionsTableView.dataSource = self          
        predictionsTableView.delegate = self
        let cellNib = UINib(nibName: "PredictionTableViewCell", bundle: nil)
        predictionsTableView.register(cellNib, forCellReuseIdentifier: "PredictionCell")

        showAllConceptsButton.layer.cornerRadius = 2.0
        showAllConceptsButton.alpha = 0.0
        self.showAllConceptsButton.isEnabled = false
    }

    @objc func viewDidRotate(notification: Notification) {
        guard generalModelIsReady else { return }

        // Ensure the video preview feed also rotates with device
        DispatchQueue.main.async {
            self.alignVideoPreviewOrientation()
        }

        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        if UIInterfaceOrientationIsLandscape(statusBarOrientation) {
            UIView.animate(withDuration: 0.1) {
                self.showAllConceptsButton.alpha = 0.0
                self.showAllConceptsButton.isEnabled = false
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                self.showAllConceptsButton.alpha = 1.0
                self.showAllConceptsButton.isEnabled = true
            }
        }
    }

    func alignVideoPreviewOrientation() {
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
        if statusBarOrientation != .unknown {
            if let videoOrientation = AVCaptureVideoOrientation(rawValue: statusBarOrientation.rawValue) {
                initialVideoOrientation = videoOrientation
            }
        }
        previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
        previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill;
    }

    @IBAction func toggleShowConcepts(_ sender: UIButton) {
        showAllConcepts = !showAllConcepts

        if showAllConcepts {
            showAllConceptsButton.setTitle("Show Fewer Concepts", for: .normal)
        } else {
            showAllConceptsButton.setTitle("Show All Concepts", for: .normal)
        }

        self.reloadAllPredictions()
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
        predictWithGeneralModel(input: input)
    }

    // MARK: Predicting with Clarifai models

    /**
     Predict using Clarifai's General model.

     - parameters:
         - input: Input containing current video frame to predict on.
     */
    func predictWithGeneralModel(input: Input) {
        generalModel.predict([input]) { (outputs, error) in
            if error != nil {
                print(error.debugDescription)
                return
            }

            if let output:Output = outputs?[0] {
                // Update table view data with new predicted concepts from Output
                guard let concepts = output.dataAsset.concepts else { return }
                let filteredConcepts = Array(self.filterConcepts(concepts:concepts))
                self.generalPredictions = filteredConcepts
                self.reloadAllPredictions()
                DispatchQueue.main.asyncAfter(deadline: .now() + self.refreshRate, execute: {
                    NotificationCenter.default.post(name: ImageProcessingDidFinish, object: self)
                })
            }
        }
    }

    func reloadAllPredictions() {
        let range = NSMakeRange(0, 1)
        let sections = NSIndexSet(indexesIn: range)
        self.predictionsTableView.reloadSections(sections as IndexSet, with: .none)
        self.predictionsTableHeight?.constant = self.predictionsTableView.contentSize.height
        UIView.animate(withDuration: refreshRate) {
            self.view.layoutIfNeeded()
        }
    }

    func filterConcepts(concepts: [Concept]) -> [Concept] {
        // Remove any unwanted concepts
        let filteredConcepts = concepts.filter { (concept) -> Bool in
            if blacklistedConcepts.contains(concept.name) {
                return false
            } else {
                return true
            }
        }

        return filteredConcepts
    }

    // MARK: NotificationHandlers
    @objc func handleImageProcessingDidComplete(notification: Notification) {
        isProcessingImage = false;
    }

    @objc func handleModelDidBecomeAvailable(notification: Notification) {
        if let userInfo = notification.userInfo {
            let modelId = userInfo[CAIModelUniqueIdentifierKey] as? String
            if modelId == "aaa03c23b3724a16a56b629203edc62c" {
                generalModelIsReady = true
                UIView.animate(withDuration: 0.6) {
                    self.showAllConceptsButton.alpha = 1.0
                    self.showAllConceptsButton.isEnabled = true
                }
            }
        }
    }

    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            var minConcepts = 5
            if showAllConcepts {
                minConcepts = Int(floor((self.view.frame.height - 10) / cellHeight) - 1.0)
            }
            return min(minConcepts, generalPredictions.count)
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "PredictionCell") as! PredictionTableViewCell
                let prediction = generalPredictions[indexPath.row]
                cell.nameLabel.text = prediction.name
                cell.setScoreValue(score: prediction.score)
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "PredictionCell") as! PredictionTableViewCell
                return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
}
