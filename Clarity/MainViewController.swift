//
//  MainViewController.swift
//  Clarity
//
//  Copyright © 2018 Clarifai. All rights reserved.
//

import UIKit
import AVFoundation
import Clarifai_Apple_SDK

class MainViewController: UIViewController, FrameExtractorDelegate, UITableViewDataSource, UITableViewDelegate {
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
    }

    func captured(image: UIImage) {
        // guard generalModelIsReady else { return } TODO: Uncomment when SDK properly loads general model

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
                self.predictionsTableView.reloadSections(sections as IndexSet, with: .fade)
                self.predictionsTableHeight?.constant = self.predictionsTableView.contentSize.height
                UIView.animate(withDuration: 0.4) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

    override func viewWillLayoutSubviews() {
        super.updateViewConstraints()
        self.predictionsTableHeight?.constant = self.predictionsTableView.contentSize.height
        UIView.animate(withDuration: 0.4) {
            self.view.layoutIfNeeded()
        }
    }

    func filterConcepts(concepts: [Concept]) -> [Concept] {
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
                generalModelIsReady = true //TODO: will change this when sdk bug fixed
            }
        }
    }

    // MARK: NotificationHandlers
    @objc func handleKeyboardWillHide(notification: Notification) {
        conceptTextField.alpha = 0
        //        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
        //        }
    }

    @objc func handleKeyboardWillShow(notification: Notification) {
        conceptTextField.isHidden = false 
        UIView.animate(withDuration: 0.4) {
            self.conceptTextField.alpha = 1
        }
//        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
//        }
    }

    @IBAction func addConcept(_ sender: AnyObject) {
        conceptTextField.becomeFirstResponder();
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
        return 70
    }
}
