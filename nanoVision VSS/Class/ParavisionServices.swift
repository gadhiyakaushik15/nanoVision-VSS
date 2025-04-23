//
//  ParavisionServices.swift
//  Paravision
//
//  Created by Kaushik Gadhiya on 05/01/24.
//

import Foundation
import ParavisionFR
import ParavisionFL
import UIKit
import AVFoundation


final class ParavisionServices {
    
    static var shared = ParavisionServices()
    private var livenessEstimator: PNLivenessEstimator!
    private var embeddingEstimator: PNEmbeddingEstimator?
    
    func initEstimator(completion: @escaping () -> (Void))  {
        DispatchQueue(label: "paravisionservices").async {
            self.livenessEstimator = PNLivenessEstimator()
            guard let embeddings = PNEmbeddingEstimator() else {
                return
            }
            self.embeddingEstimator = embeddings
            completion()
        }
    }
    
    func validness(image: UIImage) -> PNLivenessValidness? {
        do {
            if let liveness = livenessEstimator {
                let settings = PNLivenessValidnessSettings(minFaceQuality: 0.5, minFaceAcceptability: 0.15, minFaceFrontality: 85, maxFaceMaskProb: 0.5, imageIlluminationControl: 20, minFaceHeightPct: 0.25, imageBoundaryWidthPct: 0.8, imageBoundaryHeightPct: 0.8, minSharpness: 0.25)
                if let validnessData = try liveness.checkValidness(image: image, settings: settings).first {
                    return validnessData
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } catch {
            debugPrint(error)
            return nil
        }
    }
    
    func liveness(image: UIImage) -> PNLiveness? {
        do {
            if let liveness = livenessEstimator {
                if let livenessData = try liveness.getLiveness(image: image).first {
                    return livenessData
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } catch {
            debugPrint(error)
            return nil
        }
    }
    
    func identify(image: UIImage, completion: @escaping ([Peoples]?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var matchedPeople: [Peoples] = []

            do {
                guard let embeddings = self.embeddingEstimator else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                let embeddingsArray = try embeddings.getEmbeddings(image: image)
                guard let mostProminent = embeddingsArray.first else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                let peoples = OfflinePeoples.shared.peoples
                let lock = NSLock() // protect concurrent array writes

                DispatchQueue.concurrentPerform(iterations: peoples.count) { index in
                    let people = peoples[index]
                    if let embeddingsData = people.embeddedimage {
                        let identity = PNEmbeddings(vector: embeddingsData)
                        let matchScore = identity.getMatchScore(mostProminent)
                        if matchScore >= Constants.MatchScoreThreshold {
                            lock.lock()
                            people.matchScore = matchScore
                            matchedPeople.append(people)
                            lock.unlock()
                        }
                    }
                }

                DispatchQueue.main.async {
                    completion(matchedPeople)
                }

            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    func identifyWithBreak(image: UIImage, completion: @escaping ([Peoples]?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var matchedPeople: [Peoples] = []
            let group = DispatchGroup()
            let lock = NSLock()
            var stop = false

            do {
                guard let embeddings = self.embeddingEstimator else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                let embeddingsArray = try embeddings.getEmbeddings(image: image)
                guard let mostProminent = embeddingsArray.first else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                let peoples = OfflinePeoples.shared.peoples
                let queue = DispatchQueue(label: "com.matching.concurrent", attributes: .concurrent)

                for people in peoples {
                    if stop { break } // Early exit if match is already found

                    group.enter()
                    queue.async {
                        defer { group.leave() }

                        if let embeddingsData = people.embeddedimage {
                            let identity = PNEmbeddings(vector: embeddingsData)
                            let matchScore = identity.getMatchScore(mostProminent)

                            if matchScore >= Constants.MatchScoreThreshold {
                                lock.lock()
                                people.matchScore = matchScore
                                matchedPeople.append(people)
                                stop = true
                                lock.unlock()
                            }
                        }
                    }
                }

                group.wait() // Wait for all tasks to complete or get stopped

                DispatchQueue.main.async {
                    completion(matchedPeople)
                }

            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    func identify(image: UIImage) -> [Peoples]? {
        do {
            if let embeddings = self.embeddingEstimator {
                let embeddingsArray = try embeddings.getEmbeddings(image: image)
                if let mostProminent = embeddingsArray.first {
                    var matchedPeople: [Peoples] = []
                    let peoples = OfflinePeoples.shared.peoples
                    for people in  peoples {
                        if let embeddingsData = people.embeddedimage {
                            let identity = PNEmbeddings(vector: embeddingsData)
                            let matchScore = identity.getMatchScore(mostProminent)
                            if matchScore >= Constants.MatchScoreThreshold {
                                people.matchScore = matchScore
                                matchedPeople.append(people)
                            }
                        }
                    }
                    return matchedPeople
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    func createEmbeddings(image: UIImage) -> (String?, [Peoples]?) {
        do {
            if let embeddings = self.embeddingEstimator {
                let embeddingsArray = try embeddings.getEmbeddings(image: image)
                if let mostProminent = embeddingsArray.first {
                    let embeddingsStringArray = mostProminent.vector.compactMap {"\($0)"}
                    let embeddingsString = embeddingsStringArray.joined(separator: ",")
                    
                    var matchedPeople: [Peoples] = []
                    let peoples = OfflinePeoples.shared.peoples
                    for people in  peoples {
                        if let embeddingsData = people.embeddedimage {
                            let identity = PNEmbeddings(vector: embeddingsData)
                            let matchScore = identity.getMatchScore(mostProminent)
                            if matchScore >= Constants.MatchScoreThreshold {
                                people.matchScore = matchScore
                                matchedPeople.append(people)
                            }
                        }
                    }
                    return (embeddingsString, matchedPeople)
                } else {
                    return (nil, nil)
                }
            } else {
                return (nil, nil)
            }
        } catch {
            return (nil, nil)
        }
    }
    
    func identify(embeddingsOne: String, embeddingsTwo: String) -> Bool {
        let embeddingsArrayOne = embeddingsOne.components(separatedBy: ",")
        let embeddingsFloatArrayOne = embeddingsArrayOne.compactMap { Float($0)}
        let identityOne = PNEmbeddings(vector: embeddingsFloatArrayOne)
        
        let embeddingsArrayTwo = embeddingsTwo.components(separatedBy: ",")
        let embeddingsFloatArrayTwo = embeddingsArrayTwo.compactMap { Float($0)}
        let identityTwo = PNEmbeddings(vector: embeddingsFloatArrayTwo)
        
        let matchScore = identityOne.getMatchScore(identityTwo)
        if matchScore >= Constants.MatchScoreThreshold {
            return true
        } else {
            return false
        }
    }
}
