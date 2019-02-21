//
//  FoodMarketServiceImp.swift
//  Service
//
//  Created by 장공의 on 31/01/2019.
//  Copyright © 2019 team-b1. All rights reserved.
//

import UIKit
import Common
import CoreLocation
import ServiceInterface

internal class FoodMarketServiceImp: FoodMarketService {
    
    private let network: Network
    
    init(network: Network) {
        self.network = network
    }
    
    private let maximunImage: Int = 4
    
    func requestFoodMarketMore(completionHandler: @escaping (DataResponse<BusinessFoodMarket>) -> Void) {
        let requestURL = URL(string: "www.uberEats.com/foodMarket")!
        network.request(with: requestURL) { ( data, response, requestError) in
            
            if let requestError = requestError {
                completionHandler(DataResponse.failed(requestError))
                return
            }
            
            if response?.httpStatusCode == .ok {
                guard let data = data else {
                    //completionHandler(DataResponse.failed(NetworkError.noDataReceived()))
                    return
                }
                do {
                    let foodMarket: FoodMarket = try JSONDecoder().decode(FoodMarket.self, from: data)
                    
                    let banners: [AdvertisingBoard] = foodMarket.advertisingBoard
                    
                    let stores = foodMarket.stores
                    let nearestRest: [Store] = caculateDistance(stores: stores)
                    let recommendFood: [Food] = foodMarket.recommandFoods
                    let bannerImageURL: [String] = getBannerImageURL(banners: banners)
                    let expectTimeRest: [Store] = caculateExpectTime(stores: stores)
                    let newRests: [Store] = foodMarket.newStores
                    
                    let caculatedFoodMarket = BusinessFoodMarket(neareRest: nearestRest,
                                                                 recommendFood: recommendFood,
                                                                 bannerImages: bannerImageURL,
                                                                 expectTimeRest: expectTimeRest,
                                                                 newRests: newRests,
                                                                 moreRests: stores
                    )
                    
                    DispatchQueue.main.async {
                        completionHandler(DataResponse.success(caculatedFoodMarket))
                    }
                    //FIXME: - Service에서 비즈니스 로직 담당 -> nearestRest 반환하는 로직을 여기서 짜자.
                } catch {
                    fatalError()
                }
            } else {
                fatalError()
            }
        }
    }
    
    func requestFoodMarketMore(dispatchQueue: DispatchQueue?, completionHandler: @escaping (DataResponse<BusinessFoodMarket>) -> Void) {
        dispatchQueue?.async {
            self.requestFoodMarketMore(completionHandler: completionHandler)
        }
    }
    
    func requestFoodMarket(completionHandler: @escaping (DataResponse<BusinessFoodMarket>) -> Void) {
        let requestURL = URL(string: "www.uberEats.com/foodMarket")!
        network.request(with: requestURL) { ( data, response, requestError) in
            
            if let requestError = requestError {
                completionHandler(DataResponse.failed(requestError))
                return
            }
            
            if response?.httpStatusCode == .ok {
                guard let data = data else {
                    //completionHandler(DataResponse.failed(NetworkError.noDataReceived()))
                    return
                }
                do {
                    let foodMarket: FoodMarket = try JSONDecoder().decode(FoodMarket.self, from: data)
                    
                    let banners: [AdvertisingBoard] = foodMarket.advertisingBoard
                    
                    let moreRestArray = foodMarket.stores
                    let nearestRest: [Store] = caculateDistance(stores: moreRestArray)
                    let recommendFood: [Food] = foodMarket.recommandFoods
                    let bannerImageURL: [String] = getBannerImageURL(banners: banners)
                    let expectTimeRest: [Store] = caculateExpectTime(stores: moreRestArray)
                    let newRests: [Store] = foodMarket.newStores
                    
                    let nearestRestSlice = nearestRest.prefix(maximunImage)
                    let nearestRestArray = Array(nearestRestSlice)
                    
                    let recommendFoodSlice = recommendFood.prefix(maximunImage)
                    let recommendFoodArray = Array(recommendFoodSlice)
                    
                    let bannerImageSlice = bannerImageURL.prefix(maximunImage)
                    let bannerImageArry = Array(bannerImageSlice)
                    
                    let expectRestSlice = expectTimeRest.prefix(maximunImage)
                    let expectRestArray = Array(expectRestSlice)
                    
                    let newRestSlice = newRests.prefix(maximunImage)
                    let newRestArray = Array(newRestSlice)
                    
                    storeImages(neareRest: nearestRestArray,
                                recommendFood: recommendFoodArray,
                                bannerImages: bannerImageArry,
                                expectTimeRest: expectRestArray,
                                newRests: newRestArray,
                                moreRests: moreRestArray
                    )
                
                    let caculatedFoodMarket = BusinessFoodMarket(neareRest: nearestRestArray,
                                                                 recommendFood: recommendFoodArray,
                                                                 bannerImages: bannerImageArry,
                                                                 expectTimeRest: expectRestArray,
                                                                 newRests: newRestArray,
                                                                 moreRests: moreRestArray
                    )
                    
                    DispatchQueue.main.async {
                        completionHandler(DataResponse.success(caculatedFoodMarket))
                    }
                } catch {
                    fatalError()
                }
            } else {
                fatalError()
            }
        }
    }
    
