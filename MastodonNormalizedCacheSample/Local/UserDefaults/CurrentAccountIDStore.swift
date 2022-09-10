import Foundation

struct CurrentAccountIDStore {
    private enum Constants {
        static let currentAccountIDKey = "current_account_id"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func save(_ accountID: Account.ID) {
        userDefaults.set(accountID, forKey: Constants.currentAccountIDKey)
    }

    func load() -> Account.ID? {
        userDefaults.string(forKey: Constants.currentAccountIDKey)
    }

    func delete() {
        userDefaults.removeObject(forKey: Constants.currentAccountIDKey)
    }
}
