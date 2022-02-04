//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Popov
//

import UIKit

extension UITableView {

    public func dequeueReusableCell<T: UITableViewCell>(indexPath: IndexPath, reuseIdentifier: String) -> T {
        guard let cell = self.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath as IndexPath) as? T else {
            fatalError("\(type(of: self)) - \(#function): can't dequeue cell with identifier: \(reuseIdentifier); indexPath: \(indexPath).")
        }
        return cell
    }

    public func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>(reuseIdentifier: String) -> T {
        guard let view = self.dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier) as? T else {
            fatalError("\(type(of: self)) - \(#function): can't dequeue headerFooterView with identifier: \(reuseIdentifier).")
        }
        return view
    }

}
