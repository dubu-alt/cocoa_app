//
//  NSDraggingInfo+FilePathURL.swift
//  ADragDropViewExample
//
//  Created by Soulchild on 24/09/2018.
//  Copyright © 2018 fluffy. All rights reserved.
//

import Foundation
import AppKit

extension NSDraggingInfo {
    var filePathURLs: [URL] {
        // 샌드박스 앱은 readObjects(forClasses:)로 URL을 읽어야
        // 드래그된 파일에 대한 접근 권한(sandbox extension)이 부여된다.
        // 구형 NSFilenamesPboardType(경로 문자열)으로 받으면 권한 없이
        // 경로만 얻게 되어 파일 조작이 전부 실패한다.
        if let urls = draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL], !urls.isEmpty {
            return urls
        }
        return []
    }
}
