import Foundation

/// 파일명을 NFC(완성형)로 직접 변환하는 클래스.
/// 샌드박스 환경에서 외부 셸(/bin/sh)은 드래그로 받은 파일 접근 권한을
/// 상속받지 못해 실패할 수 있으므로, FileManager로 앱 프로세스 안에서 직접 변환한다.
struct RenameResult {
    var renamed = 0
    var failed = 0
}

class NfcRenamer {
    private let fileManager = FileManager.default

    func rename(_ urls: [URL]) -> RenameResult {
        var result = RenameResult()
        for url in urls {
            renameRecursively(url, &result)
        }
        return result
    }

    private func renameRecursively(_ url: URL, _ result: inout RenameResult) {
        // 하위 항목 먼저 처리 (자식 → 부모 순서로 이름 변경)
        if url.isDirectory && !url.path.hasSuffix(".app") {
            if let subpaths = try? fileManager.contentsOfDirectory(atPath: url.path) {
                for sub in subpaths {
                    renameRecursively(url.appendingPathComponent(sub), &result)
                }
            }
        }

        if url.isHidden {   // eg. .DS_Store
            return
        }

        renameSingle(url, &result)
    }

    private func renameSingle(_ url: URL, _ result: inout RenameResult) {
        let name = url.lastPathComponent
        let nfcName = name.precomposedStringWithCanonicalMapping

        // 이미 NFC면 건너뜀 (Swift의 ==는 정규화 차이를 무시하므로 바이트 단위 비교)
        if Array(name.utf8) == Array(nfcName.utf8) {
            return
        }

        // APFS/HFS+는 NFD/NFC 이름을 같은 파일로 취급하므로
        // 임시 이름을 거쳐 두 단계로 변경한다.
        let dir = url.deletingLastPathComponent()
        let tmpName = nfcName + ".nfctmp_" + String(UUID().uuidString.prefix(8))
        let tmpUrl = dir.appendingPathComponent(tmpName)
        let dstUrl = dir.appendingPathComponent(nfcName)

        do {
            try fileManager.moveItem(at: url, to: tmpUrl)
        } catch {
            NSLog("NFC rename failed (step 1) for \(url.path): \(error)")
            result.failed += 1
            return
        }

        do {
            try fileManager.moveItem(at: tmpUrl, to: dstUrl)
            result.renamed += 1
        } catch {
            NSLog("NFC rename failed (step 2) for \(url.path): \(error)")
            try? fileManager.moveItem(at: tmpUrl, to: url)  // 원래 이름으로 복구
            result.failed += 1
        }
    }
}

class ScriptGenerator {
    let urls: [URL]
    
    init(_ urls: [URL]) {
        self.urls = urls
    }
    
    func saveToFile(_ url: URL) -> Bool {
        let data = generateData()
        do {
            try data.write(to: url)
            return true
        } catch let error as NSError {
            let alert = AlertDialog(error)
            alert.showDialogModal()
            return false
        }
    }
    
    private func generateData() -> Data {
        var content = Data.init()
        content.append(generateShebang())
        content.append(generateRenameScript(self.urls))
        return content
    }
    
    private func generateShebang() -> Data {
        var content = Data.init()
        content.append("#!/bin/bash\n".data(using: .ascii)!)
        return content
    }
    
    private func generateRenameScript(_ urls: [URL]) -> Data {
        var content = Data.init()
        
        for url in urls {
            if url.isDirectory && !url.path.hasSuffix(".app") {
                let subpaths = try! FileManager.default.contentsOfDirectory(atPath: url.path)
                let subUrls = stringsToUrls(subpaths, basePath: url.path)
                content.append(generateRenameScript(subUrls))
            }
            
            if url.isHidden {   // eg. .DS_Store
                continue
            }
            
            let decomp = UrlDecomposition(url)
            let path = decomp.pathPart.replacingOccurrences(of: "\"", with: "\\\"")
            let file = decomp.lastPart.replacingOccurrences(of: "\"", with: "\\\"")
            let nfcFile = file.precomposedStringWithCanonicalMapping

            // 이미 NFC(완성형)인 파일명은 건너뜀
            // (Swift의 ==는 정규화 차이를 무시하므로 반드시 바이트 단위로 비교해야 함)
            if Array(file.utf8) == Array(nfcFile.utf8) {
                continue
            }

            // APFS/HFS+는 NFD/NFC 이름을 같은 파일로 취급하여
            // mv가 "are identical" 오류로 실패하므로 임시 이름을 거쳐 두 단계로 변경
            let src = "\(path)\(file)"
            let tmp = "\(path)\(nfcFile).nfc_tmp_$$"
            let dst = "\(path)\(nfcFile)"
            content.append("mv -f \"\(src)\" \"\(tmp)\"\n".data(using: .utf8)!)
            content.append("mv -f \"\(tmp)\" \"\(dst)\"\n".data(using: .utf8)!)
        }
        
        return content
    }
    
}

extension URL {
    /// `true` is hidden (invisible) or `false` is not hidden (visible)
    var isHidden: Bool {
        get {
            return (try? resourceValues(forKeys: [.isHiddenKey]))?.isHidden == true
        }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.isHidden = newValue
            do {
                try setResourceValues(resourceValues)
            } catch {
                print("isHidden error:", error)
            }
        }
    }
}
