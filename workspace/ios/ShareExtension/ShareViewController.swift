import Photos
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let statusLabel = UILabel()
    private let detailLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private var didStartRouting = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard didStartRouting == false else { return }
        didStartRouting = true

        Task { [weak self] in
            await self?.routeToApp()
        }
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .preferredFont(forTextStyle: .headline)
        statusLabel.textAlignment = .center
        statusLabel.text = "Unfading 여는 중"

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailLabel.textAlignment = .center
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0
        detailLabel.text = "공유한 사진을 추억 기록 화면으로 보내고 있어요."

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("닫기", for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.isHidden = true

        view.addSubview(statusLabel)
        view.addSubview(detailLabel)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -24),

            detailLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            detailLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            closeButton.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 20),
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    @objc
    private func closeTapped() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func routeToApp() async {
        let reference = await resolvePhotoReference()
        var components = URLComponents()
        components.scheme = "unfading"
        components.host = "composer"
        if let reference {
            components.queryItems = [URLQueryItem(name: "photo", value: reference)]
        }

        guard let url = components.url else {
            showFailure()
            return
        }

        extensionContext?.open(url) { [weak self] success in
            if success {
                self?.extensionContext?.completeRequest(returningItems: nil)
            } else {
                self?.showFailure()
            }
        }
    }

    private func showFailure() {
        DispatchQueue.main.async {
            self.statusLabel.text = "사진을 바로 열지 못했어요"
            self.detailLabel.text = "Unfading 앱을 직접 연 뒤 추억 기록 화면에서 다시 선택해주세요."
            self.closeButton.isHidden = false
        }
    }

    private func resolvePhotoReference() async -> String? {
        let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []

        for item in items {
            for provider in item.attachments ?? [] {
                if let assetIdentifier = await loadAssetIdentifier(from: provider) {
                    return assetIdentifier
                }
                if let tempPath = await loadImageTempPath(from: provider) {
                    return tempPath
                }
            }
        }

        return nil
    }

    private func loadAssetIdentifier(from provider: NSItemProvider) async -> String? {
        let candidates = provider.registeredTypeIdentifiers.filter {
            $0.localizedCaseInsensitiveContains("localidentifier")
                || $0.localizedCaseInsensitiveContains("phasset")
                || $0.localizedCaseInsensitiveContains("asset")
        }

        for typeIdentifier in candidates {
            if let value = await loadStringItem(from: provider, typeIdentifier: typeIdentifier) {
                return value
            }
        }

        return nil
    }

    private func loadImageTempPath(from provider: NSItemProvider) async -> String? {
        guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else { return nil }

        return await withCheckedContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, _ in
                continuation.resume(returning: url?.path)
            }
        }
    }

    private func loadStringItem(from provider: NSItemProvider, typeIdentifier: String) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                if let string = item as? String {
                    continuation.resume(returning: string)
                    return
                }
                if let data = item as? Data, let string = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: string)
                    return
                }
                if let url = item as? URL {
                    continuation.resume(returning: url.absoluteString)
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }
}
