//
//  CameraViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    lazy private var captureSession = AVCaptureSession()
    lazy private var fileOutput = AVCaptureMovieFileOutput()
    private var player: AVPlayer!
    
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Resize camera preview to fill the entire screen
        cameraView.videoPlayerLayer.videoGravity = .resizeAspectFill
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func handleTapGesture(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            playRecording()
        }
    }
    
    func playMovie(url: URL) { }
    
    func playRecording() {
        if let player = player {
            player.seek(to: CMTime.zero) // N/D, D = 600
            player.play()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestPermissionAndShowCamera()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }
    private func requestPermissionAndShowCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            requestVideoPermission()
        case .restricted:
            preconditionFailure("Video is disabled, please review device restrictions.")
        case .denied:
            preconditionFailure("Tell the user they can't use the app with out permssion.")
        case .authorized:
            showCamera()
        @unknown default:
            preconditionFailure("A new status code was added that we need to handle.")
        }
    }
    
    private func requestVideoPermission() {
        AVCaptureDevice.requestAccess(for: .video) { (Bool) in
            preconditionFailure("UI: Tell User to enable permissions for Video/Camera.")
        }
        DispatchQueue.main.async {
            self.showCamera()
        }
    }
    
    private func showCamera() {
        
        
    }
    
    func playMovie(url: URL) {
        player = AVPlayer(url: url)
        let playerView = MoviePlayerView()
        playerView.player = player
        var topRect = view.bounds
        topRect.size.height /= 4
        topRect.size.width /= 4
        topRect.origin.y = view.layoutMargins.top
        
        playerView.frame = topRect
        view.addSubview(playerView)
    }
    
    private func setupCamera() {
           let camera = bestCamera()
        let microphone = bestMicrophone()
           captureSession.beginConfiguration()
           guard let cameraInput = try? AVCaptureDeviceInput(device: camera) else {
               preconditionFailure("Can't create an input from the camera, but we should do something better than crashing!")
           }
        guard let microphoneInput = try? AVCaptureDeviceInput(device: microphone) else {
            preconditionFailure("Can't create an input from the microphone, but we should do something better than crashing!")
        }
           guard captureSession.canAddInput(cameraInput) else {
               preconditionFailure("This session can't handle this type of input: \(cameraInput)")
           }
           captureSession.addInput(cameraInput)
           if captureSession.canSetSessionPreset(.hd1920x1080) {
               captureSession.sessionPreset = .hd1920x1080
           }
        
        guard captureSession.canAddInput(microphoneInput) else {
            preconditionFailure("This session can't handle this type of input: \(microphoneInput)")
        }
        captureSession.addInput(microphoneInput)
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        }
           captureSession.commitConfiguration()
           cameraView.session = captureSession
       }
    
    private func bestCamera() -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            return device
        }
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }
        preconditionFailure("No cameras on device match the specs we need.")
    }
    
    private func bestMicrophone() -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(for: .audio) {
            return device
        }
        preconditionFailure("No microphones on device match the specs we need.")
    }
    
    @IBAction func recordButtonPressed(_ sender: Any) {
        if fileOutput.isRecording {
            fileOutput.stopRecording()
        } else {
            fileOutput.startRecording(to: newRecordingURL(), recordingDelegate: self)
        }
    }
    
    /// Creates a new file URL in the documents directory
    private func newRecordingURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        let name = formatter.string(from: Date())
        let fileURL = documentsDirectory.appendingPathComponent(name).appendingPathExtension("mov")
        return fileURL
    }
    
    func updateViews() {
        recordButton.isSelected = fileOutput.isRecording
    }
}


extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error saving video: \(error)")
        }
        print("Video URL: \(outputFileURL)")
        updateViews()
        playMovie(url: outputFileURL)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        
        updateViews()
    }
}
