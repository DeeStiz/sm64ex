import Foundation

@main
enum SM64ModernNextBehaviorTraceFilter {
    static func main() {
        let path = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/sm64-modern-debug/live-schema4.trace"
        do {
            let trace = try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path))
            print("records=\(trace.records.count) domains=\(Set(trace.records.map { $0.domain }))")
            let objectIDs = Dictionary(grouping: trace.records.filter { $0.domain == 3 }, by: { $0.recordID })
            print("object_record_ids=\(objectIDs.keys.sorted().map { String($0) })")
            for (index, record) in trace.records.enumerated() {
                if index < 12 {
                    print("head i=\(index) tick=\(record.simulationTick) dom=\(record.domain) kind=\(record.recordKind) id=0x\(String(record.recordID, radix: 16)) subject=\(record.subjectID) values=\(record.values)")
                }
                if record.values.contains(0x6268765F686D6365)
                    || record.values.contains(0x6268765F727265)
                    || record.values.contains(0x6268765F636F6E)
                    || record.recordID == 400 {
                    let values = record.values.map { String(format: "0x%016llx", $0) }.joined(separator: ",")
                    print("i=\(index) tick=\(record.simulationTick) dom=\(record.domain) kind=\(record.recordKind) id=0x\(String(record.recordID, radix: 16)) subject=\(record.subjectID) vals=\(values)")
                }
            }
        } catch {
            print("error=\(error)")
            exit(1)
        }
    }
}
