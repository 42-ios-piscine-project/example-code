//
//  MapViewController.swift
//  PPangDelivery
//
//  Created by 빵딜 on 2022/10/02.
//

import UIKit
import SnapKit
import NMapsMap
import CoreLocation


class MapViewController: UIViewController, CLLocationManagerDelegate, NMFMapViewCameraDelegate, UISearchResultsUpdating {
    
    
    //	lazy var mainVC = MainViewController()
    
    var naverMapView = NMFMapView()
    
    var centerPin = NMFMarker()
    
    var address = ""
    
    let searchController = UISearchController()
    
    lazy var myLocationButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("My Location", for: .normal)
        btn.backgroundColor = UIColor.red
        return btn
    }()
    
    lazy var orderTogetherButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("같이 먹어요 []", for: .normal)
        btn.backgroundColor = UIColor.blue
        return btn
    }()
    
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
        manager.delegate = self
        return manager
    }()
    
    var coordinate = NMGLatLng(lat: 37.488205, lng: 127.064789)
    // MARK: - 개포 새롬관 NMGLatLng(lat: 37.488205, lng: 127.064789)
    var currentCameraPosition = NMGLatLng(lat: 37.488205, lng: 127.064789)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        layout()
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        markcenterPin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.locationManager.startUpdatingLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.locationManager.stopUpdatingLocation()
    }
    
    func markcenterPin() {
        centerPin.position = NMGLatLng(
            lat: coordinate.lat,
            lng: coordinate.lng
        )
        centerPin.mapView = naverMapView
    }
    
    func setup() {
        mapInit()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else {
            return
        }
        address = text
    }
    
    func layout() {
        naverMapView.addSubview(myLocationButton)
        myLocationButton.addTarget(self, action: #selector(didTappedCurrentLocation(_:)), for: .touchDown)
        myLocationButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
        }
        
        naverMapView.addSubview(orderTogetherButton)
        orderTogetherButton.addTarget(self, action: #selector(didTappedOrderTogether(_:)), for: .touchDown)
        orderTogetherButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.right.equalTo(view.safeAreaLayoutGuide)
        }
        naverMapView.addCameraDelegate(delegate: self)
        
    }
    
    func mapView(_ mapView: NMFMapView, cameraDidChangeByReason reason: Int, animated: Bool) {
        print("카메라 이동끝")
        let cameraPosition = mapView.cameraPosition
        currentCameraPosition.lat = cameraPosition.target.lat
        currentCameraPosition.lng = cameraPosition.target.lng
        print(currentCameraPosition.lat, currentCameraPosition.lng)
        
        centerPin.position = NMGLatLng(lat: cameraPosition.target.lat, lng: cameraPosition.target.lng)
    }
    
    func mapInit() {
        naverMapView = NMFMapView(frame: view.frame)
        naverMapView.positionMode = .normal
        naverMapView.locationOverlay.anchor = CGPoint(x: 0.5, y: 0.5)
        naverMapView.locationOverlay.location = coordinate
        focusPurposeLocation(coordinate, 16)
        view.addSubview(naverMapView)
    }
    
    func focusPurposeLocation(_ coordinate: NMGLatLng, _ zoomSize: Double) {
        let focus = NMFCameraUpdate(scrollTo: coordinate, zoomTo: zoomSize)
        focus.animation = .easeIn
        focus.pivot = CGPoint(x: 0.5, y: 0.5)
        naverMapView.moveCamera(focus)
    }
    
    func getLocationUsagePermission() {
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("GPS 권한 설정됨")
        case .restricted, .notDetermined:
            print("GPS 권한 설정되지 않음")
            DispatchQueue.main.async {
                print("restrict not deter")
                self.getLocationUsagePermission()
            }
        case .denied:
            print("GPS 권한 요청 거부됨")
            DispatchQueue.main.async {
                print("permission")
                self.getLocationUsagePermission()
            }
        default:
            print("GPS: Default")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("위치 업데이트!")
            print("위도 : \(location.coordinate.latitude)")
            print("경도 : \(location.coordinate.longitude)")
            coordinate.lat = location.coordinate.latitude
            coordinate.lng = location.coordinate.longitude
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error") // 위치 가져오기 실패
    }
    
    @objc
    private func didTappedCurrentLocation(_ sender: UIButton) {
        focusPurposeLocation(coordinate, 16.5)
        print(address)
        CLGeocoder().geocodeAddressString(address, completionHandler: { placemarks, error in
            if (error != nil) {
                print(error.debugDescription)
                return
            }
            
            if let placemark = placemarks?[0]  {
                let lat = String(format: "%.04f", (placemark.location?.coordinate.longitude ?? 0.0)!)
                let lon = String(format: "%.04f", (placemark.location?.coordinate.latitude ?? 0.0)!)
                let name = placemark.name!
                let country = placemark.country!
                let region = placemark.administrativeArea!
                print("\(lat),\(lon)\n\(name),\(region) \(country)")
            }
        })
    }
    
    @objc
    private func didTappedOrderTogether(_ sender: UIButton) {
        print("같이 먹어용 버튼 클릭됨")
        let orderTogeterMarker = NMFMarker()
        orderTogeterMarker.iconTintColor = .red
        orderTogeterMarker.position = NMGLatLng(lat: currentCameraPosition.lat, lng: currentCameraPosition.lng)
        orderTogeterMarker.mapView = naverMapView
        
    }
    //    func initMapDB() {
    //        DispatchQueue.global(qos: .default).async {
    //            // 백그라운드 스레드
    //            var markers = [NMFMarker]()
    //            for index in 1...1000 {
    //                let marker = NMFMarker(position: NMGLatLng(lat: Double.random(in: 37.4...37.9),
    //                                                           lng: Double.random(in: 126.8...127.1))
    //                )
    //                marker.captionText = String(index)
    //                markers.append(marker)
    //            }
    //
    //            DispatchQueue.main.async { [weak self] in
    //                // 메인 스레드
    //                for marker in markers {
    //                    marker.mapView = self?.naverMapView
    //                }
    //            }
    //        }
    //    }
}
