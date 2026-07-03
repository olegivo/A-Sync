import Foundation

/// Разрешение конфликтов имён при сохранении файлов в папку назначения.
///
/// Вынесено в отдельный тип без зависимостей от ImageCaptureCore/файловой системы,
/// чтобы поведение можно было полностью покрыть модульными тестами на CI.
public struct FilenameResolver {

    public init() {}

    /// Возвращает имя файла, не конфликтующее с уже занятыми именами.
    ///
    /// Если `proposed` свободно — возвращается как есть. Иначе к базовой части имени
    /// добавляется суффикс `-1`, `-2`, ... до первого свободного варианта, а расширение
    /// сохраняется. Регистр учитывается так же, как в переданном множестве `existing`.
    ///
    /// - Parameters:
    ///   - proposed: Желаемое имя файла (например, `IMG_0001.HEIC`).
    ///   - existing: Уже занятые имена в целевой папке.
    /// - Returns: Уникальное имя файла.
    public func uniqueFilename(for proposed: String, existing: Set<String>) -> String {
        guard existing.contains(proposed) else { return proposed }

        let ns = proposed as NSString
        let ext = ns.pathExtension
        let base = ns.deletingPathExtension

        var index = 1
        while true {
            let candidate = ext.isEmpty ? "\(base)-\(index)" : "\(base)-\(index).\(ext)"
            if !existing.contains(candidate) {
                return candidate
            }
            index += 1
        }
    }
}
