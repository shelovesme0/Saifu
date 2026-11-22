import UIKit

/// Повертає жест «назад» свайпом від лівого краю, коли системну панель навігації сховано
/// (на вкладених екранах вона замінена власною кнопкою «назад»).
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    /// Жест працює лише тоді, коли є куди повертатися.
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
