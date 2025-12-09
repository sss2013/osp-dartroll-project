import Flutter
import UIKit
import NaverThirdPartyLogin

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // --- 네이버 로그인 SDK 초기화 ---
    let naverConnection = NaverThirdPartyLoginConnection.getSharedInstance()

    // 1. Info.plist로부터 안전하게 설정 값 불러오기
    guard let naverConsumerKey = Bundle.main.object(forInfoDictionaryKey: "NAVER_CONSUMER_KEY") as? String,
          let naverConsumerSecret = Bundle.main.object(forInfoDictionaryKey: "NAVER_CONSUMER_SECRET") as? String,
          let naverAppName = Bundle.main.object(forInfoDictionaryKey: "NAVER_APP_NAME") as? String,
          let naverUrlScheme = Bundle.main.object(forInfoDictionaryKey: "NAVER_URL_SCHEME") as? String else {
      fatalError("네이버 로그인 설정이 Info.plist에 없습니다.") // 필수 값이 없으면 앱을 강제 종료하여 문제를 즉시 알림
    }

    // 2. SDK에 설정 값 적용 (한 번만 깔끔하게)
    naverConnection?.isNaverAppOauthEnable = true // 네이버앱으로 인증 활성화
    naverConnection?.isInAppOauthEnable = true   // 인앱 브라우저 인증 활성화

    naverConnection?.serviceUrlScheme = naverUrlScheme
    naverConnection?.consumerKey = naverConsumerKey
    naverConnection?.consumerSecret = naverConsumerSecret
    naverConnection?.appName = naverAppName

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // --- 로그인 후 결과를 처리하기 위한 필수 코드 ---
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // 네이버 앱 또는 웹에서 로그인이 끝나고 내 앱으로 돌아왔을 때 이 부분이 호출됨
    let result = NaverThirdPartyLoginConnection.getSharedInstance().application(app, open: url, options: options)
    if result {
      // 네이버 로그인 콜백이 성공적으로 처리된 경우
      return true
    }

    // 다른 종류의 URL 콜백이 있다면 여기서 처리

    return super.application(app, open: url, options: options)
  }
}