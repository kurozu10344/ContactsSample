import UIKit
import Contacts

class ContactListViewController: UITableViewController {
    
    var contacts: [CNContact] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 利用可否の確認
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .notDetermined:
            // 初回アクセス時
            CNContactStore().requestAccess(for: .contacts) { (granted, error) in
                if granted {
                    self.loadContacts()
                }
                else {
                    let alert = UIAlertController(title: "Authorization Error", message: "\(error?.localizedDescription ?? "")", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }

        case .authorized:
            // アクセス許可済
            loadContacts()
            
        case .restricted:
            // ペアレンタルコントロール等の機能制限により利用不可
            let alert = UIAlertController(title: "Authorization Error", message: "restricted", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        case .denied:
            // アクセス拒否済
            let alert = UIAlertController(title: "Authorization Error", message: "denied", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func loadContacts() {
        DispatchQueue.global().async {
            let store = CNContactStore()
            let keys: [CNKeyDescriptor] = [
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]
            let fetchRequest = CNContactFetchRequest(keysToFetch: keys)
            var contacts: [CNContact] = []
            try? store.enumerateContacts(with: fetchRequest) { contact, cursor in
                contacts.append(contact)
            }
            self.contacts = contacts
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
}


// MARK: UITableView
extension ContactListViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let contact = contacts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "contact", for: indexPath)
        let fullName = CNContactFormatter.string(from: contact, style: .fullName)
        cell.textLabel?.text = fullName
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = contacts[indexPath.row]
        
        let message = """
        姓: \(contact.familyName)
        名: \(contact.givenName)
        フルネーム: \(CNContactFormatter.string(from: contact, style: .fullName) ?? "")
        メールアドレス(複数): \(contact.emailAddresses.map { $0.value as String }.joined(separator: ", "))
        電話番号(複数): \(contact.phoneNumbers.map { $0.value.stringValue }.joined(separator: ", "))
        """
        
        let alert = UIAlertController(title: "連絡先", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
