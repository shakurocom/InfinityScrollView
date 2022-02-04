//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Popov
//

import UIKit

extension UICollectionView {

    public func dequeueReusableCell<T: UICollectionViewCell>(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> T {
        guard let cell = self.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? T else {
            fatalError("\(type(of: self)) - \(#function): can't dequeue cell with identifier: \(identifier); indexPath: \(indexPath).")
        }
        return cell
    }

    public func dequeueReusableSupplementaryView<T: UICollectionReusableView>(ofKind kind: String,
                                                                              withReuseIdentifier identifier: String,
                                                                              for indexPath: IndexPath) -> T {
        let supplementaryView = self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath)
        guard let typedView = supplementaryView as? T else {
            fatalError("\(type(of: self)) - \(#function): " +
                "can't dequeue supplemenary view of kind \(kind) with identifier: \(identifier); indexPath: \(indexPath).")
        }
        return typedView
    }

}
