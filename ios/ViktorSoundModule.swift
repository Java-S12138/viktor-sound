import ExpoModulesCore
import AVFoundation

// 声音模块定义
public class ViktorSoundModule: Module {
    private var audioPlayer: AVAudioPlayer?        // 音频播放器实例
    private var isPlaying: Bool = false            // 是否正在播放音频
    private var audioDelegate: AudioPlayerDelegate? // 播放完成后的回调处理
    private var urlSession: URLSession!            // 用于音频下载的 URLSession
    private var currentTask: URLSessionDataTask?   // 当前的下载任务

    // 模块初始化方法（必须实现）
    public required init(appContext: AppContext) {
        super.init(appContext: appContext)
    }

    // 模块定义
    public func definition() -> ModuleDefinition {
        Name("ViktorSound") // 模块名

        // 模块创建时初始化网络会话配置
        OnCreate {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 3 // 超时3秒
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.urlSession = URLSession(configuration: config)
        }


        // 播放指定 URL 音频（支持自定义 header）
        Function("playWithHeaders") { (word: String,type:String, headers: [String: String]?) throws in
            try self.playAudio(word: word,type:type,headers: headers)
        }
    }

    // 播放音频主函数，检查 URL 与播放状态
    private func playAudio(word: String,type:String, headers: [String: String]?) throws {
    
        guard !isPlaying else {
            throw AudioError.alreadyPlaying
        }

        cleanup()
        isPlaying = true
        try tryPlayAudio(word: word,type:type, headers: headers, isRetry: false)
    }

    // 尝试播放音频（可重试一次）
    private func tryPlayAudio(word: String,type:String, headers: [String: String]?, isRetry: Bool) throws {
        let url = isRetry
            ? "https://dict.youdao.com/dictvoice?type=\(type == "uk" ? "1" : "0")&audio=\(word)"
            : "https://pron.lolfrank.cn/pron/\(word)_\(type).mp3"
        
        guard let audioUrl = URL(string: url) else {
                 throw AudioError.invalidUrl(url)
             }

        var request = URLRequest(url: audioUrl)
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let semaphore = DispatchSemaphore(value: 0)
        var taskError: Error?
        var taskData: Data?

        // 发起网络请求下载音频数据
        let task = urlSession.dataTask(with: request) { [weak self] data, _, error in
            guard let self else {
                taskError = AudioError.moduleDeallocated
                semaphore.signal()
                return
            }

            guard isPlaying else {
                taskError = AudioError.interrupted
                semaphore.signal()
                return
            }

            if error != nil || data == nil {
                taskError = AudioError.downloadFailed(error?.localizedDescription ?? "No data received")
                taskData = nil
            } else {
                taskData = data
            }
            semaphore.signal()
        }
        currentTask = task
        task.resume()

        semaphore.wait()
        currentTask = nil

        // 错误处理
        if let error = taskError {
            isPlaying = false
            throw error
        }

        // 无数据处理
        guard let data = taskData else {
            isPlaying = false
            throw AudioError.noData
        }
        
        if !isMP3Format(data:data) && !isRetry {
            try tryPlayAudio(word: word,type: type, headers: headers, isRetry: true)
            return
        }
        

        // 播放音频
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioDelegate = AudioPlayerDelegate { [weak self] in
                self?.cleanup()
            }
            audioPlayer?.delegate = audioDelegate
            audioPlayer?.play()
        } catch {
            if !isRetry {
                try tryPlayAudio(word: word,type: type, headers: headers, isRetry: true)
                return
            }
            isPlaying = false
            throw AudioError.playbackFailed(error.localizedDescription)
        }
    }
    
    // 验证是否为 MP3 格式
    private func isMP3Format(data: Data) -> Bool {
        guard data.count >= 4 else { return false }
        
        let header = data.prefix(4)
        let bytes = Array(header)
        
        // MP3 文件头
        if bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0 {
            return true // MP3
        }
        
        // WAV 文件头 "RIFF"
        if bytes == [0x52, 0x49, 0x46, 0x46] {
            return true // WAV
        }

        return false
    }

    // 清理播放状态
    private func cleanup() {
        currentTask?.cancel()
        currentTask = nil
        audioPlayer?.stop()
        audioPlayer?.delegate = nil
        audioPlayer = nil
        audioDelegate = nil
        isPlaying = false
    }
}

// 自定义 AVAudioPlayerDelegate 实现类
private class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinished: () -> Void

    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinished()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        onFinished()
    }
}

// 音频播放中可能出现的错误类型定义
private enum AudioError: Error {
    case invalidUrl(String)
    case alreadyPlaying
    case interrupted
    case downloadFailed(String)
    case playbackFailed(String)
    case noData
    case moduleDeallocated
    case fallbackFailed(String)

    // 错误码
    var code: String {
        switch self {
        case .invalidUrl: return "INVALID_URL"
        case .alreadyPlaying: return "ALREADY_PLAYING"
        case .interrupted: return "INTERRUPTED"
        case .downloadFailed: return "DOWNLOAD_ERROR"
        case .playbackFailed: return "PLAYBACK_ERROR"
        case .noData: return "NO_DATA"
        case .moduleDeallocated: return "INTERNAL_ERROR"
        case .fallbackFailed: return "FALLBACK_FAILED"
        }
    }

    // 错误描述信息
    var message: String {
        switch self {
        case .invalidUrl(let url): return "Invalid URL: \(url)"
        case .alreadyPlaying: return "Audio is already playing"
        case .interrupted: return "Playback was interrupted"
        case .downloadFailed(let msg): return msg
        case .playbackFailed(let msg): return "Playback failed: \(msg)"
        case .noData: return "No data received"
        case .moduleDeallocated: return "Module deallocated"
        case .fallbackFailed(let msg): return msg
        }
    }
}
