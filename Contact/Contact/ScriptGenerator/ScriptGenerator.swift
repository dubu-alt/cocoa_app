import Foundation

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
