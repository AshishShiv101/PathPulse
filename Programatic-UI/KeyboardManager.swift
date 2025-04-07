import UIKit

class KeyboardManager {
    static let shared = KeyboardManager()
    private var isObserving = false
    
    private init() {}

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardHeight = keyboardFrame.cgRectValue.height

            if let window = UIApplication.shared.windows.first {
                UIView.animate(withDuration: 0.3) {
                    window.frame.origin.y = -keyboardHeight / 2
                }
            }
        }
    }
    @objc private func keyboardWillHide(notification: NSNotification) {
        if let window = UIApplication.shared.windows.first {
            UIView.animate(withDuration: 0.3) {
                window.frame.origin.y = 0
            }
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
