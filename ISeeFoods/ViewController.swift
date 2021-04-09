//
//  ViewController.swift
//  ISeeFoods
//
//  Created by Isaac Cavalcante on 17/03/21.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    let imagePicker = UIImagePickerController()
    private var observablesElements = [ObservableElement]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imagePickedByUser = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            
            guard let ciimage = CIImage(image: imagePickedByUser) else {
                fatalError("Couldn't convert to CIImage")
            }
            
            detect(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage){
        
        guard let model = try? VNCoreMLModel(for: Inceptionv3(configuration: .init()).model) else {
            fatalError("Load CoreML model failed")
        }
        
        let request = VNCoreMLRequest(model: model) { [self] (request2, error) in
            guard let results = request2.results as? [VNClassificationObservation] else {
                fatalError("Model fail to process image")
            }
            self.observablesElements = []
            results.forEach { (element) in
                self.observablesElements.append(ObservableElement(identifier: element.identifier, confidence: element.confidence))
            }
            tableView.reloadData()
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            
        }
        print("finish")
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return observablesElements.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let confidence = String(format: "%.8f %", ((observablesElements[indexPath.row].confidence ?? 0.0) * 100))
        cell.textLabel?.text = "\(observablesElements[indexPath.row].identifier!): \(confidence)"
        
        return cell
    }


}

