/*
 * CTDisplayLink
 * Ported from SDWebImage's SDDisplayLink (iOS path only).
 * A CADisplayLink wrapper that avoids retaining its target via CTWeakProxy.
 *
 * Key SDWebImage source references:
 *   - initWithTarget:selector:     → SDDisplayLink.m:65–89
 *   - duration property            → SDDisplayLink.m:98–161
 *   - isRunning                    → SDDisplayLink.m:164–172
 *   - addToRunLoop:forMode:        → SDDisplayLink.m:174–195
 *   - removeFromRunLoop:forMode:   → SDDisplayLink.m:197–218
 *   - start / stop                 → SDDisplayLink.m:220–246
 *   - displayLinkDidRefresh:       → SDDisplayLink.m:250–265
 *
 * macOS (CVDisplayLink) and watchOS (NSTimer) paths omitted — iOS only.
 */

import QuartzCore

// Use targetTimestamp on iOS 10+ for accurate duration (WWDC Session 10147).
// The ObjC original cached this in a static BOOL (kCTDisplayLinkUseTargetTimestamp)
// and accessed targetTimestamp under a -Wunguarded-availability pragma. Swift can't
// suppress that warning, so the cached flag is folded into the equivalent
// `if #available(iOS 10.0, *)` checks at the access sites (behavior is identical).

@objc(CTDisplayLink)
@objcMembers
final class CTDisplayLink: NSObject {

    private(set) weak var target: AnyObject?
    private(set) var selector: Selector

    /// Elapsed time in seconds of the previous display frame. Zero when not running.
    var duration: TimeInterval {
        var duration: TimeInterval = 0
        if #available(iOS 10.0, *) {
            let nextFireTime = self.nextFireTime
            if nextFireTime != 0 {
                duration = displayLink.targetTimestamp - nextFireTime
            } else {
                duration = displayLink.duration
            }
        } else {
            let previousFireTime = self.previousFireTime
            if previousFireTime != 0 {
                duration = displayLink.timestamp - previousFireTime
            } else {
                duration = displayLink.duration
            }
        }
        // Fallback when system sleeps (duration goes negative).
        if duration < 0 {
            duration = displayLink.duration
        }
        return duration
    }

    var isRunning: Bool {
        return !displayLink.isPaused
    }

    private var displayLink: CADisplayLink!
    private var previousFireTime: TimeInterval = 0
    private var nextFireTime: TimeInterval = 0

    deinit {
        displayLink?.invalidate()
        displayLink = nil
    }

    private init(target: AnyObject, selector sel: Selector) {
        self.target = target
        self.selector = sel
        super.init()
        // Use weak proxy so CADisplayLink doesn't retain self (and thus target).
        // Mirrors SDDisplayLink.m:70–83.
        let weakProxy = CTWeakProxy(target: self)
        displayLink = CADisplayLink(target: weakProxy, selector: #selector(displayLinkDidRefresh(_:)))
    }

    @objc(displayLinkWithTarget:selector:)
    static func displayLink(withTarget target: AnyObject, selector sel: Selector) -> CTDisplayLink {
        return CTDisplayLink(target: target, selector: sel)
    }

    @objc(addToRunLoop:forMode:)
    func add(to runloop: RunLoop?, forMode mode: RunLoop.Mode?) {
        guard let runloop = runloop, let mode = mode else { return }
        displayLink.add(to: runloop, forMode: mode)
    }

    @objc(removeFromRunLoop:forMode:)
    func remove(from runloop: RunLoop?, forMode mode: RunLoop.Mode?) {
        guard let runloop = runloop, let mode = mode else { return }
        displayLink.remove(from: runloop, forMode: mode)
    }

    func start() {
        displayLink.isPaused = false
    }

    func stop() {
        displayLink.isPaused = true
        previousFireTime = 0
        nextFireTime = 0
    }

    // CADisplayLink callback — forward to actual target via weak proxy.
    // Mirrors SDDisplayLink.displayLinkDidRefresh: (line 250).
    func displayLinkDidRefresh(_ displayLink: CADisplayLink) {
        _ = target?.perform(selector, with: self)
        if #available(iOS 10.0, *) {
            nextFireTime = displayLink.targetTimestamp
        } else {
            previousFireTime = displayLink.timestamp
        }
    }
}
