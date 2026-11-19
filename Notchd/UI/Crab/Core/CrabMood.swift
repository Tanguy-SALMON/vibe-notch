//
//  CrabMood.swift
//  Notchd
//

import Foundation

/// Animation state of the crab icon, derived from session activity
enum CrabMood: Hashable {
    case idle        // Nothing happening: occasional blink
    case processing  // Working: scuttling legs with a tiny side-step
    case waiting     // Finished, waiting for input: small hop + pincer wave on entry, then idle blinks
    case alert       // Permission pending: gentle wiggle every few seconds
}
