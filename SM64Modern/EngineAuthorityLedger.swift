import Foundation

/// Explicit owner for each product domain while the full Swift twin is being
/// migrated.  The compatibility side is intentionally named as a bridge: it
/// is not allowed to become an implicit second authority.
enum SM64ModernSwiftEngineDomainOwner: String, CaseIterable, Equatable, Sendable {
    case swift
    case cCompatibilityBridge = "c_compatibility_bridge"
}

/// A closed, value-semantic partition of the engine domains.  Swift runtime
/// construction validates this partition so adding a new domain without
/// assigning an owner cannot silently widen the C compatibility path.
struct SM64ModernSwiftEngineAuthorityLedger: Equatable, Sendable {
    let owners: [SM64ModernSwiftEngineDomain: SM64ModernSwiftEngineDomainOwner]

    init(readiness: SM64ModernSwiftEngineDomainReadiness) {
        var owners: [SM64ModernSwiftEngineDomain: SM64ModernSwiftEngineDomainOwner] = [:]
        for domain in SM64ModernSwiftEngineDomain.allCases {
            owners[domain] = readiness.isSwiftOwned(domain)
                ? .swift
                : .cCompatibilityBridge
        }
        self.owners = owners
    }

    var isPartitioned: Bool {
        Set(owners.keys) == Set(SM64ModernSwiftEngineDomain.allCases)
            && owners.values.allSatisfy { _ in true }
    }

    func owner(of domain: SM64ModernSwiftEngineDomain) -> SM64ModernSwiftEngineDomainOwner {
        guard let owner = owners[domain] else {
            preconditionFailure("engine authority ledger omitted domain \(domain.rawValue)")
        }
        return owner
    }

    var swiftOwnedDomains: [SM64ModernSwiftEngineDomain] {
        sortedDomains(ownedBy: .swift)
    }

    var cCompatibilityBridgeDomains: [SM64ModernSwiftEngineDomain] {
        sortedDomains(ownedBy: .cCompatibilityBridge)
    }

    var unassignedDomains: [SM64ModernSwiftEngineDomain] {
        SM64ModernSwiftEngineDomain.allCases.filter { owners[$0] == nil }
    }

    var swiftOwnedDescription: String {
        swiftOwnedDomains.map(\.rawValue).joined(separator: ",")
    }

    var cCompatibilityBridgeDescription: String {
        cCompatibilityBridgeDomains.map(\.rawValue).joined(separator: ",")
    }

    private func sortedDomains(
        ownedBy owner: SM64ModernSwiftEngineDomainOwner
    ) -> [SM64ModernSwiftEngineDomain] {
        owners.compactMap { domain, candidate in
            candidate == owner ? domain : nil
        }.sorted { $0.rawValue < $1.rawValue }
    }
}
