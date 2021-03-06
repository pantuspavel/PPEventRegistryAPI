//
//  PPConcept.swift
//  PPEventRegistryAPI
//
//  Created by Pavel Pantus on 10/9/16.
//  Copyright © 2016 Pavel Pantus. All rights reserved.
//

import Foundation

/// A concept is an annotation that can be assigned to an article, story or event.
public struct PPConcept {
    let identifier: String
    let description: String
    let uri: URL?
    let image: URL?
    let score: Int
}
