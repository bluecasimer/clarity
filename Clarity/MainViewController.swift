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
    var generalPredictions: [Concept] = []
    var customPredictions: [Concept] = []
    var lastCapturedFrame: UIImage?
    var customModels: [Model] = []

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
        // won't load general model without calling predict...
        let image = UIImage()
        let dataAsset = DataAsset(image: Image(image: image))
        let input =  Input(dataAsset: dataAsset)
        generalModel.predict([input]) { (output, error) in
            print("WORKES?!!")
        }

        loadSavedModels()

        predictionsTableView.dataSource = self          
        predictionsTableView.delegate = self
        let cellNib = UINib(nibName: "PredictionTableViewCell", bundle: nil)
        predictionsTableView.register(cellNib, forCellReuseIdentifier: "PredictionCell")
        let customCellNib = UINib(nibName: "CustomPredictionTableViewCell", bundle: nil)
        predictionsTableView.register(customCellNib, forCellReuseIdentifier: "CustomPredictionCell")

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
        lastCapturedFrame = image

        if isProcessingImage {
            return
        }
        isProcessingImage = true;

        let dataAsset = DataAsset.init(image: Image.init(image: image))
        let input = Input.init(dataAsset: dataAsset)
        predictWithGeneralModel(input: input)
        predictWithCustomModels(input: input)
    }

    // MARK: Predicting with Clarifai models
    func predictWithGeneralModel(input: Input) {
        // Add predictions from Clarifai's General model
        generalModel.predict([input]) { (outputs, error) in
            if error != nil {
                print(error.debugDescription)
                return
            }

            if let output:Output = outputs?[0] {
                // Update table view data with new predicted concepts
                guard let concepts = output.dataAsset.concepts else { return }
                let filteredConcepts = Array(self.filterConcepts(concepts:concepts).prefix(5))
                self.generalPredictions = filteredConcepts
                self.reloadAllPredictions()
            }
        }
    }

    func predictWithCustomModels(input: Input) {
        if customModels.isEmpty {
            self.reloadAllPredictions()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                NotificationCenter.default.post(name: ImageProcessingDidFinish, object: self)
            }
        }

        var remainingPredictions = 0

        // Optimize by calculating embeddings first before predicting.
        input.dataAsset.embeddings { (embeddings) in
            // No need to store the photo after embedding saved.
            input.dataAsset.image.image = nil

            for model in self.customModels {
                remainingPredictions += 1

                model.predict([input]) { (outputs, error) in
                    if error != nil {
                        print(error.debugDescription)
                        return
                    }

                    if let output:Output = outputs?[0] {
                        // Update table view data with new predicted concepts.
                        guard let concepts = output.dataAsset.concepts else { return }
                        self.addCustomPredictions(predictions: concepts)
                    }

                    // After all predictions have completed, image processing is complete.
                    remainingPredictions -= 1
                    if remainingPredictions == 0 {
                        self.reloadAllPredictions()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: ImageProcessingDidFinish, object: self)
                        }
                    }
                }
            }
        }
    }

    func addCustomPredictions(predictions: [Concept]) {
        DispatchQueue.main.async {
            // Only display custom predictions if above 0.7 accuracy score.
            let customThreshold: Float = 0.7
            for prediction in predictions {
                if prediction.score < customThreshold {
                    // Score is less than threshold, so remove from table data if necessary.
                    self.customPredictions = self.customPredictions.filter({ (concept) -> Bool in
                        if concept.id == prediction.id {
                            return false
                        } else {
                            return true
                        }
                    })
                } else {
                    // Replace with new accuracy score, or insert into table view data.
                    if let i = self.customPredictions.index(where: { (concept) -> Bool in
                        return concept.id == prediction.id
                    }) {
                        self.customPredictions[i] = prediction
                    } else {
                        self.customPredictions.append(prediction)
                        self.customPredictions.sort(by: { (concept1, concept2) -> Bool in
                            return concept1.score >= concept2.score
                        })
                    }
                }
            }
        }
    }

    func reloadAllPredictions() {
        let range = NSMakeRange(0, 2)
        let sections = NSIndexSet(indexesIn: range)
        self.predictionsTableView.reloadSections(sections as IndexSet, with: .none)
        self.predictionsTableHeight?.constant = self.predictionsTableView.contentSize.height
        UIView.animate(withDuration: 0.4) {
            self.view.layoutIfNeeded()
        }
    }

    func loadSavedModels() {
        Clarifai.sharedInstance().load(entityType: EntityType.model, range: NSMakeRange(0,Int.max)) { (models, error) in
            self.customModels = models as! [Model]
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
        guard lastCapturedFrame != nil else { return }

        conceptTextField.becomeFirstResponder();

        // pause video preview
        frameExtractor.stopFrameExtraction()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard lastCapturedFrame != nil else { return true }
        conceptTextField.resignFirstResponder()

        if let text = textField.text {
            let newConcept = Concept(id: text, name: text, score: 1.0)
            let dataAsset = DataAsset(image: Image(image: lastCapturedFrame))
            dataAsset.add(concepts: [newConcept])
            let input = Input(dataAsset: dataAsset)
            trainNewModelForConcept(concept: newConcept, withInputs: [input])
        }
        return true
    }

    func trainNewModelForConcept(concept: Concept, withInputs inputs: [Input]) {
        let model = Model(id: concept.name, name: concept.name)
        model.train(concepts: [concept], inputs: inputs) { (error) in
            self.customModels.append(model)
            Clarifai.sharedInstance().save(entities: [model])
        }
    }

    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return min(3,customPredictions.count)
        case 1:
            return min(5-min(3,customPredictions.count),generalPredictions.count)
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CustomPredictionCell") as! CustomPredictionTableViewCell
            let prediction = customPredictions[indexPath.row]
            cell.nameLabel.text = prediction.name
            cell.setScoreValue(score: prediction.score)
            return cell
        case 1:
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
        return 55
    }
}