    func requestFoodMarket(dispatchQueue: DispatchQueue?, completionHandler: @escaping (DataResponse<BusinessFoodMarket>) -> Void) {
        dispatchQueue?.async {
            self.requestFoodMarket(completionHandler: completionHandler)
        }
    }
    
    private func caculateExpectTime(stores: [Store]) -> [Store] {
        
        var expectTimeStore: [Store] = []
        var expectTimes: [String] = []
        
        for store in stores {
            expectTimes =  store.deliveryTime.components(separatedBy: "-")
            
            var expectTimeInt: [Double?] = []
            expectTimeInt.append(Double(expectTimes[0]))
            expectTimeInt.append(Double(expectTimes[1]))
            
            if let fastestTime = expectTimeInt[0] {
                if fastestTime <= 30 {
                    expectTimeStore.append(store)
                }
            }
        }
        
        return expectTimeStore
    }
    
    private func caculateDistance(stores: [Store]) -> [Store] {
        var nearestRest: [Store] = []
        for store in stores {
            let currentLatitude: Double = 37.498146
            let currentLongtitude: Double = 127.027642
            
            let storeCoordinate = CLLocation(latitude: store.location.latitude, longitude: store.location.longtitude)
            let currentCoordinate = CLLocation(latitude: currentLatitude, longitude: currentLongtitude)
            
            let distance = storeCoordinate.distance(from: currentCoordinate) / 1000
            
            if distance < 2.0 {
                nearestRest.append(store)
            }
        }
        
        return nearestRest
    }
    
    private func getBannerImageURL(banners: [AdvertisingBoard]) -> [String] {
        var bannerImagesURL: [String] = []
        for banner in banners {
            bannerImagesURL.append(banner.bannerImage)
        }
        return bannerImagesURL
    }
    
    private func storeImages(neareRest: [Store], recommendFood: [Food], bannerImages: [String], expectTimeRest: [Store], newRests: [Store], moreRests: [Store] ) {
        
        for store in moreRests {
            guard let imageURL = URL(string: store.mainImage) else {
                return
            }
            ImageNetworkManager.shared.getImageByCache(imageURL: imageURL, complection: { (_, _) in
        
            })
        }
        
        for store in neareRest {
            guard let imageURL = URL(string: store.mainImage) else {
                return
            }
            ImageNetworkManager.shared.getImageByCache(imageURL: imageURL, complection: { (_, _) in
                
            })
        }
        
        for store in newRests {
            guard let imageURL = URL(string: store.mainImage) else {
                return
            }
            ImageNetworkManager.shared.getImageByCache(imageURL: imageURL, complection: { (_, _) in
                
            })
        }
        
        for store in expectTimeRest {
            guard let imageURL = URL(string: store.mainImage) else {
                return
            }
            ImageNetworkManager.shared.getImageByCache(imageURL: imageURL, complection: { (_, _) in
                
            })
        }
        
        for store in bannerImages {
            guard let imageURL = URL(string: store) else {
                return
            }
            ImageNetworkManager.shared.getImageByCache(imageURL: imageURL, complection: { (_, _) in
                
            })
        }
        
        for store in recommendFood {
            guard let imageURL = URL(string: store.foodImageURL) else {
                return
            }
            ImageNetworkManager.shared.getImageByCache(imageURL: imageURL, complection: { (_, _) in
                
            })
        }
    }
    
    /*
    private func caculateNewRest(stores: [Store]) -> [Store] {
        var newRests: [Store] = []
        for store in stores {
            if store.isNewStore {
                newRests.append(store)
            }
        }
        
        return newRests
    }
     */
}
