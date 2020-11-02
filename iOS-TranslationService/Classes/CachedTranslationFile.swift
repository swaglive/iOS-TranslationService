//
//  CachedTranslationFile.swift
//  Pods
//
//  Created by peter on 2020/11/2.
//

import Foundation

fileprivate class DataFileAccess {
    private static let queue = DispatchQueue(label: "com.swag.datafile.access", attributes: .concurrent)
    
    class func write(_ data: Data, toURL dataFileWithPathURL: URL) {
        queue.async(flags: .barrier) {
            do {
                try data.write(to: dataFileWithPathURL, options: .atomic)
            } catch (let error) {
                debugPrint("[DataFileAccess] write data failure: \(error.localizedDescription)")
            }
        }
    }
    class func read(from dataFileWithPathURL: URL) -> Data? {
        guard FileManager.default.fileExists(atPath: dataFileWithPathURL.path) else {
            return nil
        }
        var result: Data?
        queue.sync {
            do {
                result = try Data(contentsOf: dataFileWithPathURL, options: .uncached)
            } catch (let error) {
                debugPrint("[DataFileAccess] read data failure: \(error.localizedDescription)")
            }
        }
        return result
    }
}

public class CachedTranslationFile {

    private var dataFileWithPathURL: URL
    
    public init(dataDirectory: String) {
        self.dataFileWithPathURL = URL(fileURLWithPath: dataDirectory).appendingPathComponent("translation.dat")
    }
    
    public func save(_ metadata: [String: String]) {
        do {
            let data = try JSONSerialization.data(withJSONObject:metadata)
            DataFileAccess.write(data, toURL: dataFileWithPathURL)
        } catch (let error) {
            debugPrint("[CachedTranslationFile] save data failure: \(error.localizedDescription)")
        }
    }
    public func restore() -> [String: String] {
        guard let data = DataFileAccess.read(from: dataFileWithPathURL) else {
            return [:]
        }
        do {
            if let configs = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                return configs
            }
            return [:]
        } catch (let error) {
            debugPrint("[CachedTranslationFile] read data failure: \(error.localizedDescription)")
            
        }
        return [:]
    }
}
