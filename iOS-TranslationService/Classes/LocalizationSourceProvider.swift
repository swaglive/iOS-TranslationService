//
//  LocalizationSourceProvider.swift
//  SWAG
//
//  Created by peter on 2020/3/14.
//  Copyright © 2020 Machipopo Corp. All rights reserved.
//

import Foundation

public extension Notification.Name {
    static let DidUpdateLocalization = Notification.Name("DidUpdateLocalization")
}

@objcMembers
public class LocalizationSourceProvider: NSObject {
    private let url: URL
    private let session: URLSession
    private(set) var translation: [String: String] = [:]
    private let appLanguageCode: String
    private let cachedFile: CachedTranslationFile
    
    private var localEtag: String? {
        set {
            UserDefaults.standard.setValue(newValue, forKey: AppDefaultsKeys.translationsEtag)
        }
        get {
            return UserDefaults.standard.string(forKey: AppDefaultsKeys.translationsEtag)
        }
    }
    
    private var languageCode: String? {
        set {
            UserDefaults.standard.setValue(newValue, forKey: AppDefaultsKeys.languageCode)
        }
        get {
            return UserDefaults.standard.string(forKey: AppDefaultsKeys.languageCode)
        }
    }

    init(urlString: String, appLanguageCode: String, cachedFile: CachedTranslationFile) {
        self.url = URL(string: urlString)!
        self.appLanguageCode = appLanguageCode
        self.cachedFile = cachedFile
        let sessionConfig = URLSessionConfiguration.default
        self.session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        super.init()
        loadFromFile()
        if appLanguageCode != languageCode {
            fetch()
        } else {
            checkIsUpdated()
        }
    }
    
    private func loadFromFile() {
        translation = cachedFile.restore()
    }
    private func saveToFile() {
        cachedFile.save(translation)
    }
    
    private func checkIsUpdated() {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        let task = session.dataTask(with: request, completionHandler: {[weak self] (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard error == nil,
                let resp = response as? HTTPURLResponse,
                resp.statusCode == 200 else {
                return
            }
            if let etag = resp.allHeaderFields["Etag"] as? String {
                self?.validate(etag)
            }
        })
        task.resume()
    }

    private func validate(_ etag: String) {
        let currentLanguageCode = appLanguageCode
        if currentLanguageCode != languageCode ||  localEtag != etag  {
            fetch()
        }
    }

    private func fetch() {

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = session.dataTask(with: request, completionHandler: { [weak self] (data: Data?, response: URLResponse?, error: Error?) -> Void in
          if (error == nil) {

            if let data = data, let resp = response as? HTTPURLResponse {
                
                if let etag = resp.allHeaderFields["Etag"] as? String {
                    self?.localEtag = etag
                }
                self?.languageCode = self?.appLanguageCode

                let str = String(decoding: data, as: UTF8.self)

                if let jsonData = str.data(using: .utf8),
                    let jsonDict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: String] {
                    self?.translation = jsonDict ?? [:]
                    self?.saveToFile()
                    NotificationCenter.default.post(name: Notification.Name.DidUpdateLocalization, object: nil)
                }
            }
          }
          else {
              debugPrint("URL Session Task Failed: %@", error!.localizedDescription);
          }
        })
        task.resume()
    }
}
